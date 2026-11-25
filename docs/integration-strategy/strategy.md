# Integration strategy for the retiring Android trees

Status (2026-11-25): carried out. 109 local refs pushed and verified as exact tips; all pins of the nine manifests verified (checks/results). Two owner decisions after the round change the course: the a11 and tuna lines roll into LineageOS 22.2 instead of a synth/lineage-19.1 branch, and the TWRP work moves onto twrp-14.1. Directory ids are devices/<device>/<track>, which replaces the manifest-id form below. Three open device-repository pull requests were merged on the owner's instruction.

Outcome of the red-team round (reports/, reconciliation.md) as integrated by the Advisor on 2026-11-24. The material/ tables are frozen as reviewed; corrected per-project data lives in devices/<manifest-id>/repos.tsv.

## Layout

- A manifest id names one pinned manifest and its ledger directory: m8-lineage-22.2, tuna-lineage-18.1, tuna-lineage-19.1, a11-lineage-18.1, a11-lineage-19.1, bullhead-lineage-22.2, m8-twrp-14.1, a11chl-twrp-11, twrp-12.1, plus the standalone kernels. matrix.tsv carries the products each manifest builds (m8-lineage-22.2 builds m8 and a11).
- dev/<manifest-id>/<track> in each owner repository points at the built HEAD of that project. The track is the upstream branch the tree follows (lineage-18.1, twrp-14.1).
- A dev/<device>/<track> ref exists only in a repository where local work was pushed; other projects pin an upstream or owner branch tip. Ledger dev refs move only by fast-forward, never by force.
- topic/<manifest-id>/<track>/<slug> holds every other local branch, under its own slug, so no work is squashed or dropped.
- No existing fork branch moves; nothing merges into a fork default branch in this round. A synth/<track> branch, where two devices share a fork and a release, is an open item with the reviewer's `git merge-tree --write-tree` command; its conflicts are unreproduced and a camera merge cannot be built on this host.
- Uncommitted and untracked files go into the ledger as devices/<manifest-id>/patches/<project>.patch or an overlay directory, after each file is read; they create no wip branch and no new fork.

## Pins and verification

- pinned.xml pins each project by remote, a refs/heads or refs/tags ref, and the 40-hex SHA.
- checks/verify_pinned.sh fetches only the named ref into a scratch repository and requires `git merge-base --is-ancestor SHA FETCH_HEAD`, or the GitHub compare API status ahead or identical for a non-tip SHA after calibration. It never fetches a bare SHA, because GitHub serves fork-only commits by SHA from the upstream of the fork network. Calibration: a fork ref holding its SHA passes; the upstream ref with a fork-only SHA fails; a refs/pull ref fails. Private remotes form their own class.
- A tree retires only when every pushed name is an exact `ls-remote --heads --tags` tip and the verifier passes on every pin of its manifest.

## Pushes

- Every ref is resolved again with `--heads --tags` only, across every remote of the checkout, and owner repositories are looked up by basename and as android_<path>.
- A shallow push into a fork network is untested on GitHub; two pilot units test it before any tree: a small shallow project into an existing fork, and one into a non-fork owner repository, each with SHAs absent from every ref of the target. The fallback is deepening that one project.

## Open items

- synth/<track> for the shared lineage-19.1 forks.
- Symlink, alternates and gitdir-pointer audit into the retiring trees.
- bullhead-lineage-22.2 manifest checkout: one local commit, saved as a patch.
- Owner decisions: merging the three open device-repository PRs, synthesis timing, and whether the msm8226 donors and toolchains/ retire.
