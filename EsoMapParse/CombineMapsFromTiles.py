import os
import re
import sys
from PIL import Image
import shutil
import fnmatch
import math
import errno

InputPath = "c:/Temp/MapFiles/"
OutputPath = "c:/Temp/MapOutput/"


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise

mkdir_p(OutputPath)

for item in os.listdir(InputPath):
    if os.path.isfile(item):
        continue
    
    mapName = item
    path = InputPath + item + "/zoom10/"
    # print path

    files = os.listdir(path)
    numFiles = len(files)
    tileSize = math.sqrt(numFiles)

    print path, numFiles, tileSize
    
    if (not tileSize.is_integer()):
        print "\tNon-integer tile size found!"

    tileSize = int(tileSize)
    CombinedImage = Image.new('RGB', (256*tileSize, 256*tileSize))

    for y in range(0, tileSize):
        for x in range(0, tileSize):
            filename = path + mapName + "-{0}-{1}.jpg".format(x, y)
            # print filename

            if not os.path.isfile(filename):
                print "\tError: Missing file {0}!".format(filename)
                continue;
    
            NewImage = Image.open(filename)
            CombinedImage.paste(NewImage, (x*256, y*256))

    OutputFilename = OutputPath + mapName + ".jpg"
    CombinedImage.save(OutputFilename)        

    

    
