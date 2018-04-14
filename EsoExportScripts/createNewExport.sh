#!/bin/sh

VERSION="17"
LASTVERSION="16"
LASTPTSVERSION="17pts"
MAKEPTSDIFF="1"
MAKEDIFF=""

MAPSOURCEPATH="/cygdrive/d/src/uesp/EsoApps/EsoMapParse"
ESOINPUTPATH="./esomnf-$VERSION"
GAMEINPUTPATH="./gamemnf-$VERSION"
OUTPUTPATH="./goodimages-$VERSION"


pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

makediff () {
	echo "       Making Diff: $3 ..."
	
	VERSION1="$4"
	VERSION2="$5"
	SAFE1=$(printf '%s\n' "$1" | sed 's/[[\.*^$/]/\\&/g')
	SAFE2=$(printf '%s\n' "$2" | sed 's/[[\.*^$/]/\\&/g')
	
	diff -qr "$1" "$2" | grep -v ".png" | sort > "$3"
	
	sed -i "0,/Files .* and .* differ/s//\n\nChanged:\n&/" "$3"
	sed -i "0,/Only in $SAFE1/s//\n\nRemoved:\n&/" "$3"
	sed -i "0,/Only in $SAFE2/s//\n\nAdded:\n&/" "$3"
	
	sed -i "s#Files .* and .*mnf-$VERSION2\(.*\) differ#\t\1#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION1\(.*\)/: #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION2\(.*\)/: #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION1\(.*\): #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION2\(.*\): #\t\1/#g" "$3"
}

makemapsdiff () {
	echo "       Making Maps Diff: $3 ..."
	
	VERSION1="$4"
	VERSION2="$5"
	SAFE1=$(printf '%s\n' "$1" | sed 's/[[\.*^$/]/\\&/g')
	SAFE2=$(printf '%s\n' "$2" | sed 's/[[\.*^$/]/\\&/g')
	
	diff -qr "$1" "$2" | grep -v ".png" | egrep "_0|Only in $1:|Only in $2:" | sort > "$3"
	
	sed -i "0,/Files .* and .* differ/s//\n\nChanged:\n&/" "$3"
	sed -i "0,/Only in $SAFE1/s//\n\nRemoved:\n&/" "$3"
	sed -i "0,/Only in $SAFE2/s//\n\nAdded:\n&/" "$3"
	
	sed -i "s#_base_0.dds##g" "$3"
	
	sed -i "s#Files .* and .*mnf-$VERSION2\(.*\) differ#\t\1#g" "$3"
	sed -i "s#Only in $SAFE1: #\t/#g" "$3"
	sed -i "s#Only in $SAFE2: #\t/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION1\(.*\): #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION2\(.*\): #\t\1/#g" "$3"
}


if [ ! -d "$OUTPUTPATH" ]; then
	cp -rp "./NewExportBase" "$OUTPUTPATH"
fi


echo "Converting DDS to PNG..."
./convertdds.bat "./$GAMEINPUTPATH/esoui/"
./convertdds.bat "./$ESOINPUTPATH/esoui/"
./convertdds.bat "./$ESOINPUTPATH/art/"


echo "Copying Game UI Art..."
rsync -a --exclude "*.dds" "./$GAMEINPUTPATH/esoui/art/" "./$OUTPUTPATH/GameUIArt/"

echo "Copying Icons..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/art/icons/" "./$OUTPUTPATH/Icons/"

echo "Copying Loading Screens..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/art/loadingscreens/" "./$OUTPUTPATH/LoadingScreens/raw/"

echo "Copying Treasure Maps..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/art/treasuremaps/" "./$OUTPUTPATH/TreasureMaps/"

echo "Copying Crown Crates Images..."
rsync -a --exclude "*.dds" "./$GAMEINPUTPATH/esoui/art/crowncrates" "./$OUTPUTPATH/MoreImages/"

echo "Copying Collectible Images..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/art/collectibles" "./$OUTPUTPATH/MoreImages/"

echo "Copying Store Images..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/art/store" "./$OUTPUTPATH/MoreImages/"

