SyntaxHighlighter.brushes.Lua = function()
{
	var keywords =	'break do end else elseif function if local nil not or repeat return and then until while this';
	var funcs = 'math\\.\\w+ string\\.\\w+ os\\.\\w+ debug\\.\\w+ io\\.\\w+ error fopen dofile coroutine\\.\\w+ arg getmetatable ipairs loadfile loadlib loadstring longjmp print rawget rawset seek setmetatable assert tonumber tostring';

	this.regexList = [
		{ regex: new RegExp('--\\[\\[[\\s\\S]*?\\]\\]--', 'gm'),	css: 'comments' },
		{ regex: new RegExp('--[^\\[\n]?.*$', 'gm'),			    css: 'comments' },	// one line comments
		{ regex: SyntaxHighlighter.regexLib.doubleQuotedString,     css: 'string' },    // strings
		{ regex: SyntaxHighlighter.regexLib.singleQuotedString,     css: 'string' },    // strings
		{ regex: new RegExp(this.getKeywords(keywords), 'gm'),		css: 'keyword' },	// keyword
		{ regex: new RegExp(this.getKeywords(funcs), 'gm'),		    css: 'func' },		// functions
		{ regex: new RegExp('[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?', 'gm'),	css: 'number' },	// numbers		
		];
}

SyntaxHighlighter.brushes.Lua.prototype	= new SyntaxHighlighter.Highlighter();
SyntaxHighlighter.brushes.Lua.aliases = ['lua'];

