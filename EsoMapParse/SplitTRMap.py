import os
import sys
import re
from PIL import Image
import shutil
import math
import errno
import csv

BASEPATH = "d:/EGD/uesp/TamrielRebuilt/Map1/"
INPUTMAP = BASEPATH + "TR_Release_Export_256.jpg"
OUTPUTPATH = BASEPATH + "Tiles/"
DEFAULTNULLTILE = BASEPATH + "troutofrange.jpg"

    # To disable warning about decompression bomb
Image.MAX_IMAGE_PIXELS = 1000000000

MAPXTILEOFFSET = 15
MAPYTILEOFFSET = 4
MAPXTILECOUNT = 96
MAPYTILECOUNT = 96

MAPEXTENSION = ".jpg"
MAPNAME = "TR"
MINZOOMLEVEL = 9
MAPZOOMLEVEL = 16
MAXZOOMLEVEL = 17
OUTPUTIMAGESIZE = 256

g_DefaultNullImage = Image.open(DEFAULTNULLTILE)


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise
        

def MakeMapTileFilename(OutputPath, MapName, X, Y, Zoom):
    return "{0}/zoom{4}/{1}-{2}-{3}-{4}.jpg".format(OutputPath, MapName, X, Y, Zoom)


def SplitMap (OutputPath, MapFilename, MapZoomLevel):
    global g_DefaultNullImage

    MapImage = Image.open(INPUTMAP)
    
    (width, height) = MapImage.size
    NumTilesX = int(math.ceil( float(width)  / OUTPUTIMAGESIZE))
    NumTilesY = int(math.ceil( float(height) / OUTPUTIMAGESIZE))
    ZoomLevel = MapZoomLevel

    print "\t\tLoaded map image {0}x{1} pixels...".format(width, height)
    print "\t\tSplitting into {0}x{1} tiles...".format(NumTilesX, NumTilesY)

    OutputZoomPath = os.path.join(OutputPath, "zoom{0}".format(ZoomLevel))
    mkdir_p(OutputZoomPath)

    SplitImages = [[]]
    SplitImages = [[0 for x in xrange(NumTilesX+1)] for x in xrange(NumTilesY+1)] 

    for y in xrange(NumTilesY+1):
        for x in xrange(NumTilesX+1):
            SplitImages[y][x] = MapImage.crop((x*OUTPUTIMAGESIZE, y*OUTPUTIMAGESIZE, (x+1)*OUTPUTIMAGESIZE, (y+1)*OUTPUTIMAGESIZE))
            OutputFilename = MakeMapTileFilename(OutputPath, MAPNAME, x + MAPXTILEOFFSET, y + MAPYTILEOFFSET, ZoomLevel)
            SplitImages[y][x].save(OutputFilename)
            
    print "\t\tOutputting empty tiles..."

        # Output all empty/missing tiles
    for y in xrange(MAPYTILECOUNT):
        tiley = y - MAPYTILEOFFSET
        
        for x in xrange(MAPXTILECOUNT):
            tilex = x - MAPXTILEOFFSET
            
            if (tilex >= 0 and tilex <= NumTilesX and tiley >= 0 and tiley <= NumTilesY):
                continue
            
            OutputFilename = MakeMapTileFilename(OutputPath, MAPNAME, x, y, ZoomLevel)
            g_DefaultNullImage.save(OutputFilename)
            
    
    return


def MakeSmallerTileZoom(ZoomLevel, OutputPath, NumTilesX, NumTilesY):
    global g_DefaultNullImage
    
    InputZoomPath = OutputPath + "zoom{0}/".format(ZoomLevel + 1)
    OutputZoomPath = OutputPath + "zoom{0}/".format(ZoomLevel)
    mkdir_p(OutputZoomPath)

    print "\t\tMaking smaller tiles from {0} and outputting to {1}".format(InputZoomPath, OutputZoomPath)

    for y in xrange(NumTilesY+1):
        for x in xrange(NumTilesX+1):
            x1 = x*2
            x2 = x*2 + 1
            y1 = y*2
            y2 = y*2 + 1

            InputFile1 = MakeMapTileFilename(OutputPath, MAPNAME, x1, y1, ZoomLevel + 1)
            InputFile2 = MakeMapTileFilename(OutputPath, MAPNAME, x2, y1, ZoomLevel + 1)
            InputFile3 = MakeMapTileFilename(OutputPath, MAPNAME, x1, y2, ZoomLevel + 1)
            InputFile4 = MakeMapTileFilename(OutputPath, MAPNAME, x2, y2, ZoomLevel + 1)

            try:
                Image1 =  Image.open(InputFile1)
            except IOError:
                Image1 = g_DefaultNullImage

            try:
                Image2 =  Image.open(InputFile2)
            except IOError:
                Image2 = g_DefaultNullImage

            try:
                Image3 =  Image.open(InputFile3)
            except IOError:
                Image3 = g_DefaultNullImage

            try:
                Image4 =  Image.open(InputFile4)
            except IOError:
                Image4 = g_DefaultNullImage

            NewImage = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE) )
            
            NewImage.paste(Image1.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (0,0))
            NewImage.paste(Image2.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (OUTPUTIMAGESIZE/2,0))
            NewImage.paste(Image3.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (0,OUTPUTIMAGESIZE/2))
            NewImage.paste(Image4.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2))

            OutputFilename = MakeMapTileFilename(OutputPath, MAPNAME, x, y, ZoomLevel)
            NewImage.save(OutputFilename)
    return


