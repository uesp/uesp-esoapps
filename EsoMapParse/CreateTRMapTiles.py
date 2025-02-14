import os
import sys
import re
from PIL import Image
import shutil
import math
import errno
import csv

MAKE_BASE_TILES = True
MAKE_LARGEMAP = False
MAKE_LARGER_TILES = True
MAKE_SMALLER_TILES = True

    # TR Map
BASEPATH = "d:/EGD/uesp/TamrielRebuilt/TRMap-Feb2025/"
INPUTPATH = "e:/PTR_Maptiles/TR_Maptiles/"
OUTPUTPATH = BASEPATH + "Tiles/"
DEFAULTNULLTILE = BASEPATH + "troutofrange.jpg"
LARGEMAPFILE = "LargeMap.jpg"

MAPXTILEOFFSET = 46
MAPYTILEOFFSET = 37
MAPXTILECOUNT = 96
MAPYTILECOUNT = 96
MAPZOOMLEVEL = 7
USESHORTFILENAME = True
NORMALIZEOUTPUTZOOM = True
MAPNAME = "tamrielrebuilt"

    # PC Map
BASEPATH = "d:/EGD/uesp/TamrielRebuilt/PCMap-Feb2025/"
INPUTPATH = "e:/PTR_Maptiles/PC_Maptiles/"
OUTPUTPATH = BASEPATH + "Tiles/"
DEFAULTNULLTILE = BASEPATH + "troutofrange.jpg"

MAPXTILEOFFSET = 190
MAPYTILEOFFSET = 10
MAPXTILECOUNT = 96
MAPYTILECOUNT = 96
MAPNAME = "pc"

    # SHOTN Map 
BASEPATH = "d:/EGD/uesp/TamrielRebuilt/SHotNMap-Feb2025/"
INPUTPATH = "e:/PTR_Maptiles/SHotN_Maptiles/"
OUTPUTPATH = BASEPATH + "Tiles/"
DEFAULTNULLTILE = BASEPATH + "troutofrange.jpg"

MAPXTILEOFFSET = 170
MAPYTILEOFFSET = 70
MAPXTILECOUNT = 96
MAPYTILECOUNT = 96
MAPNAME = "shotn" #'''

    # To disable warning about decompression bomb
Image.MAX_IMAGE_PIXELS = 1000000000

TILEBGCOLOR = (133, 164, 182)
MAPEXTENSION = ".jpg"
SHORTMAPNAME = MAPNAME
MINZOOMLEVEL = 0
MAXZOOMLEVEL = 8
OUTPUTIMAGESIZE = 256


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise


def MakeMapTileFilename(OutputPath, MapName, ShortMapName, X, Y, Zoom):
    if (USESHORTFILENAME):
        return "{0}/zoom{4}/{1}-{2}-{3}.jpg".format(OutputPath, ShortMapName, X, Y, Zoom)
    return "{0}/zoom{4}/{1}-{2}-{3}-{4}.jpg".format(OutputPath, MapName, X, Y, Zoom)



def MakeSmallerTileZoom(ZoomLevel, OutputPath, NumTilesX, NumTilesY):
    global g_DefaultNullImage

    print("\tMakeSmallerTileZoom")

    OutputZoomLevel = ZoomLevel
    if (NORMALIZEOUTPUTZOOM): OutputZoomLevel = ZoomLevel - MINZOOMLEVEL
    
    InputZoomPath = OutputPath + "zoom{0}/".format(OutputZoomLevel + 1)
    OutputZoomPath = OutputPath + "zoom{0}/".format(OutputZoomLevel)
    mkdir_p(OutputZoomPath)

    print "\t\tMaking smaller tiles from {0} and outputting to {1}".format(InputZoomPath, OutputZoomPath)

    for y in xrange(NumTilesY):
        for x in xrange(NumTilesX):
            x1 = x*2
            x2 = x*2 + 1
            y1 = y*2
            y2 = y*2 + 1

            InputFile1 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x1, y1, OutputZoomLevel + 1)
            InputFile2 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x2, y1, OutputZoomLevel + 1)
            InputFile3 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x1, y2, OutputZoomLevel + 1)
            InputFile4 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x2, y2, OutputZoomLevel + 1)

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

            NewImage = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE), TILEBGCOLOR)
            
            NewImage.paste(Image1.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (0,0))
            NewImage.paste(Image2.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (OUTPUTIMAGESIZE/2,0))
            NewImage.paste(Image3.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (0,OUTPUTIMAGESIZE/2))
            NewImage.paste(Image4.resize((OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2), Image.ANTIALIAS), (OUTPUTIMAGESIZE/2,OUTPUTIMAGESIZE/2))

            OutputFilename = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x, y, OutputZoomLevel)
            NewImage.save(OutputFilename)
    return


