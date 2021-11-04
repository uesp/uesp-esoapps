#!/bin/sh

VERSION="$1"
MAPPATH="./goodimages-$VERSION/Maps"
NEWMAPPATH="./goodimages-$VERSION/NewMaps"
NEWPTSMAPPATH="./goodimages-$VERSION/NewMapsPts"

if [ -d "$NEWMAPPATH" ] 
then
	pushd "$NEWMAPPATH"

	for d in *
	do
		echo "$d"
		[ -d "$d" ] && rsync -av "../Maps/$d" .
	done

	popd
else
	echo "Skipping $NEWMAPPATH..."
fi

if [ -d "$NEWPTSMAPPATH" ] 
then
	pushd "$NEWPTSMAPPATH"

	for d in *
	do
		echo "$d"
		[ -d "$d" ] && rsync -av "../Maps/$d" .
	done
	
	popd
else
	echo "Skipping $NEWPTSMAPPATH..."
fi

