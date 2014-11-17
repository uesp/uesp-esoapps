import csv
import collections
import os.path
import re
import operator
import sys
import datetime
import shutil
import ntpath
#from skipdict import SkipDict

OUTPUT_PATH = "d:\\temp\\esoglobals\\"
INPUT_FILENAME = "d:\\esoexport\\goodimages10\\globals_6b.txt"
LUA_ROOT_PATH = "d:\\esoexport\\gamemnf10\\esoui\\"
#LUA_ROOT_PATH = "d:\\esoexport\\gamemnf10\\esoui\\pregame\\console\\"

#INPUT_FILENAME = "d:\\src\\uesp\\eso\\parseGlobals\\globals_6b.txt"
#LUA_ROOT_PATH = "d:\\src\\esoui\\"


class CInstanceInfo:
    def __init__(self):
        self.type = ""
        self.access = ""
        self.name = ""
        self.value = ""
        self.meta = ""
        self.index = ""
        self.string = ""
        self.firstTable = False
        self.firstIndex = False
        self.firstMeta = False
        self.children = { }
        

class CFunctionInfo:
    def __init__(self):
        self.fullName = ""
        self.fullString = ""
        self.filename = ""
        self.namespace = ""
        self.namespaceType = ""
        self.local = ""
        self.name = ""
        self.line = ""
        self.allParams = ""
        self.params = [ ]


class CFunctionCallInfo:
    def __init__(self):
        self.filename = ""
        self.line = ""
        self.fullString = ""
        self.vars = ""
        self.name = ""
        self.params = ""


functionCalls = { }
luaFunctions = { }

GlobalData_Time = ""
GlobalData_Date = ""
GlobalData_Version = ""


def ParseGlobalLogFile(filename):
    
    with open (filename, "r") as myfile:
        GlobalDataFile = myfile.read()
        
    matchLogLines = re.compile("\w*\[\d+\] = \"(.*)\",\w*")
    logLines = matchLogLines.findall(GlobalDataFile)

    parseLogLine = re.compile("([a-zA-Z]+){(.*?)}  ")
    parsedLogLines = []

    for line in logLines:
        parsedLine = parseLogLine.findall(line)
        parsedLineDict = { }
        
        for parsedLine in parsedLine:
            varName  = parsedLine[0]
            varValue = parsedLine[1]
            parsedLineDict[varName] = varValue
            
        parsedLogLines.append(parsedLineDict)

    return parsedLogLines


def CreateGlobalInstance(globalData, parsedName):
    currentParent = globalData
    lastParent = None
    currentInstance = None
    
    for name in parsedName:
        lastParent = currentParent
        
        if (name in currentParent):
            currentInstance = currentParent[name]
            currentParent = currentParent[name].children
        else:
            currentParent[name] = CInstanceInfo()
            currentInstance = currentParent[name]
            currentParent[name].name = name
            currentParent = currentParent[name].children
    
    return currentInstance


def ParseGlobalData_Start(log):
    global GlobalData_Date
    global GlobalData_Time
    global GlobalData_Version
    
    #[1] = "event{Global::Start}  niceDate{20141114}  niceTime{15:21:47}  apiVersion{100010}  timeStamp{4743725927807057920}  gameTime{647585}  lang{en}  ",
    # 

    fullDate = int(log.get('niceDate', '0'))
    
    if (fullDate > 0):
        GlobalData_Date = str(fullDate/10000 % 10000) + "-" + str(fullDate/100 % 100) + "-" + str(fullDate % 100)
        
    GlobalData_Time = log.get('niceTime', '')
    GlobalData_Version = log.get('apiVersion', '')

    return


def ParseGlobalData(globalLog):

    globalData = { }
    parseName = re.compile("([a-zA-Z0-9_()]+)\.?")

    for log in globalLog:
        event = log.get('event', '')
        name = log.get('name', '')
        parsedName = parseName.findall(name)

        if event == "Global::Start":
            ParseGlobalData_Start(log)
            continue
        elif event == "Global::End":
            continue
        elif event != "Global":
            continue

        instance = CreateGlobalInstance(globalData, parsedName)
        
        instance.type = log.get('type', '')
        instance.access = log.get('label', '')
        instance.value = log.get('value', '')
        instance.meta = log.get('meta', '')
        instance.index = log.get('index', '')
        instance.string = log.get('string', '')
        instance.firstTable = log.get('firstTable', '') == "1"
        instance.firstMeta = log.get('firstMeta', '') == "1"
        instance.firstIndex = log.get('firstIndex', '') == "1"
                
    return globalData


