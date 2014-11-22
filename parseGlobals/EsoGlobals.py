import re
import os.path
import shutil
import datetime
from string import Template
from operator import attrgetter


class CEsoGlobalInfo:
    
    def __init__(self):
        self.type = ""
        self.access = ""
        self.fullName = ""
        self.name = ""
        self.value = ""
        self.meta = ""
        self.index = ""
        self.string = ""
        self.firstTable = False
        self.firstIndex = False
        self.firstMeta = False
        self.children = { }


class CEsoGlobals:

    def __init__(self):
        self.filename = ""
        self.parseTime = ""
        self.parseDate = ""
        self.parseVersion = ""
        self.creationDate = ""
        self.matchLines = re.compile("\w*\[\d+\] = \"(.*)\",\w*")
        self.parseLine = re.compile("([a-zA-Z]+){(.*?)}  ")
        self.parseName = re.compile("([a-zA-Z0-9_()]+)[.:]?")
        self.logLineCount = 0
        self.globals = { }
        self.functionValueMap = { }
        self.allFunctions = [ ]
        self.globalObjectCount = 0
        self.globalDupFuncCount = 0

    
    def CreateFunctionMap(self):

        for func in self.allFunctions:
            
            if (not func.value in self.functionValueMap):
                self.functionValueMap[func.value] = []
                
            self.functionValueMap[func.value].append(func)


    def DumpDuplicateFunctions(self, filename):
        print "Dumping all duplicate functions to", filename
        dupFuncs = { }
        dupFuncCount = 0
        
        for key in self.functionValueMap:
            funcs = self.functionValueMap[key]
            
            if (len(funcs) > 1):
                dupFuncs[funcs[0].fullName] = funcs

        with open(filename, "w") as outFile:
            index = 0
            
            for key in dupFuncs:
                funcs = dupFuncs[key]
                index += 1
                
                value = ""
                if len(funcs) != 0: value = funcs[0].value
                outFile.write( "{0}) Duplicate set of {1} functions with value {2}\n".format(index, len(funcs), value) )

                sortedFuncs = sorted(funcs, key=attrgetter('fullName'))

                for func in sortedFuncs:
                    dupFuncCount += 1
                    outFile.write( "\t{0}()\n".format(func.fullName) )

        self.globalDupFuncCount = dupFuncCount
        print "\tOutput {0} duplicate functions in {1} unique sets".format(dupFuncCount, len(dupFuncs))
        

    def DumpRecord(self, outFile, root, header, types):
        sortedKeys = sorted(root.keys())

        for key in sortedKeys:
            obj = root[key]

            if (types != None and not obj.type in types):
                continue
            
            outFile.write(header)
            outFile.write(key)

            if (obj.type == "function"):
                outFile.write("()")
                
            outFile.write(" = ")

            if (obj.type == "table" or obj.type == "function" or
                obj.type == "userdata"):
                outFile.write(obj.type)
                outFile.write(":")
            
            outFile.write(obj.value)

            if (obj.type == "number" and obj.string != ""):
                outFile.write(" = \"")
                outFile.write(obj.string)
                outFile.write("\"")
            
            if (obj.access == "Private"):
                outFile.write("function: Private")

            if (obj.meta != ""):
                outFile.write("  (meta " + obj.meta + "}")

            if (obj.firstTable):
                outFile.write(" firstTable")

            if (obj.firstMeta):
                outFile.write(" firstMeta")

            if (obj.firstIndex):
                outFile.write(" firstIndex")
                
            outFile.write("\n")

            self.DumpRecord(outFile, obj.children, header + "\t", None)
            
        return True
    

    def Dump(self, filename, types = None):
        print "Dumping globals to", filename, "..."

        with open (filename, "w") as outFile:
            self.DumpRecord(outFile, self.globals, "", types)

        return True


    def GetGlobal(self, globalName):
        currentParent = self.globals
        currentInstance = None
        parsedName = self.parseName.findall(globalName)
        
        for name in parsedName:
            
            if (name in currentParent):
                currentInstance = currentParent[name]
                currentParent = currentParent[name].children
            else:
                currentParent[name] = CEsoGlobalInfo()
                currentInstance = currentParent[name]
                currentParent[name].name = name
                currentParent = currentParent[name].children
        
        return currentInstance
        

    def CreateGlobalInstance(self, parsedName):
        currentParent = self.globals
        parentName = ""
        currentInstance = None
        
        for name in parsedName:
            
            if (name in currentParent):
                currentInstance = currentParent[name]
                parentName += currentInstance.name + "."
                currentParent = currentParent[name].children
            else:
                currentParent[name] = CEsoGlobalInfo()
                currentInstance = currentParent[name]
                currentParent[name].name = name
                currentParent[name].fullName = parentName + name
                currentParent = currentParent[name].children
                parentName += currentInstance.name + "."

        self.globalObjectCount += 1
        return currentInstance


    def ParseLog(self, logContents):
        logLines = self.matchLines.findall(logContents)
        parsedLogLines = []

        for line in logLines:
            parsedLine = self.parseLine.findall(line)
            parsedLineDict = { }
            
            for parsedLine in parsedLine:
                parsedLineDict[parsedLine[0]] = parsedLine[1]
                
            parsedLogLines.append(parsedLineDict)
            
        return parsedLogLines


    def ParseGlobalDataStart(self, log):
        fullDate = int(log.get('niceDate', '0'))
        
        if (fullDate > 0):
            self.parseDate = str(fullDate/10000 % 10000) + "-" + str(fullDate/100 % 100) + "-" + str(fullDate % 100)
            
        self.parseTime = log.get('niceTime', '')
        self.parseVersion = log.get('apiVersion', '')

        return
    

    def ParseGlobalData(self, parsedLogLines):

        for log in parsedLogLines:
            event = log.get('event', '')
            name = log.get('name', '')

            if (name.endswith("()")):
                name = name[:-2]

            parsedName = self.parseName.findall(name)

            if event == "Global::Start":
                self.ParseGlobalDataStart(log)
                continue
            elif event == "Global::End":
                continue
            elif event != "Global":
                continue

            instance = self.CreateGlobalInstance(parsedName)
            
            instance.type = log.get('type', '')
            instance.access = log.get('label', '')
            instance.value = log.get('value', '')
            instance.meta = log.get('meta', '')
            instance.index = log.get('index', '')
            instance.string = log.get('string', '')
            instance.firstTable = log.get('firstTable', '') == "1"
            instance.firstMeta = log.get('firstMeta', '') == "1"
            instance.firstIndex = log.get('firstIndex', '') == "1"

            if (instance.type == "function"):
                self.allFunctions.append(instance)
                    
        return True


    def LoadParseFile(self, filename):
        self.filename = filename
        self.creationDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print "Loading globals dump file", filename, "..."

        globalContents = open(filename, "r").read()

        parsedLogLines = self.ParseLog(globalContents)
        self.logLineCount = len(parsedLogLines)
        self.ParseGlobalData(parsedLogLines)

        self.CreateFunctionMap()

        print "\tLoaded {0} log lines into {1} root global objects".format(self.logLineCount, len(self.globals))
        print "\tFound {0} unique functions out of {1} total".format(len(self.functionValueMap), len(self.allFunctions))
        return True


def LoadGlobals(filename):
    esoGlobals = CEsoGlobals()
    esoGlobals.LoadParseFile(filename)
    return esoGlobals
