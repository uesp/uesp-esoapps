import os
import sys
import shutil
import math
import errno
import csv

USE_COMMAND_ARGS = True

if (not USE_COMMAND_ARGS):
    FIRSTID = 1447
    BasePathIndex = "17"
    BasePath = "e:/esoexport/"
elif (len(sys.argv) < 4):
    print("Missing required command line arguments!")
    exit
else:
    BasePathIndex = sys.argv[1]
    BasePath = sys.argv[2]
    FIRSTID = int(sys.argv[3])
    print("\tUsing Base Path:" + BasePath)
    print("\tUsing Version:" + BasePathIndex)
    print("\tUsing First ID:" + str(FIRSTID))

MAPINFOFILE = BasePath + "goodimages-" + BasePathIndex + "/Maps/mapinfo.txt"
NEWMAPSFILE = BasePath + "goodimages-" + BasePathIndex + "/maps_new.txt"
OUTPUTPATH = BasePath + "goodimages-" + BasePathIndex + "/Maps/"

MAX_ZOOM_VALUE = 11

MAPNAME = 0
MAXZOOM = 1
MINZOOM = 2
NUMTILESX = 3
NUMTILESY = 4
MAPDISPLAYNAME = 5

g_MapInfos = []
g_NewMaps = []
g_NewMapsMap = { }
g_MapInfosMap = { }


def LoadNewMaps (InputFilename):
    global g_NewMaps

    print "Reading new map CSV file {0}...".format(InputFilename)

    with open(InputFilename, 'rb') as f:
        reader = csv.reader(f)
        
        for row in reader:
            g_NewMaps.append(row)
            g_NewMapsMap[row[0].strip()] = g_NewMaps[-1]

    print "\tFound {0} new maps!".format(len(g_NewMaps))
    return


def LoadMapInfo (InputFilename):
    global g_MapInfos

    print "Reading map info CSV file {0}...".format(InputFilename)

    with open(InputFilename, 'rb') as f:
        reader = csv.reader(f)
        
        for row in reader:
            g_MapInfos.append(row)
            g_MapInfosMap[row[MAPNAME].strip()] = g_MapInfos[-1]

    print "\tFound {0} map infos!".format(len(g_MapInfos))
    return


def MatchDisplayNames ():
    global g_NewMaps
    global g_MapInfos
    global g_NewMapsMap
    global g_MapInfosMap
    
    for i, row in enumerate(g_NewMaps):
        mapName = row[0].strip()
        mapDisplayName = row[1].strip()

        if (not mapName in g_MapInfosMap):
            print "Map {0} not found in map info file!".format(mapName)
            # g_MapInfos[i].append(mapName)
            continue

        # print "Found display name {0}".format(g_MapGroupNameMap[mapName][MAPGROUP_DISPLAYNAME])
        #g_MapInfos[i].append(g_MapGroupNameMap[mapName][MAPGROUP_DISPLAYNAME])
        # print "test {0}".format(g_MapInfos[i][MAPDISPLAYNAME])
        g_MapInfosMap[mapName].append(mapDisplayName)
        
    return


def CreateDBCheckMaps (OutputFilename):
    global g_NewMaps
    global g_MapInfosMap
    
    f = open(OutputFilename, "wb")

    print "Saving checkmaps SQL file {0}...".format(OutputFilename)

    for i, row in enumerate(g_NewMaps):
        mapName = row[0].strip()
        
        if (not mapName in g_MapInfosMap):
            print "Map {0} not found in map info file!".format(mapName)
        
        SqlString = ""
        SqlString += "SELECT id from uesp_gamemap.world WHERE name='{0}';\n".format(mapName)
        
        f.write(SqlString)
        
    return



