VERSION="17"
OUTPUTPATH="e:/esoexport"
mkdir "$OUTPUTPATH/gamemnf-$VERSION/"
./EsoExtractData.exe "C:/Program Files (x86)/Zenimax Online/The Elder Scrolls Online/game/client/game.mnf" "$OUTPUTPATH/gamemnf-$VERSION/" -z "$OUTPUTPATH/gamemnf-$VERSION/zosft.txt" -m "$OUTPUTPATH/gamemnf-$VERSION/mnf.txt"