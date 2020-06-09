VERSION="17pts"
OUTPUTPATH="e:/esoexport"
mkdir "$OUTPUTPATH/esomnf-$VERSION/"
./EsoExtractData.exe "C:/Program Files (x86)/Zenimax Online/The Elder Scrolls Online PTS/depot/eso.mnf" "$OUTPUTPATH/esomnf-$VERSION/" -z "$OUTPUTPATH/esomnf-$VERSION/zosft.txt" -m "$OUTPUTPATH/esomnf-$VERSION/mnf.txt"  --extractsubfile combined