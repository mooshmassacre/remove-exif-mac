# Remove EXIF v1.1

A Finder Quick Action for macOS that removes private metadata from JPEG, PNG, HEIC/HEIF, and single-image TIFF files in place. Created by **Moosh Massacre** · [gustavo@mooshmassacre.studio](mailto:gustavo@mooshmassacre.studio).

It removes embedded creator, software, and creation metadata, including metadata added by AI tools. Explicit C2PA / Content Credentials removal is planned in the [roadmap](ROADMAP.md); this version does not guarantee complete provenance removal. External records and pixel watermarks are outside its scope.

The tool removes JPEG EXIF, XMP, IPTC, comments, and other application segments, plus PNG EXIF and text chunks. It preserves compressed image data, color profiles, transparency, and animated PNG frames. It does not recompress images or add identifying metadata.

## Install

1. Download [`dist/Remove_EXIF_Installer_v1.1.zip`](dist/Remove_EXIF_Installer_v1.1.zip) and extract it.
2. Open **Install Remove EXIF.command**. If macOS blocks the first launch, Control-click it and choose **Open**.
3. In Finder, select one or more supported images and choose **Quick Actions → Remove EXIF**.

The installer places the script at `~/Library/Application Support/Remove EXIF/Remove_EXIF.command` and the Automator workflow at `~/Library/Services/Remove EXIF.workflow`. It saves earlier versions under `~/Library/Application Support/Remove EXIF/Backups`. JPEG and PNG need no third-party dependencies. HEIC/HEIF and TIFF require [ExifTool](https://exiftool.org/) installed locally at `/usr/local/bin/exiftool` or `/opt/homebrew/bin/exiftool`. The installer does not download it or request administrator privileges. If the action is not listed immediately, restart Finder or sign out and back in.

## What to expect

- The selected file is replaced at the same path and keeps its name and modification time. The action is silent on success.
- The original is not backed up by the action itself. Try it on a copy before processing irreplaceable images.
- A JPEG that relies on EXIF orientation other than `1` is skipped to avoid changing its visible rotation.
- HEIC/HEIF and single-image TIFF use ExifTool to remove private metadata while preserving color data and EXIF orientation. Required TIFF structure and HEIC container properties remain. Multi-page/SubIFD TIFF and other formats are skipped. The action requires read access to the file and write access to its containing folder. It reports failures without replacing the original.
- Finder tags and other extended file attributes are removed along with the replacement file. The filesystem creation date may change.

## Uninstall

Open **Uninstall Remove EXIF.command** from the extracted package or `~/Library/Application Support/Remove EXIF/`, then confirm **Uninstall**. It removes the Finder action and installed scripts. Your images, previous installation backups, and any separately installed ExifTool are kept.

## Development status

This v1.1 package is a preview pending macOS integration testing. Portable tests cover JPEG/PNG decoded pixels, single-image TIFF pixels and orientation, HEIC compressed media, private metadata removal, and rejection of invalid input and multi-page TIFF. Run `python tests/test_cleaners.py /path/to/exiftool` with Pillow installed and an official ExifTool source distribution (the HEIC fixture comes from its test suite). See [ROADMAP.md](ROADMAP.md).

## Source

The installer and Automator workflow live at the repository root and under [`Resources`](Resources). The workflow passes selected files to the script as arguments. To install manually, copy both resources to the locations above.

## License

[MIT](LICENSE) © 2026 Moosh Massacre <gustavo@mooshmassacre.studio>. The copyright and license notice must accompany copies or substantial portions of this project.
