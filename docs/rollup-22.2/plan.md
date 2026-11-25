# Roll-up of every device onto LineageOS 22.2

Owner direction of 2026-11-25: every device runs LineageOS 22.2, the 18.1 and 19.1 lines are pruned, and recovery work moves onto twrp-14.1. This plan records the facts that bound the work, the backlog source, and the units in order. Nothing below has run unless marked.

## Facts (measured 2026-11-25)

- m8 and bullhead already build from lineage-22.2 trees (devices/m8/lineage-22.2, devices/bullhead/lineage-22.2). The m8 tree also builds a11 (local manifest a11.xml), and android_device_htc_msm8226-common and android_kernel_htc_a11 carry lineage-22.2 lines, so a11's 18.1 and 19.1 work is a diff against an existing 22.2 line.
- tuna has no 22.2 base anywhere found: the owner forks android_device_samsung_tuna and android_device_samsung_maguro stop at lineage-19.1, and the public tuna device trees stop earlier (Unlegacy-Android at aosp-9.0). tuna's kernel line is 3.0-based (android_kernel_samsung_tuna). Android 15 platform code expects eBPF and kernel interfaces that 19.1 already needed workarounds for, so tuna on 22.2 is a port with a kernel risk, not a cherry-pick.
- The local commits to port are listed in matrix.tsv: about 60 commits in about 25 projects, plus 15 uncommitted TWRP changes in devices/*/patches.
- Build capacity is measured per host in the owner's private infrastructure record; a shallow 22.2 sync fits the first build workstation, a sync plus one device's out/ directory needs more space there.

## Units, in order

1. Restore drill (running): repo init --depth=1 from this ledger for devices/m8/lineage-22.2, sync, compare every HEAD with its pin. Passing it retires the source m8 and bullhead trees.
2. Triage, one agent, read-only: classify each commit in matrix.tsv for 22.2 as already present, applies cleanly, needs rework, or obsolete, with the evidence (patch-id against the 22.2 line, `git apply --check`, the 22.2 file that replaced the code). Output: docs/rollup-22.2/triage.tsv.
3. a11 onto 22.2: the clean and rework commits as topic branches on the 22.2 lines (frameworks_av, frameworks_base, bionic, system_netd, system_bpf, hardware_qcom_*), each conflict resolved by synthesis of both intents, one commit per mechanism.
4. tuna feasibility: kernel and HAL requirements of Android 15 against the 3.0 tuna kernel, with the cheapest decisive check (a 22.2 boot to the first init stage on device). The owner decides between a port and keeping tuna on 19.1 after this unit.
5. TWRP onto twrp-14.1: the a11chl and generic changes as topic branches beside m8's twrp-14.1 line.
6. Build capacity: the first build workstation, then existing hosts with cross compilers, then new machines only within free credits. distcc helps the kernel builds; the platform build uses Soong and Ninja locally, so it gains from ccache and disk, not distcc.

## Agents

Up to 10 Haiku, 3 Sonnet and 1 Opus agents with the orchestrator skill (owner, 2026-11-25), scaled to what triage shows. Every agent works read-only on GitHub refs or in its own scratch clone, pushes only topic/ branches, and opens no pull request; synthesis commits go through review before any merge.
