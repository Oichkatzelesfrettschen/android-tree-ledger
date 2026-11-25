# History rewrite of 2026-11-25

Four owner forks had their branches and tags rewritten to remove AI attribution lines from commit messages: android_device_htc_msm8226-common, android_hardware_interfaces, android_frameworks_av and android_bootable_recovery-m8-twrp. Only commits absent from each fork parent's refs were rewritten. Every rewritten commit keeps its tree, author, committer and dates; parents map through the commit map; 56 commits lost a GPG signature that the message change invalidated.

`2026-11-25-commit-map.tsv` maps each old commit to its replacement (repository, old, new), 333 rows. Every pin in this ledger that named an old commit now names its replacement; a pin read from an older copy of the ledger translates through this map. The old commits remain readable only through pull-request refs that GitHub keeps.
