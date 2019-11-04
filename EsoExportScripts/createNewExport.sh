#!/bin/sh

VERSION="24"
ISPTS=""
LASTVERSION="23"
LASTPTSVERSION="24pts"

MAKEPTSDIFF="1"
MAKEDIFF="1"

if [ "$ISPTS" ]; then
	MAKEPTSDIFF=""
fi

#
# Set to 1 for game updates 20 and prior.
#
CROPLOADINGSCREENS=""

MAPSOURCEPATH="/cygdrive/d/src/uesp/EsoApps/EsoMapParse"
ESOINPUTPATH="./esomnf-$VERSION"
GAMEINPUTPATH="./gamemnf-$VERSION"
OUTPUTPATH="./goodimages-$VERSION"

if [ "$ISPTS" ]; then
	ESODATAFILE="c:/Program Files (x86)/Zenimax Online/The Elder Scrolls Online PTS/depot/eso.mnf"
	GAMEDATAFILE="c:/Program Files (x86)/Zenimax Online/The Elder Scrolls Online PTS/game/client/game.mnf"
else
	ESODATAFILE="c:/Program Files (x86)/Zenimax Online/The Elder Scrolls Online/depot/eso.mnf"
	GAMEDATAFILE="c:/Program Files (x86)/Zenimax Online/The Elder Scrolls Online/game/client/game.mnf"
fi


pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

makediff () {
	echo "       Making Diff: $3 ..."
	
	EXT=".png"
	VERSION1="$4"
	VERSION2="$5"
	SAFE1=$(printf '%s\n' "$1" | sed 's/[[\.*^$/]/\\&/g')
	SAFE2=$(printf '%s\n' "$2" | sed 's/[[\.*^$/]/\\&/g')
	
	if [ "$CROPLOADINGSCREENS" ]; then
		if [[ $1 = *"loadingscreens"* ]]; then
			EXT=".jpg"
		fi
	fi
	
	diff -qr "$1" "$2" | grep -v ".png" | sort > "$3"
	
	cp -f "$3" "$3.list"
	
	sed -i "0,/Files .* and .* differ/s//\n\nChanged:\n&/" "$3"
	sed -i "0,/Only in $SAFE1/s//\n\nRemoved:\n&/" "$3"
	sed -i "0,/Only in $SAFE2/s//\n\nAdded:\n&/" "$3"
	
	sed -i "s#Files .* and .*mnf-$VERSION2\(.*\) differ#\t\1#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION1\(.*\)/: #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION2\(.*\)/: #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION1\(.*\): #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION2\(.*\): #\t\1/#g" "$3"
	
	sed -i "s#Files .* and $SAFE2\(.*\) differ#\1#g" "$3.list"
	sed -i "s#Only in $SAFE2\(.*\)/: #\1/#g" "$3.list"
	sed -i "s#Only in $SAFE2\(.*\): #\1/#g" "$3.list"
	sed -i "/Only in .*mnf-$VERSION1\(.*\): /d" "$3.list"
	sed -i "s#\.dds#$EXT#g" "$3.list"
	sed -i "s#^/##g" "$3.list"
	
}

