#!/bin/bash
# Build the release tarball the PKGBUILD pins, from a tag.
#
#   packaging/release.sh 1.0.0
#
# git archive of the tag, not GitHub's generated archive: those are made on
# demand, and a change to how GitHub compresses them has broken every
# checksum pinned against them before. Upload the file as a release asset; an
# uploaded file is stored verbatim and its checksum cannot move.
set -euo pipefail
cd "$(dirname "$0")/.."

version="${1:?usage: release.sh <version>}"
tag="${2:-v$version}"
name=app-finder
out="${OUT:-dist}"

git rev-parse -q --verify "$tag" >/dev/null || { echo "no such tag: $tag" >&2; exit 1; }

mkdir -p "$out"
tarball="$out/$name-$version.tar.gz"
# The packaging directory stays out: the PKGBUILD must not travel inside the
# tarball whose checksum it names.
git archive --format=tar --prefix="$name-$version/" "$tag" -- . ':!packaging' | gzip -n >"$tarball"

sum=$(sha256sum "$tarball" 2>/dev/null || shasum -a 256 "$tarball")
sum=${sum%% *}
sed -i.bak -e "s/^pkgver=.*/pkgver=$version/" -e "s/^sha256sums=.*/sha256sums=('$sum')/" packaging/PKGBUILD
rm -f packaging/PKGBUILD.bak
echo "$tarball"
echo "sha256 $sum"
