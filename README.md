# Port of Raylib to D

This is a WIP port of raylib to the D programming language.

This includes the v4.0.0 source of raylib from C, which will be migrated piecemeal to D.

## Platform support

Initially, only desktop will be supported, and likely only tested on Linux and MacOS (Windows users welcome to help!)

All `#ifdef` for platforms will be changed to either `version(none)` or `version(all)`, with a comment for the original ifdef. Eventually, the plan is to support all the platforms.

## Building

To build, first use the makefile in the `raylib` directory, which contains the original C code.

Then build using dub. The resulting libdraylib.a should be a drop-in replacement for raylib.

draylib is currently built with `betterC`.

The build of the C objects will be automated in the future.

## Port status

`raylib.h` and `config.h` have been converted automatically to `raylib/package.d` and `raylib/config.d`. This contains all the definitions and extern(C) bindings.
`raylib/rcore.d` will contain the ported `rcore.c` file. `rcore.c` will slowly be have all its functions removed as they are implemented in `rcore.d`

## Game plan

1. Port raylib to D, so no
2. Turn off betterC
3. Migrate C API to be more D-like, leaving original raylib API as a wrapper.
