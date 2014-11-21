import os.path
import operator
import sys
import datetime
import shutil
from string import Template
import EsoGlobals
from EsoGlobals import CEsoGlobals
import EsoLuaFile
from EsoLuaFile import CEsoLuaFile
import EsoFunctionInfo
from EsoFunctionInfo import CEsoFunctionInfo
from EsoFunctionInfo import CEsoFunctionCallInfo
import EsoFunctionDb
from EsoFunctionDb import CEsoFunctionDb
import EsoLuaTokenizer
from EsoLuaTokenizer import Token


class CEsoEnvironment:

    def __init__(self):
        self.globalData = CEsoGlobals()
        self.luaFiles = []
        self.functionInfos = CEsoFunctionInfo()
        self.functionCallInfos = CEsoFunctionCallInfo()
        self.functionDb = CEsoFunctionDb()
        self.luaDirHeaderTemplate = Template(open('templates/esoluadir_header.txt', 'r').read())
        self.luaDirFooterTemplate = Template(open('templates/esoluadir_footer.txt', 'r').read())
        self.luaFileHeaderTemplate = Template(open('templates/esoluafile_header.txt', 'r').read())
        self.luaFileFooterTemplate = Template(open('templates/esoluafile_footer.txt', 'r').read())

        self.allFunctions = { }
        #self.allFunctionsNameMap = { }


    def AddFunction(self, funcInfo):
        
        if (not funcInfo.niceName in self.allFunctions):
            self.allFunctions[funcInfo.niceName] = []

        self.allFunctions[funcInfo.niceName].append(funcInfo)

        if (not funcInfo.name in self.allFunctions):
            self.allFunctions[funcInfo.name] = []

        self.allFunctions[funcInfo.name].append(funcInfo)


    def AddFunctionIfNew(self, name, fullName):
        niceName = fullName.replace(":", ".")
        
        if (niceName in self.allFunctions and name in self.allFunctions): return self.allFunctions[name]

        funcInfo = CEsoFunctionInfo()
        funcInfo.fullName = fullName
        funcInfo.niceName = niceName
        funcInfo.name = name

        if (not niceName in self.allFunctions):
            self.allFunctions[funcInfo.fullName] = []
            self.allFunctions[funcInfo.fullName].append(funcInfo)

        if (not name in self.allFunctions):
            self.allFunctions[funcInfo.name] = []
            self.allFunctions[funcInfo.name].append(funcInfo)

        return funcInfo


    def CreateAllFunctions(self):
        print "Creating all function records from data..."

        for funcInfo in self.functionInfos:
            self.AddFunction(funcInfo)

        for callInfo in self.functionCallInfos:
            self.AddFunctionIfNew(callInfo.name, callInfo.fullName)

        for func in self.globalData.allFunctions:
            self.AddFunctionIfNew(func.name, func.fullName)

        count = 0
        
        for funcs in self.allFunctions:
            count += len(funcs)
                
        print "\tFound {0} unique function names with {1} total functions!".format(len(self.allFunctions), count)
        return True


    def LoadGlobals(self, filename):
        self.globalData = EsoGlobals.LoadGlobals(filename)


    def LoadLuaFiles(self, path):
        self.luaFiles = EsoLuaFile.LoadAllFiles(path, path)
        
        self.functionInfos = EsoFunctionInfo.FindAllFunctions(self.luaFiles)
        self.functionCallInfos = EsoFunctionInfo.FindAllFunctionCalls(self.luaFiles)
        
        self.functionDb = EsoFunctionDb.CreateDb(self.functionInfos, self.functionCallInfos)
        self.functionDb.CreateFunctionValueMap(self.globalData)
        self.functionDb.MatchGlobals(self.globalData)

        self.CreateAllFunctions()


    def CreateGlobalTemplateVars(self):
        templateVars = { }
        
        templateVars["parseTime"] = self.globalData.parseTime
        templateVars["parseDate"] = self.globalData.parseDate
        templateVars["parseVersion"] = self.globalData.parseVersion
        templateVars["creationDate"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        return templateVars

    
    def CreateLuaFileTemplateVars(self, luaFile):
        templateVars = self.CreateGlobalTemplateVars()

        templateVars["filename"] = luaFile.relFilename
        templateVars["fullFilename"] = luaFile.fullFilename
        templateVars["creationDate"] = luaFile.creationDate
        templateVars["numTokens"] = str(len(luaFile.tokenizer.tokens))
        templateVars["resourcePath"] = ""

        return templateVars
        

    def CreateLuaFileHtmlContent(self, outFile, luaFile):
        tokens = luaFile.tokenizer.tokensWithComments
                
        lastToken = EsoLuaTokenizer.CLuaToken()
        lastToken.linePos = 1
        lastToken.charPos = 0
        lastToken.charIndex = 0

        outFile.write("<div id='esolf_fileroot'>\n")
        outFile.write("<table border='0' cellpadding='0' cellspacing='0'>\n")
        outFile.write("<tbody>\n")
        outFile.write("<tr>\n")

        lines = luaFile.fileContents.split("\n")
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
            deltaString = luaFile.fileContents[startIndex : endIndex]
            #print "{0}: {1} - {2} = '{3}'".format(lineNumber, startIndex, endIndex, deltaString)
            #print "{0}:{2} - {1}, delta='{3}'".format(lineNumber, token.token, token.linePos, deltaString)

            if (len(deltaString) > 0):
                deltaString = deltaString.replace("\t", "     ").replace(" ", "&nbsp;")
                lines = deltaString.split("\n")
                lineIndex = 0

                for line in lines:
                    if len(line) != 0:
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
                obj = self.globalData.GetGlobal(token.token)
                
                if obj is None:
                    tooltip = ""
                elif obj.type == "number" and obj.string != "":
                    tooltip = "({0})\"{1}\"".format(obj.value, obj.string)
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

                if len(tooltip) > 100: tooltip = tooltip[:100] + "..."
                tooltip = tooltip.replace(">", "&gt;").replace("<", "&lt;")

            outputText = token.token.replace(">", "&gt;").replace("<", "&lt;")

            if (tooltip == ""):
                outFile.write("<code class='esolf_{0}'>{1}</code>".format(Token.toString(token.type), outputText))
            else:
                outFile.write("<code class='esolf_{0}' tooltip='{2}'>{1}</code>".format(Token.toString(token.type), outputText, tooltip))

            lastToken = token

        outFile.write("</div>\n")    
        outFile.write("</td>\n")
        outFile.write("</tr>\n")
        outFile.write("</tbody>\n")
        outFile.write("</table>\n")
        outFile.write("</div>\n")
        return True


    def CopyLuaFileHtmlResources(self, outputPath):
        shutil.copyfile("resources/esoluafile.css", os.path.join(outputPath, '') + "esoluafile.css")
        return True


    def CreateLuaFileHtml(self, luaFile, outputBasePath, copyResources = True):
        outputBasePath = os.path.join(outputBasePath, "").replace("\\", "/")
        outputFilename = outputBasePath + luaFile.relFilename
        outputHtmlFilename = outputFilename  + ".html"
        path = os.path.dirname(outputFilename)
        if not os.path.exists(path): os.makedirs(path)

        if copyResources:
            self.CopyLuaFileHtmlResources(os.path.dirname(os.path.dirname(outputBasePath)))
            
        shutil.copyfile(luaFile.fullFilename, outputFilename)

        templateVars = self.CreateLuaFileTemplateVars(luaFile)
        templateVars["resourcePath"] = os.path.relpath(outputBasePath, outputFilename).replace("\\", "/")

        with open(outputHtmlFilename, "w") as outFile:
            outFile.write(self.luaFileHeaderTemplate.safe_substitute(templateVars))
            self.CreateLuaFileHtmlContent(outFile, luaFile)
            outFile.write(self.luaFileFooterTemplate.safe_substitute(templateVars))
        
        return True


    def CreateLuaFilesHtml(self, outputBasePath):
        hasOutputResources = False
        print "Creating HTML versions of {0} Lua files...".format(len(self.luaFiles))

        for luaFile in self.luaFiles:
            self.CreateLuaFileHtml(luaFile, outputBasePath, not hasOutputResources)
            hasOutputResources = True


    def OutputLuaFilesDirTree(self, root, outputBasePath, parentPath):
        outputDirs = ""
        outputFiles = ""
        if (parentPath != ""): outputDirs += "<li><a href='../luadir.html'>[dir] ..</a></li>\n"
        sortedKeys = sorted(root.keys())

        for key in sortedKeys:
            entry = root[key]

            if (type(entry) is dict):
                link = "<a href='{0}/luadir.html'>[dir] {0}</a>".format(key)
                outputDirs += "<li class='esold_dir'>{0}</li>\n".format(link)
                self.OutputLuaFilesDirTree(entry, outputBasePath, parentPath + key + "/")
            else:
                link = "<a href='{0}.html'>{0}</a>".format(key)
                outputFiles += "<li class='esold_file'>{0}</li>\n".format(link)

        filename = os.path.join(outputBasePath, parentPath, '') + "luadir.html"
        path = os.path.dirname(filename)
        if not os.path.exists(path): os.makedirs(path)

        templateVars = self.CreateGlobalTemplateVars()
        templateVars["resourcePath"] = os.path.relpath(os.path.dirname(os.path.dirname(outputBasePath)), path).replace("\\", "/")
        templateVars["luaPath"] = parentPath
        
        with open(filename, "w") as outFile:
            outFile.write(self.luaDirHeaderTemplate.safe_substitute(templateVars))
            outFile.write("<ul class='esold_list'>\n")
            outFile.write(outputDirs)
            outFile.write(outputFiles)
            outFile.write("</ul>\n")
            outFile.write(self.luaDirFooterTemplate.safe_substitute(templateVars))


    def CreateLuaFilesDirTree(self, outputBasePath):
        rootFiles = { }

        print "Creating the Lua files directory tree to {0}...".format(outputBasePath)

        outputBasePath = os.path.join(outputBasePath, "").replace("\\", "/")
        if not os.path.exists(outputBasePath): os.makedirs(outputBasePath)

                # Create the directory/file tree
        for luaFile in self.luaFiles:
            split = luaFile.relFilename.split("/")
            paths = split[:-1]
            filename = split[-1]
            root = rootFiles

            #print "{0} ==> '{1}' + {2}".format(luaFile.relFilename, paths, filename)

            for path in paths:
                if (not path in root): root[path] = { }
                root = root[path]

            root[filename] = luaFile

        #print rootFiles
        shutil.copyfile("resources/esoluadir.css", os.path.dirname(os.path.dirname(os.path.join(outputBasePath, ''))) + "/esoluadir.css")
        self.OutputLuaFilesDirTree(rootFiles, outputBasePath, "")
        

        
            