def MakeLargerTileZoom(ZoomLevel, OutputPath, NumTilesX, NumTilesY):
    global g_DefaultNullImage

    print("\tMakeLargerTileZoom")

    OutputZoomLevel = ZoomLevel
    if (NORMALIZEOUTPUTZOOM): OutputZoomLevel = ZoomLevel - MINZOOMLEVEL
    
    InputZoomPath = OutputPath + "zoom{0}/".format(ZoomLevel)
    OutputZoomPath = OutputPath + "zoom{0}/".format(OutputZoomLevel + 1)
    mkdir_p(OutputZoomPath)

    print "\t\tMaking larger tiles from {0} and outputting to {1}".format(InputZoomPath, OutputZoomPath)

    for y in xrange(NumTilesY):
        for x in xrange(NumTilesX):
            InputFile = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x, y, OutputZoomLevel)
            
            try:
                InputImage = Image.open(InputFile)
            except IOError:
                InputImage = g_DefaultNullImage

            InputImage = InputImage.resize((OUTPUTIMAGESIZE*2,OUTPUTIMAGESIZE*2), Image.ANTIALIAS)

            NewImage1 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE), TILEBGCOLOR )
            NewImage2 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE), TILEBGCOLOR )
            NewImage3 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE), TILEBGCOLOR )
            NewImage4 = Image.new("RGB", (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE), TILEBGCOLOR )

            NewImage1.paste(InputImage.crop((0, 0, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE)), (0,0))
            NewImage2.paste(InputImage.crop((OUTPUTIMAGESIZE, 0, OUTPUTIMAGESIZE*2, OUTPUTIMAGESIZE)), (0,0))
            NewImage3.paste(InputImage.crop((0, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE*2)), (0,0))
            NewImage4.paste(InputImage.crop((OUTPUTIMAGESIZE, OUTPUTIMAGESIZE, OUTPUTIMAGESIZE*2, OUTPUTIMAGESIZE*2)), (0,0))

            x1 = x*2
            x2 = x*2 + 1
            y1 = y*2
            y2 = y*2 + 1

            OutputFilename1 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x1, y1, OutputZoomLevel + 1)
            OutputFilename2 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x2, y1, OutputZoomLevel + 1)
            OutputFilename3 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x1, y2, OutputZoomLevel + 1)
            OutputFilename4 = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x2, y2, OutputZoomLevel + 1)
            
            NewImage1.save(OutputFilename1)
            NewImage2.save(OutputFilename2)
            NewImage3.save(OutputFilename3)
            NewImage4.save(OutputFilename4)


