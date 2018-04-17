import os
import re
import sys
#import Image
from PIL import Image
import shutil
import fnmatch

USE_COMMAND_ARGS = True

if (not USE_COMMAND_ARGS):
    BasePathIndex = "17"
    BasePath = "e:/esoexport/"
elif (len(sys.argv) < 3):
    print("Missing required command line arguments!")
    exit
else:
    BasePathIndex = sys.argv[1]
    BasePath = sys.argv[2]
    print("\tUsing Base Path:" + BasePath)
    print("\tUsing Version:" + BasePathIndex)


InputPath  = BasePath + 'esomnf-' + BasePathIndex + '/art/maps/'
OutputPath = BasePath + 'goodimages-' + BasePathIndex + '/combinedmaps/'

OutputMapList = OutputPath + 'maplist.txt'
MapImageRE  = re.compile('.*[0-9]+\.png')
MapImageBaseRE = re.compile('.*_base_[0-9]+\.png')
MapGroupRE  = re.compile('([/\\a-z]*)_.*_?([0-9]+)\.png')
MapImageNumberRE  = re.compile('.*_([0-9]+)\.png')


class CImageFileInfo:
    
    def __init__(self):
        self.Filename = ""


class CImageGroup:

    def __init__(self):
        self.BaseName = ""
        self.ImageFiles = []
        self.Images = []
        self.CombinedImage = None
        self.ImageWidth = 0
        self.ImageHeight = 0
        self.CombinedWidth = 0
        self.CombinedHeight = 0
        self.MatchingSizes = True
        self.OutputImage = False


ImageInfos = []
ImageGroups = {}
print "Looking for map images in", InputPath

for root, dirnames, filenames in os.walk(InputPath):
    for filename in fnmatch.filter(filenames, '*.png'):
        if not MapImageRE.match(filename):
            #print root, filename
            continue
        NewImageInfo = CImageFileInfo()
        NewImageInfo.Filename = os.path.join(root.lower(), filename.lower())[len(InputPath):]
        NewImageInfo.IsUsed = False
        ImageInfos.append(NewImageInfo)

print "Found", len(ImageInfos), "map images!"
print "Looking for matching image groups..."
#print ImageInfos[0].Filename

for i in range(0, len(ImageInfos)):
    if ImageInfos[i].IsUsed: continue
    m = MapGroupRE.search(ImageInfos[i].Filename)
    #print m.groups()

    if m.group(1) in ImageGroups:
        ImageGroups[m.group(1)].ImageFiles.append(ImageInfos[i].Filename)
    else:
        newgroup = CImageGroup()
        newgroup.BaseName = m.group(1)
        newgroup.ImageFiles.append(ImageInfos[i].Filename)
        ImageGroups[m.group(1)] = newgroup

print "Found", len(ImageGroups), "image groups!"
# print "Total Images Grouped = ", TotalImagesGrouped, ",", len(ImageInfos) - TotalImagesGrouped, "images missed!"


print "Loading", len(ImageGroups), "image groups..."

def GetGroupIndex(Filename):
    m = MapImageNumberRE.search(Filename)
    if (m == None): return 0
    if len(m.groups()) == 0: return 0
    return int(m.groups(0)[0])