makemapsdiff () {
	echo "       Making Maps Diff: $3 ..."
	
	rsync -a --include '*/' --exclude '*' "$2" "$1"
	rsync -a --include '*/' --exclude '*' "$1" "$2"
	
	VERSION1="$4"
	VERSION2="$5"
	SAFE1=$(printf '%s\n' "$1" | sed 's/[[\.*^$/]/\\&/g')
	SAFE2=$(printf '%s\n' "$2" | sed 's/[[\.*^$/]/\\&/g')
	
	diff -qr "$1" "$2" | grep -v ".png" | egrep "_0.dds|Only in $1:|Only in $2:" | sort > "$3"
	
	cp -f "$3" "$3.list"
	
	sed -i "0,/Files .* and .* differ/s//\n\nChanged:\n&/" "$3"
	sed -i "0,/Only in $SAFE1/s//\n\nRemoved:\n&/" "$3"
	sed -i "0,/Only in $SAFE2/s//\n\nAdded:\n&/" "$3"
	
	sed -i "s#_0.dds##g" "$3"
	
	grep -e "Only in .*mnf-$VERSION2" "$3" > "$3.newmaps"
	
	sed -i "s#Files .* and .*mnf-$VERSION2\(.*\) differ#\t\1#g" "$3"
	sed -i "s#Only in $SAFE1: #\t/#g" "$3"
	sed -i "s#Only in $SAFE2: #\t/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION1\(.*\): #\t\1/#g" "$3"
	sed -i "s#Only in .*mnf-$VERSION2\(.*\): #\t\1/#g" "$3"
	
	sed -i "s#Files .* and $SAFE2\(.*\) differ#\1#g" "$3.list"
	sed -i "s#Only in $SAFE2\(.*\)/: #\1/#g" "$3.list"
	sed -i "s#Only in $SAFE2\(.*\): #\1/#g" "$3.list"
	sed -i "/Only in .*mnf-$VERSION1\(.*\): /d" "$3.list"
	sed -i "s#^/##g" "$3.list"
	sed -i "s#_0.dds#.jpg#g" "$3.list"
	
	grep ".jpg" "$3.list" > "$3.updatedmaps"
	sed -i "s#.*/##g" "$3.updatedmaps"
	sed -i "s#_base.jpg##g" "$3.updatedmaps"
	sed -i "s#.jpg##g" "$3.updatedmaps"
	
		# Only in ./esomnf-18pts/art/maps/bangkorai: bangkoraigarrison_alt_base
		# Only in ./esomnf-18pts/art/maps/housing: colossalaldmerigrotto_base
		# Only in ./esomnf-18pts/art/maps/stormhaven: ui_map_fanglairext_base
		# Only in ./esomnf-18pts/art/maps/summerset: alinor_base
	sed -i "s#_base\$##g" "$3.newmaps"
	sed "s#Only in ./esomnf-$VERSION2/art/maps/\(.*\): \(.*\)#\2,\2,\1,-1#g" "$3.newmaps" > "$OUTPUTPATH/maps_new.txt"
		
}

makezipdiff () {
	echo "       Make ZIP Diff: $3 ..."
	
	BASEPATH=`realpath $OUTPUTPATH`
	pushd "$2"
	zip -r@ "$BASEPATH/$1" < "$BASEPATH/$3"
	popd
}


if [ ! -d "$OUTPUTPATH" ]; then
	cp -rp "./NewExportBase" "$OUTPUTPATH"
fi


mkdir "$ESOINPUTPATH"
./export/EsoExtractData.exe "$ESODATAFILE" "$ESOINPUTPATH/" -z "$ESOINPUTPATH/zosft.txt" -m "$ESOINPUTPATH/mnf.txt"  --extractsubfile combined

mkdir "$GAMEINPUTPATH"
./export/EsoExtractData.exe "$GAMEDATAFILE" "$GAMEINPUTPATH/" -z "$GAMEINPUTPATH/zosft.txt" -m "$GAMEINPUTPATH/mnf.txt"


echo "Converting DDS to PNG..."
./convertdds.bat "$GAMEINPUTPATH/esoui/"
./convertdds.bat "$ESOINPUTPATH/esoui/"
./convertdds.bat "$ESOINPUTPATH/art/"


echo "Copying Game UI Art..."
rsync -a --exclude "*.dds" "$GAMEINPUTPATH/esoui/art/" "$OUTPUTPATH/GameUIArt/"

echo "Copying Icons..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/icons/" "$OUTPUTPATH/Icons/"

echo "Copying Loading Screens..."

if [ "$CROPLOADINGSCREENS" ]; then
	rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/loadingscreens/" "$OUTPUTPATH/LoadingScreens/raw/"
else
	rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/loadingscreens/" "$OUTPUTPATH/LoadingScreens/"
fi

echo "Copying Treasure Maps..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/treasuremaps/" "$OUTPUTPATH/TreasureMaps/"

echo "Copying Crown Crates Images..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/crowncrates" "$OUTPUTPATH/MoreImages/"

echo "Copying Collectible Images..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/collectibles" "$OUTPUTPATH/MoreImages/"

