'''
EsoLuaTokenizer -- Created by Daveh (dave@uesp.net) on 18 November 2014

This is a very basic tokenizer for ESO (Elder Scrolls Online) Lua scripts. It doesn't
follow the Lua grammar exactly but only good enough to parse all known scripts in ESO.
'''
import sys
import os.path


class Token:
    unknown  = -1
    none     = 0
    keyword  = 1
    name     = 2
    string   = 3
    number   = 4
    comment  = 5
    operator = 6
    other    = 7

    TOKEN_STRINGS = { -1:"unknown", 0:"none", 1:"keyword", 2:"name", 3:"string", 4:"number", 5:"comment", 6:"operator", 7:"other" }
    
    @staticmethod
    def toString(t):
        if (t in Token.TOKEN_STRINGS):
            return Token.TOKEN_STRINGS[t]
        else:
            return str(t)


class CLuaTokenIterator:
    
    def __init__(self, tokens = None, index = 0):
        self.Start(tokens, index)


    def Start(self, tokens, index):
        self.startIndex = index
        self.index = index
        self.lastToken = tokens[index]
        self.tokens = tokens
        self.isError = False
        self.errorMsg = ""

        if (self.lastToken == None):
            self.lastToken = CLuaToken()


    def GetCurrentPos(self):
        if (not self.lastToken): return (None, None)
        return (self.lastToken.linePos, self.lastToken.charPos)


    def Peek(self, tokenType, tokenName = ""):
        
        if (self.isError):
            return False

        if (self.index >= len(self.tokens)):
            return False

        if (tokenType != Token.none and self.tokens[self.index].type != tokenType):
            return False

        if (tokenName != "" and self.tokens[self.index].token != tokenName):
            return False

        return True


    def SeekIndex(self, deltaIndex):
        targetIndex = self.index + deltaIndex
        
        if (targetIndex < 0 or targetIndex >= len(self.tokens)):
            return None

        self.index = targetIndex;
        self.isError = False
        self.lastToken = self.tokens[self.index]
        
        return self.lastToken


    def SeekAbs(self, index):
        targetIndex = index
        
        if (targetIndex < 0 or targetIndex >= len(self.tokens)):
            return None

        self.index = targetIndex;
        self.isError = False
        self.lastToken = self.tokens[self.index]
        
        return self.lastToken


    def PeekIndex(self, deltaIndex, tokenType, tokenName = ""):
        
        if (self.isError):
            return False

        targetIndex = self.index + deltaIndex

        if (targetIndex < 0 or targetIndex >= len(self.tokens)):
            return False

        if (tokenType != Token.none and self.tokens[targetIndex].type != tokenType):
            return False

        if (tokenName != "" and self.tokens[targetIndex].token != tokenName):
            return False

        return True


    def PeekBehind(self, tokenType, tokenName = ""):
        
        if (self.isError):
            return False

        if (self.index <= 0 or self.index-1 >= len(self.tokens)):
            return False

        if (tokenType != Token.none and self.tokens[self.index-1].type != tokenType):
            return False

        if (tokenName != "" and self.tokens[self.index-1].token != tokenName):
            return False

        return True


    def ConsumeBehindToBracket(self, startBracket, endBracket):
        tokenType = Token.operator
        bracketCount = 0        
        
        while not self.isError:
            
            if (self.index >= len(self.tokens) or self.index < 0):
                self.isError = True
                self.errorMsg = "ERROR {0}:{1} -- Unexpected end of file found, expected a {2}!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType))
                self.Report()
                return None

            self.lastToken = self.tokens[self.index]

            if (self.lastToken.type == Token.operator and self.lastToken.token == endBracket):
                bracketCount += 1
            elif (self.lastToken.type == Token.operator and self.lastToken.token == startBracket):
                bracketCount -= 1
                if (bracketCount == 0): break

            self.index -= 1
            self.isError = False

        return self.ConsumeBehind(Token.operator, startBracket)
    

    def ConsumeToBracket(self, startBracket, endBracket):
        tokenType = Token.operator
        bracketCount = 0        
        
        while not self.isError:
            
            if (self.index >= len(self.tokens)):
                self.isError = True
                self.errorMsg = "ERROR {0}:{1} -- Unexpected end of file found, expected a {2}!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType))
                self.Report()
                return None

            self.lastToken = self.tokens[self.index]

            if (self.lastToken.type == Token.operator and self.lastToken.token == startBracket):
                bracketCount += 1
            elif (self.lastToken.type == Token.operator and self.lastToken.token == endBracket):
                bracketCount -= 1
                if (bracketCount == 0): break

            self.index += 1
            self.isError = False

        return self.Consume(Token.operator, endBracket)


    def GetTokenIndex(self, deltaIndex):
        targetIndex = self.index + deltaIndex
        if (targetIndex < 0 or targetIndex >= len(self.tokens)): return None
        return self.tokens[targetIndex]


    def ConsumeUpTo(self, tokenType = Token.none, tokenName = ""):
        return self.ConsumeTo(tokenType, tokenName, False)
        

    def ConsumeTo(self, tokenType = Token.none, tokenName = "", includeLast = True):
        
        while not self.isError:
            
            if (self.index >= len(self.tokens)):
                self.isError = True
                self.errorMsg = "ERROR {0}:{1} -- Unexpected end of file found, expected a {2}!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType))
                self.Report()
                return None

            self.lastToken = self.tokens[self.index]

            if (tokenType == Token.none or self.lastToken.type == tokenType):
                if (tokenName != "" and self.lastToken.token == tokenName):
                    break

            self.index += 1
            self.isError = False

        if (includeLast): return self.Consume(tokenType, tokenName)
        return self.lastToken


    def ConsumeBehindTo(self, tokenType = Token.none, tokenName = ""):
        
        while not self.isError:
            
            if (self.index < 0 or self.index >= len(self.tokens)):
                self.isError = True
                self.errorMsg = "ERROR {0}:{1} -- Unexpected end of file found, expected a {2}!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType))
                self.Report()
                return None

            self.lastToken = self.tokens[self.index]

            if (tokenType == Token.none or self.lastToken.type == tokenType):
                if (tokenName != "" and self.lastToken.token == tokenName):
                    break

            self.index -= 1
            self.isError = False

        return self.ConsumeBehind(tokenType, tokenName)


    def Consume(self, tokenType = Token.none, tokenName = ""):
        
        if (self.isError): return None
        
        if (self.index >= len(self.tokens)):
            self.isError = True
            self.errorMsg = "ERROR {0}:{1} -- Unexpected end of file found, expected a {2}!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType))
            self.Report()
            return None

        self.lastToken = self.tokens[self.index]

        if (tokenType != Token.none and self.lastToken.type != tokenType):
            self.isError = True
            self.errorMsg = "ERROR {0}:{1} -- Expected a {2}({4}) but found a {3}({5})!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType), Token.toString(self.lastToken.type), tokenName, self.lastToken.token)
            self.Report()
            return None

        if (tokenName != "" and self.lastToken.token != tokenName):
            self.isError = True
            self.errorMsg = "ERROR {0}:{1} -- Expected '{2}' but found '{3}'!".format(self.lastToken.linePos, self.lastToken.charPos, tokenName, self.lastToken.token)
            self.Report()
            return None

        self.isError = False
        self.index += 1
        return self.lastToken


    def ConsumeBehind(self, tokenType = Token.none, tokenName = ""):
        
        if (self.isError): return None
        
        if (self.index >= len(self.tokens) or self.index < 0):
            self.isError = True
            self.errorMsg = "ERROR {0}:{1} -- Unexpected end of file found, expected a {2}!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType))
            self.Report()
            return None

        self.lastToken = self.tokens[self.index]

        if (tokenType != Token.none and self.lastToken.type != tokenType):
            self.isError = True
            self.errorMsg = "ERROR {0}:{1} -- Expected a {2}({4}) but found a {3}({5})!".format(self.lastToken.linePos, self.lastToken.charPos, Token.toString(tokenType), Token.toString(self.lastToken.type), tokenName, self.lastToken.token)
            self.Report()
            return None

        if (tokenName != "" and self.lastToken.token != tokenName):
            self.isError = True
            self.errorMsg = "ERROR {0}:{1} -- Expected '{2}' but found '{3}'!".format(self.lastToken.linePos, self.lastToken.charPos, tokenName, self.lastToken.token)
            self.Report()
            return None

        self.isError = False
        self.index -= 1
        return self.lastToken


    def IsValidDeltaIndex(self, deltaIndex):
        targetIndex = self.index + deltaIndex
        return targetIndex >= 0 and targetIndex < len(self.tokens)


    def IsValid(self):
        return not self.isError and self.index < len(self.tokens) and self.index >= 0


    def Report(self, customMsg = ""):
        errorMsg = ""

        token = self.lastToken
        if (not token): token = CLuaToken()
        
        if (self.isError):
            errorMsg = "\t" + self.errorMsg
        elif (self.index >= len(self.tokens)):
            errorMsg = "\tReached end of tokens!"

        if (customMsg != ""):
            print "\tERROR {0}:{1} -- {2} (token = '{3}')".format(token.linePos, token.charPos, customMsg, token.token)
            
        if (errorMsg != ""):
            print errorMsg
    

