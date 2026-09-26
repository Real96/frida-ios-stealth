# Install (roothide Dopamine and plain rootless)

The release ships **four** packages, all `iphoneos-arm64e`, all fat arm64+arm64e.
Two axes: **flavor** (stealth vs vanilla) and **jailbreak layout** (roothide vs
plain rootless).

| file | flavor | for |
|---|---|---|
| `frida_<ver>_iphoneos-arm64e-roothide.deb` | stealth (anti-detect) | **roothide Dopamine** (randomized jbroot, no `/var/jb`) |
| `frida_<ver>_iphoneos-arm64e.deb` | stealth (anti-detect) | plain rootless Dopamine / Xina etc. (fixed `/var/jb`) |
| `frida_<ver>_iphoneos-arm64e-roothide-vanilla.deb` | vanilla (upstream) | **roothide Dopamine** |
| `frida_<ver>_iphoneos-arm64e-vanilla.deb` | vanilla (upstream) | plain rootless Dopamine / Xina etc. |

Pick the **one** that matches your jailbreak and the flavor you want. `dpkg -i`
the wrong layout and the daemon paths will not resolve.

## stealth vs vanilla

Same frida, same version; the only difference is whether the anti-detect source
patches were compiled in.

- **stealth** - Florida + this repo's iOS patches applied. Spoofs the process
  name and strips the plaintext `frida:rpc` literal (see "What is and is not
  hidden" below). Use against apps with jailbreak / Frida detection.
- **vanilla** - pristine upstream frida, no patches. Simplest and closest to
  what `frida --version` on your host expects. Use when the target has no
  anti-tampering, or when you want a known-clean baseline.

## roothide layout vs rootless (`/var/jb`) layout

The `-roothide` and non-`-roothide` packages hold the **same frida-server /
frida-agent binary**. They differ only in how the `.deb` is laid out and how the
daemon is loaded:

- **rootless (`frida_<ver>_iphoneos-arm64e.deb`)** - files live under `/var/jb`
  (`/var/jb/usr/sbin/frida-server`, ...). The daemon plist hardcodes `/var/jb`
  paths and the maintainer scripts call `launchctl load /var/jb/...` directly.
  This works on jailbreaks that expose a **fixed** `/var/jb` symlink (plain
  rootless Dopamine, Xina, palera1n rootless).
- **roothide (`frida_<ver>_iphoneos-arm64e-roothide.deb`)** - roothide has **no**
  `/var/jb`; its jailbreak root is a **randomized** path. So this package uses a
  rootful layout (`/usr/sbin`, `/Library/LaunchDaemons`, no `/var/jb`); roothide's
  `dpkg` relocates those into the randomized jbroot automatically. The plist uses
  jbroot-based paths and the maintainer scripts resolve the real path with
  roothide's `jbroot` command before calling `launchctl`.

Install the rootless deb on roothide and the `/var/jb/...` paths simply do not
exist, so the daemon never comes up - hence the two packages.

---

## roothide Dopamine

roothide has no `/var/jb`; it installs into a randomized jbroot. The roothide
package uses a rootful layout and `dpkg` relocates it into jbroot automatically.

```sh
# on device (Sileo -> import, or over SSH into the bootstrap):
dpkg -i frida_<ver>_iphoneos-arm64e-roothide.deb
# vanilla instead: dpkg -i frida_<ver>_iphoneos-arm64e-roothide-vanilla.deb
```

The `extrainst_` script resolves the real path with the roothide `jbroot`
command and loads the daemon. If it does not come up immediately, a respring or
reboot lets roothide's own daemon loader pick it up.

Files land at (jbroot-based paths):

```
/usr/sbin/frida-server
/usr/lib/frida-1.0/frida-agent.dylib
/Library/LaunchDaemons/re.frida.server.plist
```

### Bulletproof manual start (no daemon)

If the daemon is fussy on your roothide build, just run the server yourself. In a
bootstrap shell (jbroot is the default root there):

```sh
/usr/sbin/frida-server -l 127.0.0.1:47821 &
```

From a rootfs/SSH-as-mobile shell instead, resolve the real path first:

```sh
"$(jbroot /usr/sbin/frida-server)" -l 127.0.0.1:47821 &
```

### Custom port on roothide

Edit the daemon plist in place, then reload it:

```sh
plist="$(jbroot /Library/LaunchDaemons/re.frida.server.plist)"
# add -l 127.0.0.1:47821 to ProgramArguments (see the XML block below), then:
launchctl bootout   system "$plist" 2>/dev/null || launchctl unload "$plist"
launchctl bootstrap system "$plist" 2>/dev/null || launchctl load  "$plist"
```

---

## Plain rootless Dopamine (`/var/jb`)

```sh
dpkg -i frida_<ver>_iphoneos-arm64e.deb
# vanilla instead: dpkg -i frida_<ver>_iphoneos-arm64e-vanilla.deb
launchctl reload /var/jb/Library/LaunchDaemons/re.frida.server.plist \
  || launchctl load /var/jb/Library/LaunchDaemons/re.frida.server.plist
```

Files: `/var/jb/usr/sbin/frida-server`, `/var/jb/usr/lib/frida-1.0/frida-agent.dylib`,
`/var/jb/Library/LaunchDaemons/re.frida.server.plist`.

---

## Custom port (both variants)

Default listen address is `127.0.0.1:27042`. Add a `-l` argument to
`ProgramArguments` in the daemon plist:

```xml
<key>ProgramArguments</key>
<array>
    <string>/usr/sbin/frida-server</string>   <!-- roothide: /usr/sbin ; rootless: /var/jb/usr/sbin -->
    <string>-l</string>
    <string>127.0.0.1:47821</string>          <!-- your port; 0.0.0.0:PORT to expose on the network -->
</array>
```

Prefer a random high port (40000-60000), not 27042/27043, bound to `127.0.0.1`.
Since USB auto-discovery expects the default port, connect over a forwarded port:

```sh
iproxy 47821 47821
frida -H 127.0.0.1:47821 -f com.target.app
```

## Rename the daemon (reduce on-disk signature)

Rename the binary IN PLACE (keep it in the same dir so the agent at
`../lib/frida-1.0/frida-agent.dylib` is still found), rename the plist, and point
`Label` / `Program` / `ProgramArguments[0]` at the new name. Keep
`frida-agent.dylib` where it is - moving it out or deleting it breaks injection.

## What is and is not hidden (stealth flavor)

This section applies to the **stealth** debs only; the **vanilla** debs have none
of these edits.

Applied anti-detect (real effect on the iOS binary):

- process name spoofed to `ggbond` (`g_set_prgname`, frida-core + frida-gum)
- plaintext `frida:rpc` literal removed from the binary (base64-obfuscated,
  runtime protocol unchanged)

Not hidden in this build (Florida does these on Android via an ELF post-pass
that does not apply to a Mach-O):

- the `frida_agent_main` exported symbol
- the `gum-js-loop` / `gmain` / `gdbus` thread names
- on-disk names (`frida-server`, `re.frida.server`) unless you rename as above

A binary-level, equal-length rename of the thread names on the Mach-O can be
added to CI if you want those hidden too.