for imagegroupname in ImageGroups:
    print "Group", imagegroupname, "has", len(ImageGroups[imagegroupname].ImageFiles), "images"
    ImageGroups[imagegroupname].ImageFiles = sorted(ImageGroups[imagegroupname].ImageFiles, key=GetGroupIndex)

    for imagefile in ImageGroups[imagegroupname].ImageFiles:
        #print "   ", imagefile
        Filename = InputPath + imagefile
        NewImage = Image.open(Filename)
        ImageGroups[imagegroupname].Images.append(NewImage.copy())

        if ImageGroups[imagegroupname].ImageWidth == 0:
            ImageGroups[imagegroupname].ImageWidth, ImageGroups[imagegroupname].ImageHeight = NewImage.size
        else:
            width, height = NewImage.size
            if (ImageGroups[imagegroupname].ImageWidth  != width):
                print "Mismatched image width (", width, "!=", ImageGroups[imagegroupname].ImageWidth, " in", imagefile
                ImageGroups[imagegroupname].MatchingSizes = False
            if (ImageGroups[imagegroupname].ImageHeight != height):
                print "Mismatched image height (", height, "!=", ImageGroups[imagegroupname].ImageHeight, " in", imagefile
                ImageGroups[imagegroupname].MatchingSizes = False

    TileX = 0
    TileY = 0

    if not ImageGroups[imagegroupname].MatchingSizes:
            if len(ImageGroups[imagegroupname].ImageFiles) == 9:
                    TileX = 2
                    TileY = 2
            elif len(ImageGroups[imagegroupname].ImageFiles) == 5:
                    TileX = 2
                    TileY = 2
            elif len(ImageGroups[imagegroupname].ImageFiles) == 25 and imagegroupname == "stonefalls/ebonheart_base":
                    TileX = 2
                    TileY = 2
            elif len(ImageGroups[imagegroupname].ImageFiles) == 1:
                    TileX = 1
                    TileY = 1
            elif len(ImageGroups[imagegroupname].ImageFiles) == 36:
                    TileX = 5
                    TileY = 5
            elif len(ImageGroups[imagegroupname].ImageFiles) == 100 and imagegroupname == "clockwork/clockwork_base":
                    TileX = 4
                    TileY = 4
            else:
                    print "   Skipping group", imagegroupname, "with mismatched sizes"
                    del ImageGroups[imagegroupname].Images[:]
                    continue
    elif len(ImageGroups[imagegroupname].ImageFiles) == 1:
            TileX = 1
            TileY = 1
    elif len(ImageGroups[imagegroupname].ImageFiles) == 4:
            TileX = 2
            TileY = 2
    elif len(ImageGroups[imagegroupname].ImageFiles) == 9:
            TileX = 3
            TileY = 3
    elif len(ImageGroups[imagegroupname].ImageFiles) == 16:
            TileX = 4
            TileY = 4
    elif len(ImageGroups[imagegroupname].ImageFiles) == 25 and imagegroupname == "rivenspire/shroudedpass_base":
            TileX = 3
            TileY = 3
    elif len(ImageGroups[imagegroupname].ImageFiles) == 25:
            TileX = 5
            TileY = 5
    elif len(ImageGroups[imagegroupname].ImageFiles) == 36:
            TileX = 6
            TileY = 6
    elif len(ImageGroups[imagegroupname].ImageFiles) == 37 or imagegroupname == "summserset/summerset_base":
            TileX = 4
            TileY = 4        
    elif len(ImageGroups[imagegroupname].ImageFiles) == 49:
            TileX = 7
            TileY = 7
    elif len(ImageGroups[imagegroupname].ImageFiles) == 64:
            TileX = 8
            TileY = 8
    elif len(ImageGroups[imagegroupname].ImageFiles) == 81:
            TileX = 9
            TileY = 9
    else:
            print "   Don't know how to tile", len(ImageGroups[imagegroupname].ImageFiles), "images for ", imagegroupname
            del ImageGroups[imagegroupname].Images[:]
            continue

    CombinedImage = Image.new('RGB', (ImageGroups[imagegroupname].ImageWidth*TileX, ImageGroups[imagegroupname].ImageHeight*TileY))
    ImageGroups[imagegroupname].CombinedWidth = ImageGroups[imagegroupname].ImageWidth*TileX
    ImageGroups[imagegroupname].CombinedHeight = ImageGroups[imagegroupname].ImageHeight*TileY
    ImageIndex = 0

    for y in range(0, TileY):
            for x in range(0, TileX):
                    CombinedImage.paste(ImageGroups[imagegroupname].Images[ImageIndex], (x*ImageGroups[imagegroupname].ImageWidth, y*ImageGroups[imagegroupname].ImageHeight))
                    ImageIndex += 1

    FilePath = OutputPath + imagegroupname.split("/", 1)[0]
    Filename = OutputPath + imagegroupname + ".jpg"
    print "Saving", Filename, "..."

    if not os.path.exists(FilePath):
            os.makedirs(FilePath)

    CombinedImage.save(Filename)
    ImageGroups[imagegroupname].OutputImage = True
    del ImageGroups[imagegroupname].Images[:]



    
            
print "Exporting map list..."

with open(OutputMapList, "w") as text_file:
    text_file.write("{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}\n".format("parent", "map", "numimages", "MatchedSizes", "Width", "Height", "CombWidth", "CombHeight", "IsOutput"))
    for imagegroupname in ImageGroups:
        splitname = imagegroupname.split("/")
        text_file.write("{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}\n".format(splitname[0], splitname[1], len(ImageGroups[imagegroupname].ImageFiles), ImageGroups[imagegroupname].MatchingSizes,
                                                                          ImageGroups[imagegroupname].ImageWidth, ImageGroups[imagegroupname].ImageHeight,
                                                                          ImageGroups[imagegroupname].CombinedWidth, ImageGroups[imagegroupname].CombinedHeight,
                                                                          ImageGroups[imagegroupname].OutputImage))

    
