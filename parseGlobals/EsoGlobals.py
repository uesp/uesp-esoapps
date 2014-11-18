import re
import os.path
import shutil
import datetime
from string import Template


class CEsoGlobalInfo:
    
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
        self.headerTemplate = Template(open('templates/esoglobal_header.txt', 'r').read())
        self.footerTemplate = Template(open('templates/esoglobal_footer.txt', 'r').read())
        self.globals = { }


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


    def CreateTemplateVars(self, types):
        templateVars = { }
        
        templateVars['creationDate'] = self.creationDate
        templateVars['parseDate'] = self.parseDate
        templateVars['parseTime'] = self.parseTime
        templateVars['parseVersion'] = self.parseVersion
        templateVars['types'] = ", ".join(types) if types else "all"
        
        return templateVars


    def CreateHTMLRecord(self, outFile, root, lineHeader, level, parentName, types = None):
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
                #thisTitle = "<a href=\"{1}\">{0}</a>".format(obj.name, GetFunctionLinkName(completeName))
                thisTitle += "() = <div class='esog_function'>" + obj.type + ":" + obj.value + metaLink + "</div>"
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
            self.CreateHTMLRecord(outFile, obj.children, lineHeader + "\t", level+1, completeName, None)
            outFile.write(lineHeader + "\t</div>\n")
            
            outFile.write("</div>\n")
            
        return        

    def CreateHTML(self, filename, types = []):
        print "Creating global HTML file", filename, "..."
        templateVars = self.CreateTemplateVars(types)

        relPath =  os.path.join(os.path.dirname(filename), '')
        shutil.copyfile("resources/esoglobaldata.css", relPath + "esoglobaldata.css")

        with open(filename, "w") as outFile:
            outFile.write(self.headerTemplate.safe_substitute(templateVars))
            self.CreateHTMLRecord(outFile, self.globals, "", 1, "", types)
            outFile.write(self.footerTemplate.safe_substitute(templateVars))
            
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
        currentInstance = None
        
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
            parsedName = self.parseName.findall(name)

            if event == "Global::Start":
                self.ParseGlobalDataStart(log)
                continue
            elif event == "Global::End":
                continue
            elif event != "Global":
                continue

            instance = self.CreateGlobalInstance(parsedName)

            if (instance.name.endswith("()")):
                instance.name = instance.name[:-2]
            
            instance.type = log.get('type', '')
            instance.access = log.get('label', '')
            instance.value = log.get('value', '')
            instance.meta = log.get('meta', '')
            instance.index = log.get('index', '')
            instance.string = log.get('string', '')
            instance.firstTable = log.get('firstTable', '') == "1"
            instance.firstMeta = log.get('firstMeta', '') == "1"
            instance.firstIndex = log.get('firstIndex', '') == "1"
                    
        return True


    def LoadParseFile(self, filename):
        self.filename = filename
        self.creationDate = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print "Loading globals dump file", filename, "..."

        globalContents = open(filename, "r").read()

        parsedLogLines = self.ParseLog(globalContents)
        self.logLineCount = len(parsedLogLines)
        self.ParseGlobalData(parsedLogLines)

        print "Loaded", str(self.logLineCount), "log lines into", str(len(self.globals)), "root global objects"
        return True
