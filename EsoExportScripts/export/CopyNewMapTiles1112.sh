#!/bin/sh

VERSION="$1"
MAPPATH="./goodimages-$VERSION/Maps"
NEWMAPPATH="./goodimages-$VERSION/NewMaps"
NEWPTSMAPPATH="./goodimages-$VERSION/NewMapsPts"

pushd "$NEWMAPPATH"

for d in *
do
	echo "$d"
	[ -d "$d" ] && rsync -av "../Maps/$d" .
done

popd
pushd "$NEWPTSMAPPATH"

for d in *
do
	echo "$d"
	[ -d "$d" ] && rsync -av "../Maps/$d" .
done

popd