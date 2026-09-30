# Remove EXIF roadmap

Created by Moosh Massacre · gustavo@mooshmassacre.studio.

## v1.1 — format expansion and uninstall

- [x] HEIC/HEIF cleaning through an optional local ExifTool installation.
- [x] Single-image TIFF cleaning, retaining display orientation and color information.
- [x] Reject multi-page/SubIFD TIFF until all pages can be cleaned and verified.
- [x] Verify common private metadata after HEIC/TIFF cleaning before replacement.
- [x] Uninstaller with confirmation, preserving images and installation backups.
- [x] English documentation and regression tests.
- [ ] Validate installation, Quick Action, and uninstall on macOS before a stable release.

## Next — provenance and reliability

- [ ] Explicit C2PA / Content Credentials removal for every supported container.
- [ ] Test signed C2PA fixtures: verify embedded manifests and references are removed, and encoded media remains valid.
- [ ] Detect unsupported or remaining provenance and report it instead of claiming complete removal.
- [ ] Document that embedded credential removal does not remove external manifests, remote records, or pixel watermarks.
- [ ] Safe JPEG/PNG orientation handling for rotated or mirrored images.
- [ ] Full multi-page TIFF and SubIFD support with per-page metadata verification.
- [ ] Broader post-cleaning integrity and metadata checks for JPEG and PNG.
- [ ] Test HEIC HDR, depth, auxiliary images and motion-photo variants.

## Later — packaging and recovery

- [ ] Optional image backup and restore.
- [ ] Native macOS `.pkg` installer.
- [ ] Developer ID signing and notarization.
- [ ] Dependency setup that avoids a separate ExifTool installation.

Milestones express scope, not delivery dates. C2PA removal is planned and is not a guaranteed feature of v1.1.
