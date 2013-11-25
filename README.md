Cook2
=====
Cook2 is a fast incremental build tool intended for projects in D language. This is an experimental unstable branch of the project, original Сook 1.x.x сan be found here: http://github.com/gecko0307/cook.

Improvements since Cook 1.x.x
-----------------------------
* Command-line argument handling (cmdopt.d) now uses std.getops. All options remain the same, but multi-letter options are now preceded by double-dash (e.g. --rebuild, --release)
* Added support for [package imports](http://dlang.org/changelog.html#import_package) (new in DMD 2.064)
* Added support for renamed imports (e.g. import foo = bar.Foo) and selective imports (e.g. import std.stdio: writefln). Dependency parser still needs a lot of work, thought.
* <target>.conf now overrides default.conf
