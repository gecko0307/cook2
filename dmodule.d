/*
Copyright (c) 2011-2013 Timur Gafarov 

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dmodule;

import std.datetime;
import std.file;
import std.array;
import lexer;

/* 
 * Source code module, with all dependency information
 */
final class DModule
{
    public:
    SysTime lastModified;
    string[] imports;
    DModule[string] backdeps;
    string packageName;
    bool forceRebuild = false;
    bool rescan = true;

    override string toString() 
    {
        string output = lastModified.toISOExtString() ~ " ";
        foreach(i,v; imports) 
            output ~= v ~ " ";
        return output;
    }
}

// TODO: needs refactoring
string[] getModuleDependencies(string filename, string ext)
{
    auto text = readText(filename);
    auto lex = new Lexer(text);
    lex.addDelimiters([";", ",", "=", ":", "(", ")", "{", "}"]);
    string[] imports;
    bool expectModuleDef = false;
    bool importStatement = false;
    bool ignoreUntilSemicolon = false;
    string tmpModuleName = "";

    string lexeme = "";
    do 
    {
        lexeme = lex.getLexeme();
        if (lexeme.length > 0)
        {
            if (expectModuleDef)
            {
                expectModuleDef = false;
                tmpModuleName = lexeme;
            }
            else if (lexeme == "import")
            {
                expectModuleDef = true;
                importStatement = true;
            }
            else if ((lexeme == ",") && importStatement && !ignoreUntilSemicolon)
            {
                imports ~= moduleToPath(tmpModuleName, ext);
                expectModuleDef = true;
            }
            else if ((lexeme == ";") && importStatement)
            {
                imports ~= moduleToPath(tmpModuleName, ext);
                importStatement = false;
            }
            else if ((lexeme == "=") && importStatement && !ignoreUntilSemicolon)
            {
                expectModuleDef = true;
            }
            else if ((lexeme == ":") && importStatement && !ignoreUntilSemicolon)
            {
                ignoreUntilSemicolon = true;
            }
        }
    } 
    while (lexeme.length > 0);

    return imports;
}

string moduleToPath(string modulename, string ext)
{
    string fname = modulename;
    fname = replace(fname, ".", "/");
    fname = fname ~ ext;
    return fname;	
}

string pathToModule(string path)
{
    string mdl = path;
    mdl = replace(mdl, "/", ".");
    return mdl;	
}

