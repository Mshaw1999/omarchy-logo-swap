# Omarchy Plymouth Logo Swap (Arch / Limine)

Change your boot logo on systems using Plymouth + Limine and the Omarchy theme.  
Uses a Snapper snapshot to ensure safe rollback.

---

## Requirements

- Arch or Arch-like distro using:
  - `mkinitcpio`
  - `plymouth`
  - `limine-mkinitcpio` hook
- Theme path must exist:

/usr/share/plymouth/themes/omarchy/

-- Your new logo must be named:

~/Downloads/Logo.png

Any resolution works, but **1025×400** is recommended.
Larger images may push the LUKS password prompt off-screen.

---

## Usage

```bash
chmod +x change-omarchy-logo.sh
./change-omarchy-logo.sh
sudo reboot


If your Plymouth theme is not set to Omarchy:
sudo plymouth-set-default-theme omarchy
sudo limine-mkinitcpio
sudo reboot


Rollback (Snapper)
If the boot logo breaks anything:
sudo snapper -c root rollback
sudo reboot

Troubleshooting
Issue	Fix
Logo not visible	Resize to 1025×400 or smaller
LUKS password prompt missing	Theme too large → resize
Theme unchanged	Set default theme + rebuild initramfs
Missing limine-mkinitcpio	Install Limine hook

