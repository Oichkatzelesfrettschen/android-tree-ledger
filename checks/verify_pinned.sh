#!/bin/sh
# Verifies every pin of one manifest in parallel and prints one TSV line per
# project; exits 1 when any pin fails.
# Usage: verify_pinned.sh MANIFEST_XML [JOBS]
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PYTHON=${PYTHON:-python3}
export PYTHON
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT INT TERM
"$PYTHON" -I "$here/pins_tsv.py" "$1" | tr '\t' ' ' | sed "s#\$# $scratch#" |
  xargs -P "${2:-8}" -L 1 sh -c 'sh "$0" "$1" "$2" "$3" "$4" "$5"' "$here/verify_one.sh" >"$scratch/out.tsv" || true
cat "$scratch/out.tsv"
if grep -q '^FAIL' "$scratch/out.tsv"; then exit 1; fi
