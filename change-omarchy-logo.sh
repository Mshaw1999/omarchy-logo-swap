#!/usr/bin/env bash
# Safely replace Plymouth Omarchy logo and rebuild initramfs via Limine.
# Uses Snapper snapshot for rollback (no tar backups needed).

set -euo pipefail

THEME_DIR="/usr/share/plymouth/themes/omarchy"
THEME_NAME="omarchy"
TARGET_LOGO="${THEME_DIR}/logo.png"
SOURCE_LOGO="${HOME}/Downloads/Logo.png"

say() { printf "[*] %s\n" "$*"; }
warn() { printf "[⚠] %s\n" "$*"; }
die() { printf "[!] %s\n" "$*" >&2; exit 1; }

# Basic checks first (pre-sudo)
[[ -f "${SOURCE_LOGO}" ]] || die "Missing new logo at: ${SOURCE_LOGO}"
[[ -d "${THEME_DIR}" ]] || die "Plymouth theme not found: ${THEME_DIR}"
[[ -f "${THEME_DIR}/omarchy.plymouth" ]] || die "Missing omarchy.plymouth in theme dir"

grep -qE '^ImageDir=.*omarchy/logo\.png$' "${THEME_DIR}/omarchy.plymouth" \
  || die "omarchy.plymouth does not reference ${TARGET_LOGO}. Aborting to avoid corruption."

# Warn about large logos — do not block execution
if command -v identify >/dev/null 2>&1; then
  DIM="$(identify -format '%w %h' "${SOURCE_LOGO}")"
  W="${DIM%% *}"
  H="${DIM##* }"
  say "Detected PNG dimensions: ${W}x${H}px"

  if [[ "${W}" -gt 1025 || "${H}" -gt 400 ]]; then
    warn "This image is larger than the recommended 1025x400."
    warn "The LUKS unlock text may appear below the visible screen during boot."
    echo
  fi
else
  say "ImageMagick not found → skipping dimension hint."
fi

# Begin privileged operations
sudo true

# Snapper checkpoint
say "Creating Snapper snapshot (before-logo-swap)..."
sudo snapper -c root create --description "before-logo-swap"

# Apply changes
say "Replacing Plymouth logo..."
sudo install -m 0644 "${SOURCE_LOGO}" "${TARGET_LOGO}"

# Warn if default theme is different
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  CUR="$(plymouth-set-default-theme)"
  if [[ "${CUR}" != "${THEME_NAME}" ]]; then
    warn "Default theme is '${CUR}', not '${THEME_NAME}'."
    warn "Change it with: sudo plymouth-set-default-theme ${THEME_NAME}"
  fi
fi

# Rebuild initramfs
command -v limine-mkinitcpio >/dev/null 2>&1 \
  || die "limine-mkinitcpio not found — Limine mkinitcpio hook must be installed."

say "Rebuilding initramfs via limine-mkinitcpio..."
sudo limine-mkinitcpio

echo
say "✅ Done. Reboot to see your new Plymouth logo."
say "🔄 To revert: sudo snapper -c root rollback && sudo reboot"
