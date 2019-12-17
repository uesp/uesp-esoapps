import os
import sys
#import Image
from PIL import Image
import shutil
import math
import errno
import csv
import re

USE_COMMAND_ARGS = True

if (not USE_COMMAND_ARGS):
    BasePathIndex = "24"
    BasePath = "e:/esoexport/"
elif (len(sys.argv) < 3):
    print("Missing required command line arguments!")
    sys.exit()
else:
    BasePathIndex = sys.argv[1]
    BasePath = sys.argv[2]
    print("\tUsing Base Path:" + BasePath)
    print("\tUsing Version:" + BasePathIndex)


INPUTPATH = BasePath + "goodimages-" + BasePathIndex + "/CombinedMaps/"
OUTPUTPATH = BasePath + "goodimages-" + BasePathIndex + "/Maps/"
DEFAULTNULLTILE = BasePath + "goodimages-" + BasePathIndex + "/Maps/blacknulltile.jpg"

MAPEXTENSION = ".jpg"
CREATEZOOMLEVEL = 11
OUTPUTIMAGESIZE = 256

ONLYDOMAP = ""
ONLYDOMAPPATH = ""

g_MapFileCount = 0
g_DefaultNullImage = Image.open(DEFAULTNULLTILE)


def MakeMapTileFilename(OutputPath, MapName, X, Y, Zoom):
    return "{0}/zoom{4}/{1}-{2}-{3}.jpg".format(OutputPath, MapName, X, Y, Zoom)


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

    FullFilename = os.path.join(RootPath, MapFilename)
    FullFilename = FullFilename.replace("\\", "/")

    OutputMapName = os.path.splitext(MapFilename)[0]
    if (OutputMapName.endswith("_base")): OutputMapName = OutputMapName[:-5]

    if (ONLYDOMAP != "" and OutputMapName != ONLYDOMAP):
      print "\t\tSkipping map..."
      return

    if (ONLYDOMAPPATH != "" and not RootPath.endswith(ONLYDOMAPPATH)):
      print "\t\tSkipping map..."
      return

    OrigMapImage = Image.open(FullFilename)
    (width, height) = OrigMapImage.size

    MapImage = OrigMapImage.resize((width*2,height*2), Image.BICUBIC)
    (width, height) = MapImage.size    
    
    NumTilesX = int(math.ceil( float(width)  / OUTPUTIMAGESIZE))
    NumTilesY = int(math.ceil( float(height) / OUTPUTIMAGESIZE))
    ZoomLevel = CREATEZOOMLEVEL

    OutputMapName = os.path.splitext(MapFilename)[0]
    if (OutputMapName.endswith("_base")): OutputMapName = OutputMapName[:-5]

    if (ONLYDOMAP != "" and OutputMapName != ONLYDOMAP):
      print "\t\tSkipping map..."
      return

    if (ONLYDOMAPPATH != "" and not RootPath.endswith(ONLYDOMAPPATH)):
      print "\t\tSkipping map..."
      return

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
