# Android tree ledger

This repository records how to recreate nine retired Android source trees from GitHub alone, and where every piece of their local work now lives. Each tree has a pinned manifest whose projects resolve to public commits; every local commit and branch is pushed to an owner repository under a `dev/` or `topic/` name; and a verifier proves each pin fetchable from the ref it names.

## Layout

- `devices/<device>/<track>/pinned.xml` is the tree's `repo manifest -r` output, rewritten for publication: relative remote URLs made absolute, the unused ssh remote dropped, and each project whose built HEAD was pushed pointed at the owner repository and its `dev/<device>/<track>` ref. Local manifests are already merged into it; `local_manifests/` keeps the originals for reference.
- `devices/<device>/<track>/repos.tsv` lists every pushed ref of that tree: source path and branch, owner repository, pushed name and SHA.
- `devices/<device>/<track>/patches/` holds uncommitted changes as `git diff` output (`<path>.patch`, with the base commit in `<path>.base`); `overlay/symlinks.txt` names untracked links into the shared `toolchains/` directory; `manifests-extra/` keeps manifest variants that were never committed.
- `matrix.tsv` is the cross-repository view: owner repository, device, track, pushed ref, SHA, source tree, path and branch.
- `standalone.tsv` lists the checkouts that sat beside the trees (device kernels, donor kernels, bullhead device repositories) with every ref, the live tip that holds it and its purpose.
- `checks/` holds the verifier and its last results (`checks/results/<device>_<track>.tsv`).
- `docs/integration-strategy/` holds the red-team brief, its material, the reviewer report, the reconciliation and the strategy.

| Directory | Source tree | Products |
|---|---|---|
| devices/m8/lineage-22.2 | m8/lineage-22.2 | m8, a11 |
| devices/bullhead/lineage-22.2 | bullhead/lineage-22.2 | bullhead |
| devices/tuna/lineage-22.2 | tuna/lineage-22.2 | maguro, toro (tuna) |
| devices/tuna/lineage-18.1 | tuna/lineage-18.1 | maguro, toro (tuna) |
| devices/tuna/lineage-19.1 | tuna/lineage-19.1 | maguro, toro (tuna) |
| devices/a11/lineage-18.1 | desire510-18.1 | a11 (HTC Desire 510) |
| devices/a11/lineage-19.1 | desire510-19.1 | a11 |
| devices/a11/lineage-22.2 | desire510-kernel (standalone) | a11 kernel |
| devices/m8/twrp-14.1 | twrp14-m8 | m8 recovery |
| devices/a11chl/twrp-11 | twrp/twrp-11 | a11chl recovery |
| devices/twrp-generic/twrp-12.1 | twrp/twrp-12.1 | generic recovery |

## Recreating a tree

```sh
repo init -u https://github.com/Oichkatzelesfrettschen/android-tree-ledger -m devices/m8/lineage-22.2/pinned.xml
repo sync -c -j8
```

The private overlay step (owner credentials) runs before `repo sync`:

```sh
git clone --depth=1 https://github.com/Oichkatzelesfrettschen/android-tree-ledger-private .repo/ledger-private
mkdir -p .repo/local_manifests
cp .repo/ledger-private/devices/m8/lineage-22.2/private.xml .repo/local_manifests/private.xml
```

Then apply each `patches/<path>.patch` with `git -C <path> apply` and recreate the links in `overlay/symlinks.txt`.

Pins of repositories that are not public live in the private repository `android-tree-ledger-private`, in one `devices/<device>/<track>/private.xml` per affected track. The public manifests resolve anonymously; a tree synced from a public manifest alone lacks the projects of its overlay (vendor blob and device projects). The overlay is a repo local manifest: clone the private repository, copy the track's `private.xml` to `.repo/local_manifests/`, and run `repo sync`. `sh restore.sh DEVICE/TRACK WORKDIR` in that repository performs the whole sequence and compares every project HEAD with its pin. Access needs the owner account: `gh auth login` followed by `gh auth setup-git`, or an ssh key registered with the account plus a global `url.<ssh base>.insteadOf` rule that rewrites the https GitHub prefix to its ssh form (the private repository's README gives the exact setting). Scripted runs set `GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false SSH_ASKPASS=/bin/false` so a missing credential fails at once. The tuna/lineage-18.1 Samsung blobs come from the public fork proprietary_vendor_samsung-themuppets.

## Verifying the pins

`sh checks/verify_pinned.sh devices/<device>/<track>/pinned.xml 8` prints one line per project and exits 1 on any failure. A pin passes when its SHA is the tip (or peeled tag) of the named ref, an ancestor of that ref by the GitHub compare API, or an ancestor after a blob-less fetch of that ref alone. It never fetches a bare SHA, because GitHub serves a fork-only commit by SHA from every repository of its fork network. Calibration: a fork ref holding its SHA passes; the upstream ref with a fork-only SHA fails (compare: diverged); a `refs/pull` ref fails.

## Branch names in the owner repositories

- `dev/<device>/<track>`: the built HEAD of one project in one tree.
- `topic/<device>/<track>/<original-branch>`: every other local branch, under its original name.
- No existing branch was moved. Three open pull requests were merged into lineage-22.2 on the owner's instruction: android_device_lge_bullhead #1, android_kernel_htc_a11 #71, android_kernel_htc_msm8974 #2.

## tuna on LineageOS 22.2

`devices/tuna/lineage-22.2/pinned.xml` takes the platform forks of `devices/m8/lineage-22.2` (the proven 32-bit set: `art`, `build/soong`, `bionic`, `system/core`, `system/netd`, `system/sepolicy`, the legacy RIL and HIDL forks) and replaces the m8, a11 and msm8974 device, kernel and HAL projects with the tuna ones. `device/samsung/tuna`, `device/samsung/maguro` and `hardware/ti/omap4` pin the heads of `dev/tuna/lineage-22.2`; `frameworks/native` pins the shared GLES RenderEngine selector topic and `hardware/interfaces` the HWC1 client-target topic. `kernel/samsung/tuna` keeps the 19.1 pin until the kernel base is chosen. The `vendor/ti` and `vendor/samsung` blob projects are private repositories; their overlay entry for this track is not yet written in the private ledger. `frameworks/av` and `frameworks/base` keep the m8 pins; the tuna camera lifecycle commits are not yet re-derived onto them.

## Next: everything on LineageOS 22.2

The owner's direction of 2026-11-25 rolls every device's work into LineageOS 22.2 and prunes the 18.1 and 19.1 lines; TWRP work moves onto twrp-14.1. `matrix.tsv` is the backlog of that roll-up.
