# Port of Raylib to D

This is a WIP port of raylib to the D programming language.

This includes the v4.0.0 source of raylib from C, which is being migrated piecemeal to D.

## Platform support

Initially, only desktop will be supported, and likely only tested on Linux and MacOS (Windows users welcome to help!)

All `#ifdef` for platforms will be changed to either `version(none)` or `version(all)`, with a comment for the original ifdef. Eventually, the plan is to support all the platforms.

## External libraries

There are several external libraries that are "included" with the C version of raylib. Single file "header" libraries will be ported using cpptool and ctod (see descriptions below).

The exception is glfw, which actually has a D ported dependency glfw-d (the project that begot ctod!). Eventually, the plan is to use that port instead of the glfw binding that we currently use, but it must support all things we use for that.

## Building

To build, first use the makefile in the `raylibc` directory, which contains the original C code, with all pieces that are ported to D commented out (or are built but ignored).

Then build using dub. This produces libdraylib.a. This is *almost* a drop-in replacement for libraylib.a, but we also are depending on BindBC_GLFW. Therefore, you need to link this library in addition to libdraylib.a.

draylib is currently built with `betterC`.

I haven't yet figured out how to automate the build of libBindBC_GLFW.a. My current mechanism is:

```console
> DFLAGS="--d-version=GLFW_33" dub build bindbc-glfw --config=staticBC
> cp ~/.dub/packages/bindbc-glfw-<version>/bindbc-glfw/lib/*.a .
```

TODO: make this work better.

## Port status

* `raylib.h`, `config.h`, `rlgl.h` have all been converted automatically using dstep to the `source/raylib` package (note that `raylib.h` is converted to `raylib/package.d`).
* `raylib/rcore.d` contains the ported `rcore.c` file. `rcore.c` still exists to include some of the external C libraries that have not yet been ported.
* `raylib/raymath.d` is completely ported and is not reliant on the C library to work.
* `raylib/rtextures.d` is ported completely, and does not rely on C sources.

In the external directory, the following modules are included:

* `msf_gif.d` - ported with ctod
* `sdefl.d` - ported with ctod
* `sinfl.d` - ported with ctod
* `stb_image.d` - ported with cpptool and ctod on MacOS
* `stb_image_resize.d` - ported with cpptool and ctod on MacOS
* `stb_image_write.d` - ported with cpptool and ctod on MacOS

## Porting tools

[cpptool](https://github.com/schveiguy/cpptool) is a new tool I wrote to expand desired macros without affecting the overall structure of the code. It is very much a work in progress, and there are almost no instructions. The tool utilizes the system C preprocessor to replace only the macro expansions desired before sending the code through ctod for a final port to D. This was inspired by an idea from Adam Ruppe. Because it's system specific, porting the other OS portions is problematic, and to be worked out later.

A newly published tool by Dennis Korpel, [ctod](https://github.com/dkorpel/ctod), is used to do the final port from C to D. Raylib modules are reasonable enough and small enough that they can be done without cpptool, but all C sources are sent through ctod in the end. Originally, we thought we would still leave some compiled C code as dependencies, but now, we believe we can port all the C code to D.

## Game plan

1. Port raylib fully to D, so no C files exist for the library. The examples won't be ported, but there is an existing port of them by Danilo [here](https://github.com/D-a-n-i-l-o/raylib-d_examples). However, the C examples are used for testing while the port is in progress.
2. Turn off betterC
3. Migrate C API to be more D-like, leaving original raylib API as a wrapper.

Most likely the external libraries will not be touched once porting is done.
