import csv
import collections
import os.path
import re
import operator
import sys
import datetime
import shutil
import ntpath
import EsoGlobals
from EsoGlobals import CEsoGlobals
import EsoLuaFile
from EsoLuaFile import CEsoLuaFile
import EsoFunctionInfo
import EsoFunctionDb
import EsoEnvironment


INPUT_GLOBAL_FILENAME = "d:\\esoexport\\goodimages10\\globals_6b.txt"
OUTPUT_PATH = "d:\\temp\\esodata\\"
INPUT_LUA_PATH = "d:\\esoexport\\gamemnf10\\esoui\\"

esoEnvironment = EsoEnvironment.CEsoEnvironment()
esoEnvironment.LoadGlobals(INPUT_GLOBAL_FILENAME)
esoEnvironment.LoadLuaFiles(INPUT_LUA_PATH)


'''
esoGlobals = EsoGlobals.LoadGlobals(INPUT_GLOBAL_FILENAME)
esoGlobals.Dump(OUTPUT_PATH + "globals.txt")
esoGlobals.CreateHTML(OUTPUT_PATH + "globals.html")
esoGlobals.DumpDuplicateFunctions(OUTPUT_PATH + "globaldupfuncs.txt")

#esoFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\libraries\\globals\\debugutils.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
#esoFile.CreateHtml("d:\\temp\\esodata1\\src\\", esoGlobals)

esoFiles = EsoLuaFile.LoadAllFiles(INPUT_LUA_PATH, INPUT_LUA_PATH)
EsoLuaFile.CreateHtmlAllFiles(esoFiles, "d:\\temp\\esodata1\\src\\", esoGlobals)
'''

'''
esoFiles = EsoLuaFile.LoadAllFiles(INPUT_LUA_PATH, INPUT_LUA_PATH)
esoFunctions = EsoFunctionInfo.FindAllFunctions(esoFiles)
esoFunctionCalls = EsoFunctionInfo.FindAllFunctionCalls(esoFiles)
esoFunctionDb = EsoFunctionDb.CreateDb(esoFunctions, esoFunctionCalls)
esoFunctionDb.DumpFunctionCalls(OUTPUT_PATH + "functioncalls.txt")

esoFunctionDb.CreateFunctionValueMap(esoGlobals)
esoFunctionDb.MatchGlobals(esoGlobals)

esoFunctionDb.DumpGlobalFunctions(OUTPUT_PATH + "globalfuncs.txt")
esoFunctionDb.DumpMissingFunctions(OUTPUT_PATH + "missingfuncs.txt", esoGlobals)

esoFunctionDb.CheckNameValueDups(OUTPUT_PATH + "namedupfuncs.txt")
esoFunctionDb.CheckFunctionCalls()
esoFunctionDb.DumpMissingFunctionCalls(OUTPUT_PATH + "missingfunccalls.txt")
esoFunctionDb.DumpUnusedFunctions(OUTPUT_PATH + "unusedfunc.txt", esoGlobals)
'''

'''
#esoLuaFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\libraries\\zo_menubar\\zo_menubar.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
#esoLuaFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\pregame\\statemanager\\pc\\pregamestates.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
#esoLuaFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\pregame\\charactercreate\\zo_charactercreate.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
#esoLuaFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\libraries\\zo_templates\\optionswindowtemplate.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
#esoLuaFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\ingame\\slashcommands\\slashcommands.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
#esoLuaFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\app\\loadingscreen\\loadingscreen.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
esoLuaFile = EsoLuaFile.LoadFile("d:\\esoexport\\gamemnf10\\esoui\\libraries\\globals\\debugutils.lua", "d:\\esoexport\\gamemnf10\\esoui\\")
esoFunctionCalls = EsoFunctionInfo.FindFunctionCalls(esoLuaFile)


for call in esoFunctionCalls:
    print call.fullString
    print "\tName={0},   NiceName={2},  FullName={1}".format(call.name, call.fullName, call.niceName)
    print "\tVars={0},   Params={1}".format(call.allVariables, call.allParams)
    print "\t{0}:{1} to {2}:{3}".format(call.startLinePos, call.startCharPos, call.endLinePos, call.endCharPos)
    pass

esoLuaFiles = EsoLuaFile.LoadAllFiles(INPUT_LUA_PATH, INPUT_LUA_PATH)
esoFunctionCalls = EsoFunctionInfo.FindAllFunctionCalls(esoLuaFiles)

esoFunctionDb = EsoFunctionDb.CreateDb([], esoFunctionCalls)
esoFunctionDb.DumpFunctionCalls(OUTPUT_PATH + "functioncalls.txt")

esoFunctions = EsoFunctionInfo.FindLuaFunctions(esoLuaFile)

for function in esoFunctions:
    print function.fullName + "(" + ", ".join(function.params) + ")"
    #print function.fullString
    print "\t{0}:{1} to {2}:{3}".format(function.startLinePos, function.startCharPos, function.endLinePos, function.endCharPos)

esoLuaFiles = EsoLuaFile.LoadAllFiles(INPUT_LUA_PATH, INPUT_LUA_PATH)
tokenCount = 0
funcCount = 0

print "Parsing functions from {0} Lua files...".format(len(esoLuaFiles))

for file in esoLuaFiles:
    print file.relFilename
    tokenCount += len(file.GetTokens())
    esoFunctions = EsoFunctionInfo.FindLuaFunctions(file)
    funcCount += len(esoFunctions)

    for function in esoFunctions:
        if (function.isObject):
            print function.fullName + "(" + ", ".join(function.params) + ")"

print tokenCount, funcCount
'''

