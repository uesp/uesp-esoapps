import csv
import collections
import os.path
import re
import operator
import sys
import datetime
#from skipdict import SkipDict

INPUT_FILENAME = "d:\\esoexport\\goodimages10\\globals_6b.txt"

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

InstanceData = { }

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


def DumpGlobalData_Record(root, header, outFile):
    sortedKeys = sorted(root.keys())

    for key in sortedKeys:
        thisObject = root[key]
        
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

        DumpGlobalData_Record(thisObject.children, header + "\t", outFile)
        
    return


def DumpGlobalData(globalData, filename):

    with open (filename, "w") as outFile:
        DumpGlobalData_Record(globalData, "", outFile)

    return



def CreateGlobalHTML_Header(globalData, outFile):
    outFile.write("<html>\n")
    outFile.write("\t<head>\n")
    outFile.write("\t\t<title>UESP: ESO Global Data</title>\n")
    outFile.write("\t\t<link rel=\"stylesheet\" href=\"esoglobaldata.css\" type=\"text/css\" />\n")
    outFile.write("\t</head>\n")
    outFile.write("<body>\n")

    outFile.write("The following is all global LUA data and functions found in Elder Scrolls Online as generated by the <a href=\"http://www.uesp.net\">UESP</a>. \n")
    outFile.write("Data was exported from ESO on {0} {1}, API version {2}.\n".format(GlobalData_Date, GlobalData_Time, GlobalData_Version))
    outFile.write("See the <a href=\"#endoffile\">end of file</a> for notes on this data. \n")
    outFile.write("<br /><br />\n")
    return


def CreateGlobalHTML_Record(root, lineHeader, level, parentName, outFile):
    sortedKeys = sorted(root.keys())

    for key in sortedKeys:
        thisObject = root[key]

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
        CreateGlobalHTML_Record(thisObject.children, lineHeader + "\t", level+1, completeName, outFile)
        outFile.write(lineHeader + "\t</div>\n")
        
        outFile.write("</div>\n")
        
    return


def CreateGlobalHTML_Footer(globalData, outFile):
    currentDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    outFile.write("<br /><br />\n")
    outFile.write("<a name=\"endoffile\" />\n")
    outFile.write("<b>Data Notes:</b>\n")
    outFile.write("<ul>\n")
    outFile.write("<li>The hex numbers for tables, functions, userdata, and meta/index will change each time the UI is reloaded.</li>\n")
    outFile.write("<li>Only one of each unique table/userdata/index/meta object is listed to save space. Use the links to jump to the expanded definition of an object.</li>\n")
    outFile.write("<li>Hover over an object to get its complete name.</li>\n")
    outFile.write("</ul>\n")
    outFile.write("This file was generated automatically on {3}. Data was exported from ESO on {0} {1}, API version {2}.<br />\n".format(GlobalData_Date, GlobalData_Time, GlobalData_Version, currentDate))
    outFile.write("</body>\n")
    outFile.write("</html>\n")
    return


def CreateGlobalHTML(globalData, filename):

    with open (filename, "w") as outFile:
        CreateGlobalHTML_Header(globalData, outFile)
        CreateGlobalHTML_Record(globalData, "", 1, "", outFile)
        CreateGlobalHTML_Footer(globalData, outFile)

    return




parsedGlobalLog = ParseGlobalLogFile(INPUT_FILENAME)
print "Loaded " + str(len(parsedGlobalLog)) + " rows from " + INPUT_FILENAME

globalData = ParseGlobalData(parsedGlobalLog)
print "Parsed into " + str(len(globalData)) + " root global objects"

#DumpGlobalData(globalData, "test.txt")
#CreateGlobalHTML(globalData, "test.html")



        
    


