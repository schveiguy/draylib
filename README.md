# Port of Raylib to D

This is a WIP port of raylib to the D programming language.

This includes the v4.0.0 source of raylib from C, which will be migrated piecemeal to D.

## Platform support

Initially, only desktop will be supported, and likely only tested on Linux and MacOS (Windows users welcome to help!)

All `#ifdef` for platforms will be changed to either `version(none)` or `version(all)`, with a comment for the original ifdef. Eventually, the plan is to support all the platforms.

## Building

To build, first use the makefile in the `raylibc` directory, which contains the original C code, with all pieces that are ported to D commented out.

Then build using dub. This produces libdraylib.a. This is *almost* a drop-in replacement for libraylib.a, but we also are depending on BindBC_GLFW. Therefore, you need to link this library in addition to libdraylib.a.

draylib is currently built with `betterC`.

I haven't yet figured out how to automate the build of libBindBC_GLFW.a. My current mechanism is:

```console
> DFLAGS="--d-version=GLFW_33" dub build bindbc-glfw --config=staticBC
> cp ~/.dub/packages/bindbc-glfw-<version>/bindbc-glfw/lib/*.a .
```

TODO: make this work better.

## Port status

`raylib.h`, `config.h`, `raymath.h`, `rlgl.h` have all been converted automatically using dstep to the `source/raylib` package (note that `raylib.h` is converted to `raylib/package.d`).
`raylib/rcore.d` contains the ported `rcore.c` file. `rcore.c` still exists to
include some of the external C libraries that have not yet been ported.

## Using ctod

A newly published tool by Dennis Korpel,
[ctod](https://github.com/dkorpel/ctod), is now being used to start each port.
In fact, we are eliminating all uses of dstep, and our plan of porting all C
files is possible now.

Any D files in `raylib/external` are ports of the C headers using this tool. `rcore.d` was completed by hand copy/pasting and porting. All further modules (except `raymath.d`) will be started with this new tool, as it saves hours/days of time fixing most of the common C to D syntax differences.

## Game plan

1. Port raylib fully to D, so no C files exist for the library. The examples probably won't be ported, unless people see the need (and I won't be doing that).
2. Turn off betterC
3. Migrate C API to be more D-like, leaving original raylib API as a wrapper.
