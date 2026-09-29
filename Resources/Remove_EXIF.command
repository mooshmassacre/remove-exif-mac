#!/bin/bash
# Remove EXIF v1.0 — Moosh Massacre <gustavo@mooshmassacre.studio>
# Copyright (c) 2026 Moosh Massacre. MIT License.
# macOS: remove metadata from selected JPEG and PNG files in place.
# Remove EXIF, XMP, IPTC, and text chunks without recompressing pixels.

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

if [ "${1-}" = "--about" ]; then
    printf '%s\n' 'Remove EXIF v1.0' 'Moosh Massacre <gustavo@mooshmassacre.studio>' 'Copyright (c) 2026 Moosh Massacre. MIT License.' 'Formats: JPEG, PNG'
    exit 0
fi

if [ ! -x /usr/bin/perl ]; then
    /usr/bin/osascript -e 'display dialog "Perl is unavailable on this Mac. No files were changed." buttons {"OK"} with title "Remove EXIF"'
    exit 1
fi

if [ "$#" -eq 0 ]; then
    selection=$(/usr/bin/osascript \
        -e 'try' \
        -e 'set picked to {}' \
        -e 'try' \
        -e 'tell application "Finder" to set picked to selection as alias list' \
        -e 'end try' \
        -e 'if (count of picked) is 0 then set picked to choose file with prompt "Select JPEG or PNG images to remove metadata:" with multiple selections allowed' \
        -e 'set paths to {}' \
        -e 'repeat with itemRef in picked' \
        -e 'set end of paths to POSIX path of (itemRef as alias)' \
        -e 'end repeat' \
        -e "set AppleScript's text item delimiters to (ASCII character 30)" \
        -e 'return paths as text' \
        -e 'on error number -128' \
        -e 'return ""' \
        -e 'end try')
    [ -n "$selection" ] || exit 0
    IFS=$'\036' read -r -a picked <<< "$selection"
    set -- "${picked[@]}"
fi

ok=0
failed=0
skipped=0
details=""