def MakeBaseTileZoom(ZoomLevel, InputPath, OutputPath, NumTilesX, NumTilesY):
    global g_DefaultNullImage

    print("\tMakeBaseTileZoom")
    
    OutputZoomLevel = ZoomLevel
    if (NORMALIZEOUTPUTZOOM): OutputZoomLevel = ZoomLevel - MINZOOMLEVEL
    
    OutputZoomPath = OutputPath + "zoom{0}/".format(OutputZoomLevel)
    mkdir_p(OutputZoomPath)

    print("\t\tFinding base tiles from {0}...".format(InputPath))

    x1 = 0 - MAPXTILEOFFSET
    x2 = MAPXTILECOUNT - MAPXTILEOFFSET
    y1 = MAPYTILEOFFSET - 0
    y2 = MAPYTILEOFFSET - MAPYTILECOUNT
    print("\t\tUsing Cell Coordinates ({0}, {1}) to ({2}, {3})".format(x1, y1, x2, y2))
    
    (root, subdirs, filenames) = next(os.walk(InputPath))
    mapFiles = {}

    for mapfile in filenames:
        matches = re.match(r'(.*)\(([0-9-]+),([0-9-]+)\).bmp', mapfile)

        if (matches):
            x = int(matches.group(2))
            y = int(matches.group(3))
            mapFiles[(x,y)] = mapfile

            if (x < x1 or x > x2 or y < y2 or y > y1):
                print("\t\t({0}, {1}) is out-of-bounds".format(x, y))
        else:
            print("\t\tFile {0} does not match known tile syntax!".format(mapfile))

    print "\t\tFound {0} base filenames!".format(len(mapFiles))
    print "\t\tOutputting base tiles to {0}...".format(OutputZoomPath)
    
    for y in xrange(NumTilesY):
        for x in xrange(NumTilesX):
            cellX = x - MAPXTILEOFFSET
            cellY = MAPYTILEOFFSET - y
            OutputFile = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x, y, OutputZoomLevel)
            
            if ((cellX, cellY) in mapFiles):
                InputFile = mapFiles[(cellX, cellY)]
                
                try:
                    InputImage = Image.open(InputPath + InputFile)
                    #print("\t\t\t({0}, {1}) => to {2}".format(cellX, cellY, OutputFile))
                except IOError:
                    #print("\t\t\t({0}, {1}) NULL => to {2}".format(cellX, cellY, OutputFile))
                    InputImage = g_DefaultNullImage
            else:
                #print("\t\t\t({0}, {1}) NULL => to {2}".format(cellX, cellY, OutputFile))
                InputImage = g_DefaultNullImage
                
            InputImage.save(OutputFile)


def MakeLargeMap(InputPath, OutputPath):
    global MAPXTILEOFFSET
    global MAPYTILEOFFSET
    global MAPXTILECOUNT
    global MAPYTILECOUNT

    print("\tMakeLargeMap")
    
    mkdir_p(OutputPath)

    OutputMapFile = OutputPath + LARGEMAPFILE
    print("\t\tCreating combined map from {0} to {1}...".format(InputPath, OutputPath))

    (root, subdirs, filenames) = next(os.walk(InputPath))
    mapFiles = {}

    x1 = 0
    x2 = 0
    y1 = 0
    y2 = 0
    isFirst = True

    for mapfile in filenames:
        matches = re.match(r'(.*)\(([0-9-]+),([0-9-]+)\).bmp', mapfile)

        if (matches):
            x = int(matches.group(2))
            y = int(matches.group(3))
            mapFiles[(x,y)] = mapfile

            if (isFirst):
                x1 = x
                x2 = x
                y1 = y
                y2 = y
                isFirst = False
            else:
                if (x1 > x): x1 = x
                if (x2 < x): x2 = x
                if (y1 > y): y1 = y
                if (y2 < y): y2 = y                
        else:
            print("\t\tFile {0} does not match known tile syntax!".format(mapfile))

    print "\t\tFound {0} base filenames!".format(len(mapFiles))
    print "\t\tFound tile range ({0}, {1}) - ({2}, {3})".format(x1, y1, x2, y2)
    print "\t\tOutputting large map to {0}...".format(OutputMapFile)

    NumTilesX = x2 - x1
    NumTilesY = y2 - y1
    print "\t\tTile Size: {0} x {1}".format(NumTilesX, NumTilesY)
    OutputImage = Image.new('RGB', (256*NumTilesX, 256*NumTilesY))

    for y in xrange(NumTilesY):
        for x in xrange(NumTilesX):
            cellX = x + x1
            cellY = y + y1
            
            if ((cellX, cellY) in mapFiles):
                InputFile = mapFiles[(cellX, cellY)]
                
                try:
                    InputImage = Image.open(InputPath + InputFile)
                    # print("\t\t\t({0}, {1}) OK".format(cellX, cellY))
                except IOError:
                    InputImage = g_DefaultNullImage
                    #print("\t\t\t({0}, {1}) NULL".format(cellX, cellY))
            else:
                InputImage = g_DefaultNullImage
                #print("\t\t\t({0}, {1}) NULL".format(cellX, cellY))

            x0 = x
            y0 = NumTilesY - y - 1
            OutputImage.paste(InputImage, (x0*256, y0*256))
            
    OutputImage.save(OutputMapFile)

    MAPXTILEOFFSET = -(x1 - 1)
    MAPYTILEOFFSET = y2 + 1
    MAPXTILECOUNT = NumTilesX + 2
    MAPYTILECOUNT = NumTilesY + 2


