#!/usr/bin/env bash
# Verpackt die Exporte aus builds/<plattform>/ nach builds/release/ und erzeugt SHA256SUMS.txt.
# Aufruf: tools/package_release.sh [version]

set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
V="${1:-1.0}"
B="$ROOT/builds"
R="$B/release"

mkdir -p "$R"
find "$R" -maxdepth 1 -type f \( -name 'Brummi-*' -o -name SHA256SUMS.txt \) -delete

pack() {
    local dir="$1" name="$2"
    shift 2
    (cd "$B/$dir" && zip -q -9 "$R/Brummi-$V-$name.zip" "$@")
}

pack linux linux-x86_64 Brummi.x86_64
pack linux-arm64 linux-arm64 Brummi.arm64
pack windows windows-x86_64 Brummi.exe
pack windows-arm64 windows-arm64 Brummi.exe
pack web web index.*
cp "$B/macos/Brummi.zip" "$R/Brummi-$V-macos.zip"
cp "$B/android/Brummi.apk" "$R/Brummi-$V-android-debug.apk"

(cd "$R" && sha256sum Brummi-* > SHA256SUMS.txt)
ls -la "$R"
