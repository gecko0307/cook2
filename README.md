Cook2
=====
Cook2 is a fast incremental build tool intended for projects in D language. This is an experimental unstable branch of the project, original Сook 1.x.x сan be found here: http://github.com/gecko0307/cook.

Improvements since Cook 1.x.x
-----------------------------
* Command-line argument handling (cmdopt.d) now uses std.getops. All options remain the same, but multi-letter options are now preceded by double-dash (e.g. --rebuild, --release).
