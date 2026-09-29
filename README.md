# Remove EXIF v1.0

A Finder Quick Action for macOS that removes private metadata from JPEG and PNG images in place. Created by **Moosh Massacre** · [gustavo@mooshmassacre.studio](mailto:gustavo@mooshmassacre.studio).

The tool removes JPEG EXIF, XMP, IPTC, comments, and other application segments, plus PNG EXIF and text chunks. It preserves compressed image data, color profiles, transparency, and animated PNG frames. It does not recompress images or add identifying metadata.

## Install

1. Download [`dist/Remove_EXIF_Installer_v1.0.zip`](dist/Remove_EXIF_Installer_v1.0.zip) and extract it.
2. Open **Install Remove EXIF.command**. If macOS blocks the first launch, Control-click it and choose **Open**.
3. In Finder, select one or more JPEG or PNG images and choose **Quick Actions → Remove EXIF**.

The installer places the script at `~/Library/Application Support/Remove EXIF/Remove_EXIF.command` and the Automator workflow at `~/Library/Services/Remove EXIF.workflow`. It saves earlier versions under `~/Library/Application Support/Remove EXIF/Backups`. No administrator privileges or third-party dependencies are required. If the action is not listed immediately, restart Finder or sign out and back in.

## What to expect

- The selected file is replaced at the same path and keeps its name and modification time. The action is silent on success.
- The original is not backed up by the action itself. Try it on a copy before processing irreplaceable images.
- A JPEG that relies on EXIF orientation other than `1` is skipped to avoid changing its visible rotation.
- HEIC, TIFF, and other formats are skipped. The action requires read access to the file and write access to its containing folder. It reports failures without replacing the original.
- Finder tags and other extended file attributes are removed along with the replacement file. The filesystem creation date may change.

## Source

The installer and Automator workflow live at the repository root and under [`Resources`](Resources). The workflow passes selected files to the script as arguments. To install manually, copy both resources to the locations above.

## License

[MIT](LICENSE) © 2026 Moosh Massacre <gustavo@mooshmassacre.studio>. The copyright and license notice must accompany copies or substantial portions of this project.
