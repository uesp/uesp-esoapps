#!/bin/sh

rsync -av ./* /cygdrive/e/esoexport/ --exclude localdeploy.sh
