import os.path
import operator
import sys
import datetime
import shutil
import EsoGlobals
from EsoGlobals import CEsoGlobals
import EsoLuaFile
from EsoLuaFile import CEsoLuaFile
import EsoFunctionInfo
from EsoFunctionInfo import CEsoFunctionInfo
from EsoFunctionInfo import CEsoFunctionCallInfo
import EsoFunctionDb
from EsoFunctionDb import CEsoFunctionDb


class CEsoEnvironment:

    def __init__(self):
        self.globalData = CEsoGlobals()
        self.luaFiles = []
        self.functions = CEsoFunctionInfo()
        self.functionCalls = CEsoFunctionCallInfo()
        self.functionDb = CEsoFunctionDb()


    def LoadGlobals(self, filename):
        self.globalData = EsoGlobals.LoadGlobals(filename)


    def LoadLuaFiles(self, path):
        self.luaFiles = EsoLuaFile.LoadAllFiles(path, path)
        
        self.functions = EsoFunctionInfo.FindAllFunctions(self.luaFiles)
        self.functionCalls = EsoFunctionInfo.FindAllFunctionCalls(self.luaFiles)
        
        self.functionDb = EsoFunctionDb.CreateDb(self.functions, self.functionCalls)
        self.functionDb.CreateFunctionValueMap(self.globalData)
        self.functionDb.MatchGlobals(self.globalData)
