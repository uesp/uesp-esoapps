#!/bin/sh

OLDAPI="100019"
NEWAPI="100020"
APIPATH="/cygdrive/e/esoexport/apidata/output"

OLDAPIPATH="$APIPATH/$OLDAPI/data"
NEWAPIPATH="$APIPATH/$NEWAPI/data"

find "$OLDAPIPATH" -name *.html | sed "s#$OLDAPIPATH.*/#       #g; s#\.html#()#g" | sort > "$APIPATH/files_$OLDAPI.txt"
find "$NEWAPIPATH" -name *.html | sed "s#$NEWAPIPATH.*/#       #g; s#\.html#()#g" | sort > "$APIPATH/files_$NEWAPI.txt"

comm -23 "$APIPATH/files_$OLDAPI.txt" "$APIPATH/files_$NEWAPI.txt" > "$APIPATH/files_Removed_$OLDAPI.txt"
comm -13 "$APIPATH/files_$OLDAPI.txt" "$APIPATH/files_$NEWAPI.txt" > "$APIPATH/files_Added_$OLDAPI.txt"

echo -e "Added Functions" > "$APIPATH/apidiff_$NEWAPI.txt"
grep -v "\." "$APIPATH/files_Added_$OLDAPI.txt" >> "$APIPATH/apidiff_$NEWAPI.txt"

echo -e "\n\nRemoved Functions" >> "$APIPATH/apidiff_$NEWAPI.txt"
grep -v "\." "$APIPATH/files_Removed_$OLDAPI.txt" >> "$APIPATH/apidiff_$NEWAPI.txt"
