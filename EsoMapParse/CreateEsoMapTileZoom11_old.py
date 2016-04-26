import os
import sys
import Image
import shutil
import math
import errno
import csv
import re

BasePathIndex = "-18-pts"
ROOTPATH = "d:\\esoexport\\goodimages" + BasePathIndex + "\\maps\\"
DEFAULTNULLTILE = "d:\\esoexport\\goodimages" + BasePathIndex + "\\maps\\blacknulltile.jpg"
MAPEXTENSION = ".jpg"
CREATEZOOMLEVEL = 11
OUTPUTIMAGESIZE = 256

ONLYDOMAP = ""

g_DefaultNullImage = Image.open(DEFAULTNULLTILE)
g_MapFileCount = 0
g_MapInfos = []

MapTileRE = re.compile('([a-z0-9_\-]*)-([0-9]+)-([0-9]+)\.jpg')


#MapGroupRE  = re.compile('([\\a-z]*)_.*_?([0-9]+)\.png')
#m = MapGroupRE.search(ImageInfos[i].Filename)
#print m.groups()
#if m.group(1) in ImageGroups:


def MakeMapTileFilename(OutputPath, MapName, X, Y, Zoom):
    return "{0}\\zoom{4}\\{1}-{2}-{3}.jpg".format(OutputPath, MapName, X, Y, Zoom)


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise



def CreateExtraZoomLevel (MapPath):

    if (MapPath == "icons"): return

    if (ONLYDOMAP != "" and ONLYDOMAP != MapPath):
        print "\tSkipping {0}...".format(MapPath)
        return

    RootMapPath = os.path.join(ROOTPATH, MapPath)
    ZoomPath = os.path.join(ROOTPATH, MapPath, "zoom10")
    OutputPath = os.path.join(ROOTPATH, MapPath, "zoom11")
    mkdir_p(OutputPath)
    
    print "Creating extra zoom level from map tiles in '{0}'...".format(ZoomPath)
    
    try:
        (root, subdirs, filenames) = next(os.walk(ZoomPath))
    except StopIteration:
            print "\tError:Empty directory!"
            return

    for imagefile in filenames:
      FullFilename = os.path.join(ZoomPath, imagefile)
      m = MapTileRE.search(imagefile)
      print imagefile, m.groups()

      MapName = m.groups()[0]
      XTile = int(m.groups()[1])
      YTile = int(m.groups()[2])
      
      MapImage = Image.open(FullFilename)
      
      MapImage1 = MapImage.crop((0, 0, 127, 127)).resize((256, 256), Image.ANTIALIAS)
      MapImage2 = MapImage.crop((128, 0, 255, 127)).resize((256, 256), Image.ANTIALIAS)
      MapImage3 = MapImage.crop((0, 128, 127, 255)).resize((256, 256), Image.ANTIALIAS)
      MapImage4 = MapImage.crop((128, 128, 255, 255)).resize((256, 256), Image.ANTIALIAS)

      OutputMapFilename1 = MakeMapTileFilename(RootMapPath, MapName, XTile*2, YTile*2, CREATEZOOMLEVEL)
      OutputMapFilename2 = MakeMapTileFilename(RootMapPath, MapName, XTile*2+1, YTile*2, CREATEZOOMLEVEL)
      OutputMapFilename3 = MakeMapTileFilename(RootMapPath, MapName, XTile*2, YTile*2+1, CREATEZOOMLEVEL)
      OutputMapFilename4 = MakeMapTileFilename(RootMapPath, MapName, XTile*2+1, YTile*2+1, CREATEZOOMLEVEL)

      MapImage1.save(OutputMapFilename1)
      MapImage2.save(OutputMapFilename2)
      MapImage3.save(OutputMapFilename3)
      MapImage4.save(OutputMapFilename4)
   
    return


def IterateMapRoot ():

    (root, subdirs, filenames) = next(os.walk(ROOTPATH))

    for path in subdirs:
        CreateExtraZoomLevel(path)

    print "Found {0} map files!".format(g_MapFileCount)        
    return


IterateMapRoot()

