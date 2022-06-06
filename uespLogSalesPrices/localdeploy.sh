#!/bin/sh

rsync -av ./* /cygdrive/c/Users/dave/Documents/Elder\ Scrolls\ Online/live/Addons/uespLogSalesPrices/ --exclude Installs --exclude uespSalesPrices.lua --exclude localdeploy.sh --exclude ptsdeploy.sh
