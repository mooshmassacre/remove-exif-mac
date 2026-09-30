"""Exercise uninstall and cancellation in an isolated home, with macOS dialogs stubbed."""
from pathlib import Path
import os, subprocess, tempfile
script=(Path(__file__).resolve().parents[1]/'Uninstall Remove EXIF.command').read_text()
with tempfile.TemporaryDirectory() as tmp:
    base=Path(tmp); home=base/'home';support=home/'Library/Application Support/Remove EXIF';workflow=home/'Library/Services/Remove EXIF.workflow'
    support.mkdir(parents=True);workflow.mkdir(parents=True)
    (support/'Backups').mkdir();(support/'Backups/keep').write_text('backup')
    for name in ['Remove_EXIF.command','Uninstall Remove EXIF.command']:(support/name).write_text('installed')
    (workflow/'test').write_text('workflow');(home/'image.tif').write_text('image')
    dialog=base/'dialog';dialog.write_text('#!/bin/bash\nif [[ "$*" == *"Uninstall Remove EXIF?"* ]]; then\n [ "$CANCEL" = 1 ] && exit 1\n echo "button returned:Uninstall"\nfi\n');dialog.chmod(0o755)
    patched=script.replace('/usr/bin/osascript',str(dialog)).replace('/usr/bin/killall pbs','/usr/bin/true')
    env=dict(os.environ,HOME=str(home),CANCEL='1')
    subprocess.run(['bash','-c',patched],env=env,check=True)
    assert workflow.exists() and (support/'Remove_EXIF.command').exists()
    env['CANCEL']='0';subprocess.run(['bash','-c',patched],env=env,check=True)
    assert not workflow.exists() and not (support/'Remove_EXIF.command').exists()
    assert (support/'Backups/keep').read_text()=='backup' and (home/'image.tif').read_text()=='image'
    print('PASS: uninstall confirmation/cancellation; scripts/action removed; backups/images retained')
