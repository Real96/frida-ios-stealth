# CI build status

- status: **success**
- frida_version: 17.19.0
- commit: 1d310bf41a14dbf23e5c2a8ec19a9448284b2d0d
- run: https://github.com/Real96/frida-ios-stealth/actions/runs/36289640564
- utc: 2026-09-27T02:55:28Z

## deb artifacts
```
total 131112
drwxr-xr-x   7 runner  staff       224 Sep 27 02:55 .
drwxr-xr-x  16 runner  staff       512 Sep 27 02:55 ..
-rw-r--r--   1 runner  staff         8 Sep 27 02:55 FRIDA_VERSION.txt
-rw-r--r--   1 runner  staff  16646324 Sep 27 02:53 frida_17.19.0_iphoneos-arm64e-roothide-vanilla.deb
-rw-r--r--   1 runner  staff  16640336 Sep 27 02:55 frida_17.19.0_iphoneos-arm64e-roothide.deb
-rw-r--r--   1 runner  staff  16640544 Sep 27 02:53 frida_17.19.0_iphoneos-arm64e-vanilla.deb
-rw-r--r--   1 runner  staff  16639384 Sep 27 02:54 frida_17.19.0_iphoneos-arm64e.deb
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
APPLIED                   [florida] frida-core/0006-Florida-protocol_unexpected_command.patch
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