class CLuaToken:

    def __init__(self):
        self.type = Token.none
        self.token = ""
        self.linePos = -1
        self.charPos = -1
        self.charIndex = -1



class CLuaTokenizer:
    
    LUA_KEYWORDS = [
         "and",       "break",     "do",        "else",      "elseif",    "end",
         "false",     "for",       "function",  "goto",      "if",        "in",
         "local",     "nil",       "not",       "or",        "repeat",    "return",
         "then",      "true",      "until",     "while",
    ]

    LUA_OPERATORS = [
         "+",     "-",     "*",     "/",     "%",     "^",     "#",
         "==",    "~=",    "<=",    ">=",    "<",     ">",     "=",
         "(",     ")",     "{",     "}",     "[",     "]",     "::",
         ";",     ":",     ",",     ".",     "..",    "...",
    ]

    KEEP_COMMENTS = False


    def __init__(self):
        self.charPos = 0
        self.linePos = 0
        self.origSource = ""
        self.sourceLines = []
        self.tokens = []
        self.tokensWithComments = []


    @staticmethod
    def IsDigit(c):
        return c in "0123456789"

    @staticmethod
    def IsHexDigit(c):
        return c in "0123456789ABCDEFabcdef"


    @staticmethod
    def IsAlphaName(c):
        return c in "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_"


    @staticmethod
    def IsPunct(c):
        return c in "+-*/%^#=~<>(){}[]:;,."


    @staticmethod
    def IsSpace(c):
        return c in " \t\r"
    

    @staticmethod
    def IsLineFeed(c):
        return c in "\n"


    @staticmethod
    def IsStringChar(c):
        return c in "\"'"


    def Rebuild(self, startIndex, endIndex):

        if (startIndex < 0): startIndex = 0
        if (endIndex >= len(self.tokens)): endIndex = len(self.tokens) - 1
        if (startIndex > endIndex): return ""

        stringStartIndex = self.tokens[startIndex].charIndex
        stringEndIndex = self.tokens[endIndex].charIndex + len(self.tokens[endIndex].token)

        return self.origSource[stringStartIndex:stringEndIndex]


    def ReadTokenComment(self, i):
        startCharPos = self.charPos
        startLinePos = self.linePos
        startIndex = i

        while (i < len(self.origSource) and self.origSource[i] != "\n"):
            i += 1
            self.charPos += 1

        if (i < len(self.origSource) and self.origSource[i] == "\n"):
            i -= 1
            self.charPos -= 1

        if (self.KEEP_COMMENTS):
            newToken = CLuaToken()
            newToken.linePos = startLinePos
            newToken.charPos = startCharPos
            newToken.charIndex = startIndex
            newToken.token = self.origSource[startIndex:i+1]
            newToken.type = Token.comment
            self.tokens.append(newToken)
            
        return i, True


    def ReadTokenLongComment(self, i):
        startCharPos = self.charPos
        startLinePos = self.linePos
        startIndex = i

        # TODO: Parse end of long comment properly
        while (i+2 < len(self.origSource) and self.origSource[i:i+2] != "]]"):
            if (self.origSource[i] == "\n"):
                self.linePos += 1
                self.charPos = 0
                    
            i += 1
            self.charPos += 1

        if (i+2 >= len(self.origSource)):
            print "\tERROR {0}:{1} -- Unterminated long comment found!".format(startLinePos, startCharPos)
            return i, False

        i += 1
        self.charPos += 1

        if (self.KEEP_COMMENTS):
            newToken = CLuaToken()
            newToken.linePos = startLinePos
            newToken.charPos = startCharPos
            newToken.charIndex = startIndex
            newToken.token = self.origSource[startIndex:i+1]
            newToken.type = Token.comment
            self.tokens.append(newToken)
            
        return i, True


    def ReadTokenPunct(self, i):
        startCharPos = self.charPos
        startLinePos = self.linePos
        startIndex = i

        while (i < len(self.origSource) and self.IsPunct(self.origSource[i])):
            i += 1
            self.charPos += 1

        while i >= startIndex and not self.origSource[startIndex:i+1] in self.LUA_OPERATORS:
            op = self.origSource[startIndex:i+1]

                # Special case for comments
            if (op == "--[[" or op == "--[=[" or op == "--[==[" or op == "--[===[" or op == "--[====[" or op == "--[=====[" ):
                self.charPos = startCharPos
                return self.ReadTokenLongComment(startIndex)
            elif (op == "--"):
                self.charPos = startCharPos
                return self.ReadTokenComment(startIndex)
                
            i -= 1
            self.charPos -= 1

        if (i < startIndex):
            i = startIndex
            self.charPos += 1
            print "\tERROR {0}:{1} -- Unknown punctuation operator '{2}' found!".format(self.linePos, self.charPos, self.origSource[i])
            return i, False

        newToken = CLuaToken()
        newToken.linePos = startLinePos
        newToken.charPos = startCharPos
        newToken.charIndex = startIndex
        newToken.token = self.origSource[startIndex:i+1]
        newToken.type = Token.operator
        
        self.tokens.append(newToken)            

        return i, True
    

    def ReadTokenDigit(self, i):
        startCharPos = self.charPos
        startLinePos = self.linePos
        startIndex = i

        i += 1
        self.charPos += 1

        while (i < len(self.origSource) and self.IsDigit(self.origSource[i])):
            i += 1
            self.charPos += 1

        if (i < len(self.origSource) and self.origSource[i] in "xX"):
            i += 1
            self.charPos += 1

            while (i < len(self.origSource) and self.IsHexDigit(self.origSource[i])):
                i += 1
                self.charPos += 1
                
        if (i < len(self.origSource) and self.origSource[i] == '.'):
            i += 1
            self.charPos += 1

            while (i < len(self.origSource) and self.IsDigit(self.origSource[i])):
                i += 1
                self.charPos += 1

        if (i < len(self.origSource) and self.origSource[i] in "eEpP"):
            i += 1
            self.charPos += 1

            if (i < len(self.origSource) and self.origSource[i] in "-+"):
                i += 1
                self.charPos += 1

            while (i < len(self.origSource) and self.IsDigit(self.origSource[i])):
                i += 1
                self.charPos += 1

        i -= 1
        self.charPos -= 1

        newToken = CLuaToken()
        newToken.linePos = startLinePos
        newToken.charPos = startCharPos
        newToken.charIndex = startIndex
        newToken.token = self.origSource[startIndex:i+1]
        newToken.type = Token.number
        
        self.tokens.append(newToken)            

        return i, True


    def ReadTokenName(self, i):
        startCharPos = self.charPos
        startLinePos = self.linePos
        startIndex = i

        while (i < len(self.origSource) and self.IsAlphaName(self.origSource[i])):
            i += 1
            self.charPos += 1

        i -= 1
        self.charPos -= 1

        newToken = CLuaToken()
        newToken.linePos = startLinePos
        newToken.charPos = startCharPos
        newToken.charIndex = startIndex
        newToken.token = self.origSource[startIndex:i+1]

        if (newToken.token in self.LUA_KEYWORDS):
            newToken.type = Token.keyword
        else:
            newToken.type = Token.name

        self.tokens.append(newToken)            

        return i, True


    def ReadTokenString(self, i):
        startCharPos = self.charPos + 1
        startLinePos = self.linePos
        stringChar = self.origSource[i]
        startIndex = i
        
        i += 1
        self.charPos += 1
        lastEscape = False

        while (i < len(self.origSource)):
            
            c = self.origSource[i]

            if (lastEscape):
                if (c == "\n"):
                    self.linePos += 1
                    self.charPos = 0
                    
                lastEscape = False      
            elif (c == stringChar):
                break
            elif (c == "\n"):
                print "\tERROR {0}:{1} -- Unterminated string constant found!".format(self.linePos, self.charPos)
                return i, False
            elif (c == "\\"):
                lastEscape = True
            
            i += 1
            self.charPos += 1

        newToken = CLuaToken()
        
        newToken.type = Token.string
        newToken.linePos = startLinePos
        newToken.charPos = startCharPos
        newToken.token = self.origSource[startIndex:i+1]
        newToken.charIndex = startIndex

        self.tokens.append(newToken)
        return i, True
    

    def TokenizeFile(self, filename):
        luaContents = open(filename, "r").read()
        return self.Tokenize(luaContents)


    def Tokenize(self, luaString):
        self.origSource = luaString
        self.sourceLines = []
        self.tokens = []

        self.charPos = 0
        self.linePos = 1
        isOk = True
        i = 0

        while i < len(self.origSource) and isOk:
            c = self.origSource[i]
            self.charPos += 1

            if (self.IsLineFeed(c)):
                self.charPos = 0
                self.linePos += 1
            elif (self.IsSpace(c)):
                pass
            elif (self.IsPunct(c)):
                i, isOk = self.ReadTokenPunct(i)
            elif (self.IsDigit(c)):
                i, isOk = self.ReadTokenDigit(i)
            elif (self.IsAlphaName(c)):
                i, isOk = self.ReadTokenName(i)
            elif (self.IsStringChar(c)):
                i, isOk = self.ReadTokenString(i)
            else:
                print "\tERROR Line {0}:{1} -- Unknown character '{2}' found!".format(self.linePos, self.charPos, c)

            i += 1

        if (not isOk):
            print "Stopped Lua tokenizing due to error!"
            
        return isOk


def TestTokenAll(path):
    tokenizer = CLuaTokenizer()
    fileCount = 0

    for root, dirs, files in os.walk(path):
        for filename in files:
            if (filename.endswith(".lua")):
                fullFilename = root + "\\" + filename
                fileCount += 1
                print fileCount, fullFilename
                tokenizer.TokenizeFile(fullFilename)
                
            
    return


# test = CLuaTokenizer()
# test.TokenizeFile("d:\\esoexport\\gamemnf10\\esoui\\libraries\\zo_menubar\\zo_menubar.lua")
# print "Found {0} tokens...".format(len(test.tokens))

# TestTokenAll("d:\\esoexport\\gamemnf10\\esoui\\")

'''
for t in test.tokens:
    if (t.type == Token.string):
        print "{0}:{1} = \"{2}\"".format(t.linePos, t.charPos, t.token)
    elif (t.type == Token.keyword):
        print "{0}:{1} = Keyword {2}".format(t.linePos, t.charPos, t.token)
    else:
        print "{0}:{1} = {2}".format(t.linePos, t.charPos, t.token)

'''