def DumpGlobalData_Record(root, header, outFile, types):
    sortedKeys = sorted(root.keys())

    for key in sortedKeys:
        thisObject = root[key]

        if (types != None and not thisObject.type in types):
            continue
        
        outFile.write(header)
        outFile.write(key)
        outFile.write(" = ")

        if (thisObject.type == "table" or thisObject.type == "function" or
            thisObject.type == "userdata"):
            outFile.write(thisObject.type)
            outFile.write(":")
        
        outFile.write(thisObject.value)

        if (thisObject.type == "number" and thisObject.string != ""):
            outFile.write(" = \"")
            outFile.write(thisObject.string)
            outFile.write("\"")
        
        if (thisObject.access == "Private"):
            outFile.write("function: Private")

        if (thisObject.meta != ""):
            outFile.write("  (meta " + thisObject.meta + "}")

        if (thisObject.firstTable):
            outFile.write(" firstTable")

        if (thisObject.firstMeta):
            outFile.write(" firstMeta")

        if (thisObject.firstIndex):
            outFile.write(" firstIndex")
            
        outFile.write("\n")

        DumpGlobalData_Record(thisObject.children, header + "\t", outFile, None)
        
    return


def DumpGlobalData(globalData, filename, types = None):

    with open (filename, "w") as outFile:
        DumpGlobalData_Record(globalData, "", outFile, types)

    return


def CreateGlobalHTML_Header(globalData, outFile, types):
    outFile.write("<html>\n")
    outFile.write("\t<head>\n")
    outFile.write("\t\t<title>UESP: ESO Global Data</title>\n")
    outFile.write("\t\t<link rel=\"stylesheet\" href=\"esoglobaldata.css\" type=\"text/css\" />\n")
    outFile.write("\t</head>\n")
    outFile.write("<body>\n")
    
    typesString = ""
    
    if (types == None):
        typesString = "all"
    else:
        typesString = ", ".join(types)

    outFile.write("The following is all global LUA data ({0}) found in Elder Scrolls Online as generated by the <a href=\"http://www.uesp.net\">UESP</a>. \n".format(typesString))
    outFile.write("Data was exported from ESO on {0} {1}, API version {2}.\n".format(GlobalData_Date, GlobalData_Time, GlobalData_Version))
    outFile.write("See the <a href=\"#endoffile\">end of file</a> for notes on this data. \n")
    outFile.write("<br /><br />\n")
    return


