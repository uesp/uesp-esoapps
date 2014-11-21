import csv
import collections
import os.path
import re
import operator
from operator import attrgetter
import sys
import datetime
import shutil
import ntpath
import EsoGlobals
from EsoGlobals import CEsoGlobals
import EsoLuaFile
from EsoLuaFile import CEsoLuaFile
import EsoFunctionInfo
from EsoFunctionInfo import CEsoFunctionInfo


class CEsoFunctionDb:
        
    def __init__(self):
        self.globalFunctions = { }
        self.localFunctions = { }
        self.functionCalls = { }


    def GetFunctionCalls(self, funcName):
        funcName = funcName.replace(":", ".")
        if (not funcName in self.functionCalls): return []
        return self.functionCalls[funcName]


    def AddCallInfos(self, calls):
        
        for call in calls:
            self.AddCallInfo(call)
            
    
    def AddCallInfo(self, call):

        if (not call.name in self.functionCalls):
            self.functionCalls[call.name] = []

        self.functionCalls[call.name].append(call)


    def AddInfos(self, functionInfos):

        for function in functionInfos:
            self.AddInfo(function)


    def AddInfo(self, function):
        
        if (function.isLocal):
            self.AddLocalInfo(function)
        else:
            self.AddGlobalInfo(function)


    def AddLocalInfo(self, function):
        if (not function.filename in self.localFunctions):
            self.localFunctions[function.filename] = {}

        if (not function.niceName in self.localFunctions[function.filename]):
            self.localFunctions[function.filename][function.niceName] = []
            
        self.localFunctions[function.filename][function.niceName].append(function)

    
    def AddGlobalInfo(self, function):
        if (not function.niceName in self.globalFunctions):
            self.globalFunctions[function.niceName] = []
                
        self.globalFunctions[function.niceName].append(function)
        

    def FindGlobalFunction(self, funcName):
        niceName = funcName.replace(":", ".").replace("/", "")
        if (not niceName in self.globalFunctions): return None
        return self.globalFunctions[niceName]


    def FindLocalFunction(self, filename, funcName):
        niceName = funcName.replace(":", ".").replace("/", "")
        if (not filename in self.localFunctions): return None
        if (not niceName in self.localFunctions[filename]): return None
        return self.localFunctions[filename][niceName]


    def MatchGlobalsChildren(self, root):
        matchData = []
        missingCount = 0

        for key in root:
            obj = root[key]

            if (obj.type == "function"):
                if (obj.fullName in self.globalFunctions):
                    matchData.append(obj.fullName)
                else:
                    missingCount += 1
                    #print "\tMissing function definition for {0}".format(obj.fullName)

            resultMatch, resultCount = self.MatchGlobalsChildren(obj.children)
            missingCount += resultCount
            matchData.extend(resultMatch)
        
        return matchData, missingCount
        

    def MatchGlobals(self, esoGlobals):
        print "Looking for function matches in global data..."
        matchData, missingCount = self.MatchGlobalsChildren(esoGlobals.globals)
        print "\tFound {0} global function matches and {1} misses!".format(len(matchData), missingCount)
        return matchData


    def DumpMissingFunctions(self, filename, esoGlobals):
        print "Dumping missing functions to", filename

        with open(filename, "w") as outFile:
            for func in sorted(esoGlobals.allFunctions):
                if (not func.fullName in self.globalFunctions):
                    outFile.write("{0}()\n".format(func.fullName))


    def DumpGlobalFunctions(self, filename):
        print "Dumping global functions to", filename

        with open(filename, "w") as outFile:
            sortedKeys = sorted(self.globalFunctions)

            for funcName in sortedKeys:
                funcs = self.globalFunctions[funcName]
                outFile.write("{0}() = '{1}'\n".format(funcName, funcs[0].value))

                for func in funcs:
                    outFile.write("\t{0}:{1} -- {2}\n".format(func.filename, func.startLinePos, func.fullDefString))


    def DumpLocalFunctions(self, filename):
        print "Dumping local functions to", filename
        
        with open(filename, "w") as outFile:

            for fileName in sorted(self.localFunctions.keys()):
                funcNames = self.localFunctions[fileName]
                outFile.write("Local Functions in {0}:\n".format(fileName))

                for funcName in funcNames.keys():
                    funcs = funcNames[funcName]
                    
                    for func in funcs:
                        outFile.write("\t{0:>5}: {1}\n".format(func.startLinePos, func.fullDefString))
                                  

    def DumpUnusedFunctions(self, filename, esoGlobals):
        print "Dumping unused functions to", filename

        with open(filename, "w") as outFile:
            sortedFuncs = sorted(esoGlobals.allFunctions, key=attrgetter('fullName'))

            for func in sortedFuncs:
                if (func.fullName in self.globalFunctions): continue
                if (func.fullName in self.functionCalls): continue

                outFile.write("{0}() = {1}\n".format(func.fullName, func.value))
            

    def DumpFunctionCalls(self, filename):
        print "Dumping function calls to", filename

        with open(filename, "w") as outFile:
            sortedKeys = sorted(self.functionCalls)

            for key in sortedKeys:
                calls = self.functionCalls[key]
                outFile.write("{0}()\n".format(key))

                for call in calls:
                    outFile.write("\t{0}:{1} -- {2}\n".format(call.filename, call.startLinePos, call.fullString))


    def DumpMissingFunctionCalls(self, filename):
        nameMap = { }

        for key in self.globalFunctions:
            funcs = self.globalFunctions[key]

            for func in funcs:
                if (not func.name in nameMap):
                    nameMap[func.name] = func

        print "Dumping missing function calls to", filename

        with open(filename, "w") as outFile:
            sortedKeys = sorted(self.functionCalls)
            
            for key in sortedKeys:
                calls = self.functionCalls[key]
                if (key in nameMap): continue

                outFile.write("{0}()\n".format(key))

                for call in sorted(calls):
                    if (not call.fullName in self.globalFunctions):
                        outFile.write("\t{0} -- {1}:{2}\n".format(call.fullString, call.filename, call.startLinePos))


    def CheckFunctionCalls(self):
        matchCount = 0
        missCount = 0
        nameMatchCount = 0
        nameMissCount = 0
        nameMap = { }

        for key in self.globalFunctions:
            funcs = self.globalFunctions[key]

            for func in funcs:
                if (not func.name in nameMap):
                    nameMap[func.name] = func

        print "Checking for function call in global function definitions..."

        for key in self.functionCalls:
            calls = self.functionCalls[key]

            for call in calls:
                if (call.fullName in self.globalFunctions):
                    matchCount += 1
                else:
                    missCount += 1

                if (call.name in nameMap):
                    nameMatchCount += 1
                else:
                    nameMissCount += 1

        print "\tFound {0} matches and {1} misses (name lookup has {2} matches and {3} misses).".format(matchCount, missCount, nameMatchCount, nameMissCount)


    def CheckNameValueDups(self, filename):
        nameMap = { }
        nameMapCount = { }
        nameMapFuncs = { }
        missCount = 0
        matchCount = 0

        print "Checking for duplicate global function name/values, outputing to {0}...".format(filename)

        for key in self.globalFunctions:
            funcs = self.globalFunctions[key]

            for func in funcs:
                if (not func.name in nameMap):
                    nameMap[func.name] = func
                    nameMapCount[func.name] = 1
                    nameMapFuncs[func.name] = [ ]
                elif (nameMap[func.name].value != func.value):
                    #print "\t{0}() has value mismatch ({1} != {2})".format(func.name, func.value, nameMap[func.name].value)
                    missCount += 1
                    nameMapCount[func.name] += 1
                else:
                    matchCount += 1
                    
                nameMapFuncs[func.name].append(func)

        sortedKeys = sorted(nameMapCount.keys())
        uniqueCount = 0
        noDupCount = 0

        with open(filename, "w") as outFile:

            for key in sortedKeys:
                count = nameMapCount[key]
                
                if (count <= 1):
                    noDupCount += 1
                    continue
                
                outFile.write("{0}() = {1} duplicates\n".format(key, count))
                uniqueCount += 1

                funcs = nameMapFuncs[key]

                for func in sorted(funcs):
                    outFile.write("\t{0}() = {1}\n".format(func.fullName, func.value))

        print "\tFound {0} matches and {1} misses for {2} different functions, {3} unique names, {4} with no duplicates.".format(matchCount, missCount, len(nameMap), uniqueCount, noDupCount)
                
        
        

def CreateDb(functions = [], functionCalls = []):
    functionDb = CEsoFunctionDb()

    print "Creating function database from {0} functions...".format(len(functions))

    functionDb.AddInfos(functions)
    functionDb.AddCallInfos(functionCalls)

    print "\tFound {0} global and {1} local unique function definitions!".format(len(functionDb.globalFunctions), len(functionDb.localFunctions))
        
    return functionDb
            


