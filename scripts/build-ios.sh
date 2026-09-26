#!/usr/bin/env bash
#
# Build frida-server for iOS (roothide Dopamine, rootless, arm64e).
# Runs on a macOS runner.
#
# This script builds TWO flavors from the same frida checkout and packages each
# for both jailbreak layouts, so a release carries four .deb files:
#
#   stealth (Florida + iOS anti-detect patches):
#     out/frida_<ver>_iphoneos-arm64e-roothide.deb          roothide (jbroot)
#     out/frida_<ver>_iphoneos-arm64e.deb                   rootless (/var/jb)
#
#   vanilla (pristine upstream frida, NO patches):
#     out/frida_<ver>_iphoneos-arm64e-roothide-vanilla.deb  roothide (jbroot)
#     out/frida_<ver>_iphoneos-arm64e-vanilla.deb           rootless (/var/jb)
#
# The vanilla flavor is built FIRST from the pristine source; the anti-detect
# patches are then applied and the stealth flavor is built. The stealth deb
# names are unchanged from the original single-flavor build.
#
set -uo pipefail

WORK="$(pwd)"
INPUT_VERSION="${1:-}"

log() { echo -e "\033[0;32m[build]\033[0m $*"; }
err() { echo -e "\033[0;31m[build]\033[0m $*" >&2; }

# --- resolve frida version ---------------------------------------------------
if [ -n "${INPUT_VERSION}" ]; then
  FRIDA_TAG="${INPUT_VERSION}"
else
  FRIDA_TAG="$(curl -fsSL https://api.github.com/repos/frida/frida/releases/latest \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["tag_name"])')"
fi
[ -z "${FRIDA_TAG}" ] && { err "could not resolve frida version"; exit 1; }
log "Frida version to build: ${FRIDA_TAG}"

# --- clone frida -------------------------------------------------------------
rm -rf "${WORK}/frida"
git clone https://github.com/frida/frida.git "${WORK}/frida"
cd "${WORK}/frida"
git checkout "${FRIDA_TAG}"
git submodule update --init --recursive --depth 1

# --- python venv + build deps ------------------------------------------------
python3 -m venv .venv
# shellcheck source=/dev/null
source .venv/bin/activate
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install lief || echo "[build] lief install failed (anti-anti-frida symbol pass may be skipped)"

export PYTHON="$(command -v python3)"
export PYTHONWARNINGS=all

# frida's build post-processes (strips + codesigns) the iOS binaries during the
# build and requires IOS_CERTID. "-" means ad-hoc signing; combined with the
# embedded entitlements this is what a rootless jailbreak (Dopamine) accepts.
export IOS_CERTID="-"

