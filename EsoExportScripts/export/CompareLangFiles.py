import os
import sys
import re
import csv

BasePath = ''
Version1 = ''
Version2 = ''
Language = 'en'

USE_COMMAND_ARGS = True

if (not USE_COMMAND_ARGS):
    BasePath = "e:\\esoexport\\"
    Version1 = "30pts"
    Version2 = "30pts2"
    Language = 'en'
elif (len(sys.argv) < 5):
    print("Missing required command line arguments!")
    sys.exit()
else:
    BasePath = sys.argv[1]
    Version1 = sys.argv[2]
    Version2 = sys.argv[3]
    Language = sys.argv[4]
    print("\tUsing Base Path:" + BasePath)
    print("\tUsing Version 1:" + Version1)
    print("\tUsing Version 2:" + Version2)
    print("\tUsing  Language:" + Language)

LANGFILE1  = BasePath + "goodimages-" + Version1 + "/lang/" + Language + ".lang.csv"
LANGFILE2  = BasePath + "goodimages-" + Version2 + "/lang/" + Language + ".lang.csv"
OUTPUTFILE = BasePath + "goodimages-" + Version2 + "/lang/" + Language + ".diff.txt"


def LoadLangCsvFile (InputFilename):
    print "Reading LANG CSV file {0}...".format(InputFilename)

    fileRows = {}
    
    with open(InputFilename, 'rb') as f:
        reader = csv.reader(f)
        rowCount = 0
        
        for row in reader:
            rowCount += 1
            if (rowCount == 1): continue
                
            id = row[0]
            index = row[1] + ":" + row[2]
            text = row[4]

            if not id in fileRows:
                fileRows[id] = { }

            if not index in fileRows[id]:
                fileRows[id][index] = text
            else:
                print "\t{0}:{1}:{2} Duplicate entry found!".format(rowCount, id, index)

    print "\tFound {0} rows in lang CSV file!".format(rowCount)
    return fileRows


def CompareLangFiles(Lang1, Lang2, OutputFilename):
    deletedRows = []
    addedRows = []
    changedRows = []

    for id in Lang1:
        
        if not id in Lang2:
            
            for index in Lang1[id]:
                text1 = Lang1[id][index]
                diffText = "{0}:{1} = \"{2}\"".format(id, index, text1)
                deletedRows.append(diffText)
                #print "Deleted " + diffText

            continue
        
        for index in Lang1[id]:
            text1 = Lang1[id][index]

            if not index in Lang2[id]:
                diffText = "{0}:{1} = \"{2}\"".format(id, index, text1)
                deletedRows.append(diffText)
                #print "Deleted " + diffText
                continue
            
            text2 = Lang2[id][index]

            if (text1 != text2):
                diffText = "{0}:{1} = \"{2}\"".format(id, index, text2)
                changedRows.append(diffText)
                #print "Changed " + diffText

    for id in Lang2:

        if not id in Lang1:

            for index in Lang2[id]:
                text1 = Lang2[id][index]
                diffText = "{0}:{1} = \"{2}\"".format(id, index, text1)
                addedRows.append(diffText)
                #print "Added " + diffText

            continue

        for index in Lang2[id]:
            text2 = Lang2[id][index]

            if not index in Lang1[id]:
                diffText = "{0}:{1} = \"{2}\"".format(id, index, text2)
                addedRows.append(diffText)
                #print "Added " + diffText
                continue

    f = open(OutputFilename, "wb")

    f.write("{0} Added Texts:\n".format(len(addedRows)))
    
    for row in addedRows:
        f.write("\tAdded " + row + "\n")

    f.write("\n{0} Deleted Texts:\n".format(len(deletedRows)))
    
    for row in deletedRows:
        f.write("\tDeleted " + row + "\n")

    f.write("\n{0} Changed Texts:\n".format(len(changedRows)))
    
    for row in changedRows:
        f.write("\tChanged " + row + "\n")

    f.close()

    print "Found {0} added rows, {1} deleted rows, and {2} changed rows.".format(len(addedRows), len(deletedRows), len(changedRows))
    return


lang1 = LoadLangCsvFile(LANGFILE1)
lang2 = LoadLangCsvFile(LANGFILE2)
CompareLangFiles(lang1, lang2, OUTPUTFILE)

