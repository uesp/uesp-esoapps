import csv
import collections
import os.path
import re
import operator
import sys
import datetime
import shutil
from string import Template
import EsoLuaTokenizer
from EsoLuaTokenizer import CLuaTokenizer
from EsoLuaTokenizer import Token


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
        self.tokenizer.TokenizeWithComments(self.fileContents)
        return True
        

    def LoadParseFile(self, filename, relPath):
        self.fullFilename = filename.replace("\\", "/")
        self.relFilename = os.path.relpath(filename, relPath).replace("\\", "/")
        self.creationDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print "\tLoading and Parsing Lua file", self.relFilename, "..."

        self.fileContents = open(filename, "r").read()
        
		# Skip UTF-8 BOM at the start of some files
	if (self.fileContents[:3] == "\xEF\xBB\xBF"):
		self.fileContents = self.fileContents[3:]
			
        return self.Parse()
    

def LoadFile(filename, relPath = ""):
    newFile = CEsoLuaFile()
    newFile.LoadParseFile(filename, relPath)
    return newFile
    

def LoadAllFiles(path, relPath = ""):
    luaFiles = []

    print "Loading and parsing all Lua files from", relPath, "..."
    
    for root, dirs, files in os.walk(path):
        for filename in files:
            if (filename.endswith(".lua")):
                newFile = CEsoLuaFile()
                newFile.LoadParseFile(root + "\\" + filename, relPath)
                luaFiles.append(newFile)

    print "\tFound {0} files!".format(len(luaFiles))
    return luaFiles