def CreateDBCheckParentMaps (OutputFilename):
    global g_NewMaps
    global g_MapInfosMap
    
    f = open(OutputFilename, "wb")

    print "Saving parent checkmaps SQL file {0}...".format(OutputFilename)

    for i, row in enumerate(g_NewMaps):
        mapName = row[0].strip()
        parentMapName = row[2].strip()
        
        if (not mapName in g_MapInfosMap):
            print "Map {0} not found in map info file!".format(mapName)

        if (not parentMapName in g_MapInfosMap):
            print "Parent Map {0} not found in map info file!".format(parentMapName)
        
        SqlString = ""
        SqlString += "SELECT id from uesp_gamemap.world WHERE name='{0}';\n".format(parentMapName)
        
        f.write(SqlString)
        
    return


def CreateDBOutput (OutputFilename):
    global g_MapInfos
    
    f = open(OutputFilename, "wb")
    ID = FIRSTID

    print "Saving SQL file {0}...".format(OutputFilename)

    for i, row in enumerate(g_NewMaps):
        mapName = row[0].strip()
        mapDisplayName = row[1].strip()
        mapParentName = row[2].strip()
        mapParentID = row[3].strip()
                
        if (not mapName in g_MapInfosMap):
            print "Map {0} not found in map info file!".format(mapName)
            continue

        mapInfo = g_MapInfosMap[mapName]
        
        posTop = int(mapInfo[NUMTILESY])*256
        posLeft = 0
        posRight = int(mapInfo[NUMTILESX])*256
        posBottom = 0

        posTop = 1000000
        posRight = 1000000
        
        # print "{1}: Length = {0}".format(len(row), i)
        SqlString = ""
        SqlString += "SELECT @parent_revision_id := revisionId FROM uesp_gamemap.world WHERE id={0};\n".format(ID)
        SqlString += "INSERT INTO uesp_gamemap.revision(worldId, parentId, editUserId, editUserText, editComment, patrolled) VALUES({0}, @parent_revision_id, 0, 'Bot', 'Import by script', 0);\n".format(ID)
        SqlString += "SET @revision_id = LAST_INSERT_ID();\n"
                
        SqlString += "DELETE FROM uesp_gamemap.world WHERE id={0};\n".format(ID)
        SqlString += "INSERT INTO uesp_gamemap.world(id, revisionId, parentId, name, displayName, minZoom, maxZoom, zoomOffset, posLeft, posTop, posRight, posBottom, enabled) VALUES({0}, @revision_id, {9}, \"{1}\", \"{8}\", {3}, {2}, {3}, {4}, {5}, {6}, {7}, 1);\n".format(ID, mapInfo[MAPNAME], MAX_ZOOM_VALUE, mapInfo[MINZOOM], posLeft, posTop, posRight, posBottom, mapDisplayName, mapParentID)

        SqlString += "INSERT INTO uesp_gamemap.world_history(worldId, parentId, revisionId, name, displayName, minZoom, maxZoom, zoomOffset, posLeft, posTop, posRight, posBottom, enabled) VALUES({0}, @revision_id, {9}, \"{1}\", \"{8}\", {3}, {2}, {3}, {4}, {5}, {6}, {7}, 1);\n".format(ID, mapInfo[MAPNAME], MAX_ZOOM_VALUE, mapInfo[MINZOOM], posLeft, posTop, posRight, posBottom, mapDisplayName, mapParentID)
        SqlString += "SET @world_history_id = LAST_INSERT_ID();\n"

        SqlString += "UPDATE uesp_gamemap.revision SET worldHistoryId=@world_history_id WHERE id=@revision_id;\n"
        
        f.write(SqlString)
        ID += 1

    f.close()
    return


LoadMapInfo(MAPINFOFILE)
LoadNewMaps(NEWMAPSFILE)
MatchDisplayNames()
CreateDBCheckMaps(OUTPUTPATH + "checkmaps.sql")
CreateDBCheckParentMaps(OUTPUTPATH + "checkparents.sql")
CreateDBOutput(OUTPUTPATH + "newmaps.sql")