def MakeLargerTileZoom(ZoomLevel, OutputPath, NumTilesX, NumTilesY):
    global g_DefaultNullImage
    
    InputZoomPath = OutputPath + "zoom{0}/".format(ZoomLevel)
    OutputZoomPath = OutputPath + "zoom{0}/".format(ZoomLevel + 1)
    mkdir_p(OutputZoomPath)

    print "\t\tMaking larger tiles from {0} and outputting to {1}".format(InputZoomPath, OutputZoomPath)

    for y in xrange(NumTilesY):
        for x in xrange(NumTilesX):
            InputFile = MakeMapTileFilename(OutputPath, MAPNAME, x, y, ZoomLevel)
            
            try:
                InputImage = Image.open(InputFile)
            except IOError:
                InputImage = g_DefaultNullImage

            InputImage = InputImage.resize((OUTPUTIMAGESIZE*2,OUTPUTIMAGESIZE*2), Image.ANTIALIAS)

            NewImage1 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE) )
            NewImage2 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE) )
            NewImage3 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE) )
            NewImage4 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE) )

            NewImage1.paste(InputImage.crop((0, 0, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE)), (0,0))
            NewImage2.paste(InputImage.crop((OUTPUTIMAGESIZE, 0, OUTPUTIMAGESIZE*2, OUTPUTIMAGESIZE)), (0,0))
            NewImage3.paste(InputImage.crop((0, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE*2)), (0,0))
            NewImage4.paste(InputImage.crop((OUTPUTIMAGESIZE, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE*2, OUTPUTIMAGESIZE*2)), (0,0))

            x1 = x*2
            x2 = x*2 + 1
            y1 = y*2
            y2 = y*2 + 1

            OutputFilename1 = MakeMapTileFilename(OutputPath, MAPNAME, x1, y1, ZoomLevel + 1)
            OutputFilename2 = MakeMapTileFilename(OutputPath, MAPNAME, x2, y1, ZoomLevel + 1)
            OutputFilename3 = MakeMapTileFilename(OutputPath, MAPNAME, x1, y2, ZoomLevel + 1)
            OutputFilename4 = MakeMapTileFilename(OutputPath, MAPNAME, x2, y2, ZoomLevel + 1)
            
            NewImage1.save(OutputFilename1)
            NewImage2.save(OutputFilename2)
            NewImage3.save(OutputFilename3)
            NewImage4.save(OutputFilename4)



SplitMap(OUTPUTPATH, INPUTMAP, MAPZOOMLEVEL)


    # Make the larger map tiles
NumTilesX = MAPYTILECOUNT
NumTilesY = MAPXTILECOUNT

for ZoomLevel in xrange(MAPZOOMLEVEL, MAXZOOMLEVEL):
    MakeLargerTileZoom(ZoomLevel, OUTPUTPATH, NumTilesX, NumTilesY)
    
    NumTilesX = NumTilesX * 2
    NumTilesY = NumTilesY * 2
    

    # Make the smaller map tiles
NumTilesX = MAPYTILECOUNT
NumTilesY = MAPXTILECOUNT

for ZoomLevel in xrange(MAPZOOMLEVEL - 1, MINZOOMLEVEL-1, -1):

    NumTilesX = int(math.ceil(NumTilesX / 2))
    NumTilesY = int(math.ceil(NumTilesY / 2))
    
    MakeSmallerTileZoom(ZoomLevel, OUTPUTPATH, NumTilesX, NumTilesY)
    
