import csv
import collections
import os.path
import re
import operator
import sys
import datetime
import shutil
import ntpath
from string import Template
import EsoLuaTokenizer
from EsoLuaTokenizer import CLuaTokenizer
from EsoLuaTokenizer import Token


class CEsoLuaFile:

    headerTemplate = Template(open('templates/esoluafile_header.txt', 'r').read())
    footerTemplate = Template(open('templates/esoluafile_footer.txt', 'r').read())
    

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
        #print "Loading and Parsing Lua file", self.relFilename, "..."

        self.fileContents = open(filename, "r").read()
        return self.Parse()


    def CreateTemplateVars(self, globalData):
        templateVars = { }

        templateVars["filename"] = self.relFilename
        templateVars["fullFilename"] = self.fullFilename
        templateVars["creationDate"] = self.creationDate
        templateVars["numTokens"] = str(len(self.tokenizer.tokens))
        templateVars["parseTime"] = globalData.parseTime
        templateVars["parseDate"] = globalData.parseDate
        templateVars["parseVersion"] = globalData.parseVersion
        templateVars["resourcePath"] = ""

        return templateVars
        

    def CreateHtmlContent(self, outFile, globalData):
        tokens = self.tokenizer.tokensWithComments
                
        lastToken = EsoLuaTokenizer.CLuaToken()
        lastToken.linePos = 1
        lastToken.charPos = 0
        lastToken.charIndex = 0

        outFile.write("<div id='esolf_fileroot'>\n")
        outFile.write("<table border='0' cellpadding='0' cellspacing='0'>\n")
        outFile.write("<tbody>\n")
        outFile.write("<tr>\n")

        lines = self.fileContents.split("\n")
        outFile.write("<td class='esolf_linenumbers'>\n")
        lineNumber = 1

        for line in lines:
            outFile.write("\t<div id='{0}' class='esolf_lineno'>{0}</div>".format(lineNumber))
            lineNumber += 1

        outFile.write("</td>\n")
        outFile.write("<td class='esolf_codelines'>\n")
        outFile.write("\t<div class='esolf_codeline'>")
        lineNumber = 1

        for token in tokens:
            startIndex = lastToken.charIndex + len(lastToken.token)
            endIndex = token.charIndex
            deltaString = self.fileContents[startIndex : endIndex]
            #print "{0}: {1} - {2} = '{3}'".format(lineNumber, startIndex, endIndex, deltaString)
            #print "{0}:{2} - {1}, delta='{3}'".format(lineNumber, token.token, token.linePos, deltaString)

            if (len(deltaString) > 0):
                deltaString = deltaString.replace("\t", "     ").replace(" ", "&nbsp;")
                lines = deltaString.split("\n")
                lineIndex = 0

                for line in lines:
                    if len(line) == 0:
                        outFile.write("&nbsp;")
                    else:
                        outFile.write("<code class='esolf_space'>{0}</code>".format(line))

                    if (lineIndex + 1 < len(lines)):
                        lineIndex += 1
                        outFile.write("</div>\n")
                        outFile.write("\t<div class='esolf_codeline'>")
                        
                lineNumber = token.linePos
            elif (lineNumber != token.linePos):
                outFile.write("</div>\n")
                outFile.write("\t<div class='esolf_codeline'>")
                lineNumber = token.linePos

            tooltip = ""
            
            if (token.type == Token.name):
                obj = globalData.GetGlobal(token.token)
                
                if obj is None:
                    tooltip = ""
                elif obj.type == "number" and obj.string != "":
                    tooltip = "\"{1}\"({0})".format(obj.value, obj.string)
                elif obj.type == "number":
                    tooltip = obj.value
                elif obj.type == "string":
                    tooltip = obj.value
                elif obj.type == "function":
                    tooltip = "function:" + obj.value
                elif obj.type == "userdata":
                    tooltip = "userdata:" + obj.value
                elif obj.type == "table":
                    tooltip = "table:" + obj.value

            if (tooltip == ""):
                outFile.write("<code class='esolf_{0}'>{1}</code>".format(Token.toString(token.type), token.token))
            else:
                outFile.write("<code class='esolf_{0}' tooltip='{2}'>{1}</code>".format(Token.toString(token.type), token.token, tooltip))

            lastToken = token

        outFile.write("</div>\n")    
        outFile.write("</td>\n")
        outFile.write("</tr>\n")
        outFile.write("</tbody>\n")
        outFile.write("</table>\n")
        outFile.write("</div>\n")
        return True


    def CopyHtmlResources(self, outputPath):
        shutil.copyfile("resources/esoluafile.css", os.path.join(outputPath, '') + "esoluafile.css")
        return True


    def CreateHtml(self, outputBasePath, globalData, copyResources = True):
        outputBasePath = os.path.join(outputBasePath, "").replace("\\", "/")
        outputFilename = outputBasePath + self.relFilename
        outputHtmlFilename = outputFilename  + ".html"
        path = os.path.dirname(outputFilename)

        if not os.path.exists(path):
            os.makedirs(path)

        if copyResources:
            self.CopyHtmlResources(os.path.dirname(os.path.dirname(outputBasePath)))
            
        shutil.copyfile(self.fullFilename, outputFilename)

        templateVars = self.CreateTemplateVars(globalData)
        templateVars["resourcePath"] = os.path.relpath(outputBasePath, outputFilename).replace("\\", "/")

        with open(outputHtmlFilename, "w") as outFile:
            outFile.write(self.headerTemplate.safe_substitute(templateVars))
            self.CreateHtmlContent(outFile, globalData)
            outFile.write(self.footerTemplate.safe_substitute(templateVars))
        
        return True
    
#
# filename = app/test/asd.lua
# outputPath = d:/test/esodata/src/
# resourcePath = ../../
#

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


def CreateHtmlAllFiles(esoFiles, outputBasePath, globalData):
    hasOutputResources = False

    print "Creating HTML versions of {0} Lua files...".format(len(esoFiles))

    for file in esoFiles:
        file.CreateHtml(outputBasePath, globalData, not hasOutputResources)
        hasOutputResources = True
