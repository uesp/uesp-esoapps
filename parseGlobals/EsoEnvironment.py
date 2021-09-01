import os.path
import operator
import sys
import datetime
import shutil
from shutil import copyfile
import re
import string
from operator import attrgetter
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

    def __init__(self, searchEngineID = ""):
        self.globalData = CEsoGlobals()
        self.inputPath = ""
        self.luaFiles = []
        self.otherFiles = {}
        self.functionInfos = CEsoFunctionInfo()
        self.functionCallInfos = CEsoFunctionCallInfo()
        self.functionDb = CEsoFunctionDb()
        self.luaDirHeaderTemplate = Template(open('templates/esoluadir_header.txt', 'r').read())
        self.luaDirFooterTemplate = Template(open('templates/esoluadir_footer.txt', 'r').read())
        self.luaFileHeaderTemplate = Template(open('templates/esoluafile_header.txt', 'r').read())
        self.luaFileFooterTemplate = Template(open('templates/esoluafile_footer.txt', 'r').read())
        self.functionHeaderTemplate = Template(open('templates/esofunction_header.txt', 'r').read())
        self.functionFooterTemplate = Template(open('templates/esofunction_footer.txt', 'r').read())
        self.mainHeaderTemplate = Template(open('templates/esomain_header.txt', 'r').read())
        self.mainContentTemplate = Template(open('templates/esomain_content.txt', 'r').read())
        self.mainFooterTemplate = Template(open('templates/esomain_footer.txt', 'r').read())
        self.mainFuncHeaderTemplate = Template(open('templates/esomainfunc_header.txt', 'r').read())
        self.mainFuncFooterTemplate = Template(open('templates/esomainfunc_footer.txt', 'r').read())
        self.globalHeaderTemplate = Template(open('templates/esoglobal_header.txt', 'r').read())
        self.globalFooterTemplate = Template(open('templates/esoglobal_footer.txt', 'r').read())
        self.apiVersionTemplate = Template(open('templates/esoapiversion_main.txt', 'r').read())
        
        self.googleSearchEngineID = searchEngineID

        if searchEngineID == "":
            self.searchHeaderTemplate = ""
        else:
            self.searchHeaderTemplate = Template(open('templates/esosearch_header.txt', 'r').read())        

        self.luaFileOutputPath = ""
        self.functionOutputPath = ""
        self.outputPath = ""
        

        self.INVALID_FUNCNAME_CHARS = "[*?|:<>\/()\[\]\"\']"

        self.allFunctions = { }
        self.functionValueMap = { }
        self.functionNameValueMap = { }
        self.functionLetterCounts = { }


    def GetFunctionNameAliases(self, funcName):
        funcName = funcName.replace(":", ".")
        if (funcName not in self.functionNameValueMap): return []
        funcValue = self.functionNameValueMap[funcName]
        if (funcValue not in self.functionValueMap): return []
        return self.functionValueMap[funcValue]
    

    def CreateFunctionValueMap(self):
        print "Creating function value map..."
        
        matchCount = 0
        missCount = 0

        for obj in self.globalData.allFunctions:
            self.functionNameValueMap[obj.fullName] = obj.value
            
            if (obj.fullName in self.allFunctions):
                matchCount += 1
                funcInfos = self.allFunctions[obj.fullName]
                globalFuncs = []

                for func in funcInfos:
                    if not func.isLocal:
                        func.value = obj.value
                        globalFuncs.append(func)

                if (not obj.value in self.functionValueMap):
                    self.functionValueMap[obj.value] = []

                self.functionValueMap[obj.value].extend(globalFuncs)
            else:
                missCount += 1
        
        print "\tSet values of {0} functions with {1} misses!".format(matchCount, missCount)


    def AddFunction(self, funcInfo):
        
        if (not funcInfo.niceName in self.allFunctions):
            self.allFunctions[funcInfo.niceName] = []

        self.allFunctions[funcInfo.niceName].append(funcInfo)

        if (funcInfo.niceName == funcInfo.name): return

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
            self.allFunctions[niceName] = []
            self.allFunctions[niceName].append(funcInfo)

        if (niceName == name): return funcInfo

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


    def SanitizeFunctionName(self, funcName):
        return re.sub( self.INVALID_FUNCNAME_CHARS, "_", funcName)


    def GetFunctionNameSubPath(self, funcName):
        if (len(funcName) < 3): return ""
        funcName = self.SanitizeFunctionName(funcName)
        return funcName[0].lower() + "/" + funcName[1].lower() + "/" + funcName[2].lower()


    def CreateLuaFileLink(self, outputPath, filename, linePos = None):
        relPath = os.path.join(os.path.relpath(self.luaFileOutputPath, outputPath), "").replace("\\", "/")
        link = ""
        
        if (linePos is None or linePos <= 0):
            link = "<a href='{1}{0}' class='eso_filelink'>{0}</a>".format(filename, relPath)
        else:
            link = "<a href='{2}{0}.html#{1}' class='eso_filelink'>{0}:{1}</a>".format(filename, linePos, relPath)
            
        return link


    def CreateLuaFunctionLink(self, outputPath, niceName, funcName, includeBrackets = True):
        niceName = self.SanitizeFunctionName(niceName)
        subPath = self.GetFunctionNameSubPath(niceName)
        targetPath = os.path.join(self.functionOutputPath, subPath)
        relPath = os.path.relpath(targetPath, outputPath)
        relPath = os.path.join(relPath, "").replace("\\", "/")

        if includeBrackets and not funcName.endswith(")") : funcName += "()"
        link = "<a href='{0}{1}.html' class='eso_functionlink'>{2}</a>".format(relPath, niceName, funcName)
        return link
    

    def CreateFunctionHtmlContent(self, outFile, funcName, functions, outputPath):
        funcAliasCount = 0
        funcGlobalDefCount = 0
        funcLocalDefCount = 0
        funcCallCount = 0

        funcParts = filter(None, re.split("[.:\[\]]+", funcName))

        if (len(funcParts) > 0 and funcParts[-1] != funcName):
            funcLink = self.CreateLuaFunctionLink(outputPath, funcParts[-1], funcParts[-1])
            outFile.write("<div class='esofn_seealso'>See also: {0}</div>".format(funcLink))
        
        outFile.write("<h3 id='esofn_aliases'>Function Aliases</h3>\n")
        outFile.write("<ul class='esofn_aliaslist'>\n")

        aliases = self.GetFunctionNameAliases(funcName)

        for func in aliases:
            if (func.fullName != funcName):
                funcAliasCount += 1
                funcLink = self.CreateLuaFunctionLink(outputPath, func.niceName, func.fullName)
                outFile.write("<li>{0}</li>\n".format(funcLink))

        if (funcAliasCount == 0):
            outFile.write("<li>No known aliases for this function.</li>\n")

        outFile.write("</ul>\n")
        outFile.write("<h3 id='esofn_globaldefs'>Global Function Definitions</h3>\n")
        outFile.write("<ul class='esofn_deflist'>\n")

        for func in functions:
            if (func.filename == ""): continue
            if (func.isLocal): continue
            funcGlobalDefCount += 1
            fileLink = self.CreateLuaFileLink(outputPath, func.filename, func.startLinePos)

            if (funcName == func.niceName):
                funcLink = "<div class='eso_functionlink'>{0}</div>".format(func.fullDefString)
            else:
                funcLink = self.CreateLuaFunctionLink(outputPath, func.niceName, func.fullDefString)
                
            outFile.write("<li>{0} -- {1}</li>\n".format(fileLink, funcLink))

        if (funcGlobalDefCount == 0):
            outFile.write("<li>No known global definitions for this function.</li>\n")
       
        outFile.write("</ul>\n")
        outFile.write("<h3 id='esofn_localdefs'>Local Function Definitions</h3>\n")
        outFile.write("<ul class='esofn_deflist'>\n")
        
        for func in functions:
            if (func.filename == ""): continue
            if (not func.isLocal): continue
            funcLocalDefCount += 1
            fileLink = self.CreateLuaFileLink(outputPath, func.filename, func.startLinePos)

            if (funcName == func.niceName):
                funcLink = "<div class='eso_functionlink'>{0}</div>".format(func.fullDefString)
            else:
                funcLink = self.CreateLuaFunctionLink(outputPath, func.niceName, func.fullDefString)
                
            outFile.write("<li>{0} -- {1}</</li>\n".format(fileLink, funcLink))

        if (funcLocalDefCount == 0):
            outFile.write("<li>No known local definitions for this function.</li>\n")
       
        outFile.write("</ul>\n")
        outFile.write("<h3 id='esofn_calls'>Function Calls</h3>\n")
        outFile.write("<ul class='esofn_calllist'>\n")

        funcParts = re.split("[:.]+", funcName)
        lastFuncName = funcName
        if len(funcParts) >= 1: lastFuncName = funcParts[-1]
        
        funcCalls = self.functionDb.GetFunctionCalls(lastFuncName)
        
        for call in funcCalls:
            if lastFuncName != funcName and call.niceName != funcName: continue
            
            funcCallCount += 1
            fileLink = self.CreateLuaFileLink(outputPath, call.filename, call.startLinePos)

            if (call.niceName == funcName):
                funcLink = "<div class='eso_functionlink'>{0}</div>".format(call.fullString)
            else:
                funcLink = self.CreateLuaFunctionLink(outputPath, call.niceName, call.fullString)
                
            outFile.write("<li>{0} -- {1}</li>\n".format(fileLink, funcLink))

        if (funcCallCount == 0):
            outFile.write("<li>No known calls of this function.</li>\n")

        outFile.write("</ul>\n")


    def CreateFunctionHtml(self, outputBasePath, funcName, functions):
        niceName = self.SanitizeFunctionName(funcName)
        outputBasePath = os.path.join(outputBasePath, "").replace("\\", "/")
        outputPath = os.path.join(outputBasePath, self.GetFunctionNameSubPath(niceName), "").replace("\\", "/")
        outputFilename = outputPath + niceName + ".html"

        if (not os.path.exists(outputPath)): os.makedirs(outputPath)

        templateVars = self.CreateGlobalTemplateVars()
        templateVars["name"] = funcName + "()"
        templateVars["resourcePath"] = os.path.relpath(outputBasePath, outputFilename).replace("\\", "/")
				
        with open(outputFilename, "w") as outFile:
            outFile.write(self.functionHeaderTemplate.safe_substitute(templateVars))
            outFile.write(self.searchHeaderTemplate.safe_substitute(templateVars))
            self.CreateFunctionHtmlContent(outFile, funcName, functions, outputPath)
            outFile.write(self.functionFooterTemplate.safe_substitute(templateVars))


    def CopyResources(self, outputPath):
        if (not os.path.exists(outputPath)): os.makedirs(outputPath)

        for root, dirs, files in os.walk("resources"):
            for filename in files:
                fullFilename = root + "/" + filename
                shutil.copyfile(fullFilename, os.path.join(outputPath, "") + filename)
            

    def CreateAllFunctionHtml(self, outputBasePath):
        self.functionOutputPath = outputBasePath.replace("\\", "/")
        print "Creating all function HTML files in {0}...".format(outputBasePath)

        if (not os.path.exists(outputBasePath)): os.makedirs(outputBasePath)
        funcIndex = 0

        for funcName in self.allFunctions:
            funcs = self.allFunctions[funcName]
            self.CreateFunctionHtml(outputBasePath, funcName, funcs)

            funcIndex += 1
            if funcIndex % 1000 == 0: print "\tCreated {0} of {1} function files".format(funcIndex, len(self.allFunctions))


    def LoadGlobals(self, filename):
        self.globalData = EsoGlobals.LoadGlobals(filename)


    def LoadLuaFiles(self, path):
        self.inputPath = path
        self.luaFiles = EsoLuaFile.LoadAllFiles(path, path)

        self.otherFiles = self.FindOtherFiles(path)
        
        self.functionInfos = EsoFunctionInfo.FindAllFunctions(self.luaFiles)
        self.functionCallInfos = EsoFunctionInfo.FindAllFunctionCalls(self.luaFiles)

        self.functionDb = EsoFunctionDb.CreateDb(self.functionInfos, self.functionCallInfos)
        self.functionDb.MatchGlobals(self.globalData)

        self.CreateAllFunctions()
        self.CreateFunctionValueMap()


    def CreateGlobalTemplateVars(self, types = []):
        templateVars = { }
        
        templateVars["parseTime"] = self.globalData.parseTime
        templateVars["parseDate"] = self.globalData.parseDate
        templateVars["parseVersion"] = self.globalData.parseVersion
        templateVars["creationDate"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        templateVars['types'] = ", ".join(types) if types else "all"
        templateVars['googleSearchEngineID'] = self.googleSearchEngineID
        templateVars["resourcePath"] = ""
        templateVars["homeUrl"] = "/" + self.globalData.parseVersion

        return templateVars

    
    def CreateLuaFileTemplateVars(self, luaFile):
        templateVars = self.CreateGlobalTemplateVars()

        templateVars["filename"] = luaFile.relFilename
        templateVars["fullFilename"] = luaFile.fullFilename
        templateVars["creationDate"] = luaFile.creationDate
        templateVars["numTokens"] = str(len(luaFile.tokenizer.tokens))
        templateVars["resourcePath"] = ""
        templateVars["homeUrl"] = "/" + self.globalData.parseVersion

        return templateVars
        

    def CreateLuaFileHtmlContent(self, outFile, luaFile, outputPath):
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
            outFile.write("\t<div class='esolf_lineno'>{0}</div>".format(lineNumber))
            lineNumber += 1

        outFile.write("</td>\n")
        outFile.write("<td class='esolf_codelines'>\n")
        outFile.write("\t<div id='1' class='esolf_codeline'>")
        lineNumber = 1

        for token in tokens:
            startIndex = lastToken.charIndex + len(lastToken.token)
            endIndex = token.charIndex
            deltaString = luaFile.fileContents[startIndex : endIndex]

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
                        outFile.write("\t<div id='{0}' class='esolf_codeline'>".format(lineNumber + lineIndex))
                        
                lineNumber = token.linePos
            elif (lineNumber != token.linePos):
                lineNumber = token.linePos
                outFile.write("</div>\n")
                outFile.write("\t<div id='{0}' class='esolf_codeline'>".format(lineNumber))

            tooltip = ""
            outputText = token.token.replace(">", "&gt;").replace("<", "&lt;")
            
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

                if (token.token in self.allFunctions):
                    outputText = self.CreateLuaFunctionLink(outputPath, token.token, token.token, False)

                    # Output multi-line comments        
            elif (token.type == Token.comment):
                lines = outputText.split("\n")
                lineIndex = 0

                while lineIndex + 1 < len(lines):
                    line = lines[lineIndex]
                    lineIndex += 1
                    outFile.write("<code class='esolf_{0}'>{1}</code>".format("comment", line))
                    outFile.write("</div>\n")
                    outFile.write("\t<div id='{0}' class='esolf_codeline'>".format(lineNumber + lineIndex))
                    
                outputText = lines[-1]

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


    def CreateLuaFileHtml(self, luaFile, outputBasePath):
        outputBasePath = os.path.join(outputBasePath, "").replace("\\", "/")
        outputFilename = outputBasePath + luaFile.relFilename
        outputHtmlFilename = outputFilename  + ".html"
        
        path = os.path.dirname(outputFilename)
        if not os.path.exists(path): os.makedirs(path)
        
        templateVars = self.CreateLuaFileTemplateVars(luaFile)
        templateVars["resourcePath"] = os.path.relpath(outputBasePath, outputFilename).replace("\\", "/")

        with open(outputHtmlFilename, "w") as outFile:
            outFile.write(self.luaFileHeaderTemplate.safe_substitute(templateVars))
            outFile.write(self.searchHeaderTemplate.safe_substitute(templateVars))
            self.CreateLuaFileHtmlContent(outFile, luaFile, path)
            outFile.write(self.luaFileFooterTemplate.safe_substitute(templateVars))
        
        return True


    def CreateLuaFilesHtml(self, outputBasePath):
        print "Creating HTML versions of {0} Lua files...".format(len(self.luaFiles))
        self.luaFileOutputPath = outputBasePath.replace("\\", "/")
        
        for luaFile in self.luaFiles:
            self.CreateLuaFileHtml(luaFile, outputBasePath)


    def SetOutputPath(self, outputPath):
        self.luaFileOutputPath = os.path.join(outputPath, "src", "").replace("\\", "/")
        self.functionOutputPath = os.path.join(outputPath, "data", "").replace("\\", "/")
        

    def FindOtherFiles(self, path):
        otherFiles = {}
        count = 0

        print "Finding other files from", path, "..."
    
        for root, dirs, files in os.walk(path):
            rootFiles = otherFiles
            basePath = root[len(path):]
            print "Root = ", basePath
            print "Dirs = ", dirs
            # print "Files = ", files

            thisDirs = basePath.split("/")

            for dirName in thisDirs:
                if (not dirName in rootFiles):
                    rootFiles[dirName] = {}
                    
                rootFiles = rootFiles[dirName]

            if (not "__files" in rootFiles):
                rootFiles["__files"] = []
            
            for filename in files:
                if (filename.endswith(".xml") or filename.endswith(".txt")):
                    rootFiles["__files"].append(filename)
                    count = count + 1
            

        print "\tFound {0} other files!".format(count)
        return otherFiles
        

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
            elif not (type(entry) is str):
                link = "<a href='{0}.html'>{0}</a> <a href='{0}'><small>(raw)</small></a>".format(key)
                outputFiles += "<li class='esold_file'>{0}</li>\n".format(link)
            else:
                link = "<a href='{0}'>{0}</a>".format(key)
                outputFiles += "<li class='esold_file'>{0}</li>\n".format(link)

        filename = os.path.join(outputBasePath, parentPath, '') + "luadir.html"
        path = os.path.dirname(filename)
        if not os.path.exists(path): os.makedirs(path)

        templateVars = self.CreateGlobalTemplateVars()
        templateVars["resourcePath"] = os.path.relpath(os.path.dirname(os.path.dirname(outputBasePath)), path).replace("\\", "/")
        templateVars["luaPath"] = parentPath
        
        with open(filename, "w") as outFile:
            outFile.write(self.luaDirHeaderTemplate.safe_substitute(templateVars))
            outFile.write(self.searchHeaderTemplate.safe_substitute(templateVars))
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

        self.CreateLuaOtherFilesDirTree(rootFiles, self.otherFiles)

        #print rootFiles
        self.OutputLuaFilesDirTree(rootFiles, outputBasePath, "")


    def CreateLuaOtherFilesDirTree(self, rootFiles, otherFiles):

        if "__files" in otherFiles:
            for filename in otherFiles["__files"]:
                rootFiles[filename] = filename

        for pathname in otherFiles:
            if (pathname != "__files"):
                
                if not pathname in rootFiles:
                    rootFiles[pathname] = { }
                    
                self.CreateLuaOtherFilesDirTree(rootFiles[pathname], otherFiles[pathname])


    def CountFunctionLetters(self):
        self.functionLetterCounts = { }
        letters = self.GetFunctionHeaderLetters()

        for letter in letters:
            self.functionLetterCounts[letter] = 0

        for funcName in self.allFunctions:
            
            if len(funcName) < 1:
                self.functionLetterCounts['_'] += 1
            elif funcName[0] in self.INVALID_FUNCNAME_CHARS:
                self.functionLetterCounts['_'] += 1
            else:
                letter = funcName[0].upper()
                if letter not in self.functionLetterCounts: self.functionLetterCounts[letter] = 0
                self.functionLetterCounts[letter] += 1


    def GetFunctionHeaderLetters(self):
        return "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"


    def CreateFunctionLetterHeader(self, currentLetter = ""):
        letters = self.GetFunctionHeaderLetters()
        result = ""

        if currentLetter == "":
            result += "<a tooltip='{1}'>{0}</a>".format("All", len(self.allFunctions))
        else:
            result += "<a href='functions.html' tooltip='{1}'>{0}</a>".format("All", len(self.allFunctions))

        for letter in letters:
            if (letter == currentLetter):
                result += "<a tooltip='{1}'>{0}</a>".format(letter, self.functionLetterCounts[letter])
            else:
                result += "<a href='functions_{0}.html' tooltip='{1}'>{0}</a>".format(letter, self.functionLetterCounts[letter])

        return result
            

    def CreateAllFunctionPages(self, outputPath):
        print "Creating all function pages to", outputPath
        self.CountFunctionLetters()
        self.CreateFunctionPage(outputPath)

        for letter in self.functionLetterCounts:
            self.CreateFunctionPage(outputPath, letter)


    def CreateFunctionPageContent(self, outFile, outputPath, letter = ""):
        firstLetter = ""

        outFile.write("<ul class='esofn_funclist'>\n")

        for funcName in sorted(self.allFunctions):
                            
            if len(funcName) < 1:
                firstLetter = "_"
            elif funcName[0] in self.INVALID_FUNCNAME_CHARS:
                firstLetter = "_"
            else:
                firstLetter = funcName[0].upper()

            if letter != "" and firstLetter != letter: continue
        
            funcLink = self.CreateLuaFunctionLink(outputPath, funcName, funcName)
            outFile.write("<li>{0}</li>\n".format(funcLink))

        outFile.write("</ul>\n")        


    def CreateFunctionPage(self, outputPath, letter = ''):
        templateVars = self.CreateGlobalTemplateVars()
        templateVars["funcLetter"] = letter
        templateVars["letterHeader"] = self.CreateFunctionLetterHeader(letter)

        filename = "functions_{0}.html".format(letter)

        if (letter == ""):
            templateVars["funcLetter"] = "All"
            filename = "functions.html"
            
        outputFilename = os.path.join(outputPath, filename).replace("\\", "/")

        with open(outputFilename, "w") as outFile:
            outFile.write(self.mainFuncHeaderTemplate.safe_substitute(templateVars))
            outFile.write(self.searchHeaderTemplate.safe_substitute(templateVars))
            self.CreateFunctionPageContent(outFile, outputPath, letter)
            outFile.write(self.mainFuncFooterTemplate.safe_substitute(templateVars))


    def CreateMainPage(self, outputPath):
        templateVars = self.CreateGlobalTemplateVars()
        templateVars["funcCount"] = len(self.allFunctions)
        templateVars["localFuncCount"] = len(self.functionDb.localFunctions)
        templateVars["globalFuncCount"] = len(self.functionDb.globalFunctions)
        templateVars["funcCallCount"] = len(self.functionDb.functionCalls)
        templateVars["globalObjectCount"] = self.globalData.globalObjectCount
        templateVars["luaFileCount"] = len(self.luaFiles)
        templateVars["globalDupFuncCount"] = self.globalData.globalDupFuncCount
        templateVars["missingFuncCount"] = self.functionDb.missingFuncCount
        templateVars["unusedFuncCount"] = self.functionDb.unusedFuncCount

        outputFilename = os.path.join(outputPath, "index.html").replace("\\", "/")

        with open(outputFilename, "w") as outFile:
            outFile.write(self.mainHeaderTemplate.safe_substitute(templateVars))
            outFile.write(self.searchHeaderTemplate.safe_substitute(templateVars))
            outFile.write(self.mainContentTemplate.safe_substitute(templateVars))
            outFile.write(self.mainFooterTemplate.safe_substitute(templateVars))
        

    def CreateAll(self, outputPath):
        self.outputPath = outputPath
        self.SetOutputPath(outputPath)
        self.CopyResources(outputPath)

        self.globalData.Dump(outputPath + "globals.txt")
        self.CreateGlobalHtml(outputPath + "globals.html")
        self.globalData.DumpDuplicateFunctions(outputPath + "globaldupfuncs.txt")

        self.functionDb.DumpFunctionCalls(outputPath + "functioncalls.txt")
        self.functionDb.DumpGlobalFunctions(outputPath + "globalfuncs.txt")
        self.functionDb.DumpLocalFunctions(outputPath + "localfuncs.txt")
        self.functionDb.DumpMissingFunctions(outputPath + "missingfuncs.txt", self.globalData)
        self.functionDb.DumpUnusedFunctions(outputPath + "unusedfunc.txt", self.globalData)

        self.CopyRawFiles(outputPath + "src\\")
            
        self.CreateLuaFilesHtml(outputPath + "src\\")
        self.CreateLuaFilesDirTree(outputPath + "src\\")
        self.CreateAllFunctionPages(outputPath)
        self.CreateAllFunctionHtml(outputPath + "data\\")

        self.CreateApiVersionHtml(outputPath + "api.html")
        self.CreateMainPage(outputPath)


    def CopyRawFiles(self, outputPath):
    
        if not os.path.exists(outputPath):
            os.makedirs(outputPath)
    
        self.CopyRawFiles_OtherFiles(self.inputPath, outputPath, self.otherFiles)
        self.CopyRawFiles_LuaFiles(self.inputPath, outputPath, self.luaFiles)


    def CopyRawFiles_LuaFiles(self, inputPath, outputPath, luaFiles):
    
        for luaFile in self.luaFiles:
            filename = os.path.basename(luaFile.relFilename)
            path = os.path.dirname(luaFile.relFilename)

            destPath = outputPath + path + "\\"
            destFilename = destPath + filename
            srcFilename = inputPath + path + "\\" + filename

            if not os.path.exists(destPath):
                os.makedirs(destPath)

            print "Copying {0} to {1}...".format(srcFilename, destFilename)
            copyfile(srcFilename, destFilename)

    
    def CopyRawFiles_OtherFiles(self, inputPath, outputPath, otherFiles):
    
        if not os.path.exists(outputPath):
            os.makedirs(outputPath)

        if ("__files" in otherFiles):
            for filename in otherFiles["__files"]:
                destFilename = outputPath + filename
                srcFilename = inputPath + filename
                print "Copying {0} to {1}...".format(srcFilename, destFilename)
                copyfile(srcFilename, destFilename)

        for pathname in otherFiles:
            if (pathname != "__files"):
                print "Copying files from {0}...".format(pathname)
                self.CopyRawFiles_OtherFiles(inputPath + pathname + "\\", outputPath + pathname + "\\", otherFiles[pathname])
        

    def CreateGlobalHtmlRecord(self, outFile, root, lineHeader, level, parentName, types = None):
        sortedKeys = sorted(root.keys())

        for key in sortedKeys:
            obj = root[key]

            if (types and not obj.type in types):
                continue

            if (parentName == ""):
                completeName = obj.name
            else:
                completeName = parentName + "." + obj.name
            
            metaName = ""
            tableName = ""
            indexName = ""
            tableLink = ""
            metaLink = ""
            indexLink = ""
            accessClass = ""

            if (obj.firstTable):
                tableName = "table_" + obj.value
                outFile.write("<a name=\"{0}\" />\n".format(tableName))
            else:
                tableLink = " <a class=\"esog_table\" href=\"#table_{0}\">table:{0}</a>".format(obj.value)

            if (obj.firstMeta and obj.meta != ""):
                metaLink = " <div class=\"esog_meta\">meta:" + obj.meta + "</div>"
                metaName = "meta_" + obj.meta
                outFile.write("<a name=\"{0}\" />\n".format(metaName))
            elif (obj.meta != ""):
                metaLink = " <a class=\"esog_meta\" href=\"#meta_{0}\">meta:{0}</a>".format(obj.meta)

            if (obj.firstIndex and obj.index != ""):
                indexLink = " <div class=\"esog_index\">index:" + obj.index + "</div>"
                indexName = "index_" + obj.index
                outFile.write("<a name=\"{0}\" />\n".format(indexName))
            elif (obj.index != ""):
                indexLink = " <a class=\"esog_index\" href=\"#index_{0}\">index:{0}</a>".format(obj.index)

            if (obj.access == "Private"):
                accessClass = " esog_private"

            outFile.write(lineHeader + "<div class=\"esog_section{0}\" title=\"{1}\">\n".format(level, completeName))
            thisTitle = obj.name
            
            if (obj.type == "table"):
                
                if (tableLink == ""):
                    thisTitle += " = <div class='esog_table'>" + obj.type + ":" + obj.value + tableLink + "</div>"
                else:
                    thisTitle += " = <div class='esog_table'>" + tableLink + "</div>"
                    
            elif (obj.type == "function"):
                thisTitle = self.CreateLuaFunctionLink(self.outputPath, obj.name, obj.name)
                thisTitle += " = <div class='esog_function'>" + obj.type + ":" + obj.value + metaLink + "</div>"
                #thisTitle = "<a href=\"{1}\">{0}</a>".format(obj.name, GetFunctionLinkName(completeName))
                #thisTitle += "() = <div class='esog_function'>" + obj.type + ":" + obj.value + metaLink + "</div>"
            elif (obj.type == "userdata"):
                thisTitle += " = <div class='esog_userdata'>" + obj.type + ":" + obj.value + metaLink + indexLink + "</div>"
            elif (obj.type == "number" and obj.name.startswith("SI_")):
                thisTitle += " (" + obj.value + ") = \"" + obj.string + "\""
            elif (obj.access == "Private"):
                thisTitle += " = Private"
            elif (obj.type == "number"):
                thisTitle += " = <div class='esog_number'>" + obj.value + "</div>"
            elif (obj.type == "string"):
                thisTitle += " = <div class='esog_string'>\"" + obj.value + "\"</div>"
            else:
                thisTitle += " = " + obj.value
            
            outFile.write(lineHeader + "\t<div class=\"esog_title{1}\">{0}</div>".format(thisTitle, accessClass))
            outFile.write("\n")

            outFile.write(lineHeader + "\t<div class=\"esog_children\">\n")
            self.CreateGlobalHtmlRecord(outFile, obj.children, lineHeader + "\t", level+1, completeName, None)
            outFile.write(lineHeader + "\t</div>\n")
            
            outFile.write("</div>\n")
            

    def CreateGlobalHtml(self, filename, types = []):
        print "Creating global Html file", filename, "..."
        templateVars = self.CreateGlobalTemplateVars(types)

        with open(filename, "w") as outFile:
            outFile.write(self.globalHeaderTemplate.safe_substitute(templateVars))
            outFile.write(self.searchHeaderTemplate.safe_substitute(templateVars))
            self.CreateGlobalHtmlRecord(outFile, self.globalData.globals, "", 1, "", types)
            outFile.write(self.globalFooterTemplate.safe_substitute(templateVars))


    def CreateApiVersionHtml(self, filename):
        print "Creating API version Html file", filename, "..."

        apiVersionHistory = open("templates/esoapiversion_history.txt", "r").read()
        apiLines = apiVersionHistory.split("\n")
        apiVersion = self.globalData.parseVersion
        foundLineIndex = -1
        i = 0

        while i < len(apiLines):
            if apiLines[i].find(apiVersion) >= 0:
                foundLineIndex = i
                break
            
            i += 1

        newLine = "<li><a href='{0}/'><b>v{0}</b></a> -- Created on {1}</li>".format(apiVersion, self.globalData.creationDate)

        if foundLineIndex >= 0:
            apiLines[foundLineIndex] = newLine
        else:
            apiLines.append(newLine)

        apiVersionHistory = "\n".join(apiLines)
        open("templates/esoapiversion_history.txt", "w").write(apiVersionHistory)

        templateVars = self.CreateGlobalTemplateVars()
        templateVars["apiVersionHistory"] = apiVersionHistory

        with open(filename, "w") as outFile:
            outFile.write(self.apiVersionTemplate.safe_substitute(templateVars))