echo "Copying Store Images..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/store" "$OUTPUTPATH/MoreImages/"

echo "Copying Tree Icons..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/treeicons" "$OUTPUTPATH/MoreImages/"

echo "Copying Tutorial Images..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/art/tutorial" "$OUTPUTPATH/MoreImages/"

echo "Copying Language files..."
rsync -a --exclude "*.dds" "$ESOINPUTPATH/gamedata/lang/" "$OUTPUTPATH/Lang/"
rsync -a --exclude "*.dds" "$ESOINPUTPATH/esoui/lang/" "$OUTPUTPATH/Lang/client/"
rsync -a --exclude "*.dds" "$GAMEINPUTPATH/esoui/ingamelocalization" "$OUTPUTPATH/Lang/"
rsync -a --exclude "*.dds" "$GAMEINPUTPATH/esoui/internalingamelocalization" "$OUTPUTPATH/Lang/"
rsync -a --exclude "*.dds" "$GAMEINPUTPATH/esoui/pregamelocalization" "$OUTPUTPATH/Lang/"


if [ "$CROPLOADINGSCREENS" ]; then
	echo "Cropping Loading Screens..."
	cd $OUTPUTPATH/LoadingScreens/
	./croploadscreens.sh
fi


echo "Splitting Icons..."
cd $OUTPUTPATH/Icons/
./moveicons.sh
./movesubdiricons.sh
cd ../../

BASEPATH=`realpath ./`
python "$MAPSOURCEPATH/CombineEsoMaps.py" "$VERSION" "$BASEPATH/" 
python "$MAPSOURCEPATH/CreateEsoMapTiles.py" "$VERSION" "$BASEPATH/" 
python "$MAPSOURCEPATH/CreateEsoMapTileZoom11.py" "$VERSION" "$BASEPATH/" 


if [ $MAKEDIFF ]; then
	echo "Making Diffs..."
	makediff "./esomnf-$LASTVERSION/esoui/art/icons/" "./esomnf-$VERSION/esoui/art/icons/" "./goodimages-$VERSION/icons.diff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/loadingscreens/" "./esomnf-$VERSION/esoui/art/loadingscreens/" "./goodimages-$VERSION/loadscreens.diff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/treasuremaps/" "./esomnf-$VERSION/esoui/art/treasuremaps/" "./goodimages-$VERSION/treasuremaps.diff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/crowncrates/" "./esomnf-$VERSION/esoui/art/crowncrates/" "./goodimages-$VERSION/crowncrates.diff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/collectibles/" "./esomnf-$VERSION/esoui/art/collectibles/" "./goodimages-$VERSION/collectibles.diff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/store/" "./esomnf-$VERSION/esoui/art/store/" "./goodimages-$VERSION/store.diff.txt" $LASTVERSION $VERSION
	makediff "./esomnf-$LASTVERSION/esoui/art/treeicons/" "./esomnf-$VERSION/esoui/art/treeicons/" "./goodimages-$VERSION/treeicons.diff.txt" $LASTVERSION $VERSION 
	makediff "./esomnf-$LASTVERSION/esoui/art/tutorial/" "./esomnf-$VERSION/esoui/art/tutorial/" "./goodimages-$VERSION/tutorial.diff.txt"  $LASTVERSION $VERSION
	makediff "./gamemnf-$LASTVERSION/esoui/art/" "./gamemnf-$VERSION/esoui/art/" "./goodimages-$VERSION/gameuiart.diff.txt" $LASTVERSION $VERSION
	makemapsdiff "./esomnf-$LASTVERSION/art/maps/" "./esomnf-$VERSION/art/maps/" "./goodimages-$VERSION/maps.diff.txt" $LASTVERSION $VERSION
fi

