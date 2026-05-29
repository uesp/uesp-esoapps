#!/bin/sh

VERSION="50pts"
NEXTFREEWORLDID="2817"

MAPSOURCEPATH="/cygdrive/d/src/uesp/EsoApps/EsoMapParse"
ESOINPUTPATH="./esomnf-$VERSION"
GAMEINPUTPATH="./gamemnf-$VERSION"
OUTPUTPATH="./goodimages-$VERSION"
BASEPATH=`realpath ./`

python "$MAPSOURCEPATH/CreateDbStatementForNewMaps.py" "$VERSION" "$BASEPATH/" "$NEXTFREEWORLDID"
