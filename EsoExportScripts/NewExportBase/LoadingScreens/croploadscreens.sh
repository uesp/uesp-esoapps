#!/bin/sh

for f in raw/*.png
do
	echo "Cropping loading screen $f..."
	basefile=$(basename "$f")
	extension="${basefile##*.}"
	filename="${basefile%.*}"
    convert $f -background black -flatten -crop 1680x1050+0+0 +repage $filename.jpg
done