if [ $MAKEPTSDIFF ]; then
	echo "Making PTS Diffs..."
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/icons/" "./esomnf-$VERSION/esoui/art/icons/" "./goodimages-$VERSION/icons.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/loadingscreens/" "./esomnf-$VERSION/esoui/art/loadingscreens/" "./goodimages-$VERSION/loadscreens.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/treasuremaps/" "./esomnf-$VERSION/esoui/art/treasuremaps/" "./goodimages-$VERSION/treasuremaps.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/crowncrates/" "./esomnf-$VERSION/esoui/art/crowncrates/" "./goodimages-$VERSION/crowncrates.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/collectibles/" "./esomnf-$VERSION/esoui/art/collectibles/" "./goodimages-$VERSION/collectibles.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/store/" "./esomnf-$VERSION/esoui/art/store/" "./goodimages-$VERSION/store.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/treeicons/" "./esomnf-$VERSION/esoui/art/treeicons/" "./goodimages-$VERSION/treeicons.ptsdiff.txt" $LASTPTSVERSION $VERSION 
	makediff "./esomnf-$LASTPTSVERSION/esoui/art/tutorial/" "./esomnf-$VERSION/esoui/art/tutorial/" "./goodimages-$VERSION/tutorial.ptsdiff.txt"  $LASTPTSVERSION $VERSION
	makediff "./gamemnf-$LASTPTSVERSION/esoui/art/" "./gamemnf-$VERSION/esoui/art/" "./goodimages-$VERSION/gameuiart.ptsdiff.txt" $LASTPTSVERSION $VERSION
	makemapsdiff "./esomnf-$LASTPTSVERSION/art/maps/" "./esomnf-$VERSION/art/maps/" "./goodimages-$VERSION/maps.ptsdiff.txt" $LASTPTSVERSION $VERSION
fi


echo "Extracting book and quest data..."
./export/ParseBooks.exe "$VERSION" "./"


echo "Compressing Books..."
pushd "$OUTPUTPATH/Books/"
zip -rq "../books.zip" *
popd

echo "Compressing Quests..."
pushd "$OUTPUTPATH/Quests/"
zip -rq "../quests.zip" Quests.txt Zones.txt
popd

echo "Compressing Game UI Art..."
pushd "$OUTPUTPATH/GameUIArt/"
zip -rq "../gameuiart.zip" *
cd ..
zip -urq "gameuiart.zip" gameuiart.ptsdiff.txt gameuiart.diff.txt
popd

echo "Compressing Icons..."
pushd "$OUTPUTPATH/Icons/"
zip -rq "../spliticons.zip" *
cd ..
zip -urq "spliticons.zip" icons.ptsdiff.txt icons.diff.txt
popd

BASEPATH=`realpath $OUTPUTPATH`
pushd "./esomnf-$VERSION/esoui/art/icons/"
zip -Rq "$BASEPATH/icons.zip" '*.png'
popd
pushd "$OUTPUTPATH"
zip -urq "icons.zip" icons.ptsdiff.txt icons.diff.txt
popd

echo "Compressing Language Files..."
pushd "$OUTPUTPATH/Lang/"
zip -rq "../lang.zip" *
popd

echo "Compressing Loading Screens..."
pushd "$OUTPUTPATH/LoadingScreens/"

if [ "$CROPLOADINGSCREENS" ]; then
	zip -q "../loadscreens.zip" *.jpg
else
	zip -q "../loadscreens.zip" *.png
fi

cd ..
zip -urq "loadscreens.zip" loadscreens.ptsdiff.txt loadscreens.diff.txt
popd

echo "Compressing Treasure Maps..."
pushd "$OUTPUTPATH/TreasureMaps/"
zip -q "../treasuremaps.zip" *.png
cd ..
zip -urq "treasuremaps.zip" treasuremaps.ptsdiff.txt treasuremaps.diff.txt
popd

echo "Compressing Crown Crate Images..."
pushd "$OUTPUTPATH/MoreImages/crowncrates/"
zip -rq "../../crowncrates.zip" *
cd ../../
zip -urq "crowncrates.zip" crowncrates.ptsdiff.txt crowncrates.diff.txt
popd

echo "Compressing Collectible Images..."
pushd "$OUTPUTPATH/MoreImages/collectibles/"
zip -rq "../../collectibles.zip" *
cd ../../
zip -urq "collectibles.zip" collectibles.ptsdiff.txt collectibles.diff.txt
popd

