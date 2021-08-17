import csv
import re

INPUT_FILENAME = "EsoNameChanges.txt"


rawNameChangeData = []

with open(INPUT_FILENAME, 'rb') as csvFile:
    reader = csv.reader(csvFile, quotechar="'")
    
    for row in reader:
        rawNameChangeData.append(row)

print("Loaded {0} rows from CSV file {1}.\n".format(len(rawNameChangeData), INPUT_FILENAME))


nameChangeData = {}

for row in rawNameChangeData:
    itemId = int(row[0])
    level = int(row[1])
    name = row[2]

    if (not itemId in nameChangeData):
        nameChangeData[itemId] = {}

    if (level in nameChangeData[itemId]):
        print "\t{0}-{1}: Duplicate level data found!".format(itemId, level)

    name = name.replace("'", '')
    name = name.title()
    name = re.sub(r'( [vixlVIXL]+$)', lambda pat: pat.group(1).upper(), name)
    nameChangeData[itemId][level] = name

for itemId, itemData in nameChangeData.iteritems():
    levels = sorted(itemData.iterkeys())
    
    for level in levels:
        if (level != 1):
            itemData[1] = itemData[level]
            itemData.pop(level)
        break

uniqueNameChangeData = {}
refNameChangeData = {}
nextUniqueDataId = 0

for itemId, itemData in nameChangeData.iteritems():
    foundData = False

    for uniqueId, itemData1 in uniqueNameChangeData.iteritems():
        
        if (itemData1 == itemData):
            refNameChangeData[itemId] = uniqueId
            foundData = True
            break

    if (not foundData):
        uniqueNameChangeData[nextUniqueDataId] = itemData
        refNameChangeData[itemId] = nextUniqueDataId
        nextUniqueDataId = nextUniqueDataId + 1


for uniqueId, itemData in uniqueNameChangeData.iteritems():
    print "$ESO_NAMEDATA{0} = array(".format(uniqueId)

    levels = sorted(itemData.iterkeys())
    
    for level in levels:
        name = itemData[level]
        print "\t{0} => '{1}',".format(level, name)

    print ");\n"

print "$ESO_NAMEDATA_ITEMS = array(\n"    

for itemId, uniqueId in refNameChangeData.iteritems():
    print "\t{0} => &$ESO_NAMEDATA{1},".format(itemId, uniqueId)

print ");\n"
    

print "Found {0} of {1} data sets that are unique!".format(len(uniqueNameChangeData), len(nameChangeData))
