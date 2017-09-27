import os
import sys
#import Image
from PIL import Image
import shutil
import math
import errno
import csv

BasePathIndex = "-16pts"
INPUTPATH = "e:\\esoexport\\goodimages" + BasePathIndex + "\\combinedmaps\\"
OUTPUTPATH = "e:\\esoexport\\goodimages" + BasePathIndex + "\\maps\\"
DEFAULTNULLTILE = "e:\\esoexport\\goodimages" + BasePathIndex + "\\maps\\blacknulltile.jpg"

MAPEXTENSION = ".jpg"
MAXZOOMLEVEL = 10
MAXZOOM_OUTPUT = 11
OUTPUTIMAGESIZE = 256

ONLYDOMAP = ""
ONLYDOMAPPATH = ""

g_DefaultNullImage = Image.open(DEFAULTNULLTILE)
g_MapFileCount = 0
g_MapInfos = []


class CMapInfo:
  name = ''
  maxZoom = MAXZOOMLEVEL
  minZoom = MAXZOOMLEVEL
  numTilesX = 0
  numTilesY = 0


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

    MapImage = Image.open(os.path.join(RootPath, MapFilename))
    
    (width, height) = MapImage.size
    NumTilesX = int(math.ceil( float(width)  / OUTPUTIMAGESIZE))
    NumTilesY = int(math.ceil( float(height) / OUTPUTIMAGESIZE))
    ZoomLevel = MAXZOOMLEVEL

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

    while True:
        TotalTiles = NumTilesX * NumTilesY
        if (TotalTiles == 1): break

        MaxX = NumTilesX
        MaxY = NumTilesY
        NumTilesX = int(math.ceil(float(NumTilesX) / 2))
        NumTilesY = int(math.ceil(float(NumTilesY) / 2))
        ZoomLevel = ZoomLevel - 1   

        print "\t\t\tCreating zoom level {0}...".format(ZoomLevel)

        OutputPath = os.path.join(OutputBasePath, "zoom{0}".format(ZoomLevel))
        mkdir_p(OutputPath)

        for y in xrange(NumTilesY):
            for x in xrange(NumTilesX):
                NewImage = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE) )

                try:
                    ImageNW = SplitImages[y*2][x*2]
                except IndexError:
                    ImageNW = g_DefaultNullImage

                if (x*2+1 < MaxX): 
                    ImageNE = SplitImages[y*2][x*2+1]
                else:
                    ImageNE = g_DefaultNullImage
                    
                if (y*2+1 < MaxY): 
                    ImageSW = SplitImages[y*2+1][x*2]                   
                else:
                    ImageSW = g_DefaultNullImage

                if (x*2+1 < MaxX and y*2+1 < MaxY): 
                    ImageSE = SplitImages[y*2+1][x*2+1]
                else:
                    ImageSE = g_DefaultNullImage
                
                NewImage.paste(ImageNW.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (0,0))
                NewImage.paste(ImageNE.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (OUTPUTIMAGESIZE/2,0))
                NewImage.paste(ImageSW.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (0,OUTPUTIMAGESIZE/2))
                NewImage.paste(ImageSE.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2))

                SplitImages[y][x] = NewImage

                OutputFilename = MakeMapTileFilename(OutputBasePath, OutputMapName, x, y, ZoomLevel)
                SplitImages[y][x].save(OutputFilename)
                
    NewMapInfo = CMapInfo()
    NewMapInfo.name = OutputMapName
    NewMapInfo.maxZoom = MAXZOOMLEVEL
    NewMapInfo.minZoom = ZoomLevel
    NewMapInfo.numTilesX = FirstNumTilesX
    NewMapInfo.numTilesY = FirstNumTilesY
    g_MapInfos.append(NewMapInfo)    
    
    return


def DumpMapInfo (OutputFilename):

    f = open(OutputFilename, "wb")

    f.write("Name, MaxZoom, MinZoom, NumTilesX, NumTilesY\n")

    for MapInfo in g_MapInfos:
        f.write("{0}, {1}, {2}, {3}, {4}\n".format(MapInfo.name, MAXZOOM_OUTPUT, MapInfo.minZoom, MapInfo.numTilesX, MapInfo.numTilesY))

    f.close()
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

if (ONLYDOMAP == "" and ONLYDOMAPPATH == ""):
  DumpMapInfo(os.path.join(OUTPUTPATH, "mapinfo.txt"))