echo "Compressing Store Images..."
pushd "$OUTPUTPATH/MoreImages/store/"
zip -rq "../../store.zip" *
cd ../../
zip -urq "store.zip" store.ptsdiff.txt store.diff.txt
popd

echo "Compressing Tree Icons..."
pushd "$OUTPUTPATH/MoreImages/treeicons/"
zip -rq "../../treeicons.zip" *
cd ../../
zip -urq "treeicons.zip" treeicons.ptsdiff.txt treeicons.diff.txt
popd

echo "Compressing Tutorial Images..."
pushd "$OUTPUTPATH/MoreImages/tutorial/"
zip -rq "../../tutorial.zip" *
cd ../../
zip -urq "tutorial.zip" tutorial.ptsdiff.txt tutorial.diff.txt
popd

echo "Compressing Maps..."
pushd "$OUTPUTPATH/CombinedMaps/"
zip -rq "../maps.zip" * maplist.txt
cd ../maps/
zip -urq "../maps.zip" mapinfo.txt
cd ..
zip -urq "maps.zip" maps.ptsdiff.txt maps.diff.txt
popd

echo "Copying Updated Maps..."
pushd "$OUTPUTPATH/Maps/"
xargs -a ../maps.diff.txt.updatedmaps cp -Rt ../NewMaps/

if [ "$MAKEPTSDIFF" ]; then
	mkdir ../NewMapsPts/
	xargs -a ../maps.ptsdiff.txt.updatedmaps cp -Rt ../NewMapsPts/
fi

popd

makezipdiff "icons.diff.zip" "./esomnf-$VERSION/esoui/art/icons/" "icons.diff.txt.list"
makezipdiff "loadscreens.diff.zip" "$OUTPUTPATH/LoadingScreens/" "loadscreens.diff.txt.list"
makezipdiff "treasuremaps.diff.zip" "$OUTPUTPATH/TreasureMaps/" "treasuremaps.diff.txt.list"
makezipdiff "crowncrates.diff.zip" "$OUTPUTPATH/MoreImages/crowncrates/" "crowncrates.diff.txt.list"
makezipdiff "collectibles.diff.zip" "$OUTPUTPATH/MoreImages/collectibles/" "collectibles.diff.txt.list"
makezipdiff "store.diff.zip" "$OUTPUTPATH/MoreImages/store/" "store.diff.txt.list"
makezipdiff "tutorial.diff.zip" "$OUTPUTPATH/MoreImages/tutorial/" "tutorial.diff.txt.list"
makezipdiff "gameuiart.diff.zip" "$OUTPUTPATH/GameUIArt/" "gameuiart.diff.txt.list"
makezipdiff "maps.diff.zip" "$OUTPUTPATH/CombinedMaps/" "maps.diff.txt.list"

makezipdiff "icons.ptsdiff.zip" "./esomnf-$VERSION/esoui/art/icons/" "icons.ptsdiff.txt.list"
makezipdiff "loadscreens.ptsdiff.zip" "$OUTPUTPATH/LoadingScreens/" "loadscreens.ptsdiff.txt.list"
makezipdiff "treasuremaps.ptsdiff.zip" "$OUTPUTPATH/TreasureMaps/" "treasuremaps.ptsdiff.txt.list"
makezipdiff "crowncrates.ptsdiff.zip" "$OUTPUTPATH/MoreImages/crowncrates/" "crowncrates.ptsdiff.txt.list"
makezipdiff "collectibles.ptsdiff.zip" "$OUTPUTPATH/MoreImages/collectibles/" "collectibles.ptsdiff.txt.list"
makezipdiff "store.ptsdiff.zip" "$OUTPUTPATH/MoreImages/store/" "store.ptsdiff.txt.list"
makezipdiff "tutorial.ptsdiff.zip" "$OUTPUTPATH/MoreImages/tutorial/" "tutorial.ptsdiff.txt.list"
makezipdiff "gameuiart.ptsdiff.zip" "$OUTPUTPATH/GameUIArt/" "gameuiart.ptsdiff.txt.list"
makezipdiff "maps.ptsdiff.zip" "$OUTPUTPATH/CombinedMaps/" "maps.ptsdiff.txt.list"