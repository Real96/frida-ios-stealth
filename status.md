# CI build status

- status: **success**
- frida_version: 17.25.0
- commit: 6362c2b81c9428eaab88e2e6c5e5ff167039e0d8
- run: https://github.com/Real96/frida-ios-stealth/actions/runs/41102750779
- utc: 2026-10-30T18:09:03Z

## deb artifacts
```
total 188456
drwxr-xr-x   7 runner  staff       224 Oct 30 18:08 .
drwxr-xr-x  16 runner  staff       512 Oct 30 18:08 ..
-rw-r--r--   1 runner  staff  23574500 Oct 30 18:05 frida_17.25.0_iphoneos-arm64e-roothide-vanilla.deb
-rw-r--r--   1 runner  staff  23580108 Oct 30 18:08 frida_17.25.0_iphoneos-arm64e-roothide.deb
-rw-r--r--   1 runner  staff  23573596 Oct 30 18:04 frida_17.25.0_iphoneos-arm64e-vanilla.deb
-rw-r--r--   1 runner  staff  23574196 Oct 30 18:08 frida_17.25.0_iphoneos-arm64e.deb
-rw-r--r--   1 runner  staff         8 Oct 30 18:08 FRIDA_VERSION.txt
```

## patch report
```
# patch report  (frida root: /Users/runner/work/frida-ios-stealth/frida-ios-stealth/frida)
# Florida pinned: 6d4b2e88ebe2bace12322db93470b0e68d4240c9

SKIPPED(does-not-apply)   [florida] frida-core/0001-Florida-string_frida_rpc.patch
APPLIED                   [florida] frida-core/0002-Florida-frida_agent_so.patch
SKIPPED(does-not-apply)   [florida] frida-core/0003-Florida-symbol_frida_agent_main.patch
SKIPPED(does-not-apply)   [florida] frida-core/0004-Florida-thread_gum_js_loop.patch
SKIPPED(does-not-apply)   [florida] frida-core/0005-Florida-thread_gmain.patch
SKIPPED(does-not-apply)   [florida] frida-core/0006-Florida-protocol_unexpected_command.patch
SKIPPED(does-not-apply)   [florida] frida-core/0007-Florida-update-python-script.patch
APPLIED                   [florida] frida-core/0008-Florida-pool-frida.patch
APPLIED                   [florida] frida-core/0009-Florida-memfd-name-jit-cache.patch
APPLIED                   [florida] frida-core/0010-exec-anti-anti-frida.py.patch
APPLIED                   [florida] frida-gum/0001-Florida-pool-frida.patch
APPLIED                   [ios] frida-core/0001-ios-rpc-string-obfuscation.patch

# Patches touching linux/*, droidy/*, memfd (Linux/Android code paths) may
# apply to files present in the tree but those files are not compiled into
# the iOS/Darwin server. The anti-anti-frida.py symbol pass is ELF-oriented
# and only runs on the non-Darwin embed path; on iOS it is effectively a no-op.
# [ios] patches are re-derived for the current frida and carry the real
# iOS-relevant anti-detect edits (e.g. rpc-string obfuscation).
```

_full tail in build-tail.log on this branch_
