#!/bin/bash
# Remove EXIF v1.1 — Moosh Massacre <gustavo@mooshmassacre.studio>
# Copyright (c) 2026 Moosh Massacre. MIT License.
set -u
SUPPORT="$HOME/Library/Application Support/Remove EXIF"
WORKFLOW="$HOME/Library/Services/Remove EXIF.workflow"
alert() {
    /usr/bin/osascript -e 'on run argv' -e 'display dialog (item 1 of argv) buttons {"OK"} with title "Remove EXIF"' -e 'end run' "$1" >/dev/null 2>&1 || printf '%s\n' "$1" >&2
}
# Only remove this project's known files; never follow a redirected support folder.
[ ! -L "$SUPPORT" ] || { alert 'Uninstall stopped: the support folder is a symbolic link.'; exit 1; }
answer=$(/usr/bin/osascript -e 'display dialog "Uninstall Remove EXIF? The Finder Quick Action and installed scripts will be removed. Existing backups and your images will be kept." buttons {"Cancel", "Uninstall"} default button "Cancel" cancel button "Cancel" with title "Remove EXIF"') || exit 0
case "$answer" in *'button returned:Uninstall'*) ;; *) exit 0 ;; esac
/bin/rm -rf "$WORKFLOW" || { alert 'Could not remove the Quick Action. Check folder permissions.'; exit 1; }
/bin/rm -f "$SUPPORT/Remove_EXIF.command" "$SUPPORT/Uninstall Remove EXIF.command" || { alert 'Could not remove the installed scripts. Check folder permissions.'; exit 1; }
/bin/rmdir "$SUPPORT" >/dev/null 2>&1 || true
/usr/bin/killall pbs >/dev/null 2>&1 || true
alert 'Remove EXIF was uninstalled. Existing backups were kept. Restart Finder if the action still appears.'