def CreateGlobalHTML_Record(root, lineHeader, level, parentName, outFile, types):
    sortedKeys = sorted(root.keys())

    for key in sortedKeys:
        thisObject = root[key]

        if (types != None and not thisObject.type in types):
            continue

        if (parentName == ""):
            completeName = thisObject.name
        else:
            completeName = parentName + "." + thisObject.name
        
        metaName = ""
        tableName = ""
        indexName = ""
        tableLink = ""
        metaLink = ""
        indexLink = ""
        accessClass = ""

        if (thisObject.firstTable):
            tableName = "table_" + thisObject.value
            outFile.write("<a name=\"{0}\" />\n".format(tableName))
        else:
            tableLink = " <a class=\"esog_table\" href=\"#table_{0}\">table:{0}</a>".format(thisObject.value)

        if (thisObject.firstMeta and thisObject.meta != ""):
            metaLink = " <div class=\"esog_meta\">meta:" + thisObject.meta + "</div>"
            metaName = "meta_" + thisObject.meta
            outFile.write("<a name=\"{0}\" />\n".format(metaName))
        elif (thisObject.meta != ""):
            metaLink = " <a class=\"esog_meta\" href=\"#meta_{0}\">meta:{0}</a>".format(thisObject.meta)

        if (thisObject.firstIndex and thisObject.index != ""):
            indexLink = " <div class=\"esog_index\">index:" + thisObject.index + "</div>"
            indexName = "index_" + thisObject.index
            outFile.write("<a name=\"{0}\" />\n".format(indexName))
        elif (thisObject.index != ""):
            indexLink = " <a class=\"esog_index\" href=\"#index_{0}\">index:{0}</a>".format(thisObject.index)

        if (thisObject.access == "Private"):
            accessClass = " esog_private"

        outFile.write(lineHeader + "<div class=\"esog_section{0}\" title=\"{1}\">\n".format(level, completeName))
        thisTitle = thisObject.name
        
        if (thisObject.type == "table"):
            
            if (tableLink == ""):
                thisTitle += " = " + thisObject.type + ":" + thisObject.value + tableLink
            else:
                thisTitle += " = " + tableLink
                
        elif (thisObject.type == "function"):
            thisTitle = "<a href=\"{1}\">{0}</a>".format(thisObject.name, GetFunctionLinkName(completeName))
            thisTitle += " = " + thisObject.type + ":" + thisObject.value + metaLink
        elif (thisObject.type == "userdata"):
            thisTitle += " = " + thisObject.type + ":" + thisObject.value + metaLink + indexLink
        elif (thisObject.type == "number" and thisObject.name.startswith("SI_")):
            thisTitle += " (" + thisObject.value + ") = \"" + thisObject.string + "\""
        elif (thisObject.access == "Private"):
            thisTitle += " = Private"
        else:
            thisTitle += " = " + thisObject.value
        
        outFile.write(lineHeader + "\t<div class=\"esog_title{1}\">{0}</div>".format(thisTitle, accessClass))
        outFile.write("\n")

        outFile.write(lineHeader + "\t<div class=\"esog_children\">\n")
        CreateGlobalHTML_Record(thisObject.children, lineHeader + "\t", level+1, completeName, outFile, None)
        outFile.write(lineHeader + "\t</div>\n")
        
        outFile.write("</div>\n")
        
    return


def CreateGlobalHTML_Footer(globalData, outFile, types):
    currentDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    typesString = ""
    
    if (types == None):
        typesString = "all"
    else:
        typesString = ", ".join(types)
        
    outFile.write("<hr />\n")
    outFile.write("<div class=\"esog_footer\">\n")
    outFile.write("<a name=\"endoffile\" />\n")
    outFile.write("<b>Data Notes:</b>\n")
    outFile.write("<ul>\n")
    outFile.write("<li>The hex numbers for tables, functions, userdata, and meta/index will change each time the UI is reloaded.</li>\n")
    outFile.write("<li>Only one of each unique table/userdata/index/meta object is listed to save space. Use the links to jump to the expanded definition of an object.</li>\n")
    outFile.write("<li>Hover over an object to get its complete name.</li>\n")
    outFile.write("</ul>\n")
    outFile.write("This file was generated automatically on {3}. Data ({4}) was exported from ESO on {0} {1}, API version {2}.<br />\n".format(GlobalData_Date, GlobalData_Time, GlobalData_Version, currentDate, typesString))
    outFile.write("</div>\n</body>\n")
    outFile.write("</html>\n")
    return


def CreateGlobalHTML(globalData, filename, types = None):
    path = ntpath.dirname(filename)
    shutil.copyfile("esoglobaldata.css", path + "\\esoglobaldata.css")

    with open (filename, "w") as outFile:
        CreateGlobalHTML_Header(globalData, outFile, types)
        CreateGlobalHTML_Record(globalData, "", 1, "", outFile, types)
        CreateGlobalHTML_Footer(globalData, outFile, types)

    return


totalLuaFunctions = 0
totalLuaDuplicates = 0
totalLuaCalls = 0
totalIgnoredLuaFiles = 0
#matchFunctions = re.compile("((?:local\s+)?function\s+.*)\s*\n")
matchFunctions = re.compile("((?:local\s+)?function\s+.*)")
#matchFunctions = re.compile("((?:local\s+)?function\s+.*\))\s*\n")
#matchFunctions = re.compile("((?:local\s+)?function\s+.*)\n")

