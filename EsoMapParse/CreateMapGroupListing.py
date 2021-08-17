import os
import sys
import Image
import shutil
import math
import errno
import csv

INPUTFILE = "d:\\esoexport\\maptiles\\MapGroups1.txt"
MAPINFOFILE = "d:\\esoexport\\maptiles\\mapinfo.txt"
OUTPUTFILE = "d:\\esoexport\\maptiles\\MapList1.txt"

MAPALLIANCE = 0
MAPAREA = 1
MAPNAME = 2
MAPSUBGROUPCOUNT = 3
MAPDISPLAYNAME = 4

g_MapGroups = []
g_MapInfos  = []
g_MapNames = { }


def LoadMapInfo (InputFilename):
    global g_MapInfos
    global g_MapNames

    print "Reading CSV file {0}...".format(InputFilename)

    with open(InputFilename, 'rb') as f:
        reader = csv.reader(f)
        
        for row in reader:
            g_MapInfos.append(row)
            g_MapNames[row[0].strip()] = g_MapInfos[-1]

    print "\tFound {0} rows!".format(len(g_MapInfos))
    return


def LoadMapGroups (InputFilename):
    global g_MapGroups

    print "Reading CSV file {0}...".format(InputFilename)

    with open(InputFilename, 'rb') as f:
        reader = csv.reader(f)
        
        for row in reader:
            g_MapGroups.append(row)

    print "\tFound {0} rows!".format(len(g_MapGroups))
    return


def IsValidMap (MapName):
    return MapName in g_MapNames


def CreateMapGroupListing (OutputFilename):
    f = open(OutputFilename, "wb")
    IsFirst = True
    LastGroup1 = ''
    LastGroup2 = ''

    print "Saving group listing file {0}...".format(OutputFilename)

    for row in g_MapGroups:

        if (IsFirst):
            IsFirst = False
            continue

        MapName = row[MAPNAME].strip()
        MapDisplayName = row[MAPDISPLAYNAME].strip()
        
        if (not IsValidMap(MapName)):
            print "Skipping {0}...".format(MapName)
            continue

        CurrentGroup1 = row[MAPALLIANCE].strip().capitalize()
        CurrentGroup2 = row[MAPAREA].strip().capitalize()
        SubGroupCount = int(row[MAPSUBGROUPCOUNT])

        if (SubGroupCount <= 1): CurrentGroup2 = ''
        
        OutputString = ""

        if (CurrentGroup1 != LastGroup1):
            if (LastGroup1 != ''):
                if (LastGroup2 != ''): OutputString += "\t\t\t</ul>\n"
                OutputString += "\t\t</ul>\n"
                
            OutputString += "\t<li class='MapListHeader'>{0}</li>\n".format(CurrentGroup1)
            OutputString += "\t\t<ul>\n"

            if (CurrentGroup2 != ''):
                OutputString += "\t\t<li class='MapListHeader'>{0}</li>\n".format(CurrentGroup2)
                OutputString += "\t\t\t<ul>\n"
                
        elif (CurrentGroup2 != LastGroup2):
            if (LastGroup2 != ''):
                OutputString += "\t\t\t</ul>\n"

            if (CurrentGroup2 != ''):
                OutputString += "\t\t<li class='MapListHeader'>{0}</li>\n".format(CurrentGroup2)
                OutputString += "\t\t\t<ul>\n"

        if (CurrentGroup2 != ''): OutputString += "\t"
        OutputString += "\t\t<li>{0}</li>\n".format(MapDisplayName)

        f.write(OutputString)

        LastGroup1 = CurrentGroup1
        LastGroup2 = CurrentGroup2

    f.write("\t\t\t</ul>\n\t\t</ul>\n")
    f.close()
    return


LoadMapInfo(MAPINFOFILE)
LoadMapGroups(INPUTFILE)
CreateMapGroupListing(OUTPUTFILE)

#for key, value in g_MapNames.iteritems():
#   print key

