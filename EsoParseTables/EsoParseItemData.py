import csv
import re

#INPUT_FILENAME = "item-68118.csv"
#INPUT_FILENAME = "item-68120.csv"
#INPUT_FILENAME = "item-26588.csv"
#INPUT_FILENAME = "item-23662.csv"
#INPUT_FILENAME = "item-23668.csv"
#INPUT_FILENAME = "item-63757.csv"
#INPUT_FILENAME = "item-107884.csv"
INPUT_FILENAME = "item-68944.csv"


itemData = []

with open(INPUT_FILENAME, 'rb') as csvFile:
    reader = csv.reader(csvFile)
    
    for row in reader:
        itemData.append(row)

print("Loaded {0} rows from CSV file {1}.\n".format(len(itemData), INPUT_FILENAME))

headerRow = itemData[0]

compareColumns = [
        "armorRating",
        #"weaponPower",
        "value",
        #"name",
        #"enchantDesc",
        #"setBonusDesc1",
        #"setBonusDesc2",
        #"setBonusDesc3",
        #"setBonusDesc4",
        #"setBonusDesc5",
        "traitDesc",
        #"maxCharges",
        #"icon",
    ]

compareColumnIds = []

for col in compareColumns:
    compareColumnIds.append(headerRow.index(col))

iterRows = iter(itemData)
next(iterRows)

itemDataMap = {}
itemLevelMap = {}
maxChargesMap = {}
traitDescMap = {}

maxChargesId = -1
traitDescId = -1

internalLevelId = headerRow.index("internalLevel")
internalSubtypeId = headerRow.index("internalSubtype")
qualityId = headerRow.index("quality")
levelId = headerRow.index("level")
#maxChargesId = headerRow.index("maxCharges")
traitDescId = headerRow.index("traitDesc")


for row in iterRows:
    rowId = ""

    for colId in compareColumnIds:
        rowId += row[colId] + "-"

    if not rowId in itemDataMap.keys():
        itemDataMap[rowId] = {}
        itemDataMap[rowId]['count'] = 0
        itemDataMap[rowId]['levels'] = []

    intLevel = row[internalLevelId]
    intSubtype = row[internalSubtypeId]

    itemDataMap[rowId]['count'] += 1
    itemDataMap[rowId]['levels'].append(intLevel + ":" + intSubtype)

    if (maxChargesId >= 0):
        maxChargesMap[intLevel + ":" + intSubtype] = row[maxChargesId]

    if (traitDescId >= 0):
        quality = row[qualityId]
        level = row[levelId]
        traitDescMap[level + ":" + quality] = row[traitDescId]
    
    
    
outputArray = {}

for key, value in itemDataMap.items():
    #print(key)

    iterRows = iter(value['levels'])
    firstValue = next(iterRows)
    targetValue = firstValue.replace(":", ", ")

    #print(firstValue)
    outputArray[firstValue] = "\t{0:<8} => array({1}),".format("'" + firstValue + "'", targetValue)
    #print(outputArray[firstValue])
    
    for row in iterRows:
        #print("\t" + row)
        outputArray[row] = "\t{0:<8} => array({1}),".format("'" + row + "'", targetValue)
        #print(outputArray[firstValue])


def NumericCompare(x, y):
    values1 = x.split(":")
    values2 = y.split(":")

    l1 = int(values1[0])
    t1 = int(values1[1])
    l2 = int(values2[0])
    t2 = int(values2[1])

    if (l1 == l2): return t1 - t2
    return l1 - l2



#for key in sorted(outputArray.iterkeys(), cmp=NumericCompare):
    #print (outputArray[key])


for key in sorted(maxChargesMap.iterkeys(), cmp=NumericCompare):
    print ("\t{0:<8} => {1},".format("'" + key + "'", maxChargesMap[key]))


for key in sorted(traitDescMap.iterkeys(), cmp=NumericCompare):
    row = traitDescMap[key]
    if (row == ""): continue
    value = re.findall(r'\d+', row)[0]
    print ("\t{0:<8} => {1},".format("'" + key + "'", value))


print("Found {0} unique items!".format(len(itemDataMap)))    