matchFunctionName = re.compile("(local)?\s*function\s+([A-Za-z0-9_]+)?([:.])?([A-Za-z0-9_]+)\s*\(\s*(.*)\s*\)")
matchFunctionParams = re.compile("([A-Za-z0-9_]+)\s*,?")
matchFunctionCall = re.compile("(?:([A-Za-z_\[][A-Za-z0-9_,.\[\]\t ]*)\s*=\s*)?([A-Za-z_][A-Za-z0-9_.:\[\]]*)\s*\((.*)\)")

# function name()
# function name(var)
# function name(var1, var2)
# x, y, z = func()

def FindLuaFunctions_ParseFunction(filename, function, lineNumber, luaFunctions):
    global totalLuaDuplicates
    
        # 0=local, 1=Namespace, 2=:|., 3=Function, 4=Params
    funcData = matchFunctionName.findall(function)

    if (len(funcData) <= 0):
        return None

    #print "\t", funcData[0]
    funcParams = ""

    if (funcData[0][4] != ""):
        funcParams = matchFunctionParams.findall(funcData[0][4])

    newFunc = CFunctionInfo()
    newFunc.fullString = function
    newFunc.local = funcData[0][0]
    newFunc.namespace = funcData[0][1]
    newFunc.namespaceType = funcData[0][2]
    newFunc.name = funcData[0][3]
    newFunc.line = str(lineNumber)
    newFunc.allParams = funcData[0][4]
    newFunc.fullName = newFunc.namespace + newFunc.namespaceType + newFunc.name
    newFunc.filename = filename

    niceName = CreateNiceFunctionName(newFunc.fullName)

    #print "\t\t", newFunc.fullName

    if (newFunc.local != ""):
        return newFunc

    if (niceName in luaFunctions):
        totalLuaDuplicates += 1
        print "\tDuplicate function " + niceName + " found!"
        print "\t\tExisting Found in " + luaFunctions[niceName].filename + " Line " + luaFunctions[niceName].line
        print "\t\t     New Found in " + newFunc.filename + " Line " + newFunc.line
        print "\t\tExisting Def: " + luaFunctions[niceName].fullString
        print "\t\t     New Def: " + newFunc.fullString
        return None

    luaFunctions[niceName] = newFunc
    return newFunc


def FindLuaFunctions_ParseFile(filename, luaFileContents, luaFunctions):
    global totalLuaFunctions
    global totalLuaCalls
    global functionCalls

    fileLines = luaFileContents.split("\n")
    functions = [ ]
    lineNumbers = [ ]

    for i, line in enumerate(fileLines):
        lineFuncs = matchFunctions.findall(line)
        functions.extend(lineFuncs)
        lineNumbers.extend([i+1] * len(lineFuncs))

        if (len(lineFuncs) > 0):
            continue

        callFuncs = matchFunctionCall.findall(line)
        #functionCalls.extend(callFuncs)
        paramCallFuncs = [ ]

        for call in callFuncs:
            paramCallFuncs = matchFunctionCall.findall(call[2])

        callFuncs.extend(paramCallFuncs)                    

        for call in callFuncs:
            newCallInfo = CFunctionCallInfo()
            newCallInfo.filename = filename
            newCallInfo.line = str(i+1)
            newCallInfo.vars = call[0].strip()
            newCallInfo.name = call[1].strip()
            newCallInfo.params = call[2].strip()
            
            if (newCallInfo.vars.startswith("local")):
                newCallInfo.vars = newCallInfo.vars[5:].strip()

            if (newCallInfo.vars == ""):
                newCallInfo.fullString = newCallInfo.name + "(" + newCallInfo.params + ")"
            else:
                newCallInfo.fullString = newCallInfo.vars + " = " + newCallInfo.name + "(" + newCallInfo.params + ")"
            
            if (not newCallInfo.name in functionCalls):
                functionCalls[newCallInfo.name] = [ ]

            functionCalls[newCallInfo.name].append(newCallInfo)

            
        
        #if (len(callFuncs) > 0):
            #print callFuncs

    # print "\tFound " + str(len(functions)) + " functions and " + str(len(functionCalls)) + " calls in " + str(len(lineNumbers)) + " lines"

    for i, func in enumerate(functions):
        FindLuaFunctions_ParseFunction(filename, func, lineNumbers[i], luaFunctions)

    totalLuaFunctions += len(functions)
    totalLuaCalls += len(functionCalls)
    return


