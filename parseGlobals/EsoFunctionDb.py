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
from EsoFunctionInfo import CEsoFunctionInfo


class CEsoFunctionDb:
        
    def __init__(self):
        self.globalFunctions = { }
        self.localFunctions = { }
        self.globalFunctionValueMap = { }


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


    def CreateFunctionValueMap(self, esoGlobals):
        print "Creating function value map from global data..."
        
        matchCount = 0
        missCount = 0

        for obj in esoGlobals.allFunctions:
            if (obj.fullName in self.globalFunctions):
                matchCount += 1
                funcInfos = self.globalFunctions[obj.fullName]

                for func in funcInfos:
                    func.value = obj.value

                if (not obj.value in self.globalFunctionValueMap):
                    self.globalFunctionValueMap[obj.value] = []

                self.globalFunctionValueMap[obj.value].extend(funcInfos)
            else:
                missCount += 1
        
        print "\tSet values of {0} functions with {1} misses!".format(matchCount, missCount)
        self.UpdateFunctionDuplicates(esoGlobals)
        

    def UpdateFunctionDuplicates(self, esoGlobals):
        matchCount = 0

        for obj in esoGlobals.allFunctions:
            if (not obj.fullName in self.globalFunctions and obj.value in self.globalFunctionValueMap):
                funcAlias = self.globalFunctionValueMap[obj.value][0]
                self.globalFunctions[obj.fullName] = []
                self.globalFunctions[obj.fullName].append(funcAlias)
                matchCount += 1
                #print "\tUpdated function {0} with its alias {1}.".format(obj.fullName, funcAlias.fullName)
            
        print "\tUpdated {0} duplicate functions names.".format(matchCount)
        return matchCount


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
            for func in esoGlobals.allFunctions:
                if (not func.fullName in self.globalFunctions):
                    outFile.write("{0}()\n".format(func.fullName))


    def DumpGlobalFunctions(self, filename):
        print "Dumping globals functions to", filename

        with open(filename, "w") as outFile:

            for funcName in self.globalFunctions:
                funcs = self.globalFunctions[funcName]

                outFile.write("{0}()\n".format(funcName))

                for func in funcs:
                    outFile.write("\t{0}:{1} -- {2}\n".format(func.filename, func.startLinePos, func.fullDefString))
        
        

def CreateDb(functions):
    functionDb = CEsoFunctionDb()

    print "Creating function database from {0} functions...".format(len(functions))

    for func in functions:
        functionDb.AddInfo(func)

    print "\tFound {0} global and {1} local unique function definitions!".format(len(functionDb.globalFunctions), len(functionDb.localFunctions))
        
    return functionDb
            


