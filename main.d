module test;

import std.stdio;
import session;
import cmdopt;

static string versionString = "2.0.0";

void main(string[] args)
{
    CmdOptions ops = new CmdOptions(args);

    if (ops.help)
    {
        printHelp(ops.program, versionString);
        return;
    }

    BuildSession bs = new BuildSession(ops);
    bs.build();
}

void printHelp(string programName, string programVersion)
{
    writeln
    (
        "Cook2 ", programVersion, "\n",
        "A tool for building projects in D programming language\n",
        "\n"
        "Usage:\n",
        programName, " [MAINMODULE] [OPTIONS]\n",
        "\n"
        "OPTIONS:\n"
        "\n"
        "--help            Display this information\n"
        "--emulate         Don't write anything to disk\n"
        "--quiet           Don't print messages\n"
        "--rebuild         Force rebuilding all modules\n"
        "--nocache         Disable reading/writing module cache\n"
        "--lib             Build a static library instead of an executable\n"
        "--release         Compile modules in release mode\n"
        "--noconsole       Under Windows, hide application console window\n"
        "--strip           Remove debug symbols from resulting binary using \"strip\"\n"
        "                  (currently works only under Linux)\n"
        "-o FILE           Compile to specified filename\n"
        "--clean           Remove temporary data (object files, cache, etc.)\n"
        "--cache FILE      Use specified cache file\n"
        "--rc FILE         Under Windows, compile and link specified resource file\n"
      "-c\"...\"           Pass specified option(s) to compiler\n"
      "-l\"...\"           Pass specified option(s) to linker\n"
        "--run             Run program after compilation (does't work in emulation mode)\n"
        "--dc FILE         Specify default configuration file (default \"default.conf\")\n"
    );
}

