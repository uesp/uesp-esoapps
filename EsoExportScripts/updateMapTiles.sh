#!/bin/sh

VERSION="31pts"
OUTPUTPATH="./goodimages-$VERSION"

rsync -ar "./$OUTPUTPATH/Maps/" --files-from="./$OUTPUTPATH/maps.diff.txt.updatedmaps" "./$OUTPUTPATH/NewMaps/"
rsync -ar "./$OUTPUTPATH/Maps/" --files-from="./$OUTPUTPATH/maps.ptsdiff.txt.updatedmaps" "./$OUTPUTPATH/NewMapsPts/"