import os
import sys
#import Image
from PIL import Image
import shutil
import math
import errno
import csv
import re

BasePathIndex = "-14"
INPUTPATH = "e:\\esoexport\\goodimages" + BasePathIndex + "\\CombinedMaps\\"
OUTPUTPATH = "e:\\esoexport\\goodimages" + BasePathIndex + "\\maps\\"
DEFAULTNULLTILE = "e:\\esoexport\\goodimages" + BasePathIndex + "\\maps\\blacknulltile.jpg"

MAPEXTENSION = ".jpg"
CREATEZOOMLEVEL = 11
OUTPUTIMAGESIZE = 256

g_MapFileCount = 0
g_DefaultNullImage = Image.open(DEFAULTNULLTILE)


def MakeMapTileFilename(OutputPath, MapName, X, Y, Zoom):
    return "{0}\\zoom{4}\\{1}-{2}-{3}.jpg".format(OutputPath, MapName, X, Y, Zoom)


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise

        
def SplitMap (RootPath, MapFilename):
    global g_MapInfos
    global g_MapFileCount
    global g_DefaultNullImage

    if (not MapFilename.endswith(MAPEXTENSION)): return
    
    print "\t{0}".format(MapFilename)
    g_MapFileCount += 1

    OrigMapImage = Image.open(os.path.join(RootPath, MapFilename))
    (width, height) = OrigMapImage.size

    MapImage = OrigMapImage.resize((width*2,height*2), Image.BICUBIC)
    (width, height) = MapImage.size    
    
    NumTilesX = int(math.ceil( float(width)  / OUTPUTIMAGESIZE))
    NumTilesY = int(math.ceil( float(height) / OUTPUTIMAGESIZE))
    ZoomLevel = CREATEZOOMLEVEL

    OutputMapName = os.path.splitext(MapFilename)[0]
    if (OutputMapName.endswith("_base")): OutputMapName = OutputMapName[:-5]

    OutputBasePath = os.path.join(OUTPUTPATH, OutputMapName)
    mkdir_p(OutputBasePath)

    OutputPath = os.path.join(OutputBasePath, "zoom{0}".format(ZoomLevel))
    mkdir_p(OutputPath)
    
    print "\t\tSplitting into {0}x{1} tiles...".format(NumTilesX, NumTilesY)

    FirstNumTilesX = NumTilesX
    FirstNumTilesY = NumTilesY

    SplitImages = [[]]
    SplitImages = [[0 for x in xrange(NumTilesX)] for x in xrange(NumTilesY)]

    for y in xrange(NumTilesY):
        for x in xrange(NumTilesX):
            SplitImages[y][x] = MapImage.crop((x*OUTPUTIMAGESIZE, y*OUTPUTIMAGESIZE, (x+1)*OUTPUTIMAGESIZE, (y+1)*OUTPUTIMAGESIZE))
            OutputFilename = MakeMapTileFilename(OutputBasePath, OutputMapName, x, y, ZoomLevel)
            SplitImages[y][x].save(OutputFilename)
    
    return


def IterateMapFiles (MapPath):
    print "Looking for map files in '{0}'...".format(MapPath)
    (root, subdirs, filenames) = next(os.walk(MapPath))

    for mapfile in filenames:
        SplitMap(root, mapfile)
        
    return


def IterateMapRootPaths ():
    (root, subdirs, filenames) = next(os.walk(INPUTPATH))

    for path in subdirs:
        IterateMapFiles(os.path.join(root, path))

    print "Found {0} map files!".format(g_MapFileCount)        
    return


IterateMapRootPaths()
