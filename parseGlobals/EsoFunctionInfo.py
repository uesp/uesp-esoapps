import csv
import collections
import os.path
import re
import operator
import sys
import datetime
import shutil
import ntpath
import EsoLuaFile
import EsoLuaTokenizer
from EsoLuaTokenizer import CLuaTokenizer
from EsoLuaTokenizer import CLuaTokenIterator
from EsoLuaTokenizer import Token
from EsoLuaFile import CEsoLuaFile


class CEsoFunctionInfo:
    
    def __init__(self):
        self.name = ""
        self.niceName = ""
        self.fullName = ""
        self.fullString = ""
        self.fullDefString = ""
        self.filename = ""
        self.namespace = ""
        self.namespaceType = ""
        self.isLocal = False
        self.isObject = False
        self.allParams = ""
        self.value = ""
        self.params = []
        self.startLinePos = -1
        self.startCharPos = -1
        self.startTokenIndex = -1
        self.defEndLinePos = -1
        self.defEndCharPos = -1
        self.defEndTokenIndex = -1
        self.endLinePos = -1
        self.endCharPos = -1
        self.endTokenIndex = -1


class CEsoFunctionCallInfo:
    
    def __init__(self):
        self.filename = ""
        self.startLinePos = ""
        self.startCharPos = ""
        self.startTokenIndex = -1
        self.endLinePos = ""
        self.endCharPos = ""
        self.endTokenIndex = -1
        self.fullString = ""
        self.allVariables = ""
        self.variables = []
        self.name = ""
        self.fullName = ""
        self.niceName = ""
        self.allParams = ""
        self.params = []


def ParseLuaFunctionCall(esoLuaFile, tokenIter):
    origTokenIndex = tokenIter.index

        # Find start of function name
    while tokenIter.IsValid():

        if (tokenIter.PeekIndex(-1, Token.operator, ".") or tokenIter.PeekIndex(-1, Token.operator, ":")):
            tokenIter.SeekIndex(-1)
            isBracket = False
            
            if (tokenIter.PeekIndex(-1, Token.operator, ")")):
                tokenIter.ConsumeBehindToBracket("(", ")")
                tokenIter.Consume()
                isBracket = True
            elif (tokenIter.PeekIndex(-1, Token.operator, "]")):
                tokenIter.ConsumeBehindTo(Token.operator, "[")
                tokenIter.Consume()
            
            if (tokenIter.PeekIndex(-1, Token.name)):
                tokenIter.SeekIndex(-1)
            elif isBracket:
                break
            else:
                tokenIter.Report("1Unknown function call format found!")
                break
        else:
            break

        # Find start of function variables
    if tokenIter.Peek(Token.operator, "="):
        pass

    tokenIter.Consume()

    if (not tokenIter.IsValid()):
        tokenIter.Report("2Unknown function call format found!")
        tokenIter.SeekAbs(origTokenIndex + 1)
        return None

    newFuncCall = CEsoFunctionCallInfo()
    newFuncCall.filename = esoLuaFile.relFilename
    newFuncCall.startTokenIndex = tokenIter.index - 1
    newFuncCall.startLinePos = tokenIter.lastToken.linePos
    newFuncCall.startCharPos = tokenIter.lastToken.charPos

    while tokenIter.IsValid() and tokenIter.index < origTokenIndex:
        tokenIter.ConsumeUpTo(Token.operator, "(")
        if (tokenIter.index < origTokenIndex): tokenIter.Consume()
        
    newFuncCall.name = tokenIter.GetTokenIndex(-1).token
    nameEndTokenIndex = tokenIter.index - 1
    startParamTokenIndex = tokenIter.index + 1

    token = tokenIter.ConsumeToBracket("(", ")")

    if token is None:
        tokenIter.Report("3Unknown function call format found!")
        tokenIter.SeekAbs(origTokenIndex + 1)
        return None

    newFuncCall.endTokenIndex = tokenIter.index - 1
    newFuncCall.endLinePos = tokenIter.lastToken.linePos
    newFuncCall.endCharPos = tokenIter.lastToken.charPos + len(tokenIter.lastToken.token) - 1

    newFuncCall.fullString = esoLuaFile.tokenizer.Rebuild(newFuncCall.startTokenIndex, newFuncCall.endTokenIndex)
    newFuncCall.allVariables = ""
    newFuncCall.fullName = esoLuaFile.tokenizer.Rebuild(newFuncCall.startTokenIndex, nameEndTokenIndex)
    newFuncCall.niceName =  newFuncCall.fullName.replace(":", ".")
    newFuncCall.allParams = esoLuaFile.tokenizer.Rebuild(startParamTokenIndex, newFuncCall.endTokenIndex - 1)

    tokenIter.SeekAbs(origTokenIndex + 1)
    return newFuncCall


