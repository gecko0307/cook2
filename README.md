Cook2
=====
Cook is a fast incremental build tool intended for projects in D language. In contrast to most other build automation programs, Cook by default requires no project hierarchy description - it automatically collects information about imports from D source files in project directory. Moreover, Cook caches dependencies between modules, and then uses this cache to find out which modules had been changed and need recompiling.

NOTE: Cook is not being developed anymore. This repository is in maintainance mode, and there will be only bugfix releases. Please, consider using Dub instead of Cook.

Requirements
------------
Cook is written in D and supports Windows and Linux. By default it works with Digital Mars D compiler (DMD), but you can use it with other compilers (and, for some extent, even with other languages!) as well by writing proper configuration file.

Features
--------
* Supports Windows and Linux
* No need to install system-wide - Cook executable runs from anywhere, including project directory
* Performs incremental building by default
* Very fast
* Low memory requirements (happily builds large projects on outdated 32-bit systems, even with 512 MB RAM!)
* Powerful and robust dependency scanner with support for "version" and "debug" conditions
* Fully configurable. You can define paths to compiler and linker, override default compilation/linkage commands, etc.
* Can cross-compile Windows programs under Linux using Wine
* Supports automatic dependency resolution from remote Git repositories or local directories (experimental feature). No need for a package registry - everything is fully decentralized, you can fetch any Git repository in the world

License
-------
Copyright (c) 2011-2014 Timur Gafarov. Distributed under the Boost Software License, Version 1.0. (See accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt)