echo "Copying Tree Icons..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/art/treeicons" "./$OUTPUTPATH/MoreImages/"

echo "Copying Tutorial Images..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/art/tutorial" "./$OUTPUTPATH/MoreImages/"

echo "Copying Language files..."
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/gamedata/lang/" "./$OUTPUTPATH/Lang/"
rsync -a --exclude "*.dds" "./$ESOINPUTPATH/esoui/lang/" "./$OUTPUTPATH/Lang/client/"
rsync -a --exclude "*.dds" "./$GAMEINPUTPATH/esoui/ingamelocalization" "./$OUTPUTPATH/Lang/"
rsync -a --exclude "*.dds" "./$GAMEINPUTPATH/esoui/internalingamelocalization" "./$OUTPUTPATH/Lang/"
rsync -a --exclude "*.dds" "./$GAMEINPUTPATH/esoui/pregamelocalization" "./$OUTPUTPATH/Lang/"


echo "Cropping Loading Screens..."
cd ./$OUTPUTPATH/LoadingScreens/
./croploadscreens.sh
cd ../../


echo "Splitting Icons..."
cd ./$OUTPUTPATH/Icons/
./moveicons.sh
./movesubdiricons.sh
cd ../../


python "$MAPSOURCEPATH/CombineEsoMaps.py" 17 "/cygdrive/e/esoexport/" 
python "$MAPSOURCEPATH/CreateEsoMapTiles.py" 17 "/cygdrive/e/esoexport/" 
python "$MAPSOURCEPATH/CreateEsoMapTileZoom11.py" 17 "/cygdrive/e/esoexport/" 


if [ $MAKEDIFF ]; then
	echo "Making Diffs..."
	makediff "./esomnf-$LASTVERSION/esoui/art/icons/" "./esomnf-$VERSION/esoui/art/icons/" "./goodimages-$VERSION/icons.ptsdiff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/loadingscreens/" "./esomnf-$VERSION/esoui/art/loadingscreens/" "./goodimages-$VERSION/loadscreens.ptsdiff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/treasuremaps/" "./esomnf-$VERSION/esoui/art/treasuremaps/" "./goodimages-$VERSION/treasuremaps.ptsdiff.txt" $LASTVERSION $VERSION
	makediff "./gamemnf-$LASTVERSION/esoui/art/crowncrates/" "./gamemnf-$VERSION/esoui/art/crowncrates/" "./goodimages-$VERSION/crowncrates.ptsdiff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/collectibles/" "./esomnf-$VERSION/esoui/art/collectibles/" "./goodimages-$VERSION/collectibles.ptsdiff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/store/" "./esomnf-$VERSION/esoui/art/store/" "./goodimages-$VERSION/store.ptsdiff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/treeicons/" "./esomnf-$VERSION/esoui/art/treeicons/" "./goodimages-$VERSION/treeicons.ptsdiff.txt" $LASTVERSION $VERSION 
	makediff "./esomnf-$LASTVERSION/esoui/art/tutorial/" "./esomnf-$VERSION/esoui/art/tutorial/" "./goodimages-$VERSION/tutorial.ptsdiff.txt"  $LASTVERSION $VERSION
	makediff "./gamemnf-$LASTVERSION/esoui/art/" "./gamemnf-$VERSION/esoui/art/" "./goodimages-$VERSION/gameuiart.ptsdiff.txt" $LASTVERSION $VERSION
	makemapsdiff "./esomnf-$LASTVERSION/art/maps/" "./esomnf-$VERSION/art/maps/" "./goodimages-$VERSION/maps.ptsdiff.txt" $LASTVERSION $VERSION
fi