def FindFunctionCalls(esoLuaFile):
    functionCalls = []
    tokens = esoLuaFile.GetTokens()
    tokenIter = CLuaTokenIterator(esoLuaFile.GetTokens(), 0)

    while tokenIter.IsValid():
        
        if (tokenIter.Peek(Token.keyword, "function")):
            tokenIter.ConsumeTo(Token.operator, ")")
        elif (tokenIter.Peek(Token.name) and tokenIter.PeekIndex(1, Token.operator, "(")):
            newFuncCall = ParseLuaFunctionCall(esoLuaFile, tokenIter)
            if (newFuncCall): functionCalls.append(newFuncCall)
        else:
            tokenIter.Consume()
 
    return functionCalls


def FindAllFunctionCalls(esoLuaFiles):
    functionCalls = []

    print "Finding all function calls in {0} Lua files...".format(len(esoLuaFiles))

    for file in esoLuaFiles:
        print file.relFilename
        functionCalls.extend(FindFunctionCalls(file))

    print "\tFound {0} function calls!".format(len(functionCalls))
    return functionCalls


def ParseLuaFunction(esoLuaFile, i):
    tokens = esoLuaFile.GetTokens()
    token = tokens[i]
    newFunction = CEsoFunctionInfo()
    newFunction.filename = esoLuaFile.relFilename
    startIndex = i
    startNameTokenIndex = -1
    endNameTokenIndex = -1

    tokenIter = CLuaTokenIterator(tokens, i)

    if (tokenIter.PeekBehind(Token.keyword, "local")):
        tokenIter = CLuaTokenIterator(tokens, i - 1)
        startIndex = i - 1
        token = tokenIter.lastToken
        newFunction.startTokenIndex = tokenIter.index
        newFunction.startLinePos = token.linePos
        newFunction.startCharPos = token.charPos
    elif (tokenIter.PeekIndex(-1, Token.operator, "=")):
        deltaIndex = -1
                
        if (tokenIter.PeekIndex(-2, Token.name)):
            deltaIndex -= 1
            
            if (tokenIter.PeekIndex(-3, Token.operator, ".")):
                if (tokenIter.PeekIndex(-4, Token.name)):
                    deltaIndex -= 2
                    
            if (tokenIter.PeekIndex(deltaIndex-1, Token.keyword, "local")):
                deltaIndex -= 1
        elif (tokenIter.PeekIndex(-2, Token.operator, "]")):
            deltaIndex -= 1

            while (tokenIter.IsValidDeltaIndex(deltaIndex - 1) and not tokenIter.PeekIndex(deltaIndex - 1, Token.operator, "[")):
                deltaIndex -= 1

            if tokenIter.PeekIndex(deltaIndex - 1, Token.operator, "["):
                deltaIndex -= 1

                if tokenIter.PeekIndex(deltaIndex - 1, Token.name):
                    deltaIndex -= 1

            if (tokenIter.PeekIndex(deltaIndex - 1, Token.keyword, "local")):
                deltaIndex -= 1
        else:
            tokenIter.Report("Unknown function definition format found!")

        tokenIter = CLuaTokenIterator(tokens, i + deltaIndex)
        startIndex = i + deltaIndex
        newFunction.isObject = True
        token = tokenIter.lastToken
        newFunction.startTokenIndex = tokenIter.index
        newFunction.startLinePos = token.linePos
        newFunction.startCharPos = token.charPos

        if (tokenIter.Peek(Token.keyword, "local")):
            token = tokenIter.Consume(Token.keyword, "local")
            newFunction.isLocal = True

        startNameTokenIndex = tokenIter.index

        if (tokenIter.Peek(Token.name) and not tokenIter.PeekIndex(+1, Token.operator, "[")):
            token = tokenIter.Consume(Token.name)
                 
            if (tokenIter.Peek(Token.operator, ".")):
                newFunction.namespace = token.token
                newFunction.namespaceType = "."
                token = tokenIter.Consume(Token.operator, ".")

                token = tokenIter.Consume(Token.name)
                if (not token): return None, tokenIter.index

                newFunction.name = token.token
            else:
                newFunction.name = token.token
        elif (tokenIter.Peek(Token.operator, "[") or tokenIter.PeekIndex(+1, Token.operator, "[")):
            startArrayToken = tokenIter.index

            if (tokenIter.Peek(Token.name)):
                token = tokenIter.Consume(Token.name)
                
            token = tokenIter.Consume(Token.operator, "[")
            
            while (tokenIter.IsValid() and not tokenIter.Peek(Token.operator, "]")):
                token = tokenIter.Consume(Token.none)

            token = tokenIter.Consume(Token.operator, "]")
            if (not token): return None, tokenIter.index

            newFunction.name = esoLuaFile.tokenizer.Rebuild(startArrayToken, tokenIter.index - 1)
        elif (tokenIter.Peek(Token.operator, "=")):
            newFunction.name = ""
        else:
            print tokenIter.lastToken.token
            tokenIter.Report("Unknown function definition format found!") 
            return None, tokenIter.index

        endNameTokenIndex = tokenIter.index - 1

        token = tokenIter.Consume(Token.operator, "=")
        if (not token): return None, tokenIter.index
    else:
        token = tokenIter.lastToken
        newFunction.startTokenIndex = tokenIter.index
        newFunction.startLinePos = token.linePos
        newFunction.startCharPos = token.charPos

    if (tokenIter.Peek(Token.keyword, "local")):
        newFunction.isLocal = True
        tokenIter.Consume(Token.keyword, "local")

    token = tokenIter.Consume(Token.keyword, "function")
        
    if (tokenIter.Peek(Token.name)):
        startNameTokenIndex = tokenIter.index
        token = tokenIter.Consume(Token.name)

        if (tokenIter.Peek(Token.operator, ".") or tokenIter.Peek(Token.operator, ":")):
            newFunction.namespace = token.token
            token = tokenIter.Consume(Token.operator)
            newFunction.namespaceType = token.token

            token = tokenIter.Consume(Token.name)
            if (not token): return None, tokenIter.index

            newFunction.name = token.token
        else:
            newFunction.name = token.token

        endNameTokenIndex = tokenIter.index - 1

    token = tokenIter.Consume(Token.none, "(")
    if (not token): return None, tokenIter.index

        # Function parameters
    bracketCount = 0
    startParamIndex = tokenIter.index
    token = tokenIter.Consume(Token.none)

    while (token):
        if (token.token == "("):
            bracketCount += 1
        elif (token.token == ")"):
            if bracketCount <= 0:
                break
            else:
                bracketCount -= 1
        elif (token.token == ","):
            lastParamIndex = tokenIter.index
        elif (token.type == Token.name):

            if (tokenIter.Peek(Token.none, ":")):
                tokenIter.Consume(Token.none)

                token2 = tokenIter.Consume(Token.name)

                if (not token2):
                    tokenIter.isError = False
                    newFunction.params.append(token.token + ":")
                else:
                    token = token2
                    newFunction.params.append(token.token + ":" + token2.token)
            
            else:
                newFunction.params.append(token.token)
            
        elif (token.token == "..."):
            newFunction.params.append(token.token)
        else:
            tokenIter.Report("Invalid function parameter '{0}' found!".format(token.token))
            
        token = tokenIter.Consume(Token.none)

    if (not token or token.token != ")"):
        tokenIter.Report("Unexpected end of file while looking for function parameter list!")
        return None, tokenIter.index

    newFunction.endDefTokenIndex = tokenIter.index - 1
    newFunction.endDefLinePos = token.linePos
    newFunction.endDefCharPos = token.charPos

        # Find end of function
    blockCount = 0
    token = tokenIter.Consume(Token.none)

    while (token):
        if (token.token == "if" or token.token == "do"):
            blockCount += 1
        elif (token.token == "end"):
            if blockCount <= 0:
                break
            else:
                blockCount -= 1
            
        token = tokenIter.Consume(Token.none)

    if (not token or token.token != "end"):
        tokenIter.Report("Unexpected end of file while looking for end of function block!")
        return None, tokenIter.index

    newFunction.endLinePos = token.linePos
    newFunction.endCharPos = token.charPos + 3
    newFunction.endTokenIndex = tokenIter.index - 1

    if (newFunction.namespace != ""):
        newFunction.niceName = newFunction.namespace + "." + newFunction.name
    else:
        newFunction.niceName = newFunction.name

    newFunction.allParams = esoLuaFile.tokenizer.Rebuild(startParamIndex, newFunction.endDefTokenIndex - 1)
    newFunction.fullName = esoLuaFile.tokenizer.Rebuild(startNameTokenIndex, endNameTokenIndex)
    newFunction.fullDefString = esoLuaFile.tokenizer.Rebuild(startIndex, newFunction.endDefTokenIndex)
    newFunction.fullString = esoLuaFile.tokenizer.Rebuild(startIndex, newFunction.endTokenIndex)

    return newFunction, i


def FindFunctions(esoLuaFile):
    functions = []
    tokens = esoLuaFile.GetTokens()
    i = 0

    while i < len(tokens):
        token = tokens[i]
        
        if (token.type == EsoLuaTokenizer.Token.keyword and token.token == "function"):
            newFunc, lastDefIndex = ParseLuaFunction(esoLuaFile, i)
            if (newFunc): functions.append(newFunc)
        
        i += 1
 
    return functions


def FindAllFunctions(esoLuaFiles):
    functions = []

    print "Finding all functions in {0} Lua files...".format(len(esoLuaFiles))

    for file in esoLuaFiles:
        functions.extend(FindFunctions(file))

    print "\tFound {0} functions!".format(len(functions))
    return functions
