# frida-ios-stealth

Fully automated CI that builds **frida-server** for iOS
(**roothide Dopamine, rootless, `/var/jb`, arm64e**), entirely in
**GitHub Actions on a macOS runner**. Nothing is built locally.

Each release ships **two flavors**, each in **two packagings**, so four `.deb`
files in total:

| file | flavor | jailbreak layout |
|---|---|---|
| `frida_<ver>_iphoneos-arm64e-roothide.deb` | **stealth** (Florida anti-detect) | roothide (jbroot) |
| `frida_<ver>_iphoneos-arm64e.deb` | **stealth** (Florida anti-detect) | rootless (`/var/jb`) |
| `frida_<ver>_iphoneos-arm64e-roothide-vanilla.deb` | **vanilla** (pristine upstream) | roothide (jbroot) |
| `frida_<ver>_iphoneos-arm64e-vanilla.deb` | **vanilla** (pristine upstream) | rootless (`/var/jb`) |

- **stealth** applies the **Florida** + iOS anti-detect patches (use against apps
  with jailbreak / Frida detection).
- **vanilla** is pristine upstream frida with **no patches** (simplest, use when
  the target has no anti-tampering).

The two `_iphoneos-arm64e` vs `_iphoneos-arm64e-roothide` variants contain the
**same binary**; they differ only in packaging — see `INSTALL.md`.

## How it runs

- Trigger: every push to `main` that touches the build, and manual
  `workflow_dispatch` (input `frida_version`, blank = latest stable `frida/frida`).
  Push builds always use the latest release. The workflow resolves the version
  itself through the GitHub API, authenticated with the job token (anonymous
  calls from Actions runners get rate-limited with HTTP 403), falling back to
  `git ls-remote` on the frida tags, then passes the tag to `build-ios.sh`.
- Runner: `macos-14` (Xcode, iOS SDK, `lipo`, `codesign`). iOS Frida cannot be
  built on Linux; it needs Apple's toolchain.
- Steps: resolve version -> clone `frida` at the tag with submodules ->
  **build the vanilla flavor from the pristine source** (`./configure
  --prefix=/var/jb/usr --host=ios-arm64e -- -Dfrida-core:assets=installed` ->
  `gmake` -> ad-hoc `codesign`) and package it -> clone `Ylarod/Florida` (pinned)
  and apply its frida-core/frida-gum patches (`patch -p1`, non-applicable ones
  logged, never fatal) -> **rebuild the stealth flavor** and package it ->
  GitHub Release. Each flavor is packaged for both the rootless (`/var/jb`) and
  roothide (jbroot) layouts, so four `.deb` files are attached.

`--host=ios-arm64e` emits a fat **arm64 + arm64e** binary in one pass, so the
single `arm64e` package runs on every A12+ device. `arm64eoabi` (old-ABI, needs
Xcode 11.7) is intentionally dropped - Dopamine targets the new arm64e ABI - so
no separate `mkfatmacho` merge is required.

## Status channel

The GitHub MCP used to drive this has no Actions-log access, so each run
self-reports to the orphan branch **`ci-status`** (`status.md`,
`build-tail.log`). That branch is CI-filtered and never triggers a build.

## Install on roothide Dopamine

Pick **one** file: the `-roothide` package for roothide, and add the `-vanilla`
suffix if you want pristine frida instead of the anti-detect build.

```sh
# on the device, over SSH into the bootstrap or via Sileo import:
dpkg -i frida_<ver>_iphoneos-arm64e-roothide.deb            # stealth (anti-detect)
# or:
dpkg -i frida_<ver>_iphoneos-arm64e-roothide-vanilla.deb    # vanilla (upstream)
```

Full install steps for both jailbreak layouts, manual daemon start, custom port
and daemon renaming are in **`INSTALL.md`**. See the release notes for the exact
applied/skipped patch list of the stealth build.

## Credits

- Frida - https://frida.re
- Florida anti-detect patches - https://github.com/Ylarod/Florida
- iOS build + packaging recipe - miticollo's gists
