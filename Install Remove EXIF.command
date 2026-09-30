#!/bin/bash
# Remove EXIF v1.1 installer — Moosh Massacre <gustavo@mooshmassacre.studio>
# Installs only into the current user's Library. No administrator access needed.
set -u

PACKAGE_DIR="$(cd "$(dirname "$0")" && /bin/pwd -P)"
SOURCE_SCRIPT="$PACKAGE_DIR/Resources/Remove_EXIF.command"
SOURCE_WORKFLOW="$PACKAGE_DIR/Resources/Remove EXIF.workflow"
SUPPORT="$HOME/Library/Application Support/Remove EXIF"
SERVICES="$HOME/Library/Services"
SCRIPT_DEST="$SUPPORT/Remove_EXIF.command"
WORKFLOW_DEST="$SERVICES/Remove EXIF.workflow"

alert() {
  /usr/bin/osascript -e 'on run argv' \
    -e 'display dialog (item 1 of argv) buttons {"OK"} default button "OK" with title "Remove EXIF"' \
    -e 'end run' "$1" >/dev/null 2>&1 || /bin/echo "$1" >&2
}
fail() { alert "Installation failed: $1"; exit 1; }

[ -f "$PACKAGE_DIR/Uninstall Remove EXIF.command" ] || fail "Uninstaller is missing from the package."
[ -f "$SOURCE_SCRIPT" ] || fail "Script is missing from the installer."
[ -f "$SOURCE_WORKFLOW/Contents/document.wflow" ] || fail "Quick Action is missing from the installer."
[ -f "$SOURCE_WORKFLOW/Contents/Info.plist" ] || fail "Quick Action configuration is missing."
/usr/bin/plutil -lint "$SOURCE_WORKFLOW/Contents/document.wflow" >/dev/null 2>&1 || fail "Invalid Automator workflow."
/usr/bin/plutil -lint "$SOURCE_WORKFLOW/Contents/Info.plist" >/dev/null 2>&1 || fail "Invalid Quick Action configuration."
/bin/mkdir -p "$SUPPORT" "$SERVICES" || fail "Cannot create user Library folders."

STAMP=$(/bin/date '+%Y%m%d-%H%M%S')
BACKUP="$SUPPORT/Backups/$STAMP-$$"
/bin/mkdir -p "$BACKUP" || fail "Cannot create the backup folder."
[ ! -e "$SCRIPT_DEST" ] || /bin/cp -p "$SCRIPT_DEST" "$BACKUP/Remove_EXIF.command" || fail "Cannot back up the existing script."
[ ! -e "$WORKFLOW_DEST" ] || /bin/cp -R "$WORKFLOW_DEST" "$BACKUP/Remove EXIF.workflow" || fail "Cannot back up the existing Quick Action."

SCRIPT_STAGE=$(/usr/bin/mktemp "$SUPPORT/.Remove_EXIF.XXXXXXXX") || fail "Cannot stage the script."
/bin/cp "$SOURCE_SCRIPT" "$SCRIPT_STAGE" || { /bin/rm -f "$SCRIPT_STAGE"; fail "Cannot copy the script."; }
/bin/chmod 755 "$SCRIPT_STAGE" || { /bin/rm -f "$SCRIPT_STAGE"; fail "Cannot set script permissions."; }
WORKFLOW_STAGE=$(/usr/bin/mktemp -d "$SERVICES/.Remove_EXIF.XXXXXXXX") || { /bin/rm -f "$SCRIPT_STAGE"; fail "Cannot stage the Quick Action."; }
/bin/cp -R "$SOURCE_WORKFLOW/." "$WORKFLOW_STAGE/" || { /bin/rm -rf "$WORKFLOW_STAGE"; /bin/rm -f "$SCRIPT_STAGE"; fail "Cannot copy the Quick Action."; }

if [ -e "$WORKFLOW_DEST" ]; then
  /bin/mv "$WORKFLOW_DEST" "$BACKUP/Original Remove EXIF.workflow" || { /bin/rm -rf "$WORKFLOW_STAGE"; /bin/rm -f "$SCRIPT_STAGE"; fail "Cannot replace the existing Quick Action."; }
fi
if ! /bin/mv "$WORKFLOW_STAGE" "$WORKFLOW_DEST"; then
  [ ! -e "$BACKUP/Original Remove EXIF.workflow" ] || /bin/mv "$BACKUP/Original Remove EXIF.workflow" "$WORKFLOW_DEST"
  /bin/rm -f "$SCRIPT_STAGE"
  fail "Cannot install the Quick Action."
fi
if ! /bin/mv -f "$SCRIPT_STAGE" "$SCRIPT_DEST"; then
  /bin/rm -rf "$WORKFLOW_DEST"
  [ ! -e "$BACKUP/Original Remove EXIF.workflow" ] || /bin/mv "$BACKUP/Original Remove EXIF.workflow" "$WORKFLOW_DEST"
  fail "Cannot install the script."
fi

/usr/bin/touch "$WORKFLOW_DEST" >/dev/null 2>&1 || true
/usr/bin/killall pbs >/dev/null 2>&1 || true
/bin/cp "$PACKAGE_DIR/Uninstall Remove EXIF.command" "$SUPPORT/Uninstall Remove EXIF.command" || fail "Cannot install the uninstaller."
/bin/chmod 755 "$SUPPORT/Uninstall Remove EXIF.command" || fail "Cannot set uninstaller permissions."
alert "Remove EXIF is installed. Select JPEG, PNG, HEIC, or TIFF files in Finder, then choose Quick Actions > Remove EXIF."
exit 0
