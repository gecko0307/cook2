/*
Copyright (c) 2014 Timur Gafarov 

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

module project;

import std.file;
import std.datetime;

import cmdopt;
import conf;
import dmodule;

class Project
{
    CmdOptions ops;
    Config config;

    int[string] versionIds;
    int[string] debugIds;
    string ext;

    DModule[string] modules;
    string mainModuleFilename;

    this(CmdOptions cmdops, Config conf)
    {
        ext = conf.get("source.ext"); //".d";
        ops = cmdops;
        config = conf;

        version(Posix)   versionIds["Posix"] = 1;
        version(linux)   versionIds["linux"] = 1;
        version(Windows) versionIds["Windows"] = 1;
        version(Win32)   versionIds["Win32"] = 1;
        version(Win64)   versionIds["Win64"] = 1;
        version(OSX)     versionIds["OSX"] = 1;
        version(X86)     versionIds["X86"] = 1;
        version(X86_64)  versionIds["X86_64"] = 1;
        versionIds["D_Version2"] = 1;
    }

    DModule addModule(string filename)
    {
        auto m = new DModule(filename, ext);
        m.versionIds = versionIds.dup;
        m.debugIds = debugIds.dup;
        modules[filename] = m;
        return m;
    }
}