def FindLuaFunctions_CheckFile(filename, luaFunctions):

    if (not filename.endswith(".lua")):
        return False
    
    #print "Checking LUA source file " + filename

    with open (filename, "r") as inFile:
        fileContents = inFile.read()

    FindLuaFunctions_ParseFile(filename, fileContents, luaFunctions)
        
    return True


def FindLuaFunctions(searchPath):
    global totalIgnoredLuaFiles
    
    luaFunctions = { }
    
    totalFiles = 0

    for subdir, dirs, files in os.walk(searchPath):
        subPath = subdir + "\\"

        if ("\\gamepad\\" in subPath or
            "\\pregame\\" in subPath or
            "\\pregamelocalization\\" in subPath):
            print "\tSkipping " + subdir + "..."
            totalIgnoredLuaFiles += 1
            continue
        
        for filename in files:
            if (FindLuaFunctions_CheckFile(subPath + filename, luaFunctions)):
                totalFiles += 1
            
    print "Found " + str(totalFiles) + " LUA files"
    print "Ignored " + str(totalIgnoredLuaFiles) + " LUA files"
    print "Found " + str(totalLuaFunctions) + " LUA functions"
    print "Found " + str(totalLuaCalls) + " LUA function calls for " + str(len(functionCalls)) + " different functions"
    print "Found " + str(totalLuaDuplicates) + " duplicate function definitions"

    return luaFunctions


def DumpLuaFunctionCall(outFile, funcName, funcCalls):
    outFile.write(funcName)
    outFile.write("()\n")

    for call in funcCalls:
        outFile.write("\t")
        outFile.write(call.fullString)
        #outFile.write("\n")
        #outFile.write("\t\t")
        outFile.write(" -- ")
        outFile.write(call.filename)
        outFile.write(":")
        outFile.write(call.line)
        outFile.write("\n")        

    outFile.write("\n")
    return


def DumpLuaFunctionCalls(filename):

    sortedKeys = sorted(functionCalls.keys())

    with open(filename, "w") as outFile:
        for funcName in sortedKeys:
            DumpLuaFunctionCall(outFile, funcName, functionCalls[funcName])
        
    return


def CreateFunctionCallHTML_Header(outFile, funcName):
    
    funcData = luaFunctions.get(funcName, None)
    
    outFile.write("<html>\n")
    outFile.write("\t<head>\n")
    outFile.write("\t\t<title>UESP: ESO Function Call {0}</title>\n".format(funcName))
    outFile.write("\t\t<link rel=\"stylesheet\" href=\"esofunccall.css\" type=\"text/css\" />\n")
    outFile.write("\t</head>\n")
    outFile.write("<body>\n")
    outFile.write("<h1 class=\"esofc_title\">Function Calls for {0}():</h1>\n".format(funcName))
    outFile.write("The following are all the LUA function calls for the {0}() function found in Elder Scrolls Online as generated by the <a href=\"http://www.uesp.net\">UESP</a>. \n".format(funcName))
    #outFile.write("Data was exported from ESO on {0} {1}, API version {2}.\n".format(GlobalData_Date, GlobalData_Time, GlobalData_Version))
    outFile.write("<br /><br />\n")

    if (funcData == None):
        outFile.write("No function definition found!\n")
    else:
        
        outFile.write("Function definition found in {0}\n".format(CreateLuaFileLink(funcData.filename, funcData.line, "..\\")))
                      
    #outFile.write("<br /><br />\n")
    return


def CreateFunctionCallHTML_Call(outFile, funcName, funcCall):

    CreateFunctionCallHTML_Header(outFile, funcName)

    outFile.write("<ul>\n")

    for call in funcCall:
        outFile.write("\t<li>\n")
        #outFile.write("<div class=\"esofc_filename\">{0}:{1}</div>\n".format(call.filename, call.line))
        outFile.write("<div class=\"esofc_filename\">{0}</div>\n".format(CreateLuaFileLink(call.filename, call.line, "..\\")))
        outFile.write(" -- <div class=\"esofc_record\">{0}</div>\n".format(call.fullString))
        outFile.write("\t</li>\n")

    outFile.write("</ul>\n")
    CreateFunctionCallHTML_Footer(outFile)    
    return


