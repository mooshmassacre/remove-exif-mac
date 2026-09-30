from pathlib import Path
import zipfile
root=Path(__file__).resolve().parents[1]
out=root/'dist/Remove_EXIF_Installer_v1.1.zip'
files=[root/x for x in ['Install Remove EXIF.command','Uninstall Remove EXIF.command','LICENSE','README.md','ROADMAP.md']]
files+=sorted(p for p in (root/'Resources').rglob('*') if p.is_file())
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as archive:
    for p in files:
        info=zipfile.ZipInfo.from_file(p,'Remove EXIF Installer/'+p.relative_to(root).as_posix())
        info.compress_type=zipfile.ZIP_DEFLATED
        if p.suffix=='.command':info.external_attr=(0o100755<<16)
        archive.writestr(info,p.read_bytes())
with zipfile.ZipFile(out) as archive: assert archive.testzip() is None
print(out)
