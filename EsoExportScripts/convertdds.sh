#!/bin/sh

SRCPATH="$1"
OUTPUTTYPE="png"

find "$SRCPATH" -name '*.dds' -exec echo Converting \{\} \; -exec ./nconvert.exe -quiet -overwrite -out $OUTPUTTYPE \{\} \;