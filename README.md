Cook2
=====
Cook2 is a fast incremental build tool intended for projects in D language. This is an experimental unstable branch of the project, original Сook 1.x.x сan be found here: http://github.com/gecko0307/cook.

Improvements since Cook 1.x.x
-----------------------------
* Command-line argument handling ([cmdopt.d](https://github.com/gecko0307/cook2/blob/master/cmdopt.d)) now uses [std.getopt](http://dlang.org/phobos/std_getopt.html). All options remain the same, but multi-letter options are now preceded by double-dash (e.g. --rebuild, --release)
* Added support for [package imports](http://dlang.org/changelog.html#import_package) (new in DMD 2.064)
* Added support for renamed imports (e.g. import foo = bar.Foo) and selective imports (e.g. import std.stdio: writefln). Import parser still needs a lot of work, though
* target.conf now overrides default.conf
