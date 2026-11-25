#!/bin/sh
# Verifies one pin: URL REF SHA PATH. PASS when SHA is the tip (or peeled tag) of
# REF, or an ancestor of REF by the GitHub compare API, or an ancestor after a
# blob-less fetch of REF alone. A bare SHA is never fetched, since GitHub serves a
# fork-only commit by SHA from every repository of its fork network. REF must be
# under refs/heads or refs/tags.
# Usage: verify_one.sh URL REF SHA PATH SCRATCH
set -eu
url=$1; ref=$2; sha=$3; path=$4; scratch=$5
out() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$path" "$url" "$ref" "$sha"; }
[ -n "$scratch" ] && [ -d "$scratch" ] || { out FAIL-no-scratch; exit 0; }
case "$ref" in refs/heads/[0-9a-f]*) [ "${#ref}" -eq 51 ] && ! echo "${ref#refs/heads/}" | grep -q '[^0-9a-f]' && ref=- ;; esac
case "$ref" in refs/heads/*|refs/tags/*|-) ;; *) out FAIL-ref-class; exit 0;; esac
if [ "$ref" != - ] && ! git ls-remote --exit-code "$url" "$ref" >/dev/null 2>&1; then ref=-; fi
# The configured credential helper (gh) authenticates private remotes; a missing
# credential fails the pin instead of opening an interactive or graphical prompt.
export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false SSH_ASKPASS=/bin/false
if [ "$ref" = - ]; then
  # A pin without an upstream ref passes only as the tip of some head or tag, or,
  # on GitHub, as an ancestor of the default branch; the ledger then names that ref.
  all=$(git ls-remote --heads --tags "$url" 2>/dev/null) || { out FAIL-ls-remote; exit 0; }
  hit=$(printf '%s\n' "$all" | awk -v s="$sha" '$1==s {print $2; exit}')
  [ -z "$hit" ] || { ref=$hit; out PASS-tip-noref; exit 0; }
  case "$url" in https://github.com/*)
    slug=$(echo "$url" | sed 's#https://github.com/##; s#[.]git$##')
    db=$(gh api "repos/$slug" --jq .default_branch 2>/dev/null || echo -)
    st=$(gh api "repos/$slug/compare/$sha...$db" --jq .status 2>/dev/null || echo error)
    case "$st" in ahead|identical) ref="refs/heads/$db"; out PASS-compare-noref; exit 0;; esac ;;
  esac
  db=$(git ls-remote --symref "$url" HEAD 2>/dev/null | awk '/^ref:/ {print $2; exit}')
  [ -n "$db" ] || { out FAIL-noref; exit 0; }
  d=$(mktemp -d "$scratch/vp.XXXXXX")
  git init -q --bare "$d"
  if git -C "$d" fetch -q --filter=blob:none "$url" "$db" 2>/dev/null && git -C "$d" merge-base --is-ancestor "$sha" FETCH_HEAD 2>/dev/null; then ref=$db; out PASS-fetch-noref; else out FAIL-noref; fi
  exit 0
fi
tips=$(git ls-remote "$url" "$ref" "$ref^{}" 2>/dev/null | cut -f1) || { out FAIL-ls-remote; exit 0; }
[ -n "$tips" ] || { out FAIL-ref-absent; exit 0; }
if printf '%s\n' "$tips" | grep -qx "$sha"; then out PASS-tip; exit 0; fi
case "$url" in
  https://github.com/*)
    slug=$(echo "$url" | sed 's#https://github.com/##; s#[.]git$##')
    st=$(gh api "repos/$slug/compare/$sha...${ref#refs/*/}" --jq .status 2>/dev/null || echo error)
    case "$st" in ahead|identical) out PASS-compare; exit 0;; diverged|behind) out "FAIL-compare-$st"; exit 0;; esac ;;
esac
d=$(mktemp -d "$scratch/vp.XXXXXX")
git init -q --bare "$d"
if git -C "$d" fetch -q --filter=blob:none "$url" "$ref" 2>/dev/null && git -C "$d" merge-base --is-ancestor "$sha" FETCH_HEAD 2>/dev/null; then out PASS-fetch; else out FAIL-not-ancestor; fi
