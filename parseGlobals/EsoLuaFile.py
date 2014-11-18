import csv
import collections
import os.path
import re
import operator
import sys
import datetime
import shutil
import ntpath
from EsoLuaTokenizer import CLuaTokenizer


class CEsoLuaFile:

    def __init__(self):
        self.fullFilename = ""
        self.relFilename = ""
        self.fileContents = ""
        self.creationDate = ""
        self.tokenizer = CLuaTokenizer()
        self.localObjects = { }
        self.objects = { }


    def GetTokens(self):
        return self.tokenizer.tokens


    def Parse(self):
        self.tokenizer.Tokenize(self.fileContents)
        return True
        

    def LoadParseFile(self, filename, relPath):
        self.fullFilename = filename.replace("\\", "/")
        self.relFilename = os.path.relpath(filename, relPath).replace("\\", "/")
        self.creationDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print "Loading and Parsing Lua file", self.relFilename, "..."

        self.fileContents = open(filename, "r").read()
        return self.Parse()


def LoadLuaFile(filename, relPath = ""):
    newFile = CEsoLuaFile()
    newFile.LoadParseFile(filename, relPath)
    return newFile
    

def LoadAllLuaFiles(path, relPath = ""):
    luaFiles = []
    
    for root, dirs, files in os.walk(path):
        for filename in files:
            if (filename.endswith(".lua")):
                newFile = CEsoLuaFile()
                newFile.LoadParseFile(root + "\\" + filename, relPath)
                luaFiles.append(newFile)
    
    return luaFiles