def CreateFunctionCallHTML_Footer(outFile):
    currentDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    outFile.write("<hr />\n")
    outFile.write("<div class=\"esofc_footer\">\n")
    outFile.write("<a name=\"endoffile\" />\n")
    outFile.write("This file was generated automatically on {3}. Function data was exported from ESO on {0} {1}, API version {2}.<br />\n".format(GlobalData_Date, GlobalData_Time, GlobalData_Version, currentDate))
    outFile.write("</div>\n</body>\n")
    outFile.write("</html>\n")
    return


def CreateNiceFunctionName(funcName):
    return funcName.replace(":", ".")


def CreateFunctionFilename(funcName):
    return CreateNiceFunctionName(funcName) + ".html"


def GetFunctionLinkName(funcName):
    filename = "functioncalls\\" + CreateNiceFunctionName(funcName)
    
    if filename.endswith("()"):
        filename = filename[:-2]
        
    filename += ".html"
    return filename


def CreateLuaFileLink(filename, line, relPath = ""):
    baseFilename = os.path.relpath(filename, LUA_ROOT_PATH)
    link = "<a href=\"" + relPath + "src\\" + baseFilename + ".html#" + str(line) + "\">" + baseFilename + ":" + str(line) + "</a>"
    return link


def CreateFunctionCallHTML(path):

    if not os.path.exists(path):
        os.makedirs(path)

    shutil.copyfile("esofunccall.css", path + "esofunccall.css")
   
    for funcName in functionCalls:
        funcCall = functionCalls[funcName]
        
        filename = path + CreateFunctionFilename(funcName)
        
        with open(filename, "w") as outFile:
            CreateFunctionCallHTML_Call(outFile, funcName, functionCalls[funcName])

    return


def CreateLuaSource_Header(outFile, filename, relPath):
    outFile.write("\t<head>\n")
    outFile.write("\t\t<title>UESP:ESO Data -- {0}</title>\n".format(filename))
    outFile.write("\t\t<link rel=\"stylesheet\" href=\"{0}\\esoluafile.css\" type=\"text/css\" />\n".format(relPath))
    outFile.write("\t\t<link rel=\"stylesheet\" href=\"{0}\\shCore.css\" type=\"text/css\" />\n".format(relPath))
    outFile.write("\t\t<link rel=\"stylesheet\" href=\"{0}\\shCoreDefault.css\" type=\"text/css\" />\n".format(relPath))
    outFile.write("\t\t<script type=\"text/javascript\" src=\"{0}\\shCore.js\"></script>\n".format(relPath))
    outFile.write("\t\t<script type=\"text/javascript\" src=\"{0}\\shBrushLua.js\"></script>\n".format(relPath))
    outFile.write("\t\t<script type=\"text/javascript\" src=\"{0}\\jquery.js\"></script>\n".format(relPath))
    outFile.write("\t</head>\n")
    outFile.write("<body>\n")
    outFile.write("<h1 class=\"esofc_title\">ESO LUA File: {0}</h1>\n".format(filename))
    
    return


def CreateLuaSource_LUAData(outFile, luaFile):
    outFile.write("<pre class=\"brush: lua;\">")
    convertFile = luaFile.replace("<", "&lt;").replace(">", "&gt;")
    outFile.write(convertFile)
    outFile.write("</pre>\n")

    return


