#!/bin/sh

for f in ./*.png
do
	echo "Splitting icon file $f..."
	basefile=$(basename "$f")
	firstsection="${basefile%%_*}"
	secondsection="${basefile#*_}"
	#echo "     Base  =$basefile"
	#echo "     First =$firstsection"
	#echo "     Second=$secondsection"
	
	newpath="$firstsection"
	mkdir -p $newpath
	
	newfile="$newpath/$secondsection"
	
	mv -f $f $newfile
	#break
done