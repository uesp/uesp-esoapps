import os
import sys
import Image
import shutil
import math
import errno
import csv


INPUTFILE = "d:\\esoexport\\maptiles\\mapinfo.txt"
GROUPFILE = "d:\\esoexport\\maptiles\\mapgroups1.txt"
OUTPUTFILE = "d:\\esoexport\\maptiles\\mapdata.sql"
FIRSTID = 100
MAPNAME = 0
MAXZOOM = 1
MINZOOM = 2
NUMTILESX = 3
NUMTILESY = 4
MAPDISPLAYNAME = 5

MAPGROUP_ALLIANCE = 0
MAPGROUP_AREA = 1
MAPGROUP_NAME = 2
MAPGROUP_SUBGROUPCOUNT = 3
MAPGROUP_DISPLAYNAME = 4

g_MapGroups = []
g_MapInfos = []
g_MapGroupNameMap = {}



def LoadMapGroups (InputFilename):
    global g_MapGroups
    global g_MapGroupNameMap

    print "Reading CSV file {0}...".format(InputFilename)

    with open(InputFilename, 'rb') as f:
        reader = csv.reader(f)
        
        for row in reader:
            g_MapGroups.append(row)
            g_MapGroupNameMap[row[MAPGROUP_NAME].strip()] = g_MapGroups[-1]

    print "\tFound {0} rows!".format(len(g_MapGroups))
    return


def LoadMapInfo (InputFilename):
    global g_MapInfos

    print "Reading CSV file {0}...".format(InputFilename)

    with open(InputFilename, 'rb') as f:
        reader = csv.reader(f)
        
        for row in reader:
            g_MapInfos.append(row)

    print "\tFound {0} rows!".format(len(g_MapInfos))
    return


def MatchDisplayNames ():
    global g_MapGroups
    global g_MapGroupNameMap
    global g_MapInfos
    
    IsFirst = True

    for i, row in enumerate(g_MapInfos):

        if (IsFirst):
            IsFirst = False
            continue

        mapName = row[MAPNAME].strip()

        if (not mapName in g_MapGroupNameMap):
            print "Map {0} not found in group file!".format(mapName)
            g_MapInfos[i].append(mapName)
            continue

        # print "Found display name {0}".format(g_MapGroupNameMap[mapName][MAPGROUP_DISPLAYNAME])
        g_MapInfos[i].append(g_MapGroupNameMap[mapName][MAPGROUP_DISPLAYNAME])
        # print "test {0}".format(g_MapInfos[i][MAPDISPLAYNAME])
        
    return


def CreateDBOutput (OutputFilename):
    global g_MapInfos
    
    f = open(OutputFilename, "wb")
    ID = FIRSTID
    IsFirst = True

    print "Saving SQL file {0}...".format(OutputFilename)

    for i, row in enumerate(g_MapInfos):

        if (IsFirst):
            IsFirst = False
            continue

        posTop = int(row[NUMTILESY])*256
        posLeft = 0
        posRight = int(row[NUMTILESX])*256
        posBottom = 0

        posTop = 1000000
        posRight = 1000000
        
        # print "{1}: Length = {0}".format(len(row), i)
        SqlString = ""
        SqlString += "SELECT @parent_revision_id := revisionId FROM uesp_gamemap.world WHERE id={0};\n".format(ID)
        SqlString += "INSERT INTO uesp_gamemap.revision(worldId, parentId, editUserId, editUserText, editComment, patrolled) VALUES({0}, @parent_revision_id, 0, 'Bot', 'Import by script', 0);\n".format(ID)
        SqlString += "SET @revision_id = LAST_INSERT_ID();\n"
        
        
        SqlString += "DELETE FROM uesp_gamemap.world WHERE id={0};\n".format(ID)
        SqlString += "INSERT INTO uesp_gamemap.world(id, revisionId, name, displayName, minZoom, maxZoom, zoomOffset, posLeft, posTop, posRight, posBottom, enabled) VALUES({0}, @revision_id, \"{1}\", \"{8}\", {3}, {2}, {3}, {4}, {5}, {6}, {7}, 1);\n".format(ID, row[MAPNAME], row[MAXZOOM], row[MINZOOM], posLeft, posTop, posRight, posBottom, row[MAPDISPLAYNAME])

        SqlString += "INSERT INTO uesp_gamemap.world_history(worldId, revisionId, name, displayName, minZoom, maxZoom, zoomOffset, posLeft, posTop, posRight, posBottom, enabled) VALUES({0}, @revision_id, \"{1}\", \"{8}\", {3}, {2}, {3}, {4}, {5}, {6}, {7}, 1);\n".format(ID, row[MAPNAME], row[MAXZOOM], row[MINZOOM], posLeft, posTop, posRight, posBottom, row[MAPDISPLAYNAME])
        SqlString += "SET @world_history_id = LAST_INSERT_ID();\n"

        SqlString += "UPDATE uesp_gamemap.revision SET worldHistoryId=@world_history_id WHERE id=@revision_id;\n"
        
        f.write(SqlString)
        ID += 1

    f.close()
    return

LoadMapInfo(INPUTFILE)
LoadMapGroups(GROUPFILE)
MatchDisplayNames()
CreateDBOutput(OUTPUTFILE)


 

