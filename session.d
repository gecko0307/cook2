/*
Copyright (c) 2013-2014 Timur Gafarov 

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

module session;

import std.stdio;
import std.path;
import std.file;
import std.string;
import std.datetime;
import std.conv;
import std.digest.crc;

import cmdopt;
import conf;
import lexer;
import dmodule;
import project;
import exdep;

class BuildSession
{
    CmdOptions ops;
    Config config;
    string[] versionIds;
    string[] debugIds;
    string[] externals;

    // Quit at any time without throwing an exception
    void quit(int code, string message = "")
    {
        if (message.length > 0)
            writefln("Cook session failed: %s", message);

        if (ops._debug_)
            printConfig();

        version(Windows) 
            std.process.system("pause");
        std.c.process.exit(code);
    }

    void printConfig()
    {
        writeln("Configuration:");
        string[] confContents;
        foreach(i, v; config.data)
        {
            string f = formatPattern(v, config, '%');
            confContents ~= std.string.format(" %s: %s", i, f);
        }
        confContents.sort;
        foreach(i, v; confContents)
            writeln(v);
    }

    this(CmdOptions cmdops, Config conf)
    {
        ops = cmdops;
        config = conf;
        prepare();
    }

    void prepare()
    {
        // Set default configuration keys
        string tempTarget = "main";
        config.set("profile", "default", false);
        config.set("prephase", "", false);
        config.set("postphase", "", false);
        config.set("source.language", "d", false);
        config.set("source.ext", ".d", false);
        config.set("compiler", "dmd", false);
        config.set("linker", "dmd", false);
        version(Windows) config.set("librarian", "lib", false);
        version(linux) config.set("librarian", "dmd", false);
        config.set("cflags", "", false); 
        config.set("lflags", "", false);
        //config.set("modules", ""); // TODO?
        config.set("obj.path", "", false);
        config.set("obj.path.use", "true", false);
        config.set("obj.ext", "", false);
        config.set("modules.main", "main", false);
        config.set("modules.forced", "", false);
        config.set("target", "", false);
        config.set("rc", "", false);
        config.set("modules.cache", "main.cache", false);
        config.set("project.compile", "%compiler% %cflags% -c %source% -of%object%", false);
        config.set("project.link", "%linker% %lflags% -of%target% %objects% %packages%", false);
        version(Windows) config.set("project.linklib", "%librarian% %lflags% -c -p32 -of%target% %objects%", false);
        version(linux) config.set("project.linklib", "%librarian% %lflags% -lib -of%target% %objects%", false);
        version(Windows) config.set("project.linkpkg", "%librarian% %lflags% -c -p32 -of%package% %objects%", false);
        version(linux) config.set("project.linkpkg", "%librarian% %lflags% -lib -of%package% %objects%", false);
        version(linux) config.set("project.run", "./%target%", false);
        version(Windows) config.set("project.run", "%target%", false);
        config.set("project.packages", "", false);
        version(Windows)
        {
            config.set("obj.path", "o_windows/");
            config.set("obj.ext", ".obj");
        }
        version(linux)
        {
            config.set("obj.path", "o_linux/");
            config.set("obj.ext", ".o");
            config.append("lflags", "-L-rpath -L\".\" -L-ldl ");
        }

        config.set("modules.maindir", ".");

        if (ops.targets.length)
        {
            // FIXME: currently we use only first given target
            string mainModule = ops.targets[0];
            config.set("modules.main", mainModule);

            // strip extension, if any
            if (extension(config.get("modules.main")) == ".d") 
                config.set("modules.main", config.get("modules.main")[0..$-2]);

            tempTarget = baseName(config.get("modules.main"));
            config.set("modules.cache", config.get("modules.main") ~ ".cache");
            
            string maindir = dirName(config.get("modules.main"));
            config.set("modules.maindir", maindir);
        }

        if (ops.output.length)
        {
            tempTarget = ops.output;
        }

        if (ops.clean)
        {
            if (exists(config.get("modules.cache"))) 
                std.file.remove(config.get("modules.cache"));
            // FIXME: use config for these
            if (exists("o_linux")) rmdirRecurse("o_linux");
            if (exists("o_windows")) rmdirRecurse("o_windows");
            quit(0);
        }

        if (ops.cache.length) 
            config.set("modules.cache", ops.cache);

        if (ops.rc.length) 
            config.set("rc", ops.rc);

        if (ops.cflags.length) 
            config.append("cflags", ops.cflags ~ " ");

        if (ops.lflags.length) 
            config.append("lflags", ops.lflags ~ " ");

        if ("./" ~ tempTarget != ops.program)
            config.set("target", tempTarget);
        else 
            quit(1, "illegal target name: \"" ~ tempTarget ~ "\" (conflicts with Cook executable)");

        version(Windows)
        {
            if (ops.noconsole) 
                config.append("lflags", "-L/exet:nt/su:windows ");
        }

        // Read user-wide default configuration
        string userConfigFilename = home(".cook/default.conf");
        if (exists(userConfigFilename))
        {
            readConfiguration(config, userConfigFilename);
        }

        // Read default configuration
        string defaultConfigFilename = "default.conf";
        if (exists(defaultConfigFilename))
        {
            readConfiguration(config, defaultConfigFilename);
        }

        // Read project configuration
        if (ops.conf.length) 
        {
            if (exists(ops.conf))
                readConfiguration(config, ops.conf);
        }
        else
        {
            string configFilename = "./" ~ config.get("target") ~ ".conf";
            if (exists(configFilename))
                readConfiguration(config, configFilename);
        }

        config.append("cflags", " -I%modules.maindir% ");

        if (ops.release)
            config.append("cflags", " -release -O -inline -noboundscheck ");
    }

    void build(Project proj)
    {
        string externalsStr = config.get("project.external");
        if (externalsStr.length)
            externals = split(externalsStr);

        setVersionIds(proj);
        
        if (!ops.rebuild)
            readCache(proj);

        scanProjectHierarchy(proj);
        traceBackwardDependencies(proj);
        addForcedModules(proj);
        writeCache(proj);

        if (ops.dump.length)
        {
            if (ops.dump in proj.modules)
            {
                auto m = proj.modules[ops.dump];
                writefln("Filename: %s", m.filename);
                writefln("Package name: %s", m.packageName);
                writefln("Last modified: %s", m.lastModified);
                writefln("Imports: %s", m.importedFiles);
                writefln("Version ids: %s", m.versionIds);
                writefln("Debug ids: %s", m.debugIds);
            }
        }

        doPrephase();
        compileAndLink(proj);
        strip();
        run();
        if (ops._debug_)
            printConfig();
    }

    void setVersionIds(Project proj)
    {
        versionIds = split(config.get("version"));
        debugIds = split(config.get("debug"));

        foreach(v; versionIds)
            proj.versionIds[v] = 1;

        foreach(v; debugIds)
            proj.debugIds[v] = 1;

        string ver;
        foreach(i, v; versionIds)
        {
            ver ~= " -version=" ~ v;
        }
        if (ver.length)
            config.append("cflags", ver);

        string deb;
        foreach(i, v; debugIds)
        {
            deb ~= " -debug=" ~ v;
        }
        if (deb.length)
            config.append("cflags", deb);
    }

    void readCache(Project proj)
    {
        string cacheFile = config.get("modules.cache");
        if (exists(cacheFile) && !ops.nocache)
        {
            string cache = readText(cacheFile);
            foreach (line; splitLines(cache))
            {
                auto tokens = split(line);
                auto m = proj.addModule(tokens[0]);
                m.lastModified = SysTime.fromISOExtString(tokens[1]);
                m.globalFile = cast(bool)to!uint(tokens[2]);
                foreach (i; tokens[3..$])
                    m.addImportFile(i);        
            }
        }
    }

    void scanProjectHierarchy(Project proj)
    {
        proj.mainModuleFilename = config.get("modules.main") ~ config.get("source.ext");
        if (exists(proj.mainModuleFilename))
        {
            scanDependencies(proj, proj.mainModuleFilename);
        }
        else
            quit(1, "no main module found");

        if (proj.modules.length == 0) 
            quit(1, "no source files found");
    }

    void scanDependencies(Project proj, string fileName, bool globalFile = false)
    {
        DModule m;

        if (!exists(fileName))
            return;
        
        // if it is a new module
        if (!(fileName in proj.modules))
        {
            if (!ops.quiet) writefln("Analyzing \"%s\"...", fileName);
            m = proj.addModule(fileName);
            m.globalFile = globalFile;
            m.lastModified = timeLastModified(fileName);
            if (!m.buildDependencyList())
                quit(1, "cannot build proper dependency list");
            m.packageName = pathToModule(dirName(fileName));           
            scanModule(proj, m);
        }
        else // if we already have it
        {
            m = proj.modules[fileName];

            //TODO: cache this
            m.packageName = pathToModule(dirName(fileName));

            auto lm = timeLastModified(fileName);
            if (lm > m.lastModified)
            {
                if (!ops.quiet) writefln("Analyzing \"%s\"...", fileName);
                m.lastModified = lm;
                if (!m.buildDependencyList())
                    quit(1, "cannot build proper dependency list");
                m.forceRebuild = true;
                scanModule(proj, m);
            }    
        }
        
        foreach (mName; m.importedFiles)
        {
            scanDependencies(proj, mName);
        }
    }

    bool existsInExternals(
        string filename, 
        ref string externalFilename)
    {
        foreach(e; externals)
        {
            string f = e ~ "/" ~ filename;
            if (exists(f))
            {
                externalFilename = f;
                return true;
            }
        }
        return false;
    }

    void scanModule(Project proj, DModule m)
    {
        foreach(importedFile; m.importedFiles)
        {
            string subprojectFile = importedFile;
            
            if (config.get("modules.maindir") != ".")
                subprojectFile = 
                    config.get("modules.maindir") ~ "/" ~ importedFile;

            string externalFile;
            
            if (exists(importedFile))
                scanDependencies(proj, importedFile);
            else if (exists(subprojectFile))
                scanDependencies(proj, subprojectFile);
            else if (existsInExternals(subprojectFile, externalFile))
                scanDependencies(proj, externalFile, true);
            else
            {
                // Treat it as package import (<importedFile>/package.d)
                string pkgFile = 
                    stripExtension(importedFile) ~ "/"
                  ~ moduleToPath("package", config.get("source.ext"));
                  
                string subprojectPkgFile = 
                    config.get("modules.maindir") ~ "/"
                  ~ pkgFile;
                  
                if (exists(pkgFile))
                    scanDependencies(proj, pkgFile);
                else if (exists(subprojectPkgFile))
                    scanDependencies(proj, subprojectPkgFile);
            }
        }
    }

    void traceBackwardDependencies(Project proj)
    {
        if (!ops.nobacktrace)
        {
            foreach(modulei, modulev; proj.modules)
            {
                foreach (mName; modulev.importedFiles)
                {
                    if (mName in proj.modules)
                    {
                        auto imModule = proj.modules[mName];
                        imModule.backdeps[modulei] = modulev;
                    }
                }
            }
            foreach(mName, m; proj.modules)
            {
                foreach(i, v; m.backdeps)
                {
                    v.forceRebuild = v.forceRebuild || m.forceRebuild;
                }
            }
        }
    }

    void addForcedModules(Project proj)
    {
        foreach(fileName; split(config.get("modules.forced")))
        {
            if (exists(fileName))
            {
                DModule m = proj.addModule(fileName);
                m.lastModified = timeLastModified(fileName);

                if (!m.buildDependencyList())
                    quit(1, "cannot build proper dependency list");

                foreach(importedFile; m.importedFiles)
                {
                    if (exists(importedFile))
                        scanDependencies(proj, importedFile);
                }
            }
        }
    }

    void doPrephase()
    {
        uint retcode;
        string prephase = formatPattern(config.get("prephase"), config, '%');
        if (prephase != "")
        {
            if (!ops.quiet)
                writeln(prephase);
            if (!ops.emulate)
            {
                retcode = std.process.system(prephase);
                if (retcode)
                    quit(1, "Prephase error");
            }
        }
    }

    void writeCache(Project proj)
    {
        string cache;
        foreach (i, m; proj.modules)
        {
            //TODO: cache module's package also
            cache ~= i ~ " " ~ m.toString() ~ "\n";
        }

        if (!ops.emulate) 
            if (!ops.nocache)
                std.file.write(config.get("modules.cache"), cache);
    }

    void compileAndLink(Project proj)
    {
        string[] pkgList = split(config.get("project.packages"));

        string linkList;

        // Compile modules
        if (config.get("obj.path") != "")
            if (!exists(config.get("obj.path"))) 
                mkdir(config.get("obj.path"));
        bool terminate = false;
        foreach (i, v; proj.modules)
        {
            if (!terminate && exists(i))
            {
                string targetObjectName = i;
                string tobjext = extension(targetObjectName);
                targetObjectName = targetObjectName[0..$-tobjext.length] ~ config.get("obj.ext");
                string targetObject;
                if (v.globalFile)
                {
                    string hash = crc32Of(targetObjectName).crcHexString;
                    targetObject = home(format(".cook/obj/%s/%s%s", 
                        config.get("profile"), 
                        hash, 
                        config.get("obj.ext")));
                }
                else
                    targetObject = config.get("obj.path") ~ "/" ~ targetObjectName;

                if ((timeLastModified(i) > timeLastModified(targetObject, SysTime.min)) 
                    || v.forceRebuild
                    || ops.rebuild)
                {
                    if (config.get("obj.path.use") == "false")
                        targetObject = targetObjectName;

                    config.set("source", i);
                    config.set("object", targetObject);
                    string command = formatPattern(config.get("project.compile"), config, '%');
                    if (!ops.quiet)
                        writeln(command);
                    if (!ops.emulate)
                    {
                        auto retcode = std.process.system(command);
                        if (retcode)
                            terminate = true;
                    }
                }

                if (config.get("obj.path.use") == "false")
                    targetObject = targetObjectName;

                if (!matches(v.packageName, pkgList))
                    linkList ~= targetObject ~ " ";
            }
        }

        // If compilation error occured
        if (terminate)
        {
            quit(1, "compilation error");
        }

        // Compile resource file, if any
        version(Windows)
        {
            if (config.get("rc").length > 0)
            {
                string res = stripExtension(config.get("rc")) ~ ".res ";
                string command = "windres -i " ~ config.get("rc") ~ " -o " ~ res ~ "-O res";
                if (!ops.quiet)
                    writeln(command);
                if (!ops.emulate)
                {
                    auto retcode = std.process.system(command);
                    if (retcode)
                        quit(1);
                }
                config.append("lflags", res); 
            }
        }

        // Link packages, if any
        // WARNING: alpha stage, needs work!
        // TODO: do not relink a package, if it is unchanged
        // TODO: do not create a package, if it is empty
        string pkgLibList;
        foreach(pkg; pkgList)
        {
            string pkgLinkList;
            foreach(i, m; proj.modules)
            {
                if (m.packageName == pkg)
                {
                    string targetObjectName = i;
                    string tobjext = extension(targetObjectName);
                    targetObjectName = targetObjectName[0..$-tobjext.length] ~ config.get("obj.ext");

                    string targetObject = config.get("obj.path") ~ targetObjectName;
                    pkgLinkList ~= targetObject ~ " ";
                }
            }

            //TODO: pkgext should be a configuration key
            string pkgExt;
            version(Windows) pkgExt = ".lib";
            version(linux) pkgExt = ".a";

            config.set("objects", pkgLinkList);
            config.set("package", pkg ~ pkgExt);
            string command = formatPattern(config.get("project.linkpkg"), config, '%');
            if (!ops.quiet)
                writeln(command);
            if (!ops.emulate)
            {
                auto retcode = std.process.system(command);
                if (retcode)
                    quit(1, "package linking error");
            }

            pkgLibList ~= config.get("package") ~ " ";
        }

        // Link
        config.set("objects", linkList);           
        config.set("packages", pkgLibList);
        if (ops.lib)
        {
            version(Windows) config.append("target", ".lib");
            version(linux)   config.append("target", ".a");

            string command = formatPattern(config.get("project.linklib"), config, '%');
            if (!ops.quiet)
                writeln(command);
            if (!ops.emulate)
            {
                auto retcode = std.process.system(command);
                if (retcode)
                    quit(1, "linking error");
            }
        }
        else
        {
            version(Windows) config.append("target", ".exe");

            string command = formatPattern(config.get("project.link"), config, '%');
            if (!ops.quiet)
                writeln(command);
            if (!ops.emulate)
            {
                auto retcode = std.process.system(command);
                if (retcode)
                    quit(1, "linking error");
            }
        }
    }

    void strip()
    {
        if (ops.strip)
        {
            version(linux)
            {
                string command = "strip " ~ config.get("target");
                if (!ops.quiet)
                    writeln(command);
                if (!ops.emulate)
                    std.process.system(command);
            }
        }
    }

    void run()
    {
        if (ops.run && !ops.lib) 
        {
            if (!ops.emulate)
            {
                string command = formatPattern(config.get("project.run"), config, '%');
                if (!ops.quiet)
                    writeln(command);
                if (!ops.emulate)
                    std.process.system(command);
            }
        }
    }
}

