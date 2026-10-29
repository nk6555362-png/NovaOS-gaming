#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/work-profile"
WORK="$ROOT/work"
OUT="$ROOT/out"
RELENG="/usr/share/archiso/configs/releng"

[[ -d "$RELENG" ]] || { echo "Archiso releng profile missing: $RELENG" >&2; exit 1; }

rm -rf -- "$PROFILE" "$WORK"
mkdir -p "$OUT"
cp -a "$RELENG" "$PROFILE"

# Add NovaOS live-session and Calamares configuration to the disposable profile.
mkdir -p "$PROFILE/airootfs"
cp -a "$ROOT/overlay/." "$PROFILE/airootfs/"

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
