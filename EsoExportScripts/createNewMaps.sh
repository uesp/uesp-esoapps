#!/bin/sh

VERSION="42pts"
NEXTFREEWORLDID="2501"

MAPSOURCEPATH="/cygdrive/d/src/uesp/EsoApps/EsoMapParse"
ESOINPUTPATH="./esomnf-$VERSION"
GAMEINPUTPATH="./gamemnf-$VERSION"
OUTPUTPATH="./goodimages-$VERSION"
BASEPATH=`realpath ./`

python "$MAPSOURCEPATH/CreateDbStatementForNewMaps.py" "$VERSION" "$BASEPATH/" "$NEXTFREEWORLDID"