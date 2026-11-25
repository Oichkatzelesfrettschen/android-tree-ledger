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

Then apply each `patches/<path>.patch` with `git -C <path> apply` and recreate the links in `overlay/symlinks.txt`.

Eleven pins name owner repositories that are still private, so an anonymous sync of those trees needs credentials until their publication scans finish: android_device_htc_a11chl (a11chl/twrp-11), proprietary_vendor_htc_a11chl (a11/lineage-18.1, a11/lineage-19.1, m8/lineage-22.2), proprietary_vendor_htc_m8 (m8/lineage-22.2), android_vendor_microg (tuna/lineage-18.1, tuna/lineage-19.1), proprietary_vendor_ti (tuna/lineage-18.1, tuna/lineage-19.1), android_system_memory_libion and proprietary_vendor_samsung (tuna/lineage-19.1). The tuna/lineage-18.1 Samsung blobs come from the public fork proprietary_vendor_samsung-themuppets.

## Verifying the pins

`sh checks/verify_pinned.sh devices/<device>/<track>/pinned.xml 8` prints one line per project and exits 1 on any failure. A pin passes when its SHA is the tip (or peeled tag) of the named ref, an ancestor of that ref by the GitHub compare API, or an ancestor after a blob-less fetch of that ref alone. It never fetches a bare SHA, because GitHub serves a fork-only commit by SHA from every repository of its fork network. Calibration: a fork ref holding its SHA passes; the upstream ref with a fork-only SHA fails (compare: diverged); a `refs/pull` ref fails.

## Branch names in the owner repositories

- `dev/<device>/<track>`: the built HEAD of one project in one tree.
- `topic/<device>/<track>/<original-branch>`: every other local branch, under its original name.
- No existing branch was moved. Three open pull requests were merged into lineage-22.2 on the owner's instruction: android_device_lge_bullhead #1, android_kernel_htc_a11 #71, android_kernel_htc_msm8974 #2.

## Next: everything on LineageOS 22.2

The owner's direction of 2026-11-25 rolls every device's work into LineageOS 22.2 and prunes the 18.1 and 19.1 lines; TWRP work moves onto twrp-14.1. `matrix.tsv` is the backlog of that roll-up.
