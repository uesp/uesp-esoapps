#!/bin/sh

rsync -av ./* /cygdrive/c/Users/Dave/Documents/Elder\ Scrolls\ Online/pts/AddOns/uespSalesHelper/ --exclude Installs --exclude localdeploy.sh --exclude ptsdeploy.sh
