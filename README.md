# Port of Raylib to D

This is a WIP port of raylib to the D programming language.

This includes the v4.0.0 source of raylib from C, which is being migrated piecemeal to D.

## Platform support

Initially, only desktop will be supported, and likely only tested on Linux and MacOS (Windows users welcome to help!)

All `#ifdef` for platforms will be changed to either `version(none)` or `version(all)`, with a comment for the original ifdef. Eventually, the plan is to support all the platforms.

## External libraries

There are several external libraries that are "included" with the C version of raylib. Most external API will be included via importC, and compiled with the native C compiler of the OS (which is required for importC anyway). There are some exceptions which were small and easy to port.

It is important to note that we aren't *building* any C files with importC, we are just using it to *import* C files. To that end, all importC files are in an `importc` directory, and not included in the `source` directory.

## Building

To build, first use the makefile in the `raylibc` directory, which contains the original C code, with all pieces that are ported to D commented out (or are built but ignored).

Then build using dub. This produces libdraylib.a. This is a drop-in replacement for libraylib.a.

draylib is currently built with `betterC`. Once all files are ported, we will remove this restriction.

## Port status

* `raylib.h`, `config.h`, `rlgl.h`, `rgestures.h` have all been converted automatically using dstep to the `source/raylib` package (note that `raylib.h` is converted to `raylib/package.d`).
* `raylib/rcore.d` contains the ported `rcore.c` file. `rcore.c` still exists to include some of the external C libraries that have not yet been ported.
* `raylib/raymath.d` is completely ported and is not reliant on the C library to work.
* `raylib/rtextures.d` is ported completely, and relies on importC headers for `stb_image` to work (see `stb_image_import.c` in the importc directory)
* `raylib/rutils.d` is ported completely
* `raylib/rtext.d` is ported completely, and relies on importC headers for `stb_truetype` to work (see `stb_truetype_import.c` in the importc directory)

In the external directory, the following modules are included:

* `msf_gif.d` - ported with ctod
* `sdefl.d` - ported with ctod
* `sinfl.d` - ported with ctod

## Ctod

A tool by Dennis Korpel, [ctod](https://github.com/dkorpel/ctod), is used to port from C to D. Only C files that we plan to port are sent through here. Ones that are not necessary to port will be used via importC.

## Game plan

1. Port raylib main files to D, so no C files exist for the core library. The examples won't be ported, but there is an existing port of them by Danilo [here](https://github.com/schveiguy/raylib-d_examples). However, the C examples are used for testing while the port is in progress.
2. Provide importC shims for the external files (such as GLFW or stb_image). These will be added as needed when the modules depending on them are ported to D.
3. Turn off betterC
4. Migrate C API to be more D-like, leaving original raylib API as a wrapper.