def MakeBaseTileZoomFromLargeMap(ZoomLevel, InputPath, OutputPath, NumTilesX, NumTilesY):
    global g_DefaultNullImage

    print("\tMakeBaseTileZoomFromLargeMap")
    
    OutputZoomLevel = ZoomLevel
    if (NORMALIZEOUTPUTZOOM): OutputZoomLevel = ZoomLevel - MINZOOMLEVEL
    
    OutputZoomPath = OutputPath + "zoom{0}/".format(OutputZoomLevel)
    mkdir_p(OutputZoomPath)

    InputFile = OutputPath + LARGEMAPFILE
    print("\t\tLoading large map from {0}...".format(InputFile))

    x1 = 0 - MAPXTILEOFFSET
    x2 = MAPXTILECOUNT - MAPXTILEOFFSET
    y1 = MAPYTILEOFFSET - 0
    y2 = MAPYTILEOFFSET - MAPYTILECOUNT
    print("\t\tUsing Cell Coordinates ({0}, {1}) to ({2}, {3})".format(x1, y1, x2, y2))

    InputImage = Image.open(InputFile)

    for y in xrange(NumTilesY):
        for x in xrange(NumTilesX):
            SplitImage = Image.new('RGB', (OUTPUTIMAGESIZE, OUTPUTIMAGESIZE), TILEBGCOLOR)
            
            if (x <= 0 or y <= 0 or x >= NumTilesX-1 or y >= NumTilesY-1):
                SplitImage = g_DefaultNullImage
            else:
                x0 = x - 1
                y0 = y - 1
                SplitImage.paste(InputImage, (-x0*OUTPUTIMAGESIZE, -y0*OUTPUTIMAGESIZE))

            OutputFilename = MakeMapTileFilename(OutputPath, MAPNAME, SHORTMAPNAME, x, y, OutputZoomLevel)
            SplitImage.save(OutputFilename)


mkdir_p(BASEPATH)
g_DefaultNullImage = Image.open(DEFAULTNULLTILE)


if (MAKE_BASE_TILES):
    MakeBaseTileZoom(MAPZOOMLEVEL, INPUTPATH, OUTPUTPATH, MAPXTILECOUNT, MAPYTILECOUNT)

if (MAKE_LARGEMAP):
    MakeLargeMap(INPUTPATH, OUTPUTPATH)
    MakeBaseTileZoomFromLargeMap(MAPZOOMLEVEL, INPUTPATH, OUTPUTPATH, MAPXTILECOUNT, MAPYTILECOUNT)


if (MAKE_LARGER_TILES):
    NumTilesX = MAPXTILECOUNT
    NumTilesY = MAPYTILECOUNT

    for ZoomLevel in xrange(MAPZOOMLEVEL, MAXZOOMLEVEL):
        MakeLargerTileZoom(ZoomLevel, OUTPUTPATH, NumTilesX, NumTilesY)
        
        NumTilesX = NumTilesX * 2
        NumTilesY = NumTilesY * 2
    

if (MAKE_SMALLER_TILES):
    NumTilesX = MAPXTILECOUNT
    NumTilesY = MAPYTILECOUNT

    for ZoomLevel in xrange(MAPZOOMLEVEL - 1, MINZOOMLEVEL-1, -1):

        NumTilesX = int(math.ceil(NumTilesX / 2))
        NumTilesY = int(math.ceil(NumTilesY / 2))
        print "{0}: Size {1} x {2} tiles".format(ZoomLevel, NumTilesX+1, NumTilesY+1)
        
        MakeSmallerTileZoom(ZoomLevel, OUTPUTPATH, NumTilesX + 1, NumTilesY + 1)        