if [ $MAKEPTSDIFF ]; then
	echo "Making PTS Diffs..."
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/icons/" "./esomnf-$VERSION/esoui/art/icons/" "./goodimages-$VERSION/icons.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/loadingscreens/" "./esomnf-$VERSION/esoui/art/loadingscreens/" "./goodimages-$VERSION/loadscreens.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/treasuremaps/" "./esomnf-$VERSION/esoui/art/treasuremaps/" "./goodimages-$VERSION/treasuremaps.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./gamemnf-$LASTPTSVERSION/esoui/art/crowncrates/" "./gamemnf-$VERSION/esoui/art/crowncrates/" "./goodimages-$VERSION/crowncrates.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/collectibles/" "./esomnf-$VERSION/esoui/art/collectibles/" "./goodimages-$VERSION/collectibles.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/store/" "./esomnf-$VERSION/esoui/art/store/" "./goodimages-$VERSION/store.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/treeicons/" "./esomnf-$VERSION/esoui/art/treeicons/" "./goodimages-$VERSION/treeicons.ptsdiff.txt" $LASTPTSVERSION $VERSION 
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/tutorial/" "./esomnf-$VERSION/esoui/art/tutorial/" "./goodimages-$VERSION/tutorial.ptsdiff.txt"  $LASTPTSVERSION $VERSION
	makediff "./gamemnf-$LASTPTSVERSION/esoui/art/" "./gamemnf-$VERSION/esoui/art/" "./goodimages-$VERSION/gameuiart.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makemapsdiff "./esomnf-$LASTPTSVERSION/art/maps/" "./esomnf-$VERSION/art/maps/" "./goodimages-$VERSION/maps.ptsdiff.txt" $LASTPTSVERSION $VERSION
fi


echo "Compressing Game UI Art..."
pushd "./$OUTPUTPATH/GameUIArt/"
zip -rq "../gameuiart.zip" *
cd ..
zip -urq "gameuiart.zip" gameuiart.ptsdiff.txt gameuiart.diff.txt
popd

echo "Compressing Icons..."
pushd "./$OUTPUTPATH/Icons/"
zip -rq "../icons.zip" *
cd ..
zip -urq "icons.zip" icons.ptsdiff.txt icons.diff.txt
popd

echo "Compressing Loading Screens..."
pushd "./$OUTPUTPATH/LoadingScreens/"
zip -q "../loadscreens.zip" *.jpg
cd ..
zip -urq "loadscreens.zip" loadscreens.ptsdiff.txt loadscreens.diff.txt
popd

echo "Compressing Treasure Maps..."
pushd "./$OUTPUTPATH/TreasureMaps/"
zip -q "../treasuremaps.zip" *.png
cd ..
zip -urq "treasuremaps.zip" treasuremaps.ptsdiff.txt treasuremaps.diff.txt
popd

echo "Compressing Crown Crate Images..."
pushd "./$OUTPUTPATH/MoreImages/crowncrates/"
zip -rq "../../crowncrates.zip" *
cd ../../
zip -urq "crowncrates.zip" crowncrates.ptsdiff.txt crowncrates.diff.txt
popd

echo "Compressing Collectible Images..."
pushd "./$OUTPUTPATH/MoreImages/collectibles/"
zip -rq "../../collectibles.zip" *
cd ../../
zip -urq "collectibles.zip" collectibles.ptsdiff.txt collectibles.diff.txt
popd

echo "Compressing Store Images..."
pushd "./$OUTPUTPATH/MoreImages/store/"
zip -rq "../../store.zip" *
cd ../../
zip -urq "store.zip" store.ptsdiff.txt store.diff.txt
popd

echo "Compressing Tree Icons..."
pushd "./$OUTPUTPATH/MoreImages/treeicons/"
zip -rq "../../treeicons.zip" *
cd ../../
zip -urq "treeicons.zip" treeicons.ptsdiff.txt treeicons.diff.txt
popd

echo "Compressing Tutorial Images..."
pushd "./$OUTPUTPATH/MoreImages/tutorial/"
zip -rq "../../tutorial.zip" *
cd ../../
zip -urq "tutorial.zip" tutorial.ptsdiff.txt tutorial.diff.txt
popd

echo "Compressing Maps..."
pushd "./$OUTPUTPATH/CombinedMaps/"
zip -rq "../maps.zip" * maplist.txt
cd ../maps/
zip -urq "../maps.zip" mapinfo.txt
cd ..
zip -urq "maps.zip" maps.ptsdiff.txt maps.diff.txt
popd