# --- packaging version string ------------------------------------------------
FRIDA_VERSION="$(releng/frida_version.py 2>/dev/null || echo "${FRIDA_TAG#v}")"
# frida_version.py may append commit distance for non-exact checkouts; keep base x.y.z
FRIDA_VERSION="$(echo "${FRIDA_VERSION}" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
export FRIDA_VERSION
log "FRIDA_VERSION=${FRIDA_VERSION}"

mkdir -p "${WORK}/out"

# --- build one flavor: configure + build + install + locate + codesign -------
# usage: build_flavor <dist_dir>
# Leaves a signed frida-server + frida-agent.dylib under <dist_dir>/var/jb/usr.
build_flavor() {
  local dist="$1"

  # Always start from a clean meson build dir so patched (or pristine) sources
  # are actually recompiled for this flavor.
  rm -rf "${WORK}/frida/build"

  log "configuring (host=ios-arm64e, prefix=/var/jb/usr)"
  ./configure \
    --prefix=/var/jb/usr \
    --host=ios-arm64e \
    -- \
    -Dfrida-core:assets=installed

  local nproc; nproc=$(( $(/usr/sbin/sysctl -n hw.logicalcpu) + 1 ))
  log "building with -j${nproc}"
  gmake -j"${nproc}"

  rm -rf "${dist}"
  DESTDIR="${dist}" gmake -j"${nproc}" install

  # frida 17.x installs the agent under lib/frida-1.0/ (older frida used lib/frida/).
  local server agent
  server="${dist}/var/jb/usr/bin/frida-server"
  agent="${dist}/var/jb/usr/lib/frida-1.0/frida-agent.dylib"
  [ -f "${server}" ] || server="$(find "${dist}" -path '*/bin/frida-server' -type f | head -1)"
  [ -f "${agent}" ]  || agent="$(find "${dist}" -name 'frida-agent.dylib' -type f | head -1)"
  if [ -z "${server}" ] || [ ! -f "${server}" ]; then
    err "frida-server not found under ${dist}"
    find "${dist}" \( -name 'frida-server' -o -name 'frida-agent.dylib' \) | sed 's/^/  found: /'
    exit 2
  fi
  if [ -z "${agent}" ] || [ ! -f "${agent}" ]; then
    err "frida-agent.dylib not found under ${dist}"
    find "${dist}" -name 'frida-agent.dylib' | sed 's/^/  found: /'
    exit 2
  fi
  log "server: ${server}"
  log "agent:  ${agent}"
  log "server slices: $(lipo -archs "${server}" 2>/dev/null)"
  log "agent  slices: $(lipo -archs "${agent}" 2>/dev/null)"

  codesign -vf -s "-" --preserve-metadata=entitlements --timestamp=none "${server}"
  codesign -vf -s "-" --preserve-metadata=entitlements --timestamp=none "${agent}"
  log "codesign done"
}

# --- package one flavor into rootless + roothide debs ------------------------
# usage: package_flavor <dist_dir> <suffix>
# suffix "" -> stealth (original names) ; "-vanilla" -> vanilla flavor.
package_flavor() {
  local dist="$1" suffix="$2"
  local deb_rootless="${WORK}/out/frida_${FRIDA_VERSION}_iphoneos-arm64e${suffix}.deb"
  local deb_roothide="${WORK}/out/frida_${FRIDA_VERSION}_iphoneos-arm64e-roothide${suffix}.deb"

  FRIDA_VERSION="${FRIDA_VERSION}" bash "${WORK}/tools/package-server-fruity.sh" \
    "iphoneos-arm64e" "${dist}/var/jb" "${deb_rootless}"
  FRIDA_VERSION="${FRIDA_VERSION}" bash "${WORK}/tools/package-server-roothide.sh" \
    "iphoneos-arm64e" "${dist}/var/jb" "${deb_roothide}"

  log "packaged (rootless /var/jb): ${deb_rootless}"
  log "packaged (roothide):         ${deb_roothide}"
}

# === flavor 1: VANILLA (pristine upstream source, no patches) ================
log "=== building VANILLA (no anti-detect patches) ==="
build_flavor "${WORK}/dist-vanilla"
package_flavor "${WORK}/dist-vanilla" "-vanilla"
# free the big build/install trees before the second compile
rm -rf "${WORK}/dist-vanilla" "${WORK}/frida/build"

# === flavor 2: STEALTH (Florida + iOS anti-detect patches) ===================
log "=== building STEALTH (Florida + iOS anti-detect patches) ==="
bash "${WORK}/scripts/apply-patches.sh" "${WORK}/frida" "${WORK}/patch-report.txt" "${WORK}/patches-ios"
build_flavor "${WORK}/dist-stealth"
package_flavor "${WORK}/dist-stealth" ""

echo "${FRIDA_VERSION}" > "${WORK}/out/FRIDA_VERSION.txt"
log "=== all packages ==="
ls -la "${WORK}/out"
for d in "${WORK}/out"/*.deb; do
  echo "=== ${d} ==="
  dpkg-deb -I "${d}" || true
  dpkg-deb -c "${d}" || true
done
