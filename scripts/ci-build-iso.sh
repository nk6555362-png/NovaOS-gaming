#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/work-profile"
WORK="$ROOT/work"
OUT="$ROOT/out"
LOCAL_REPO="$ROOT/localrepo"
RELENG="/usr/share/archiso/configs/releng"

[[ -d "$RELENG" ]] || { echo "Archiso releng profile missing: $RELENG" >&2; exit 1; }

rm -rf -- "$PROFILE" "$WORK" "$LOCAL_REPO"
mkdir -p "$OUT" "$LOCAL_REPO"
cp -a "$RELENG" "$PROFILE"

# Calamares is not in the official Arch repositories. Build the community
# PKGBUILD as an unprivileged user and expose the resulting package to pacman
# through a temporary local repository used only for this ISO build.
if ! pacman -Si calamares >/dev/null 2>&1; then
  id nova-build >/dev/null 2>&1 || useradd --create-home --shell /bin/bash nova-build
  printf '%s\n' 'nova-build ALL=(root) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/nova-build
  chmod 0440 /etc/sudoers.d/nova-build
  visudo -cf /etc/sudoers.d/nova-build
  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf -- "$BUILD_DIR"' EXIT
  git clone https://aur.archlinux.org/calamares.git "$BUILD_DIR/calamares"
  chown -R nova-build:nova-build "$BUILD_DIR"
  runuser -u nova-build -- bash -lc "cd '$BUILD_DIR/calamares' && makepkg --syncdeps --noconfirm --cleanbuild"
  mapfile -t calamares_pkgs < <(find "$BUILD_DIR/calamares" -maxdepth 1 -type f -name 'calamares-*.pkg.tar.zst' ! -name 'calamares-debug-*.pkg.tar.zst' -print)
  (( ${#calamares_pkgs[@]} == 1 )) || { echo "Expected one Calamares package, found ${#calamares_pkgs[@]}." >&2; exit 1; }
  cp "${calamares_pkgs[0]}" "$LOCAL_REPO/"
  repo-add "$LOCAL_REPO/novaos-local.db.tar.gz" "$LOCAL_REPO/$(basename -- "${calamares_pkgs[0]}")"
  rm -f /etc/sudoers.d/nova-build
  userdel -r nova-build
fi

# Add NovaOS live-session and Calamares configuration to the disposable profile.
mkdir -p "$PROFILE/airootfs"
cp -a "$ROOT/overlay/." "$PROFILE/airootfs/"

cat >> "$PROFILE/pacman.conf" <<PACMAN_LOCAL_REPO

[novaos-local]
SigLevel = Optional TrustAll
Server = file://$LOCAL_REPO
PACMAN_LOCAL_REPO

# Enable multilib in this disposable profile for Steam and 32-bit libraries.
if grep -qE '^[[:space:]]*#\[multilib\]' "$PROFILE/pacman.conf"; then
  sed -i '/^[[:space:]]*#\[multilib\]/,/^[[:space:]]*#Include = \/etc\/pacman.d\/mirrorlist/s/^[[:space:]]*#//' "$PROFILE/pacman.conf"
fi

while IFS= read -r pkg || [[ -n "$pkg" ]]; do
  [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
  grep -qxF "$pkg" "$PROFILE/packages.x86_64" || printf '%s\n' "$pkg" >> "$PROFILE/packages.x86_64"
done < "$ROOT/packages.extra"

sed -i 's/^iso_name=.*/iso_name="novaos-gaming"/' "$PROFILE/profiledef.sh"
sed -i 's/^iso_label=.*/iso_label="NOVAOS_GAMING"/' "$PROFILE/profiledef.sh"

mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

shopt -s nullglob
isos=("$OUT"/*.iso)
(( ${#isos[@]} > 0 )) || { echo "No ISO produced." >&2; exit 1; }
printf 'Built ISO(s):\n'
printf ' - %s\n' "${isos[@]}"