def CreateLuaSource_Footer(outFile):
    currentDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    outFile.write("<script type=\"text/javascript\">\n")
    outFile.write("var initialHash = window.location.hash.substring(1);\n")
    outFile.write("SyntaxHighlighter.defaults['highlight'] = initialHash;\n")
    outFile.write("SyntaxHighlighter.all();\n")
    #outFile.write("window.location.hash = '';\n")
    outFile.write("setTimeout(function() { $('.gutter .line').each(function(i) {\n")
    outFile.write("\t $(this).attr('id', $(this).text()); \n")
    outFile.write("}); $('html,body').animate({scrollTop: $('#'+initialHash).offset().top},'slow'); }, 500);\n")
    outFile.write("</script>\n")
    outFile.write("<hr />\n")
    outFile.write("<i>")
    outFile.write("This file was generated automatically on {3}. File data was exported from ESO on {0} {1}, API version {2}.<br />\n".format(GlobalData_Date, GlobalData_Time, GlobalData_Version, currentDate))
    outFile.write("File content is Copyright (c) 2014 Zenimax Online Studios. All trademarks and registered trademarks present in the file are proprietary to ZeniMax Online Studios, the inclusion of which implies no affiliation with the UESP. The use of this file data is believed to fall under the fair dealing clause of Canadian copyright law.")
    outFile.write("</i>\n")
    outFile.write("</body>\n")
    outFile.write("</html>")
    
    return


def CreateLuaSource_LUA(filename, relFilename, relPath):
    outputFilename = filename + ".html"

    luaFile = ""

    with open(filename, "r") as inFile:
        luaFile = inFile.read()

    with open(outputFilename, "w") as outFile:
        CreateLuaSource_Header(outFile, relFilename, relPath)
        CreateLuaSource_LUAData(outFile, luaFile)
        CreateLuaSource_Footer(outFile)
    
    return


def CreateLuaSource(inputPath, outputPath):

    shutil.copyfile("jquery.js", OUTPUT_PATH + "jquery.js")
    shutil.copyfile("shCore.js", OUTPUT_PATH + "shCore.js")
    shutil.copyfile("shBrushLua.js", OUTPUT_PATH + "shBrushLua.js")
    shutil.copyfile("shCore.css", OUTPUT_PATH + "shCore.css")
    shutil.copyfile("shCoreDefault.css", OUTPUT_PATH + "shCoreDefault.css")
    shutil.copyfile("esoluafile.css", OUTPUT_PATH + "esoluafile.css")
    
    for root, dirs, files in os.walk(inputPath):
        subPath = root + "\\"

        subDir = os.path.relpath(subPath, inputPath)
        outputSubDir = os.path.join(outputPath, subDir)

        if not os.path.exists(outputSubDir):
            os.makedirs(outputSubDir)
        
        for filename in files:
            relFilename = os.path.relpath(subPath + filename, inputPath)
            outputFilename = os.path.join(outputSubDir, filename)
            shutil.copyfile(subPath + filename, outputFilename)

            relPath = os.path.join("..\\", os.path.relpath(outputPath, os.path.dirname(outputFilename)))

            if (filename.endswith(".lua")):
                CreateLuaSource_LUA(outputFilename, relFilename, relPath)
        
    return


callFuncs = matchFunctionCall.findall("x = y()")
callFuncs = matchFunctionCall.findall("x[0], y.z = self:zy(abc[1].t, 123)")
print callFuncs

luaFunctions = FindLuaFunctions(LUA_ROOT_PATH)

DumpLuaFunctionCalls(OUTPUT_PATH + "funccalls.txt")

#sys.exit()



parsedGlobalLog = ParseGlobalLogFile(INPUT_FILENAME)
print "Loaded " + str(len(parsedGlobalLog)) + " rows from " + INPUT_FILENAME

globalData = ParseGlobalData(parsedGlobalLog)
print "Parsed into " + str(len(globalData)) + " root global objects"

DumpGlobalData(globalData, OUTPUT_PATH + "test.txt")

CreateFunctionCallHTML(OUTPUT_PATH + "functioncalls\\")

CreateGlobalHTML(globalData, OUTPUT_PATH + "test_all.html")
CreateGlobalHTML(globalData, OUTPUT_PATH + "test_func.html", [ "function" ])
CreateGlobalHTML(globalData, OUTPUT_PATH + "test_var.html", [ "number", "string", "boolean" ] )
CreateGlobalHTML(globalData, OUTPUT_PATH + "test_data.html", [ "userdata", "table" ])

CreateLuaSource(LUA_ROOT_PATH, OUTPUT_PATH + "src\\")


        
    