for input in "$@"; do
    if [ ! -f "$input" ]; then
        skipped=$((skipped + 1))
        continue
    fi
    if [ -L "$input" ]; then
        skipped=$((skipped + 1))
        details="$details"$'\n'"${input##*/}: symbolic link skipped."
        continue
    fi

    name=${input##*/}
    ext=${name##*.}
    case $(printf '%s' "$ext" | /usr/bin/tr '[:upper:]' '[:lower:]') in
        jpg|jpeg|png) ;;
        *) skipped=$((skipped + 1)); details="$details"$'\n'"$name: only JPEG and PNG are supported."; continue ;;
    esac

    parent=${input%/*}
    [ "$parent" = "$input" ] && parent=.
    temp=$(/usr/bin/mktemp "$parent/.imagem-limpa.XXXXXXXX") || {
        failed=$((failed + 1))
        details="$details"$'\n'"$name: could not create a temporary file."
        continue
    }

    # Preserve encoded pixels and technical color information.
    result=$(/usr/bin/perl - "$input" "$temp" 2>&1 <<'PERL'
use strict;
use warnings;
use bytes;
my ($source, $target) = @ARGV;
open my $fh, '<:raw', $source or die "Could not read: $!";
local $/;
my $data = <$fh>;
close $fh;
die "Empty file." unless defined($data);
sub check_orientation {
    my ($tiff) = @_;
    my $bo = substr($tiff, 0, 2);
    die "Invalid EXIF; image skipped." unless $bo eq 'II' || $bo eq 'MM';
    my $le = $bo eq 'II';
    my $unpack16 = $le ? 'v' : 'n';
    my $unpack32 = $le ? 'V' : 'N';
    die "Invalid EXIF; image skipped." if length($tiff) < 8;
    my $ifd = unpack($unpack32, substr($tiff, 4, 4));
    die "Invalid EXIF; image skipped." if $ifd + 2 > length($tiff);
    my $count = unpack($unpack16, substr($tiff, $ifd, 2));
    die "Invalid EXIF; image skipped." if $count > 10000 || $ifd + 2 + 12 * $count > length($tiff);
    for my $i (0 .. $count - 1) {
        my $p = $ifd + 2 + 12 * $i;
        next unless unpack($unpack16, substr($tiff, $p, 2)) == 0x0112;
        my $orientation = unpack($unpack16, substr($tiff, $p + 8, 2));
        die "Image uses EXIF orientation ($orientation); skipped to avoid rotation."
            unless $orientation == 1;
    }
}
my $out;
if (substr($data, 0, 2) eq "\xFF\xD8") {
$out = "\xFF\xD8";
my $pos = 2;
my $ended = 0;
while ($pos < length($data)) {
    die "Invalid JPEG: marker missing." unless substr($data, $pos, 1) eq "\xFF";
    my $start = $pos;
    $pos++ while $pos < length($data) && substr($data, $pos, 1) eq "\xFF";
    die "Truncated JPEG." if $pos >= length($data);
    my $marker = ord(substr($data, $pos++, 1));
    die "Invalid JPEG." if $marker == 0;
    if ($marker == 0xD9) {
        $out .= "\xFF\xD9";
        $ended = 1;
        last;
    }
    if ($marker == 0x01 || $marker == 0xD8 || ($marker >= 0xD0 && $marker <= 0xD7)) {
        $out .= substr($data, $start, $pos - $start);
        next;
    }
    die "Truncated JPEG." if $pos + 2 > length($data);
    my $size = unpack('n', substr($data, $pos, 2));
    die "Invalid segment." if $size < 2 || $pos + $size > length($data);
    my $payload = substr($data, $pos + 2, $size - 2);
    my $keep = 1;
    if ($marker >= 0xE0 && $marker <= 0xEF) {
        if ($marker == 0xE1 && substr($payload, 0, 6) eq "Exif\0\0") {
            check_orientation(substr($payload, 6));
        }
        $keep = ($marker == 0xE2 && substr($payload, 0, 12) eq "ICC_PROFILE\0")
             || ($marker == 0xEE && substr($payload, 0, 5) eq 'Adobe');
    } elsif ($marker == 0xFE) {
        $keep = 0;
    }
    $out .= substr($data, $start, $pos + $size - $start) if $keep;
    $pos += $size;
    if ($marker == 0xDA) {
        my $scan_start = $pos;
        while ($pos < length($data)) {
            my $ff = index($data, "\xFF", $pos);
            die "JPEG has no valid end marker." if $ff < 0 || $ff + 1 >= length($data);
            my $next = $ff + 1;
            $next++ while $next < length($data) && substr($data, $next, 1) eq "\xFF";
            die "Truncated JPEG." if $next >= length($data);
            my $code = ord(substr($data, $next, 1));
            if ($code == 0 || ($code >= 0xD0 && $code <= 0xD7)) {
                $pos = $next + 1;
                next;
            }
            $out .= substr($data, $scan_start, $ff - $scan_start);
            $pos = $ff;
            last;
        }
    }
}
die "JPEG has no end marker." unless $ended;
} elsif (substr($data, 0, 8) eq "\x89PNG\r\n\x1A\n") {
    $out = substr($data, 0, 8);
    my $pos = 8;
    my $ended = 0;
    my $has_header = 0;
    my $has_pixels = 0;
    while ($pos + 12 <= length($data)) {
        my $size = unpack('N', substr($data, $pos, 4));
        my $type = substr($data, $pos + 4, 4);
        die "Invalid PNG chunk." unless $type =~ /^[A-Za-z]{4}$/;
        die "Truncated PNG." if $size > length($data) - $pos - 12;
        die "PNG header missing." if $pos == 8 && $type ne 'IHDR';
        check_orientation(substr($data, $pos + 8, $size)) if $type eq 'eXIf';
        $has_header = 1 if $type eq 'IHDR';
        $has_pixels = 1 if $type eq 'IDAT';
        # Essential data, color, transparency, and animated PNG frames.
        my $keep = $type =~ /^[A-Z]/
                || $type =~ /^(?:iCCP|sRGB|gAMA|cHRM|sBIT|tRNS|cICP|mDCv|cLLi|acTL|fcTL|fdAT)$/;
        $out .= substr($data, $pos, $size + 12) if $keep;
        $pos += $size + 12;
        if ($type eq 'IEND') { $ended = 1; last; }
    }
    die "Incomplete PNG." unless $ended && $has_header && $has_pixels;
} else {
    die "Content is neither JPEG nor PNG.";
}
open my $dest, '>:raw', $target or die "Could not save: $!";
print {$dest} $out or die "Write failed: $!";
close $dest or die "Finalize failed: $!";
PERL
    )
    process_status=$?
    mode=$(/usr/bin/stat -f '%Lp' "$input" 2>/dev/null)
    if [ "$process_status" -eq 0 ] && [ -s "$temp" ] && [ -n "$mode" ] && /bin/chmod "$mode" "$temp" && /usr/bin/touch -r "$input" "$temp" && /bin/mv -f "$temp" "$input"; then
            ok=$((ok + 1))
    else
            /bin/rm -f "$temp"
            failed=$((failed + 1))
            result=${result##*$'\n'}
            details="$details"$'\n'"$name: ${result:-could not replace the file.}"
    fi
done

summary="Images cleaned: $ok. Failed: $failed. Skipped: $skipped."
if [ "$failed" -gt 0 ] || [ "$skipped" -gt 0 ]; then
    /usr/bin/osascript -e 'on run argv' -e 'display dialog (item 1 of argv) buttons {"OK"} default button "OK" with title "Remove EXIF"' -e 'end run' "$summary$details"
fi

[ "$failed" -eq 0 ]
