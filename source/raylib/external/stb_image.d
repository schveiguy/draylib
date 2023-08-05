module raylib.external.stb_image;
@nogc nothrow:
extern(C): __gshared:

private template HasVersion(string versionId) {
	mixin("version("~versionId~") {enum HasVersion = true;} else {enum HasVersion = false;}");
}
import core.stdc.config: c_long, c_ulong;
//public import config;
//static if (!HasVersion!"SUPPORT_FILEFORMAT_BMP") {

    version = STBI_NO_BMP;

//}

static if (!HasVersion!"SUPPORT_FILEFORMAT_PNG") {







}
//static if (!HasVersion!"SUPPORT_FILEFORMAT_TGA") {

    version = STBI_NO_TGA;

//}

//static if (!HasVersion!"SUPPORT_FILEFORMAT_JPG") {

    version = STBI_NO_JPEG;        // Image format .jpg and .jpeg

//}

//static if (!HasVersion!"SUPPORT_FILEFORMAT_PSD") {

    version = STBI_NO_PSD;

//}

static if (!HasVersion!"SUPPORT_FILEFORMAT_GIF") {







}
//static if (!HasVersion!"SUPPORT_FILEFORMAT_PIC") {

    version = STBI_NO_PIC;

//}

static if (!HasVersion!"SUPPORT_FILEFORMAT_HDR") {







}

// Image fileformats not supported by default
//version = STBI_NO_PIC;

version = STBI_NO_PNM;             // Image format .ppm and .pgm


version (__TINYC__) {







}

version = STB_IMAGE_IMPLEMENTATION;

/* stb_image - v2.27 - public domain image loader - http://nothings.org/stb
                                  no warranty implied; use at your own risk

   Do this:
      #define STB_IMAGE_IMPLEMENTATION
   before you include this file in *one* C or C++ file to create the implementation.

   // i.e. it should look like this:
   #include ...
   #include ...
   #include ...
   #define STB_IMAGE_IMPLEMENTATION
   #include "stb_image.h"

   You can #define STBI_ASSERT(x) before the #include to avoid using assert.h.
   And #define STBI_MALLOC, STBI_REALLOC, and STBI_FREE to avoid using malloc,realloc,free


   QUICK NOTES:
      Primarily of interest to game developers and other people who can
          avoid problematic images and only need the trivial interface

      JPEG baseline & progressive (12 bpc/arithmetic not supported, same as stock IJG lib)
      PNG 1/2/4/8/16-bit-per-channel

      TGA (not sure what subset, if a subset)
      BMP non-1bpp, non-RLE
      PSD (composited view only, no extra channels, 8/16 bit-per-channel)

      GIF (*comp always reports as 4-channel)
      HDR (radiance rgbE format)
      PIC (Softimage PIC)
      PNM (PPM and PGM binary only)

      Animated GIF still needs a proper API, but here's one way to do it:
          http://gist.github.com/urraka/685d9a6340b26b830d49

      - decode from memory or through FILE (define STBI_NO_STDIO to remove code)
      - decode from arbitrary I/O callbacks
      - SIMD acceleration on x86/x64 (SSE2) and ARM (NEON)

   Full documentation under "DOCUMENTATION" below.


LICENSE

  See end of file for license information.

RECENT REVISION HISTORY:

      2.27  (2021-07-11) document stbi_info better, 16-bit PNM support, bug fixes
      2.26  (2020-07-13) many minor fixes
      2.25  (2020-02-02) fix warnings
      2.24  (2020-02-02) fix warnings; thread-local failure_reason and flip_vertically
      2.23  (2019-08-11) fix clang static analysis warning
      2.22  (2019-03-04) gif fixes, fix warnings
      2.21  (2019-02-25) fix typo in comment
      2.20  (2019-02-07) support utf8 filenames in Windows; fix warnings and platform ifdefs
      2.19  (2018-02-11) fix warning
      2.18  (2018-01-30) fix warnings
      2.17  (2018-01-29) bugfix, 1-bit BMP, 16-bitness query, fix warnings
      2.16  (2017-07-23) all functions have 16-bit variants; optimizations; bugfixes
      2.15  (2017-03-18) fix png-1,2,4; all Imagenet JPGs; no runtime SSE detection on GCC
      2.14  (2017-03-03) remove deprecated STBI_JPEG_OLD; fixes for Imagenet JPGs
      2.13  (2016-12-04) experimental 16-bit API, only for PNG so far; fixes
      2.12  (2016-04-02) fix typo in 2.11 PSD fix that caused crashes
      2.11  (2016-04-02) 16-bit PNGS; enable SSE2 in non-gcc x64
                         RGB-format JPEG; remove white matting in PSD;
                         allocate large structures on the stack;
                         correct channel count for PNG & BMP
      2.10  (2016-01-22) avoid warning introduced in 2.09
      2.09  (2016-01-16) 16-bit TGA; comments in PNM files; STBI_REALLOC_SIZED

   See end of file for full revision history.


 ============================    Contributors    =========================

 Image formats                          Extensions, features
    Sean Barrett (jpeg, png, bmp)          Jetro Lauha (stbi_info)
    Nicolas Schulz (hdr, psd)              Martin "SpartanJ" Golini (stbi_info)
    Jonathan Dummer (tga)                  James "moose2000" Brown (iPhone PNG)
    Jean-Marc Lienher (gif)                Ben "Disch" Wenger (io callbacks)
    Tom Seddon (pic)                       Omar Cornut (1/2/4-bit PNG)
    Thatcher Ulrich (psd)                  Nicolas Guillemot (vertical flip)
    Ken Miller (pgm, ppm)                  Richard Mitton (16-bit PSD)
    github:urraka (animated gif)           Junggon Kim (PNM comments)
    Christopher Forseth (animated gif)     Daniel Gibson (16-bit TGA)
                                           socks-the-fox (16-bit PNG)
                                           Jeremy Sawicki (handle all ImageNet JPGs)
 Optimizations & bugfixes                  Mikhail Morozov (1-bit BMP)
    Fabian "ryg" Giesen                    Anael Seghezzi (is-16-bit query)
    Arseny Kapoulkine                      Simon Breuss (16-bit PNM)
    John-Mark Allen
    Carmelo J Fdez-Aguera

 Bug & warning fixes
    Marc LeBlanc            David Woo          Guillaume George     Martins Mozeiko
    Christpher Lloyd        Jerry Jansson      Joseph Thomson       Blazej Dariusz Roszkowski
    Phil Jordan                                Dave Moore           Roy Eltham
    Hayaki Saito            Nathan Reed        Won Chun
    Luke Graham             Johan Duparc       Nick Verigakis       the Horde3D community
    Thomas Ruf              Ronny Chevalier                         github:rlyeh
    Janez Zemva             John Bartholomew   Michal Cichon        github:romigrou
    Jonathan Blow           Ken Hamada         Tero Hanninen        github:svdijk
    Eugene Golushkov        Laurent Gomila     Cort Stratton        github:snagar
    Aruelien Pocheville     Sergio Gonzalez    Thibault Reuille     github:Zelex
    Cass Everitt            Ryamond Barbiero                        github:grim210
    Paul Du Bois            Engin Manap        Aldo Culquicondor    github:sammyhw
    Philipp Wiesemann       Dale Weiler        Oriol Ferrer Mesia   github:phprus
    Josh Tobin                                 Matthew Gregan       github:poppolopoppo
    Julian Raschke          Gregory Mullen     Christian Floisand   github:darealshinji
    Baldur Karlsson         Kevin Schmidt      JR Smith             github:Michaelangel007
                            Brad Weinberger    Matvey Cherevko      github:mosra
    Luca Sas                Alexander Veselov  Zack Middleton       [reserved]
    Ryan C. Gordon          [reserved]                              [reserved]
                     DO NOT ADD YOUR NAME HERE

                     Jacko Dirks

  To add your name to the credits, pick a random blank space in the middle and fill it.
  80% of merge conflicts on stb PRs are due to people adding their name at the end
  of the credits.
*/

 

// DOCUMENTATION
//
// Limitations:
//    - no 12-bit-per-channel JPEG
//    - no JPEGs with arithmetic coding
//    - GIF always returns *comp=4
//
// Basic usage (see HDR discussion below for HDR usage):
//    int x,y,n;
//    unsigned char *data = stbi_load(filename, &x, &y, &n, 0);
//    // ... process data if not NULL ...
//    // ... x = width, y = height, n = # 8-bit components per pixel ...
//    // ... replace '0' with '1'..'4' to force that many components per pixel
//    // ... but 'n' will always be the number that it would have been if you said 0
//    stbi_image_free(data)
//
// Standard parameters:
//    int *x                 -- outputs image width in pixels
//    int *y                 -- outputs image height in pixels
//    int *channels_in_file  -- outputs # of image components in image file
//    int desired_channels   -- if non-zero, # of image components requested in result
//
// The return value from an image loader is an 'unsigned char *' which points
// to the pixel data, or NULL on an allocation failure or if the image is
// corrupt or invalid. The pixel data consists of *y scanlines of *x pixels,
// with each pixel consisting of N interleaved 8-bit components; the first
// pixel pointed to is top-left-most in the image. There is no padding between
// image scanlines or between pixels, regardless of format. The number of
// components N is 'desired_channels' if desired_channels is non-zero, or
// *channels_in_file otherwise. If desired_channels is non-zero,
// *channels_in_file has the number of components that _would_ have been
// output otherwise. E.g. if you set desired_channels to 4, you will always
// get RGBA output, but you can check *channels_in_file to see if it's trivially
// opaque because e.g. there were only 3 channels in the source image.
//
// An output image with N components has the following components interleaved
// in this order in each pixel:
//
//     N=#comp     components
//       1           grey
//       2           grey, alpha
//       3           red, green, blue
//       4           red, green, blue, alpha
//
// If image loading fails for any reason, the return value will be NULL,
// and *x, *y, *channels_in_file will be unchanged. The function
// stbi_failure_reason() can be queried for an extremely brief, end-user
// unfriendly explanation of why the load failed. Define STBI_NO_FAILURE_STRINGS
// to avoid compiling these strings at all, and STBI_FAILURE_USERMSG to get slightly
// more user-friendly ones.
//
// Paletted PNG, BMP, GIF, and PIC images are automatically depalettized.
//
// To query the width, height and component count of an image without having to
// decode the full file, you can use the stbi_info family of functions:
//
//   int x,y,n,ok;
//   ok = stbi_info(filename, &x, &y, &n);
//   // returns ok=1 and sets x, y, n if image is a supported format,
//   // 0 otherwise.
//
// Note that stb_image pervasively uses ints in its public API for sizes,
// including sizes of memory buffers. This is now part of the API and thus
// hard to change without causing breakage. As a result, the various image
// loaders all have certain limits on image size; these differ somewhat
// by format but generally boil down to either just under 2GB or just under
// 1GB. When the decoded image would be larger than this, stb_image decoding
// will fail.
//
// Additionally, stb_image will reject image files that have any of their
// dimensions set to a larger value than the configurable STBI_MAX_DIMENSIONS,
// which defaults to 2**24 = 16777216 pixels. Due to the above memory limit,
// the only way to have an image with such dimensions load correctly
// is for it to have a rather extreme aspect ratio. Either way, the
// assumption here is that such larger images are likely to be malformed
// or malicious. If you do need to load an image with individual dimensions
// larger than that, and it still fits in the overall size limit, you can
// #define STBI_MAX_DIMENSIONS on your own to be something larger.
//
// ===========================================================================
//
// UNICODE:
//
//   If compiling for Windows and you wish to use Unicode filenames, compile
//   with
//       #define STBI_WINDOWS_UTF8
//   and pass utf8-encoded filenames. Call stbi_convert_wchar_to_utf8 to convert
//   Windows wchar_t filenames to utf8.
//
// ===========================================================================
//
// Philosophy
//
// stb libraries are designed with the following priorities:
//
//    1. easy to use
//    2. easy to maintain
//    3. good performance
//
// Sometimes I let "good performance" creep up in priority over "easy to maintain",
// and for best performance I may provide less-easy-to-use APIs that give higher
// performance, in addition to the easy-to-use ones. Nevertheless, it's important
// to keep in mind that from the standpoint of you, a client of this library,
// all you care about is #1 and #3, and stb libraries DO NOT emphasize #3 above all.
//
// Some secondary priorities arise directly from the first two, some of which
// provide more explicit reasons why performance can't be emphasized.
//
//    - Portable ("ease of use")
//    - Small source code footprint ("easy to maintain")
//    - No dependencies ("ease of use")
//
// ===========================================================================
//
// I/O callbacks
//
// I/O callbacks allow you to read from arbitrary sources, like packaged
// files or some other source. Data read from callbacks are processed
// through a small internal buffer (currently 128 bytes) to try to reduce
// overhead.
//
// The three functions you must define are "read" (reads some bytes of data),
// "skip" (skips some bytes of data), "eof" (reports if the stream is at the end).
//
// ===========================================================================
//
// SIMD support
//
// The JPEG decoder will try to automatically use SIMD kernels on x86 when
// supported by the compiler. For ARM Neon support, you must explicitly
// request it.
//
// (The old do-it-yourself SIMD API is no longer supported in the current
// code.)
//
// On x86, SSE2 will automatically be used when available based on a run-time
// test; if not, the generic C versions are used as a fall-back. On ARM targets,
// the typical path is to have separate builds for NEON and non-NEON devices
// (at least this is true for iOS and Android). Therefore, the NEON support is
// toggled by a build flag: define STBI_NEON to get NEON loops.
//
// If for some reason you do not want to use any of SIMD code, or if
// you have issues compiling it, you can disable it entirely by
// defining STBI_NO_SIMD.
//
// ===========================================================================
//
// HDR image support   (disable by defining STBI_NO_HDR)
//
// stb_image supports loading HDR images in general, and currently the Radiance
// .HDR file format specifically. You can still load any file through the existing
// interface; if you attempt to load an HDR file, it will be automatically remapped
// to LDR, assuming gamma 2.2 and an arbitrary scale factor defaulting to 1;
// both of these constants can be reconfigured through this interface:
//
//     stbi_hdr_to_ldr_gamma(2.2f);
//     stbi_hdr_to_ldr_scale(1.0f);
//
// (note, do not use _inverse_ constants; stbi_image will invert them
// appropriately).
//
// Additionally, there is a new, parallel interface for loading files as
// (linear) floats to preserve the full dynamic range:
//
//    float *data = stbi_loadf(filename, &x, &y, &n, 0);
//
// If you load LDR images through this interface, those images will
// be promoted to floating point values, run through the inverse of
// constants corresponding to the above:
//
//     stbi_ldr_to_hdr_scale(1.0f);
//     stbi_ldr_to_hdr_gamma(2.2f);
//
// Finally, given a filename (or an open file or memory block--see header
// file for details) containing image data, you can query for the "most
// appropriate" interface to use (that is, whether the image is HDR or
// not), using:
//
//     stbi_is_hdr(char *filename);
//
// ===========================================================================
//
// iPhone PNG support:
//
// We optionally support converting iPhone-formatted PNGs (which store
// premultiplied BGRA) back to RGB, even though they're internally encoded
// differently. To enable this conversion, call
// stbi_convert_iphone_png_to_rgb(1).
//
// Call stbi_set_unpremultiply_on_load(1) as well to force a divide per
// pixel to remove any premultiplied alpha *only* if the image file explicitly
// says there's premultiplied data (currently only happens in iPhone images,
// and only if iPhone convert-to-rgb processing is on).
//
// ===========================================================================
//
// ADDITIONAL CONFIGURATION
//
//  - You can suppress implementation of any of the decoders to reduce
//    your code footprint by #defining one or more of the following
//    symbols before creating the implementation.
//
//        STBI_NO_JPEG
//        STBI_NO_PNG
//        STBI_NO_BMP
//        STBI_NO_PSD
//        STBI_NO_TGA
//        STBI_NO_GIF
//        STBI_NO_HDR
//        STBI_NO_PIC
//        STBI_NO_PNM   (.ppm and .pgm)
//
//  - You can request *only* certain decoders and suppress all other ones
//    (this will be more forward-compatible, as addition of new decoders
//    doesn't require you to disable them explicitly):
//
//        STBI_ONLY_JPEG
//        STBI_ONLY_PNG
//        STBI_ONLY_BMP
//        STBI_ONLY_PSD
//        STBI_ONLY_TGA
//        STBI_ONLY_GIF
//        STBI_ONLY_HDR
//        STBI_ONLY_PIC
//        STBI_ONLY_PNM   (.ppm and .pgm)
//
//   - If you use STBI_NO_PNG (or _ONLY_ without PNG), and you still
//     want the zlib decoder to be available, #define STBI_SUPPORT_ZLIB
//
//  - If you define STBI_MAX_DIMENSIONS, stb_image will reject images greater
//    than that size (in either width or height) without further processing.
//    This is to let programs in the wild set an upper bound to prevent
//    denial-of-service attacks on untrusted data, as one could generate a
//    valid image of gigantic dimensions and force stb_image to allocate a
//    huge block of memory and spend disproportionate time decoding it. By
//    default this is set to (1 << 24), which is 16777216, but that's still
//    very big.

version (STBI_NO_STDIO) {} else {

public import core.stdc.stdio;
} // STBI_NO_STDIO


enum STBI_VERSION = 1;


enum
{
   STBI_default = 0, // only used for desired_channels

   STBI_grey = 1,
   STBI_grey_alpha = 2,
   STBI_rgb = 3,
   STBI_rgb_alpha = 4
}

public import core.stdc.stdlib;
alias stbi_uc = ubyte;
alias stbi_us = ushort;

version (none) {





}


//////////////////////////////////////////////////////////////////////////////
//
// PRIMARY API - works on images of any type
//

//
// load image by filename, open file, or memory buffer
//

struct _Stbi_io_callbacks {
    @nogc extern(C) nothrow:
   int function(void* user, char* data, int size) read; // fill 'data' with 'size' bytes.  return number of bytes actually read
   void function(void* user, int n) skip; // skip the next 'n' bytes, or 'unget' the last -n bytes if negative
   int function(void* user) eof; // returns nonzero if we are at end of file/data
}alias stbi_io_callbacks = _Stbi_io_callbacks;

////////////////////////////////////
//
// 8-bits-per-channel interface
//

extern stbi_uc* stbi_load_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* channels_in_file, int desired_channels);
extern stbi_uc* stbi_load_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* channels_in_file, int desired_channels);

version (STBI_NO_STDIO) {} else {

extern stbi_uc* stbi_load(const(char)* filename, int* x, int* y, int* channels_in_file, int desired_channels);
extern stbi_uc* stbi_load_from_file(FILE* f, int* x, int* y, int* channels_in_file, int desired_channels);
// for stbi_load_from_file, file pointer is left pointing immediately after image
}


version (STBI_NO_GIF) {} else {

extern stbi_uc* stbi_load_gif_from_memory(const(stbi_uc)* buffer, int len, int** delays, int* x, int* y, int* z, int* comp, int req_comp);
}


version (STBI_WINDOWS_UTF8) {





}

////////////////////////////////////
//
// 16-bits-per-channel interface
//

extern stbi_us* stbi_load_16_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* channels_in_file, int desired_channels);
extern stbi_us* stbi_load_16_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* channels_in_file, int desired_channels);

version (STBI_NO_STDIO) {} else {

extern stbi_us* stbi_load_16(const(char)* filename, int* x, int* y, int* channels_in_file, int desired_channels);
extern stbi_us* stbi_load_from_file_16(FILE* f, int* x, int* y, int* channels_in_file, int desired_channels);
}


////////////////////////////////////
//
// float-per-channel interface
//
version (STBI_NO_LINEAR) {} else {

   extern float* stbi_loadf_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* channels_in_file, int desired_channels);
   extern float* stbi_loadf_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* channels_in_file, int desired_channels);

   version (STBI_NO_STDIO) {} else {

   extern float* stbi_loadf(const(char)* filename, int* x, int* y, int* channels_in_file, int desired_channels);
   extern float* stbi_loadf_from_file(FILE* f, int* x, int* y, int* channels_in_file, int desired_channels);
   }

}


version (STBI_NO_HDR) {} else {

   extern void stbi_hdr_to_ldr_gamma(float gamma);
   extern void stbi_hdr_to_ldr_scale(float scale);
} // STBI_NO_HDR


version (STBI_NO_LINEAR) {} else {

   extern void stbi_ldr_to_hdr_gamma(float gamma);
   extern void stbi_ldr_to_hdr_scale(float scale);
} // STBI_NO_LINEAR


// stbi_is_hdr is always defined, but always returns false if STBI_NO_HDR
extern int stbi_is_hdr_from_callbacks(const(stbi_io_callbacks)* clbk, void* user);
extern int stbi_is_hdr_from_memory(const(stbi_uc)* buffer, int len);
version (STBI_NO_STDIO) {} else {

extern int stbi_is_hdr(const(char)* filename);
extern int stbi_is_hdr_from_file(FILE* f);
} // STBI_NO_STDIO



// get a VERY brief reason for failure
// on most compilers (and ALL modern mainstream compilers) this is threadsafe
extern const(char)* stbi_failure_reason();

// free the loaded image -- this is just free()
extern void stbi_image_free(void* retval_from_stbi_load);

// get image dimensions & components without fully decoding
extern int stbi_info_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp);
extern int stbi_info_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* comp);
extern int stbi_is_16_bit_from_memory(const(stbi_uc)* buffer, int len);
extern int stbi_is_16_bit_from_callbacks(const(stbi_io_callbacks)* clbk, void* user);

version (STBI_NO_STDIO) {} else {

extern int stbi_info(const(char)* filename, int* x, int* y, int* comp);
extern int stbi_info_from_file(FILE* f, int* x, int* y, int* comp);
extern int stbi_is_16_bit(const(char)* filename);
extern int stbi_is_16_bit_from_file(FILE* f);
}




// for image formats that explicitly notate that they have premultiplied alpha,
// we just return the colors as stored in the file. set this flag to force
// unpremultiplication. results are undefined if the unpremultiply overflow.
extern void stbi_set_unpremultiply_on_load(int flag_true_if_should_unpremultiply);

// indicate whether we should process iphone images back to canonical format,
// or just pass them through "as-is"
extern void stbi_convert_iphone_png_to_rgb(int flag_true_if_should_convert);

// flip the image vertically, so the first pixel in the output array is the bottom left
extern void stbi_set_flip_vertically_on_load(int flag_true_if_should_flip);

// as above, but only applies to images loaded on the thread that calls the function
// this function is only available if your compiler supports thread-local variables;
// calling it will fail to link if your compiler doesn't
extern void stbi_set_unpremultiply_on_load_thread(int flag_true_if_should_unpremultiply);
extern void stbi_convert_iphone_png_to_rgb_thread(int flag_true_if_should_convert);
extern void stbi_set_flip_vertically_on_load_thread(int flag_true_if_should_flip);

// ZLIB client - used by PNG, available for other purposes

extern char* stbi_zlib_decode_malloc_guesssize(const(char)* buffer, int len, int initial_size, int* outlen);
extern char* stbi_zlib_decode_malloc_guesssize_headerflag(const(char)* buffer, int len, int initial_size, int* outlen, int parse_header);
extern char* stbi_zlib_decode_malloc(const(char)* buffer, int len, int* outlen);
extern int stbi_zlib_decode_buffer(char* obuffer, int olen, const(char)* ibuffer, int ilen);

extern char* stbi_zlib_decode_noheader_malloc(const(char)* buffer, int len, int* outlen);
extern int stbi_zlib_decode_noheader_buffer(char* obuffer, int olen, const(char)* ibuffer, int ilen);


version (none) {





}

//
//
////   end header file   /////////////////////////////////////////////////////
 // STBI_INCLUDE_STB_IMAGE_H


version (STB_IMAGE_IMPLEMENTATION) {


static if (HasVersion!"STBI_ONLY_JPEG" || HasVersion!"STBI_ONLY_PNG" || HasVersion!"STBI_ONLY_BMP" 
  || HasVersion!"STBI_ONLY_TGA" || HasVersion!"STBI_ONLY_GIF" || HasVersion!"STBI_ONLY_PSD" 
  || HasVersion!"STBI_ONLY_HDR" || HasVersion!"STBI_ONLY_PIC" || HasVersion!"STBI_ONLY_PNM"
  || HasVersion!"STBI_ONLY_ZLIB") {
}

static if (HasVersion!"STBI_NO_PNG" && !HasVersion!"STBI_SUPPORT_ZLIB" && !HasVersion!"STBI_NO_ZLIB") {







}


public import core.stdc.stdarg;
public import core.stdc.stddef; // ptrdiff_t on osx
public import core.stdc.stdlib;

public import core.stdc.string;
public import core.stdc.limits;

static if (!HasVersion!"STBI_NO_LINEAR" || !HasVersion!"STBI_NO_HDR") {

public import core.stdc.math;  // ldexp, pow
}


version (STBI_NO_STDIO) {} else {

public import core.stdc.stdio;

}


version (STBI_ASSERT) {} else {

public import core.stdc.assert_;
enum string STBI_ASSERT(string x) = ` assert(x)`;

}


version (STBI_NO_THREAD_LOCALS) {} else {

   static if (HasVersion!"none" &&  __cplusplus >= 201103L) {







   } else static if (HasVersion!"__GNUC__" && __GNUC__ < 5) {
      enum STBI_THREAD_LOCAL =       __thread;

   } else version (_MSC_VER) {
   }

   version (STBI_THREAD_LOCAL) {} else {
   }
}


version (_MSC_VER) {








} else {
public import core.stdc.stdint;

alias stbi__uint16 = ushort;
alias stbi__int16 = short;
alias stbi__uint32 = uint;
alias stbi__int32 = int;
}


// should produce compiler error if size is wrong
alias validate_uint32 = ubyte[stbi__uint32.sizeof==4 ? 1 : -1];

version (_MSC_VER) {







} else {
enum string STBI_NOTUSED(string v) = `  (void)sizeof(v)`;

}


version (_MSC_VER) {







}

version (STBI_HAS_LROTL) {







} else {
   enum string stbi_lrot(string x,string y) = `  (((x) << (y)) | ((x) >> (-(y) & 31)))`;

}


static if (HasVersion!"STBI_MALLOC" && HasVersion!"STBI_FREE" && (HasVersion!"STBI_REALLOC" || HasVersion!"STBI_REALLOC_SIZED")) {





} else static if (!HasVersion!"STBI_MALLOC" && !HasVersion!"STBI_FREE" && !HasVersion!"STBI_REALLOC" && !HasVersion!"STBI_REALLOC_SIZED") {
// ok
} else {







}

version (STBI_MALLOC) {} else {

enum string STBI_MALLOC(string sz) = `           malloc(sz)`;

enum string STBI_REALLOC(string p,string newsz) = `     realloc(p,newsz)`;

enum string STBI_FREE(string p) = `              free(p)`;

}


version (STBI_REALLOC_SIZED) {} else {

enum string STBI_REALLOC_SIZED(string p,string oldsz,string newsz) = ` STBI_REALLOC(p,newsz)`;

}


// x86/x64 detection
static if (HasVersion!"__x86_64__" || HasVersion!"_M_X64") {
}

static if (HasVersion!"__GNUC__" && HasVersion!"STBI__X86_TARGET" && !HasVersion!"__SSE2__" && !HasVersion!"STBI_NO_SIMD") {
}

static if (HasVersion!"Windows" && HasVersion!"STBI__X86_TARGET" && !HasVersion!"STBI_MINGW_ENABLE_SSE2" && !HasVersion!"STBI_NO_SIMD") {
}

static if (!HasVersion!"STBI_NO_SIMD" && (HasVersion!"STBI__X86_TARGET" || HasVersion!"STBI__X64_TARGET")) {
}

// ARM NEON
static if (HasVersion!"STBI_NO_SIMD" && HasVersion!"STBI_NEON") {







}

version (STBI_NEON) {
}

version (STBI_SIMD_ALIGN) {} else {

enum string STBI_SIMD_ALIGN(string type, string name) = ` type name`;

}


version (STBI_MAX_DIMENSIONS) {} else {

enum STBI_MAX_DIMENSIONS = (1 << 24);

}


///////////////////////////////////////////////
//
//  stbi__context struct and start_xxx functions

// stbi__context structure is our basic context used by all images, so it
// contains all the IO context, plus some basic image information
struct _Stbi__context {
   stbi__uint32 img_x, img_y;
   int img_n, img_out_n;

   stbi_io_callbacks io;
   void* io_user_data;

   int read_from_callbacks;
   int buflen;
   stbi_uc[128] buffer_start;
   int callback_already_read;

   stbi_uc* img_buffer, img_buffer_end;
   stbi_uc* img_buffer_original, img_buffer_original_end;
}alias stbi__context = _Stbi__context;


private void stbi__refill_buffer(stbi__context* s);

// initialize a memory-decode context
private void stbi__start_mem(stbi__context* s, const(stbi_uc)* buffer, int len) {
   s.io.read = null;
   s.read_from_callbacks = 0;
   s.callback_already_read = 0;
   s.img_buffer = s.img_buffer_original = cast(stbi_uc*) buffer;
   s.img_buffer_end = s.img_buffer_original_end = cast(stbi_uc*) buffer+len;
}

// initialize a callback-based context
private void stbi__start_callbacks(stbi__context* s, stbi_io_callbacks* c, void* user) {
   s.io = *c;
   s.io_user_data = user;
   s.buflen = typeof(s.buffer_start).sizeof;
   s.read_from_callbacks = 1;
   s.callback_already_read = 0;
   s.img_buffer = s.img_buffer_original = s.buffer_start.ptr;
   stbi__refill_buffer(s);
   s.img_buffer_original_end = s.img_buffer_end;
}

version (STBI_NO_STDIO) {} else {


private int stbi__stdio_read(void* user, char* data, int size) {
   return cast(int) fread(data,1,size,cast(FILE*) user);
}

private void stbi__stdio_skip(void* user, int n) {
   int ch = void;
   fseek(cast(FILE*) user, n, SEEK_CUR);
   ch = fgetc(cast(FILE*) user); /* have to read a byte to reset feof()'s flag */
   if (ch != EOF) {
      ungetc(ch, cast(FILE*) user); /* push byte back onto stream if valid. */
   }
}

private int stbi__stdio_eof(void* user) {
   return feof(cast(FILE*) user) || ferror(cast(FILE*) user);
}

private stbi_io_callbacks stbi__stdio_callbacks = {
   &stbi__stdio_read,
   &stbi__stdio_skip,
   &stbi__stdio_eof,
};

private void stbi__start_file(stbi__context* s, FILE* f) {
   stbi__start_callbacks(s, &stbi__stdio_callbacks, cast(void*) f);
}

//static void stop_file(stbi__context *s) { }

} // !STBI_NO_STDIO


private void stbi__rewind(stbi__context* s) {
   // conceptually rewind SHOULD rewind to the beginning of the stream,
   // but we just rewind to the beginning of the initial buffer, because
   // we only use it after doing 'test', which only ever looks at at most 92 bytes
   s.img_buffer = s.img_buffer_original;
   s.img_buffer_end = s.img_buffer_original_end;
}

enum
{
   STBI_ORDER_RGB,
   STBI_ORDER_BGR
}

struct _Stbi__result_info {
   int bits_per_channel;
   int num_channels;
   int channel_order;
}alias stbi__result_info = _Stbi__result_info;

version (STBI_NO_JPEG) {} else {







}

version (STBI_NO_PNG) {} else {

private int stbi__png_test(stbi__context* s);
private void* stbi__png_load(stbi__context* s, int* x, int* y, int* comp, int req_comp, stbi__result_info* ri);
private int stbi__png_info(stbi__context* s, int* x, int* y, int* comp);
private int stbi__png_is16(stbi__context* s);
}


version (STBI_NO_BMP) {} else {







}

version (STBI_NO_TGA) {} else {







}

version (STBI_NO_PSD) {} else {








}

version (STBI_NO_HDR) {} else {

private int stbi__hdr_test(stbi__context* s);
private float* stbi__hdr_load(stbi__context* s, int* x, int* y, int* comp, int req_comp, stbi__result_info* ri);
private int stbi__hdr_info(stbi__context* s, int* x, int* y, int* comp);
}


version (STBI_NO_PIC) {} else {







}

version (STBI_NO_GIF) {} else {

private int stbi__gif_test(stbi__context* s);
private void* stbi__gif_load(stbi__context* s, int* x, int* y, int* comp, int req_comp, stbi__result_info* ri);
private void* stbi__load_gif_main(stbi__context* s, int** delays, int* x, int* y, int* z, int* comp, int req_comp);
private int stbi__gif_info(stbi__context* s, int* x, int* y, int* comp);
}


version (STBI_NO_PNM) {} else {








}

struct stbi__g_failure_reason_holder
{
    static const(char)* v;
}
alias stbi__g_failure_reason = stbi__g_failure_reason_holder.v;

extern const(char)* stbi_failure_reason() {
   return stbi__g_failure_reason;
}

version (STBI_NO_FAILURE_STRINGS) {} else {

private int stbi__err(const(char)* str) {
   stbi__g_failure_reason = str;
   return 0;
}
}


private void* stbi__malloc(size_t size) {
    return malloc(size);
}

// stb_image uses ints pervasively, including for offset calculations.
// therefore the largest decoded image size we can support with the
// current code, even on 64-bit targets, is INT_MAX. this is not a
// significant limitation for the intended use case.
//
// we do, however, need to make sure our size calculations don't
// overflow. hence a few helper functions for size calculations that
// multiply integers together, making sure that they're non-negative
// and no overflow occurs.

// return 1 if the sum is valid, 0 on overflow.
// negative terms are considered invalid.
private int stbi__addsizes_valid(int a, int b) {
   if (b < 0) return 0;
   // now 0 <= b <= INT_MAX, hence also
   // 0 <= INT_MAX - b <= INTMAX.
   // And "a + b <= INT_MAX" (which might overflow) is the
   // same as a <= INT_MAX - b (no overflow)
   return a <= 2147483647 - b;
}

// returns 1 if the product is valid, 0 on overflow.
// negative factors are considered invalid.
private int stbi__mul2sizes_valid(int a, int b) {
   if (a < 0 || b < 0) return 0;
   if (b == 0) return 1; // mul-by-0 is always safe
   // portable way to check for no overflows in a*b
   return a <= 2147483647/b;
}

static if (!HasVersion!"STBI_NO_JPEG" || !HasVersion!"STBI_NO_PNG" || !HasVersion!"STBI_NO_TGA" || !HasVersion!"STBI_NO_HDR") {

// returns 1 if "a*b + add" has no negative terms/factors and doesn't overflow
private int stbi__mad2sizes_valid(int a, int b, int add) {
   return stbi__mul2sizes_valid(a, b) && stbi__addsizes_valid(a*b, add);
}
}


// returns 1 if "a*b*c + add" has no negative terms/factors and doesn't overflow
private int stbi__mad3sizes_valid(int a, int b, int c, int add) {
   return stbi__mul2sizes_valid(a, b) && stbi__mul2sizes_valid(a*b, c) &&
      stbi__addsizes_valid(a*b*c, add);
}

// returns 1 if "a*b*c*d + add" has no negative terms/factors and doesn't overflow
static if (!HasVersion!"STBI_NO_LINEAR" || !HasVersion!"STBI_NO_HDR" || !HasVersion!"STBI_NO_PNM") {

private int stbi__mad4sizes_valid(int a, int b, int c, int d, int add) {
   return stbi__mul2sizes_valid(a, b) && stbi__mul2sizes_valid(a*b, c) &&
      stbi__mul2sizes_valid(a*b*c, d) && stbi__addsizes_valid(a*b*c*d, add);
}
}


static if (!HasVersion!"STBI_NO_JPEG" || !HasVersion!"STBI_NO_PNG" || !HasVersion!"STBI_NO_TGA" || !HasVersion!"STBI_NO_HDR") {

// mallocs with size overflow checking
private void* stbi__malloc_mad2(int a, int b, int add) {
   if (!stbi__mad2sizes_valid(a, b, add)) return null;
   return stbi__malloc(a*b + add);
}
}


private void* stbi__malloc_mad3(int a, int b, int c, int add) {
   if (!stbi__mad3sizes_valid(a, b, c, add)) return null;
   return stbi__malloc(a*b*c + add);
}

static if (!HasVersion!"STBI_NO_LINEAR" || !HasVersion!"STBI_NO_HDR" || !HasVersion!"STBI_NO_PNM") {

private void* stbi__malloc_mad4(int a, int b, int c, int d, int add) {
   if (!stbi__mad4sizes_valid(a, b, c, d, add)) return null;
   return stbi__malloc(a*b*c*d + add);
}
}


// stbi__err - error
// stbi__errpf - error returning pointer to float
// stbi__errpuc - error returning pointer to unsigned char

version (STBI_NO_FAILURE_STRINGS) {
} else {
   enum string stbi__err(string x,string y) = `  stbi__err(x)`;

}


enum string stbi__errpf(string x,string y) = `   ((float *)(size_t) (stbi__err(x,y)?NULL:NULL))`;

enum string stbi__errpuc(string x,string y) = `  ((unsigned char *)(size_t) (stbi__err(x,y)?NULL:NULL))`;


extern void stbi_image_free(void* retval_from_stbi_load) {
   free(retval_from_stbi_load);
}

version (STBI_NO_LINEAR) {} else {

private float* stbi__ldr_to_hdr(stbi_uc* data, int x, int y, int comp);
}


version (STBI_NO_HDR) {} else {

private stbi_uc* stbi__hdr_to_ldr(float* data, int x, int y, int comp);
}


private int stbi__vertically_flip_on_load_global = 0;

extern void stbi_set_flip_vertically_on_load(int flag_true_if_should_flip) {
   stbi__vertically_flip_on_load_global = flag_true_if_should_flip;
}

struct TH_1
{
    static int stbi__vertically_flip_on_load_local, stbi__vertically_flip_on_load_set;
}

static foreach(mem; __traits(allMembers, TH_1))
{
    mixin("alias ", mem, " = TH_1.", mem, ";");
}

extern void stbi_set_flip_vertically_on_load_thread(int flag_true_if_should_flip) {
   stbi__vertically_flip_on_load_local = flag_true_if_should_flip;
   stbi__vertically_flip_on_load_set = 1;
}

/*enum stbi__vertically_flip_on_load =  (stbi__vertically_flip_on_load_set       
                                         ? stbi__vertically_flip_on_load_local  
                                         : stbi__vertically_flip_on_load_global);*/


private void* stbi__load_main(stbi__context* s, int* x, int* y, int* comp, int req_comp, stbi__result_info* ri, int bpc) {
   memset(ri, 0, typeof(*ri).sizeof); // make sure it's initialized if we add new fields
   ri.bits_per_channel = 8; // default is 8 so most paths don't have to be changed
   ri.channel_order = STBI_ORDER_RGB; // all current input & output are this, but this is here so we can add BGR order
   ri.num_channels = 0;

   // test the formats with a very explicit header first (at least a FOURCC
   // or distinctive magic number first)
   version (STBI_NO_PNG) {} else {

   if (stbi__png_test(s)) return stbi__png_load(s,x,y,comp,req_comp, ri);
   }

   version (STBI_NO_BMP) {} else {





   }
   version (STBI_NO_GIF) {} else {

   if (stbi__gif_test(s)) return stbi__gif_load(s,x,y,comp,req_comp, ri);
   }

   version (STBI_NO_PSD) {} else {





   } version (STBI_NO_PSD) {
   cast(void)bpc.sizeof;
   }

   version (STBI_NO_PIC) {} else {





   }

   // then the formats that can end up attempting to load with just 1 or 2
   // bytes matching expectations; these are prone to false positives, so
   // try them later
   version (STBI_NO_JPEG) {} else {





   }
   version (STBI_NO_PNM) {} else {





   }

   version (STBI_NO_HDR) {} else {

   if (stbi__hdr_test(s)) {
      float* hdr = stbi__hdr_load(s, x,y,comp,req_comp, ri);
      return stbi__hdr_to_ldr(hdr, *x, *y, req_comp ? req_comp : *comp);
   }
   }


   version (STBI_NO_TGA) {} else {







   }

   return (cast(ubyte*)cast(size_t) (stbi__err("unknown image type")?null:null));
}

private stbi_uc* stbi__convert_16_to_8(stbi__uint16* orig, int w, int h, int channels) {
   int i = void;
   int img_len = w * h * channels;
   stbi_uc* reduced = void;

   reduced = cast(stbi_uc*) stbi__malloc(img_len);
   if (reduced == null) return (cast(ubyte*)cast(size_t) (stbi__err("outofmem")?null:null));

   for (i = 0; i < img_len; ++i)
      reduced[i] = cast(stbi_uc)((orig[i] >> 8) & 0xFF); // top half of each byte is sufficient approx of 16->8 bit scaling

   free(orig);
   return reduced;
}

private stbi__uint16* stbi__convert_8_to_16(stbi_uc* orig, int w, int h, int channels) {
   int i = void;
   int img_len = w * h * channels;
   stbi__uint16* enlarged = void;

   enlarged = cast(stbi__uint16*) stbi__malloc(img_len*2);
   if (enlarged == null) return cast(stbi__uint16*) (cast(ubyte*)cast(size_t) (stbi__err("outofmem")?null:null));

   for (i = 0; i < img_len; ++i)
      enlarged[i] = cast(stbi__uint16)((orig[i] << 8) + orig[i]); // replicate to high and low byte, maps 0->0, 255->0xffff

   free(orig);
   return enlarged;
}

private void stbi__vertical_flip(void* image, int w, int h, int bytes_per_pixel) {
   int row = void;
   size_t bytes_per_row = cast(size_t)w * bytes_per_pixel;
   stbi_uc[2048] temp = void;
   stbi_uc* bytes = cast(stbi_uc*)image;

   for (row = 0; row < (h>>1); row++) {
      stbi_uc* row0 = bytes + row*bytes_per_row;
      stbi_uc* row1 = bytes + (h - row - 1)*bytes_per_row;
      // swap row0 with row1
      size_t bytes_left = bytes_per_row;
      while (bytes_left) {
         size_t bytes_copy = (bytes_left < temp.sizeof) ? bytes_left : temp.sizeof;
         memcpy(temp.ptr, row0, bytes_copy);
         memcpy(row0, row1, bytes_copy);
         memcpy(row1, temp.ptr, bytes_copy);
         row0 += bytes_copy;
         row1 += bytes_copy;
         bytes_left -= bytes_copy;
      }
   }
}

version (STBI_NO_GIF) {} else {

private void stbi__vertical_flip_slices(void* image, int w, int h, int z, int bytes_per_pixel) {
   int slice = void;
   int slice_size = w * h * bytes_per_pixel;

   stbi_uc* bytes = cast(stbi_uc*)image;
   for (slice = 0; slice < z; ++slice) {
      stbi__vertical_flip(bytes, w, h, bytes_per_pixel);
      bytes += slice_size;
   }
}
}


private ubyte* stbi__load_and_postprocess_8bit(stbi__context* s, int* x, int* y, int* comp, int req_comp) {
   stbi__result_info ri = void;
   void* result = stbi__load_main(s, x, y, comp, req_comp, &ri, 8);

   if (result == null)
      return null;

   // it is the responsibility of the loaders to make sure we get either 8 or 16 bit.
   assert(ri.bits_per_channel == 8 || ri.bits_per_channel == 16);

   if (ri.bits_per_channel != 8) {
      result = stbi__convert_16_to_8(cast(stbi__uint16*) result, *x, *y, req_comp == 0 ? *comp : req_comp);
      ri.bits_per_channel = 8;
   }

   // @TODO: move stbi__convert_format to here

   if ((stbi__vertically_flip_on_load_set ? stbi__vertically_flip_on_load_local : stbi__vertically_flip_on_load_global)) {
      int channels = req_comp ? req_comp : *comp;
      stbi__vertical_flip(result, *x, *y, channels * int(stbi_uc.sizeof));
   }

   return cast(ubyte*) result;
}

private stbi__uint16* stbi__load_and_postprocess_16bit(stbi__context* s, int* x, int* y, int* comp, int req_comp) {
   stbi__result_info ri = void;
   void* result = stbi__load_main(s, x, y, comp, req_comp, &ri, 16);

   if (result == null)
      return null;

   // it is the responsibility of the loaders to make sure we get either 8 or 16 bit.
   assert(ri.bits_per_channel == 8 || ri.bits_per_channel == 16);

   if (ri.bits_per_channel != 16) {
      result = stbi__convert_8_to_16(cast(stbi_uc*) result, *x, *y, req_comp == 0 ? *comp : req_comp);
      ri.bits_per_channel = 16;
   }

   // @TODO: move stbi__convert_format16 to here
   // @TODO: special case RGB-to-Y (and RGBA-to-YA) for 8-bit-to-16-bit case to keep more precision

   if ((stbi__vertically_flip_on_load_set ? stbi__vertically_flip_on_load_local : stbi__vertically_flip_on_load_global)) {
      int channels = req_comp ? req_comp : *comp;
      stbi__vertical_flip(result, *x, *y, channels * int(stbi__uint16.sizeof));
   }

   return cast(stbi__uint16*) result;
}

static if (!HasVersion!"STBI_NO_HDR" && !HasVersion!"STBI_NO_LINEAR") {

private void stbi__float_postprocess(float* result, int* x, int* y, int* comp, int req_comp) {
   if ((stbi__vertically_flip_on_load_set ? stbi__vertically_flip_on_load_local : stbi__vertically_flip_on_load_global) && result != null) {
      int channels = req_comp ? req_comp : *comp;
      stbi__vertical_flip(result, *x, *y, channels * int(float.sizeof));
   }
}
}


version (STBI_NO_STDIO) {} else {


static if (HasVersion!"Windows" && HasVersion!"STBI_WINDOWS_UTF8") {






}

static if (HasVersion!"Windows" && HasVersion!"STBI_WINDOWS_UTF8") {








}

private FILE* stbi__fopen(const(char)* filename, const(char)* mode) {
   FILE* f = void;
static if (HasVersion!"Windows" && HasVersion!"STBI_WINDOWS_UTF8") {
} else {
   f = fopen(filename, mode);
}

   return f;
}


extern stbi_uc* stbi_load(const(char)* filename, int* x, int* y, int* comp, int req_comp) {
   FILE* f = stbi__fopen(filename, "rb");
   ubyte* result = void;
   if (!f) return (cast(ubyte*)cast(size_t) (stbi__err("can't fopen")?null:null));
   result = stbi_load_from_file(f,x,y,comp,req_comp);
   fclose(f);
   return result;
}

extern stbi_uc* stbi_load_from_file(FILE* f, int* x, int* y, int* comp, int req_comp) {
   ubyte* result = void;
   stbi__context s = void;
   stbi__start_file(&s,f);
   result = stbi__load_and_postprocess_8bit(&s,x,y,comp,req_comp);
   if (result) {
      // need to 'unget' all the characters in the IO buffer
      fseek(f, - cast(int) (s.img_buffer_end - s.img_buffer), SEEK_CUR);
   }
   return result;
}

extern stbi__uint16* stbi_load_from_file_16(FILE* f, int* x, int* y, int* comp, int req_comp) {
   stbi__uint16* result = void;
   stbi__context s = void;
   stbi__start_file(&s,f);
   result = stbi__load_and_postprocess_16bit(&s,x,y,comp,req_comp);
   if (result) {
      // need to 'unget' all the characters in the IO buffer
      fseek(f, - cast(int) (s.img_buffer_end - s.img_buffer), SEEK_CUR);
   }
   return result;
}

extern stbi_us* stbi_load_16(const(char)* filename, int* x, int* y, int* comp, int req_comp) {
   FILE* f = stbi__fopen(filename, "rb");
   stbi__uint16* result = void;
   if (!f) return cast(stbi_us*) (cast(ubyte*)cast(size_t) (stbi__err("can't fopen")?null:null));
   result = stbi_load_from_file_16(f,x,y,comp,req_comp);
   fclose(f);
   return result;
}


} //!STBI_NO_STDIO


extern stbi_us* stbi_load_16_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* channels_in_file, int desired_channels) {
   stbi__context s = void;
   stbi__start_mem(&s,buffer,len);
   return stbi__load_and_postprocess_16bit(&s,x,y,channels_in_file,desired_channels);
}

extern stbi_us* stbi_load_16_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* channels_in_file, int desired_channels) {
   stbi__context s = void;
   stbi__start_callbacks(&s, cast(stbi_io_callbacks*)clbk, user);
   return stbi__load_and_postprocess_16bit(&s,x,y,channels_in_file,desired_channels);
}

extern stbi_uc* stbi_load_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp, int req_comp) {
   stbi__context s = void;
   stbi__start_mem(&s,buffer,len);
   return stbi__load_and_postprocess_8bit(&s,x,y,comp,req_comp);
}

extern stbi_uc* stbi_load_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* comp, int req_comp) {
   stbi__context s = void;
   stbi__start_callbacks(&s, cast(stbi_io_callbacks*) clbk, user);
   return stbi__load_and_postprocess_8bit(&s,x,y,comp,req_comp);
}

version (STBI_NO_GIF) {} else {

extern stbi_uc* stbi_load_gif_from_memory(const(stbi_uc)* buffer, int len, int** delays, int* x, int* y, int* z, int* comp, int req_comp) {
   ubyte* result = void;
   stbi__context s = void;
   stbi__start_mem(&s,buffer,len);

   result = cast(ubyte*) stbi__load_gif_main(&s, delays, x, y, z, comp, req_comp);
   if ((stbi__vertically_flip_on_load_set ? stbi__vertically_flip_on_load_local : stbi__vertically_flip_on_load_global)) {
      stbi__vertical_flip_slices( result, *x, *y, *z, *comp );
   }

   return result;
}
}


version (STBI_NO_LINEAR) {} else {

private float* stbi__loadf_main(stbi__context* s, int* x, int* y, int* comp, int req_comp) {
   ubyte* data = void;
   version (STBI_NO_HDR) {} else {

   if (stbi__hdr_test(s)) {
      stbi__result_info ri = void;
      float* hdr_data = stbi__hdr_load(s,x,y,comp,req_comp, &ri);
      if (hdr_data)
         stbi__float_postprocess(hdr_data,x,y,comp,req_comp);
      return hdr_data;
   }
   }

   data = stbi__load_and_postprocess_8bit(s, x, y, comp, req_comp);
   if (data)
      return stbi__ldr_to_hdr(data, *x, *y, req_comp ? req_comp : *comp);
   return (cast(float*)cast(size_t) (stbi__err("unknown image type")?null:null));
}

extern float* stbi_loadf_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp, int req_comp) {
   stbi__context s = void;
   stbi__start_mem(&s,buffer,len);
   return stbi__loadf_main(&s,x,y,comp,req_comp);
}

extern float* stbi_loadf_from_callbacks(const(stbi_io_callbacks)* clbk, void* user, int* x, int* y, int* comp, int req_comp) {
   stbi__context s = void;
   stbi__start_callbacks(&s, cast(stbi_io_callbacks*) clbk, user);
   return stbi__loadf_main(&s,x,y,comp,req_comp);
}

version (STBI_NO_STDIO) {} else {

extern float* stbi_loadf(const(char)* filename, int* x, int* y, int* comp, int req_comp) {
   float* result = void;
   FILE* f = stbi__fopen(filename, "rb");
   if (!f) return (cast(float*)cast(size_t) (stbi__err("can't fopen")?null:null));
   result = stbi_loadf_from_file(f,x,y,comp,req_comp);
   fclose(f);
   return result;
}

extern float* stbi_loadf_from_file(FILE* f, int* x, int* y, int* comp, int req_comp) {
   stbi__context s = void;
   stbi__start_file(&s,f);
   return stbi__loadf_main(&s,x,y,comp,req_comp);
}
} // !STBI_NO_STDIO


} // !STBI_NO_LINEAR


// these is-hdr-or-not is defined independent of whether STBI_NO_LINEAR is
// defined, for API simplicity; if STBI_NO_LINEAR is defined, it always
// reports false!

extern int stbi_is_hdr_from_memory(const(stbi_uc)* buffer, int len) {
   version (STBI_NO_HDR) {} else {

   stbi__context s = void;
   stbi__start_mem(&s,buffer,len);
   return stbi__hdr_test(&s);
   } version (STBI_NO_HDR) {







   }
}

version (STBI_NO_STDIO) {} else {

extern int stbi_is_hdr(const(char)* filename) {
   FILE* f = stbi__fopen(filename, "rb");
   int result = 0;
   if (f) {
      result = stbi_is_hdr_from_file(f);
      fclose(f);
   }
   return result;
}

extern int stbi_is_hdr_from_file(FILE* f) {
   version (STBI_NO_HDR) {} else {

   c_long pos = ftell(f);
   int res = void;
   stbi__context s = void;
   stbi__start_file(&s,f);
   res = stbi__hdr_test(&s);
   fseek(f, pos, SEEK_SET);
   return res;
   } version (STBI_NO_HDR) {






   }
}
} // !STBI_NO_STDIO


extern int stbi_is_hdr_from_callbacks(const(stbi_io_callbacks)* clbk, void* user) {
   version (STBI_NO_HDR) {} else {

   stbi__context s = void;
   stbi__start_callbacks(&s, cast(stbi_io_callbacks*) clbk, user);
   return stbi__hdr_test(&s);
   } version (STBI_NO_HDR) {







   }
}

version (STBI_NO_LINEAR) {} else {

private float stbi__l2h_gamma = 2.2f, stbi__l2h_scale = 1.0f;

extern void stbi_ldr_to_hdr_gamma(float gamma) { stbi__l2h_gamma = gamma; }
extern void stbi_ldr_to_hdr_scale(float scale) { stbi__l2h_scale = scale; }
}


private float stbi__h2l_gamma_i = 1.0f/2.2f, stbi__h2l_scale_i = 1.0f;

extern void stbi_hdr_to_ldr_gamma(float gamma) { stbi__h2l_gamma_i = 1/gamma; }
extern void stbi_hdr_to_ldr_scale(float scale) { stbi__h2l_scale_i = 1/scale; }


//////////////////////////////////////////////////////////////////////////////
//
// Common code used by all image loaders
//

enum
{
   STBI__SCAN_load=0,
   STBI__SCAN_type,
   STBI__SCAN_header
}

private void stbi__refill_buffer(stbi__context* s) {
   int n = s.io.read(s.io_user_data,cast(char*)s.buffer_start,s.buflen);
   s.callback_already_read += cast(int) (s.img_buffer - s.img_buffer_original);
   if (n == 0) {
      // at end of file, treat same as if from memory, but need to handle case
      // where s->img_buffer isn't pointing to safe memory, e.g. 0-byte file
      s.read_from_callbacks = 0;
      s.img_buffer = s.buffer_start.ptr;
      s.img_buffer_end = s.buffer_start.ptr+1;
      *s.img_buffer = 0;
   } else {
      s.img_buffer = s.buffer_start.ptr;
      s.img_buffer_end = s.buffer_start.ptr + n;
   }
}

            private stbi_uc stbi__get8(stbi__context* s) {
   if (s.img_buffer < s.img_buffer_end)
      return *s.img_buffer++;
   if (s.read_from_callbacks) {
      stbi__refill_buffer(s);
      return *s.img_buffer++;
   }
   return 0;
}

static if (HasVersion!"STBI_NO_JPEG" && HasVersion!"STBI_NO_HDR" && HasVersion!"STBI_NO_PIC" && HasVersion!"STBI_NO_PNM") {





} else {
            private int stbi__at_eof(stbi__context* s) {
   if (s.io.read) {
      if (!s.io.eof(s.io_user_data)) return 0;
      // if feof() is true, check if buffer = end
      // special case: we've only got the special 0 character at the end
      if (s.read_from_callbacks == 0) return 1;
   }

   return s.img_buffer >= s.img_buffer_end;
}
}


static if (HasVersion!"STBI_NO_JPEG" && HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_BMP" && HasVersion!"STBI_NO_PSD" && HasVersion!"STBI_NO_TGA" && HasVersion!"STBI_NO_GIF" && HasVersion!"STBI_NO_PIC") {





} else {
private void stbi__skip(stbi__context* s, int n) {
   if (n == 0) return; // already there!
   if (n < 0) {
      s.img_buffer = s.img_buffer_end;
      return;
   }
   if (s.io.read) {
      int blen = cast(int) (s.img_buffer_end - s.img_buffer);
      if (blen < n) {
         s.img_buffer = s.img_buffer_end;
         s.io.skip(s.io_user_data, n - blen);
         return;
      }
   }
   s.img_buffer += n;
}
}


static if (HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_TGA" && HasVersion!"STBI_NO_HDR" && HasVersion!"STBI_NO_PNM") {





} else {
private int stbi__getn(stbi__context* s, stbi_uc* buffer, int n) {
   if (s.io.read) {
      int blen = cast(int) (s.img_buffer_end - s.img_buffer);
      if (blen < n) {
         int res = void, count = void;

         memcpy(buffer, s.img_buffer, blen);

         count = s.io.read(s.io_user_data, cast(char*) buffer + blen, n - blen);
         res = (count == (n-blen));
         s.img_buffer = s.img_buffer_end;
         return res;
      }
   }

   if (s.img_buffer+n <= s.img_buffer_end) {
      memcpy(buffer, s.img_buffer, n);
      s.img_buffer += n;
      return 1;
   } else
      return 0;
}
}


static if (HasVersion!"STBI_NO_JPEG" && HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_PSD" && HasVersion!"STBI_NO_PIC") {





} else {
private int stbi__get16be(stbi__context* s) {
   int z = stbi__get8(s);
   return (z << 8) + stbi__get8(s);
}
}


static if (HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_PSD" && HasVersion!"STBI_NO_PIC") {





} else {
private stbi__uint32 stbi__get32be(stbi__context* s) {
   stbi__uint32 z = stbi__get16be(s);
   return (z << 16) + stbi__get16be(s);
}
}


static if (HasVersion!"STBI_NO_BMP" && HasVersion!"STBI_NO_TGA" && HasVersion!"STBI_NO_GIF") {





} else {
private int stbi__get16le(stbi__context* s) {
   int z = stbi__get8(s);
   return z + (stbi__get8(s) << 8);
}
}


version (STBI_NO_BMP) {} else {
}

enum string STBI__BYTECAST(string x) = `  ((stbi_uc) ((x) & 255))  // truncate int to byte without warnings`;


static if (HasVersion!"STBI_NO_JPEG" && HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_BMP" && HasVersion!"STBI_NO_PSD" && HasVersion!"STBI_NO_TGA" && HasVersion!"STBI_NO_GIF" && HasVersion!"STBI_NO_PIC" && HasVersion!"STBI_NO_PNM") {





} else {
//////////////////////////////////////////////////////////////////////////////
//
//  generic converter from built-in img_n to req_comp
//    individual types do this automatically as much as possible (e.g. jpeg
//    does all cases internally since it needs to colorspace convert anyway,
//    and it never has alpha, so very few cases ). png can automatically
//    interleave an alpha=255 channel, but falls back to this for other cases
//
//  assume data buffer is malloced, so malloc a new one and free that one
//  only failure mode is malloc failing

private stbi_uc stbi__compute_y(int r, int g, int b) {
   return cast(stbi_uc) (((r*77) + (g*150) + (29*b)) >> 8);
}
}


static if (HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_BMP" && HasVersion!"STBI_NO_PSD" && HasVersion!"STBI_NO_TGA" && HasVersion!"STBI_NO_GIF" && HasVersion!"STBI_NO_PIC" && HasVersion!"STBI_NO_PNM") {





} else {
private ubyte* stbi__convert_format(ubyte* data, int img_n, int req_comp, uint x, uint y) {
   int i = void, j = void;
   ubyte* good = void;

   if (req_comp == img_n) return data;
   assert(req_comp >= 1 && req_comp <= 4);

   good = cast(ubyte*) stbi__malloc_mad3(req_comp, x, y, 0);
   if (good == null) {
      free(data);
      return (cast(ubyte*)cast(size_t) (stbi__err("outofmem")?null:null));
   }

   for (j=0; j < cast(int) y; ++j) {
      ubyte* src = data + j * x * img_n;
      ubyte* dest = good + j * x * req_comp;

      enum string STBI__COMBO(string a,string b) = `  ((a)*8+(b))`;

      enum string STBI__CASE(string a,string b) = `   case STBI__COMBO(a,b): for(i=x-1; i >= 0; --i, src += a, dest += b)`;

      // convert source image with img_n components to one with req_comp components;
      // avoid switch per pixel, so use switch per scanline and massive macros
      switch (((img_n)*8+(req_comp))) {
         case ((1)*8+(2)): for(i=x-1; i >= 0; --i, src += 1, dest += 2) { dest[0]=src[0]; dest[1]=255; } break;
         case ((1)*8+(3)): for(i=x-1; i >= 0; --i, src += 1, dest += 3) { dest[0]=dest[1]=dest[2]=src[0]; } break;
         case ((1)*8+(4)): for(i=x-1; i >= 0; --i, src += 1, dest += 4) { dest[0]=dest[1]=dest[2]=src[0]; dest[3]=255; } break;
         case ((2)*8+(1)): for(i=x-1; i >= 0; --i, src += 2, dest += 1) { dest[0]=src[0]; } break;
         case ((2)*8+(3)): for(i=x-1; i >= 0; --i, src += 2, dest += 3) { dest[0]=dest[1]=dest[2]=src[0]; } break;
         case ((2)*8+(4)): for(i=x-1; i >= 0; --i, src += 2, dest += 4) { dest[0]=dest[1]=dest[2]=src[0]; dest[3]=src[1]; } break;
         case ((3)*8+(4)): for(i=x-1; i >= 0; --i, src += 3, dest += 4) { dest[0]=src[0];dest[1]=src[1];dest[2]=src[2];dest[3]=255; } break;
         case ((3)*8+(1)): for(i=x-1; i >= 0; --i, src += 3, dest += 1) { dest[0]=stbi__compute_y(src[0],src[1],src[2]); } break;
         case ((3)*8+(2)): for(i=x-1; i >= 0; --i, src += 3, dest += 2) { dest[0]=stbi__compute_y(src[0],src[1],src[2]); dest[1] = 255; } break;
         case ((4)*8+(1)): for(i=x-1; i >= 0; --i, src += 4, dest += 1) { dest[0]=stbi__compute_y(src[0],src[1],src[2]); } break;
         case ((4)*8+(2)): for(i=x-1; i >= 0; --i, src += 4, dest += 2) { dest[0]=stbi__compute_y(src[0],src[1],src[2]); dest[1] = src[3]; } break;
         case ((4)*8+(3)): for(i=x-1; i >= 0; --i, src += 4, dest += 3) { dest[0]=src[0];dest[1]=src[1];dest[2]=src[2]; } break;
         default: assert(0); //free(data); free(good); return (cast(ubyte*)cast(size_t) (stbi__err("unsupported")?null:null));
      }
         }

   free(data);
   return good;
}
}


static if (HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_PSD") {





} else {
private stbi__uint16 stbi__compute_y_16(int r, int g, int b) {
   return cast(stbi__uint16) (((r*77) + (g*150) + (29*b)) >> 8);
}
}


static if (HasVersion!"STBI_NO_PNG" && HasVersion!"STBI_NO_PSD") {





} else {
private stbi__uint16* stbi__convert_format16(stbi__uint16* data, int img_n, int req_comp, uint x, uint y) {
   int i = void, j = void;
   stbi__uint16* good = void;

   if (req_comp == img_n) return data;
   assert(req_comp >= 1 && req_comp <= 4);

   good = cast(stbi__uint16*) stbi__malloc(req_comp * x * y * 2);
   if (good == null) {
      free(data);
      return cast(stbi__uint16*) (cast(ubyte*)cast(size_t) (stbi__err("outofmem")?null:null));
   }

   for (j=0; j < cast(int) y; ++j) {
      stbi__uint16* src = data + j * x * img_n;
      stbi__uint16* dest = good + j * x * req_comp;

      enum string STBI__COMBO(string a,string b) = `  ((a)*8+(b))`;

      enum string STBI__CASE(string a,string b) = `   case STBI__COMBO(a,b): for(i=x-1; i >= 0; --i, src += a, dest += b)`;

      // convert source image with img_n components to one with req_comp components;
      // avoid switch per pixel, so use switch per scanline and massive macros
      switch (((img_n)*8+(req_comp))) {
         case ((1)*8+(2)): for(i=x-1; i >= 0; --i, src += 1, dest += 2) { dest[0]=src[0]; dest[1]=0xffff; } break;
         case ((1)*8+(3)): for(i=x-1; i >= 0; --i, src += 1, dest += 3) { dest[0]=dest[1]=dest[2]=src[0]; } break;
         case ((1)*8+(4)): for(i=x-1; i >= 0; --i, src += 1, dest += 4) { dest[0]=dest[1]=dest[2]=src[0]; dest[3]=0xffff; } break;
         case ((2)*8+(1)): for(i=x-1; i >= 0; --i, src += 2, dest += 1) { dest[0]=src[0]; } break;
         case ((2)*8+(3)): for(i=x-1; i >= 0; --i, src += 2, dest += 3) { dest[0]=dest[1]=dest[2]=src[0]; } break;
         case ((2)*8+(4)): for(i=x-1; i >= 0; --i, src += 2, dest += 4) { dest[0]=dest[1]=dest[2]=src[0]; dest[3]=src[1]; } break;
         case ((3)*8+(4)): for(i=x-1; i >= 0; --i, src += 3, dest += 4) { dest[0]=src[0];dest[1]=src[1];dest[2]=src[2];dest[3]=0xffff; } break;
         case ((3)*8+(1)): for(i=x-1; i >= 0; --i, src += 3, dest += 1) { dest[0]=stbi__compute_y_16(src[0],src[1],src[2]); } break;
         case ((3)*8+(2)): for(i=x-1; i >= 0; --i, src += 3, dest += 2) { dest[0]=stbi__compute_y_16(src[0],src[1],src[2]); dest[1] = 0xffff; } break;
         case ((4)*8+(1)): for(i=x-1; i >= 0; --i, src += 4, dest += 1) { dest[0]=stbi__compute_y_16(src[0],src[1],src[2]); } break;
         case ((4)*8+(2)): for(i=x-1; i >= 0; --i, src += 4, dest += 2) { dest[0]=stbi__compute_y_16(src[0],src[1],src[2]); dest[1] = src[3]; } break;
         case ((4)*8+(3)): for(i=x-1; i >= 0; --i, src += 4, dest += 3) { dest[0]=src[0];dest[1]=src[1];dest[2]=src[2]; } break;
         default: assert(0); //free(data); free(good); return cast(stbi__uint16*) (cast(ubyte*)cast(size_t) (stbi__err("unsupported")?null:null));
      }
         }

   free(data);
   return good;
}
}


version (STBI_NO_LINEAR) {} else {

private float* stbi__ldr_to_hdr(stbi_uc* data, int x, int y, int comp) {
   int i = void, k = void, n = void;
   float* output = void;
   if (!data) return null;
   output = cast(float*) stbi__malloc_mad4(x, y, comp, float.sizeof, 0);
   if (output == null) { free(data); return (cast(float*)cast(size_t) (stbi__err("outofmem")?null:null)); }
   // compute number of non-alpha components
   if (comp & 1) n = comp; else n = comp-1;
   for (i=0; i < x*y; ++i) {
      for (k=0; k < n; ++k) {
         output[i*comp + k] = cast(float) (pow(data[i*comp+k]/255.0f, stbi__l2h_gamma) * stbi__l2h_scale);
      }
   }
   if (n < comp) {
      for (i=0; i < x*y; ++i) {
         output[i*comp + n] = data[i*comp + n]/255.0f;
      }
   }
   free(data);
   return output;
}
}


version (STBI_NO_HDR) {} else {

enum string stbi__float2int(string x) = `   ((int) (x))`;

private stbi_uc* stbi__hdr_to_ldr(float* data, int x, int y, int comp) {
   int i = void, k = void, n = void;
   stbi_uc* output = void;
   if (!data) return null;
   output = cast(stbi_uc*) stbi__malloc_mad3(x, y, comp, 0);
   if (output == null) { free(data); return (cast(ubyte*)cast(size_t) (stbi__err("outofmem")?null:null)); }
   // compute number of non-alpha components
   if (comp & 1) n = comp; else n = comp-1;
   for (i=0; i < x*y; ++i) {
      for (k=0; k < n; ++k) {
         float z = cast(float) pow(data[i*comp+k]*stbi__h2l_scale_i, stbi__h2l_gamma_i) * 255 + 0.5f;
         if (z < 0) z = 0;
         if (z > 255) z = 255;
         output[i*comp + k] = cast(stbi_uc) (cast(int) (z));
      }
      if (k < comp) {
         float z = data[i*comp+k] * 255 + 0.5f;
         if (z < 0) z = 0;
         if (z > 255) z = 255;
         output[i*comp + k] = cast(stbi_uc) (cast(int) (z));
      }
   }
   free(data);
   return output;
}
}


//////////////////////////////////////////////////////////////////////////////
//
//  "baseline" JPEG/JFIF decoder
//
//    simple implementation
//      - doesn't support delayed output of y-dimension
//      - simple interface (only one output format: 8-bit interleaved RGB)
//      - doesn't try to recover corrupt jpegs
//      - doesn't allow partial loading, loading multiple at once
//      - still fast on x86 (copying globals into locals doesn't help x86)
//      - allocates lots of intermediate memory (full size of all components)
//        - non-interleaved case requires this anyway
//        - allows good upsampling (see next)
//    high-quality
//      - upsampled channels are bilinearly interpolated, even across blocks
//      - quality integer IDCT derived from IJG's 'slow'
//    performance
//      - fast huffman; reasonable integer IDCT
//      - some SIMD kernels for common paths on targets with SSE2/NEON
//      - uses a lot of intermediate memory, could cache poorly

version (STBI_NO_JPEG) {} else {
}

// public domain zlib decode    v0.2  Sean Barrett 2006-11-18
//    simple implementation
//      - all input must be provided in an upfront buffer
//      - all output is written to a single output buffer (can malloc/realloc)
//    performance
//      - fast huffman

version (STBI_NO_ZLIB) {} else {


// fast-way is faster to check than jpeg huffman, but slow way is slower
enum STBI__ZFAST_BITS =  9; // accelerate all cases in default tables;

enum STBI__ZFAST_MASK =  ((1 << STBI__ZFAST_BITS) - 1);

enum STBI__ZNSYMS = 288; // number of symbols in literal/length alphabet;


// zlib-style huffman encoding
// (jpegs packs from left, zlib from right, so can't share code)
struct _Stbi__zhuffman {
   stbi__uint16[1 << 9] fast;
   stbi__uint16[16] firstcode;
   int[17] maxcode;
   stbi__uint16[16] firstsymbol;
   stbi_uc[288] size;
   stbi__uint16[288] value;
}alias stbi__zhuffman = _Stbi__zhuffman;

            private int stbi__bitreverse16(int n) {
  n = ((n & 0xAAAA) >> 1) | ((n & 0x5555) << 1);
  n = ((n & 0xCCCC) >> 2) | ((n & 0x3333) << 2);
  n = ((n & 0xF0F0) >> 4) | ((n & 0x0F0F) << 4);
  n = ((n & 0xFF00) >> 8) | ((n & 0x00FF) << 8);
  return n;
}

            private int stbi__bit_reverse(int v, int bits) {
   assert(bits <= 16);
   // to bit reverse n bits, reverse 16 and shift
   // e.g. 11 bits, bit reverse and shift away 5
   return stbi__bitreverse16(v) >> (16-bits);
}

private int stbi__zbuild_huffman(stbi__zhuffman* z, const(stbi_uc)* sizelist, int num) {
   int i = void, k = 0;
   int code = void; int[16] next_code = void; int[17] sizes = void;

   // DEFLATE spec for generating codes
   memset(sizes.ptr, 0, sizes.sizeof);
   memset(z.fast.ptr, 0, typeof(z.fast).sizeof);
   for (i=0; i < num; ++i)
      ++sizes[sizelist[i]];
   sizes[0] = 0;
   for (i=1; i < 16; ++i)
      if (sizes[i] > (1 << i))
         return stbi__err("bad sizes");
   code = 0;
   for (i=1; i < 16; ++i) {
      next_code[i] = code;
      z.firstcode[i] = cast(stbi__uint16) code;
      z.firstsymbol[i] = cast(stbi__uint16) k;
      code = (code + sizes[i]);
      if (sizes[i])
         if (code-1 >= (1 << i)) return stbi__err("bad codelengths");
      z.maxcode[i] = code << (16-i); // preshift for inner loop
      code <<= 1;
      k += sizes[i];
   }
   z.maxcode[16] = 0x10000; // sentinel
   for (i=0; i < num; ++i) {
      int s = sizelist[i];
      if (s) {
         int c = next_code[s] - z.firstcode[s] + z.firstsymbol[s];
         stbi__uint16 fastv = cast(stbi__uint16) ((s << 9) | i);
         z.size [c] = cast(stbi_uc ) s;
         z.value[c] = cast(stbi__uint16) i;
         if (s <= 9) {
            int j = stbi__bit_reverse(next_code[s],s);
            while (j < (1 << 9)) {
               z.fast[j] = fastv;
               j += (1 << s);
            }
         }
         ++next_code[s];
      }
   }
   return 1;
}

// zlib-from-memory implementation for PNG reading
//    because PNG allows splitting the zlib stream arbitrarily,
//    and it's annoying structurally to have PNG call ZLIB call PNG,
//    we require PNG read all the IDATs and combine them into a single
//    memory buffer

struct _Stbi__zbuf {
   stbi_uc* zbuffer, zbuffer_end;
   int num_bits;
   stbi__uint32 code_buffer;

   char* zout;
   char* zout_start;
   char* zout_end;
   int z_expandable;

   stbi__zhuffman z_length, z_distance;
}alias stbi__zbuf = _Stbi__zbuf;

            private int stbi__zeof(stbi__zbuf* z) {
   return (z.zbuffer >= z.zbuffer_end);
}

            private stbi_uc stbi__zget8(stbi__zbuf* z) {
   return stbi__zeof(z) ? 0 : *z.zbuffer++;
}

private void stbi__fill_bits(stbi__zbuf* z) {
   do {
      if (z.code_buffer >= (1U << z.num_bits)) {
        z.zbuffer = z.zbuffer_end; /* treat this as EOF so we fail. */
        return;
      }
      z.code_buffer |= cast(uint) stbi__zget8(z) << z.num_bits;
      z.num_bits += 8;
   } while (z.num_bits <= 24);
}

            private uint stbi__zreceive(stbi__zbuf* z, int n) {
   uint k = void;
   if (z.num_bits < n) stbi__fill_bits(z);
   k = z.code_buffer & ((1 << n) - 1);
   z.code_buffer >>= n;
   z.num_bits -= n;
   return k;
}

private int stbi__zhuffman_decode_slowpath(stbi__zbuf* a, stbi__zhuffman* z) {
   int b = void, s = void, k = void;
   // not resolved by fast table, so compute it the slow way
   // use jpeg approach, which requires MSbits at top
   k = stbi__bit_reverse(a.code_buffer, 16);
   for (s=9 +1; ; ++s)
      if (k < z.maxcode[s])
         break;
   if (s >= 16) return -1; // invalid code!
   // code size is s, so:
   b = (k >> (16-s)) - z.firstcode[s] + z.firstsymbol[s];
   if (b >= 288) return -1; // some data was corrupt somewhere!
   if (z.size[b] != s) return -1; // was originally an assert, but report failure instead.
   a.code_buffer >>= s;
   a.num_bits -= s;
   return z.value[b];
}

            private int stbi__zhuffman_decode(stbi__zbuf* a, stbi__zhuffman* z) {
   int b = void, s = void;
   if (a.num_bits < 16) {
      if (stbi__zeof(a)) {
         return -1; /* report error for unexpected end of data. */
      }
      stbi__fill_bits(a);
   }
   b = z.fast[a.code_buffer & ((1 << 9) - 1)];
   if (b) {
      s = b >> 9;
      a.code_buffer >>= s;
      a.num_bits -= s;
      return b & 511;
   }
   return stbi__zhuffman_decode_slowpath(a, z);
}

private int stbi__zexpand(stbi__zbuf* z, char* zout, int n) {
   char* q = void;
   uint cur = void, limit = void, old_limit = void;
   z.zout = zout;
   if (!z.z_expandable) return stbi__err("output buffer limit");
   cur = cast(uint) (z.zout - z.zout_start);
   limit = old_limit = cast(uint) (z.zout_end - z.zout_start);
   if ((2147483647 *2U +1U) - cur < cast(uint) n) return stbi__err("outofmem");
   while (cur + n > limit) {
      if(limit > (2147483647 *2U +1U) / 2) return stbi__err("outofmem");
      limit *= 2;
   }
   q = cast(char*) realloc(z.zout_start,limit);
   cast(void)old_limit.sizeof;
   if (q == null) return stbi__err("outofmem");
   z.zout_start = q;
   z.zout = q + cur;
   z.zout_end = q + limit;
   return 1;
}

private const(int)[31] stbi__zlength_base = [
   3,4,5,6,7,8,9,10,11,13,
   15,17,19,23,27,31,35,43,51,59,
   67,83,99,115,131,163,195,227,258,0,0 ];

private const(int)[31] stbi__zlength_extra =
[ 0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,0,0 ];

private const(int)[32] stbi__zdist_base = [ 1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577,0,0];

private const(int)[32] stbi__zdist_extra =
[ 0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13];

private int stbi__parse_huffman_block(stbi__zbuf* a) {
   char* zout = a.zout;
   for(;;) {
      int z = stbi__zhuffman_decode(a, &a.z_length);
      if (z < 256) {
         if (z < 0) return stbi__err("bad huffman code"); // error in huffman codes
         if (zout >= a.zout_end) {
            if (!stbi__zexpand(a, zout, 1)) return 0;
            zout = a.zout;
         }
         *zout++ = cast(char) z;
      } else {
         stbi_uc* p = void;
         int len = void, dist = void;
         if (z == 256) {
            a.zout = zout;
            return 1;
         }
         z -= 257;
         len = stbi__zlength_base[z];
         if (stbi__zlength_extra[z]) len += stbi__zreceive(a, stbi__zlength_extra[z]);
         z = stbi__zhuffman_decode(a, &a.z_distance);
         if (z < 0) return stbi__err("bad huffman code");
         dist = stbi__zdist_base[z];
         if (stbi__zdist_extra[z]) dist += stbi__zreceive(a, stbi__zdist_extra[z]);
         if (zout - a.zout_start < dist) return stbi__err("bad dist");
         if (zout + len > a.zout_end) {
            if (!stbi__zexpand(a, zout, len)) return 0;
            zout = a.zout;
         }
         p = cast(stbi_uc*) (zout - dist);
         if (dist == 1) { // run of one byte; common in images.
            stbi_uc v = *p;
            if (len) { do *zout++ = v; while (--len); }
         } else {
            if (len) { do *zout++ = *p++; while (--len); }
         }
      }
   }
}

private int stbi__compute_huffman_codes(stbi__zbuf* a) {
   static const(stbi_uc)[19] length_dezigzag = [ 16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15 ];
   stbi__zhuffman z_codelength = void;
   stbi_uc[286+32+137] lencodes = void;//padding for maximum single op
   stbi_uc[19] codelength_sizes = void;
   int i = void, n = void;

   int hlit = stbi__zreceive(a,5) + 257;
   int hdist = stbi__zreceive(a,5) + 1;
   int hclen = stbi__zreceive(a,4) + 4;
   int ntot = hlit + hdist;

   memset(codelength_sizes.ptr, 0, codelength_sizes.sizeof);
   for (i=0; i < hclen; ++i) {
      int s = stbi__zreceive(a,3);
      codelength_sizes[length_dezigzag[i]] = cast(stbi_uc) s;
   }
   if (!stbi__zbuild_huffman(&z_codelength, codelength_sizes.ptr, 19)) return 0;

   n = 0;
   while (n < ntot) {
      int c = stbi__zhuffman_decode(a, &z_codelength);
      if (c < 0 || c >= 19) return stbi__err("bad codelengths");
      if (c < 16)
         lencodes[n++] = cast(stbi_uc) c;
      else {
         stbi_uc fill = 0;
         if (c == 16) {
            c = stbi__zreceive(a,2)+3;
            if (n == 0) return stbi__err("bad codelengths");
            fill = lencodes[n-1];
         } else if (c == 17) {
            c = stbi__zreceive(a,3)+3;
         } else if (c == 18) {
            c = stbi__zreceive(a,7)+11;
         } else {
            return stbi__err("bad codelengths");
         }
         if (ntot - n < c) return stbi__err("bad codelengths");
         memset(lencodes.ptr+n, fill, c);
         n += c;
      }
   }
   if (n != ntot) return stbi__err("bad codelengths");
   if (!stbi__zbuild_huffman(&a.z_length, lencodes.ptr, hlit)) return 0;
   if (!stbi__zbuild_huffman(&a.z_distance, lencodes.ptr+hlit, hdist)) return 0;
   return 1;
}

private int stbi__parse_uncompressed_block(stbi__zbuf* a) {
   stbi_uc[4] header = void;
   int len = void, nlen = void, k = void;
   if (a.num_bits & 7)
      stbi__zreceive(a, a.num_bits & 7); // discard
   // drain the bit-packed data into header
   k = 0;
   while (a.num_bits > 0) {
      header[k++] = cast(stbi_uc) (a.code_buffer & 255); // suppress MSVC run-time check
      a.code_buffer >>= 8;
      a.num_bits -= 8;
   }
   if (a.num_bits < 0) return stbi__err("zlib corrupt");
   // now fill header the normal way
   while (k < 4)
      header[k++] = stbi__zget8(a);
   len = header[1] * 256 + header[0];
   nlen = header[3] * 256 + header[2];
   if (nlen != (len ^ 0xffff)) return stbi__err("zlib corrupt");
   if (a.zbuffer + len > a.zbuffer_end) return stbi__err("read past buffer");
   if (a.zout + len > a.zout_end)
      if (!stbi__zexpand(a, a.zout, len)) return 0;
   memcpy(a.zout, a.zbuffer, len);
   a.zbuffer += len;
   a.zout += len;
   return 1;
}

private int stbi__parse_zlib_header(stbi__zbuf* a) {
   int cmf = stbi__zget8(a);
   int cm = cmf & 15;
   /* int cinfo = cmf >> 4; */
   int flg = stbi__zget8(a);
   if (stbi__zeof(a)) return stbi__err("bad zlib header"); // zlib spec
   if ((cmf*256+flg) % 31 != 0) return stbi__err("bad zlib header"); // zlib spec
   if (flg & 32) return stbi__err("no preset dict"); // preset dictionary not allowed in png
   if (cm != 8) return stbi__err("bad compression"); // DEFLATE required for png
   // window = 1 << (8 + cinfo)... but who cares, we fully buffer output
   return 1;
}

private const(stbi_uc)[288] stbi__zdefault_length = [
   8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
   8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
   8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
   8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
   8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, 7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8
];
private const(stbi_uc)[32] stbi__zdefault_distance = [
   5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
];
/*
Init algorithm:
{
   int i;   // use <= to match clearly with spec
   for (i=0; i <= 143; ++i)     stbi__zdefault_length[i]   = 8;
   for (   ; i <= 255; ++i)     stbi__zdefault_length[i]   = 9;
   for (   ; i <= 279; ++i)     stbi__zdefault_length[i]   = 7;
   for (   ; i <= 287; ++i)     stbi__zdefault_length[i]   = 8;

   for (i=0; i <=  31; ++i)     stbi__zdefault_distance[i] = 5;
}
*/

private int stbi__parse_zlib(stbi__zbuf* a, int parse_header) {
   int final_ = void, type = void;
   if (parse_header)
      if (!stbi__parse_zlib_header(a)) return 0;
   a.num_bits = 0;
   a.code_buffer = 0;
   do {
      final_ = stbi__zreceive(a,1);
      type = stbi__zreceive(a,2);
      if (type == 0) {
         if (!stbi__parse_uncompressed_block(a)) return 0;
      } else if (type == 3) {
         return 0;
      } else {
         if (type == 1) {
            // use fixed code lengths
            if (!stbi__zbuild_huffman(&a.z_length , stbi__zdefault_length.ptr , 288)) return 0;
            if (!stbi__zbuild_huffman(&a.z_distance, stbi__zdefault_distance.ptr, 32)) return 0;
         } else {
            if (!stbi__compute_huffman_codes(a)) return 0;
         }
         if (!stbi__parse_huffman_block(a)) return 0;
      }
   } while (!final_);
   return 1;
}

private int stbi__do_zlib(stbi__zbuf* a, char* obuf, int olen, int exp, int parse_header) {
   a.zout_start = obuf;
   a.zout = obuf;
   a.zout_end = obuf + olen;
   a.z_expandable = exp;

   return stbi__parse_zlib(a, parse_header);
}

extern char* stbi_zlib_decode_malloc_guesssize(const(char)* buffer, int len, int initial_size, int* outlen) {
   stbi__zbuf a = void;
   char* p = cast(char*) stbi__malloc(initial_size);
   if (p == null) return null;
   a.zbuffer = cast(stbi_uc*) buffer;
   a.zbuffer_end = cast(stbi_uc*) buffer + len;
   if (stbi__do_zlib(&a, p, initial_size, 1, 1)) {
      if (outlen) *outlen = cast(int) (a.zout - a.zout_start);
      return a.zout_start;
   } else {
      free(a.zout_start);
      return null;
   }
}

extern char* stbi_zlib_decode_malloc(const(char)* buffer, int len, int* outlen) {
   return stbi_zlib_decode_malloc_guesssize(buffer, len, 16384, outlen);
}

extern char* stbi_zlib_decode_malloc_guesssize_headerflag(const(char)* buffer, int len, int initial_size, int* outlen, int parse_header) {
   stbi__zbuf a = void;
   char* p = cast(char*) stbi__malloc(initial_size);
   if (p == null) return null;
   a.zbuffer = cast(stbi_uc*) buffer;
   a.zbuffer_end = cast(stbi_uc*) buffer + len;
   if (stbi__do_zlib(&a, p, initial_size, 1, parse_header)) {
      if (outlen) *outlen = cast(int) (a.zout - a.zout_start);
      return a.zout_start;
   } else {
      free(a.zout_start);
      return null;
   }
}

extern int stbi_zlib_decode_buffer(char* obuffer, int olen, const(char)* ibuffer, int ilen) {
   stbi__zbuf a = void;
   a.zbuffer = cast(stbi_uc*) ibuffer;
   a.zbuffer_end = cast(stbi_uc*) ibuffer + ilen;
   if (stbi__do_zlib(&a, obuffer, olen, 0, 1))
      return cast(int) (a.zout - a.zout_start);
   else
      return -1;
}

extern char* stbi_zlib_decode_noheader_malloc(const(char)* buffer, int len, int* outlen) {
   stbi__zbuf a = void;
   char* p = cast(char*) stbi__malloc(16384);
   if (p == null) return null;
   a.zbuffer = cast(stbi_uc*) buffer;
   a.zbuffer_end = cast(stbi_uc*) buffer+len;
   if (stbi__do_zlib(&a, p, 16384, 1, 0)) {
      if (outlen) *outlen = cast(int) (a.zout - a.zout_start);
      return a.zout_start;
   } else {
      free(a.zout_start);
      return null;
   }
}

extern int stbi_zlib_decode_noheader_buffer(char* obuffer, int olen, const(char)* ibuffer, int ilen) {
   stbi__zbuf a = void;
   a.zbuffer = cast(stbi_uc*) ibuffer;
   a.zbuffer_end = cast(stbi_uc*) ibuffer + ilen;
   if (stbi__do_zlib(&a, obuffer, olen, 0, 0))
      return cast(int) (a.zout - a.zout_start);
   else
      return -1;
}
}


// public domain "baseline" PNG decoder   v0.10  Sean Barrett 2006-11-18
//    simple implementation
//      - only 8-bit samples
//      - no CRC checking
//      - allocates lots of intermediate memory
//        - avoids problem of streaming data between subsystems
//        - avoids explicit window management
//    performance
//      - uses stb_zlib, a PD zlib implementation with fast huffman decoding

version (STBI_NO_PNG) {} else {

struct _Stbi__pngchunk {
   stbi__uint32 length;
   stbi__uint32 type;
}alias stbi__pngchunk = _Stbi__pngchunk;

private stbi__pngchunk stbi__get_chunk_header(stbi__context* s) {
   stbi__pngchunk c = void;
   c.length = stbi__get32be(s);
   c.type = stbi__get32be(s);
   return c;
}

private int stbi__check_png_header(stbi__context* s) {
   static const(stbi_uc)[8] png_sig = [ 137,80,78,71,13,10,26,10 ];
   int i = void;
   for (i=0; i < 8; ++i)
      if (stbi__get8(s) != png_sig[i]) return stbi__err("bad png sig");
   return 1;
}

struct _Stbi__png {
   stbi__context* s;
   stbi_uc* idata, expanded, out_;
   int depth;
}alias stbi__png = _Stbi__png;


enum {
   STBI__F_none=0,
   STBI__F_sub=1,
   STBI__F_up=2,
   STBI__F_avg=3,
   STBI__F_paeth=4,
   // synthetic filters used for first scanline to avoid needing a dummy row of 0s
   STBI__F_avg_first,
   STBI__F_paeth_first
}

private stbi_uc[5] first_row_filter = [
   STBI__F_none,
   STBI__F_sub,
   STBI__F_none,
   STBI__F_avg_first,
   STBI__F_paeth_first
];

private int stbi__paeth(int a, int b, int c) {
   int p = a + b - c;
   int pa = abs(p-a);
   int pb = abs(p-b);
   int pc = abs(p-c);
   if (pa <= pb && pa <= pc) return a;
   if (pb <= pc) return b;
   return c;
}

private const(stbi_uc)[9] stbi__depth_scale_table = [ 0, 0xff, 0x55, 0, 0x11, 0,0,0, 0x01 ];

// create the png data from post-deflated data
private int stbi__create_png_image_raw(stbi__png* a, stbi_uc* raw, stbi__uint32 raw_len, int out_n, stbi__uint32 x, stbi__uint32 y, int depth, int color) {
   int bytes = (depth == 16? 2 : 1);
   stbi__context* s = a.s;
   stbi__uint32 i = void, j = void, stride = x*out_n*bytes;
   stbi__uint32 img_len = void, img_width_bytes = void;
   int k = void;
   int img_n = s.img_n; // copy it into a local for later

   int output_bytes = out_n*bytes;
   int filter_bytes = img_n*bytes;
   int width = x;

   assert(out_n == s.img_n || out_n == s.img_n+1);
   a.out_ = cast(stbi_uc*) stbi__malloc_mad3(x, y, output_bytes, 0); // extra bytes to write off the end into
   if (!a.out_) return stbi__err("outofmem");

   if (!stbi__mad3sizes_valid(img_n, x, depth, 7)) return stbi__err("too large");
   img_width_bytes = (((img_n * x * depth) + 7) >> 3);
   img_len = (img_width_bytes + 1) * y;

   // we used to check for exact match between raw_len and img_len on non-interlaced PNGs,
   // but issue #276 reported a PNG in the wild that had extra data at the end (all zeros),
   // so just check for raw_len < img_len always.
   if (raw_len < img_len) return stbi__err("not enough pixels");

   for (j=0; j < y; ++j) {
      stbi_uc* cur = a.out_ + stride*j;
      stbi_uc* prior = void;
      int filter = *raw++;

      if (filter > 4)
         return stbi__err("invalid filter");

      if (depth < 8) {
         if (img_width_bytes > x) return stbi__err("invalid width");
         cur += x*out_n - img_width_bytes; // store output to the rightmost img_len bytes, so we can decode in place
         filter_bytes = 1;
         width = img_width_bytes;
      }
      prior = cur - stride; // bugfix: need to compute this after 'cur +=' computation above

      // if first row, use special filter that doesn't sample previous row
      if (j == 0) filter = first_row_filter[filter];

      // handle first byte explicitly
      for (k=0; k < filter_bytes; ++k) {
         switch (filter) {
            case STBI__F_none : cur[k] = raw[k]; break;
            case STBI__F_sub : cur[k] = raw[k]; break;
            case STBI__F_up : cur[k] = (cast(stbi_uc) ((raw[k] + prior[k]) & 255)); break;
            case STBI__F_avg : cur[k] = (cast(stbi_uc) ((raw[k] + (prior[k]>>1)) & 255)); break;
            case STBI__F_paeth : cur[k] = (cast(stbi_uc) ((raw[k] + stbi__paeth(0,prior[k],0)) & 255)); break;
            case STBI__F_avg_first : cur[k] = raw[k]; break;
            case STBI__F_paeth_first: cur[k] = raw[k]; break;
         default: break;}
      }

      if (depth == 8) {
         if (img_n != out_n)
            cur[img_n] = 255; // first pixel
         raw += img_n;
         cur += out_n;
         prior += out_n;
      } else if (depth == 16) {
         if (img_n != out_n) {
            cur[filter_bytes] = 255; // first pixel top byte
            cur[filter_bytes+1] = 255; // first pixel bottom byte
         }
         raw += filter_bytes;
         cur += output_bytes;
         prior += output_bytes;
      } else {
         raw += 1;
         cur += 1;
         prior += 1;
      }

      // this is a little gross, so that we don't switch per-pixel or per-component
      if (depth < 8 || img_n == out_n) {
         int nk = (width - 1)*filter_bytes;
         enum string STBI__CASE(string f) = ` \
             case f:     \
                for (k=0; k < nk; ++k)`;







         switch (filter) {
            // "none" filter turns into a memcpy here; make that explicit.
            case STBI__F_none: memcpy(cur, raw, nk); break;
            case STBI__F_sub: for (k=0; k < nk; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + cur[k-filter_bytes]) & 255)); } break;
            case STBI__F_up: for (k=0; k < nk; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + prior[k]) & 255)); } break;
            case STBI__F_avg: for (k=0; k < nk; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + ((prior[k] + cur[k-filter_bytes])>>1)) & 255)); } break;
            case STBI__F_paeth: for (k=0; k < nk; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + stbi__paeth(cur[k-filter_bytes],prior[k],prior[k-filter_bytes])) & 255)); } break;
            case STBI__F_avg_first: for (k=0; k < nk; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + (cur[k-filter_bytes] >> 1)) & 255)); } break;
            case STBI__F_paeth_first: for (k=0; k < nk; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + stbi__paeth(cur[k-filter_bytes],0,0)) & 255)); } break;
         default: break;}
                  raw += nk;
      } else {
         assert(img_n+1 == out_n);
         enum string STBI__CASE(string f) = ` \
             case f:     \
                for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) \
                   for (k=0; k < filter_bytes; ++k)`;










         switch (filter) {
            case STBI__F_none: for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) for (k=0; k < filter_bytes; ++k) { cur[k] = raw[k]; } break;
            case STBI__F_sub: for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) for (k=0; k < filter_bytes; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + cur[k- output_bytes]) & 255)); } break;
            case STBI__F_up: for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) for (k=0; k < filter_bytes; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + prior[k]) & 255)); } break;
            case STBI__F_avg: for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) for (k=0; k < filter_bytes; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + ((prior[k] + cur[k- output_bytes])>>1)) & 255)); } break;
            case STBI__F_paeth: for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) for (k=0; k < filter_bytes; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + stbi__paeth(cur[k- output_bytes],prior[k],prior[k- output_bytes])) & 255)); } break;
            case STBI__F_avg_first: for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) for (k=0; k < filter_bytes; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + (cur[k- output_bytes] >> 1)) & 255)); } break;
            case STBI__F_paeth_first: for (i=x-1; i >= 1; --i, cur[filter_bytes]=255,raw+=filter_bytes,cur+=output_bytes,prior+=output_bytes) for (k=0; k < filter_bytes; ++k) { cur[k] = (cast(stbi_uc) ((raw[k] + stbi__paeth(cur[k- output_bytes],0,0)) & 255)); } break;
         default: break;}
                  // the loop above sets the high byte of the pixels' alpha, but for
         // 16 bit png files we also need the low byte set. we'll do that here.
         if (depth == 16) {
            cur = a.out_ + stride*j; // start at the beginning of the row again
            for (i=0; i < x; ++i,cur+=output_bytes) {
               cur[filter_bytes+1] = 255;
            }
         }
      }
   }

   // we make a separate pass to expand bits to pixels; for performance,
   // this could run two scanlines behind the above code, so it won't
   // intefere with filtering but will still be in the cache.
   if (depth < 8) {
      for (j=0; j < y; ++j) {
         stbi_uc* cur = a.out_ + stride*j;
         stbi_uc* in_ = a.out_ + stride*j + x*out_n - img_width_bytes;
         // unpack 1/2/4-bit into a 8-bit buffer. allows us to keep the common 8-bit path optimal at minimal cost for 1/2/4-bit
         // png guarante byte alignment, if width is not multiple of 8/4/2 we'll decode dummy trailing data that will be skipped in the later loop
         stbi_uc scale = (color == 0) ? stbi__depth_scale_table[depth] : 1; // scale grayscale values to 0..255 range

         // note that the final byte might overshoot and write more data than desired.
         // we can allocate enough data that this never writes out of memory, but it
         // could also overwrite the next scanline. can it overwrite non-empty data
         // on the next scanline? yes, consider 1-pixel-wide scanlines with 1-bit-per-pixel.
         // so we need to explicitly clamp the final ones

         if (depth == 4) {
            for (k=x*img_n; k >= 2; k-=2, ++in_) {
               *cur++ = cast(ubyte)(scale * ((*in_ >> 4) ));
               *cur++ = cast(ubyte)(scale * ((*in_ ) & 0x0f));
            }
            if (k > 0) *cur++ = cast(ubyte)(scale * ((*in_ >> 4) ));
         } else if (depth == 2) {
            for (k=x*img_n; k >= 4; k-=4, ++in_) {
               *cur++ = cast(ubyte)(scale * ((*in_ >> 6) ));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 4) & 0x03));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 2) & 0x03));
               *cur++ = cast(ubyte)(scale * ((*in_ ) & 0x03));
            }
            if (k > 0) *cur++ = cast(ubyte)(scale * ((*in_ >> 6) ));
            if (k > 1) *cur++ = cast(ubyte)(scale * ((*in_ >> 4) & 0x03));
            if (k > 2) *cur++ = cast(ubyte)(scale * ((*in_ >> 2) & 0x03));
         } else if (depth == 1) {
            for (k=x*img_n; k >= 8; k-=8, ++in_) {
               *cur++ = cast(ubyte)(scale * ((*in_ >> 7) ));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 6) & 0x01));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 5) & 0x01));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 4) & 0x01));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 3) & 0x01));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 2) & 0x01));
               *cur++ = cast(ubyte)(scale * ((*in_ >> 1) & 0x01));
               *cur++ = cast(ubyte)(scale * ((*in_ ) & 0x01));
            }
            if (k > 0) *cur++ = cast(ubyte)(scale * ((*in_ >> 7) ));
            if (k > 1) *cur++ = cast(ubyte)(scale * ((*in_ >> 6) & 0x01));
            if (k > 2) *cur++ = cast(ubyte)(scale * ((*in_ >> 5) & 0x01));
            if (k > 3) *cur++ = cast(ubyte)(scale * ((*in_ >> 4) & 0x01));
            if (k > 4) *cur++ = cast(ubyte)(scale * ((*in_ >> 3) & 0x01));
            if (k > 5) *cur++ = cast(ubyte)(scale * ((*in_ >> 2) & 0x01));
            if (k > 6) *cur++ = cast(ubyte)(scale * ((*in_ >> 1) & 0x01));
         }
         if (img_n != out_n) {
            int q = void;
            // insert alpha = 255
            cur = a.out_ + stride*j;
            if (img_n == 1) {
               for (q=x-1; q >= 0; --q) {
                  cur[q*2+1] = 255;
                  cur[q*2+0] = cur[q];
               }
            } else {
               assert(img_n == 3);
               for (q=x-1; q >= 0; --q) {
                  cur[q*4+3] = 255;
                  cur[q*4+2] = cur[q*3+2];
                  cur[q*4+1] = cur[q*3+1];
                  cur[q*4+0] = cur[q*3+0];
               }
            }
         }
      }
   } else if (depth == 16) {
      // force the image data from big-endian to platform-native.
      // this is done in a separate pass due to the decoding relying
      // on the data being untouched, but could probably be done
      // per-line during decode if care is taken.
      stbi_uc* cur = a.out_;
      stbi__uint16* cur16 = cast(stbi__uint16*)cur;

      for(i=0; i < x*y*out_n; ++i,cur16++,cur+=2) {
         *cur16 = (cur[0] << 8) | cur[1];
      }
   }

   return 1;
}

private int stbi__create_png_image(stbi__png* a, stbi_uc* image_data, stbi__uint32 image_data_len, int out_n, int depth, int color, int interlaced) {
   int bytes = (depth == 16 ? 2 : 1);
   int out_bytes = out_n * bytes;
   stbi_uc* final_ = void;
   int p = void;
   if (!interlaced)
      return stbi__create_png_image_raw(a, image_data, image_data_len, out_n, a.s.img_x, a.s.img_y, depth, color);

   // de-interlacing
   final_ = cast(stbi_uc*) stbi__malloc_mad3(a.s.img_x, a.s.img_y, out_bytes, 0);
   if (!final_) return stbi__err("outofmem");
   for (p=0; p < 7; ++p) {
      int[7] xorig = [ 0,4,0,2,0,1,0 ];
      int[7] yorig = [ 0,0,4,0,2,0,1 ];
      int[7] xspc = [ 8,8,4,4,2,2,1 ];
      int[7] yspc = [ 8,8,8,4,4,2,2 ];
      int i = void, j = void, x = void, y = void;
      // pass1_x[4] = 0, pass1_x[5] = 1, pass1_x[12] = 1
      x = (a.s.img_x - xorig[p] + xspc[p]-1) / xspc[p];
      y = (a.s.img_y - yorig[p] + yspc[p]-1) / yspc[p];
      if (x && y) {
         stbi__uint32 img_len = ((((a.s.img_n * x * depth) + 7) >> 3) + 1) * y;
         if (!stbi__create_png_image_raw(a, image_data, image_data_len, out_n, x, y, depth, color)) {
            free(final_);
            return 0;
         }
         for (j=0; j < y; ++j) {
            for (i=0; i < x; ++i) {
               int out_y = j*yspc[p]+yorig[p];
               int out_x = i*xspc[p]+xorig[p];
               memcpy(final_ + out_y*a.s.img_x*out_bytes + out_x*out_bytes,
                      a.out_ + (j*x+i)*out_bytes, out_bytes);
            }
         }
         free(a.out_);
         image_data += img_len;
         image_data_len -= img_len;
      }
   }
   a.out_ = final_;

   return 1;
}

private int stbi__compute_transparency(stbi__png* z, ref stbi_uc[3] tc, int out_n) {
   stbi__context* s = z.s;
   stbi__uint32 i = void, pixel_count = s.img_x * s.img_y;
   stbi_uc* p = z.out_;

   // compute color-based transparency, assuming we've
   // already got 255 as the alpha value in the output
   assert(out_n == 2 || out_n == 4);

   if (out_n == 2) {
      for (i=0; i < pixel_count; ++i) {
         p[1] = (p[0] == tc[0] ? 0 : 255);
         p += 2;
      }
   } else {
      for (i=0; i < pixel_count; ++i) {
         if (p[0] == tc[0] && p[1] == tc[1] && p[2] == tc[2])
            p[3] = 0;
         p += 4;
      }
   }
   return 1;
}

private int stbi__compute_transparency16(stbi__png* z, ref stbi__uint16[3] tc, int out_n) {
   stbi__context* s = z.s;
   stbi__uint32 i = void, pixel_count = s.img_x * s.img_y;
   stbi__uint16* p = cast(stbi__uint16*) z.out_;

   // compute color-based transparency, assuming we've
   // already got 65535 as the alpha value in the output
   assert(out_n == 2 || out_n == 4);

   if (out_n == 2) {
      for (i = 0; i < pixel_count; ++i) {
         p[1] = (p[0] == tc[0] ? 0 : 65535);
         p += 2;
      }
   } else {
      for (i = 0; i < pixel_count; ++i) {
         if (p[0] == tc[0] && p[1] == tc[1] && p[2] == tc[2])
            p[3] = 0;
         p += 4;
      }
   }
   return 1;
}

private int stbi__expand_png_palette(stbi__png* a, stbi_uc* palette, int len, int pal_img_n) {
   stbi__uint32 i = void, pixel_count = a.s.img_x * a.s.img_y;
   stbi_uc* p = void, temp_out = void, orig = a.out_;

   p = cast(stbi_uc*) stbi__malloc_mad2(pixel_count, pal_img_n, 0);
   if (p == null) return stbi__err("outofmem");

   // between here and free(out) below, exitting would leak
   temp_out = p;

   if (pal_img_n == 3) {
      for (i=0; i < pixel_count; ++i) {
         int n = orig[i]*4;
         p[0] = palette[n ];
         p[1] = palette[n+1];
         p[2] = palette[n+2];
         p += 3;
      }
   } else {
      for (i=0; i < pixel_count; ++i) {
         int n = orig[i]*4;
         p[0] = palette[n ];
         p[1] = palette[n+1];
         p[2] = palette[n+2];
         p[3] = palette[n+3];
         p += 4;
      }
   }
   free(a.out_);
   a.out_ = temp_out;

   cast(void)len.sizeof;

   return 1;
}

private int stbi__unpremultiply_on_load_global = 0;
private int stbi__de_iphone_flag_global = 0;

extern void stbi_set_unpremultiply_on_load(int flag_true_if_should_unpremultiply) {
   stbi__unpremultiply_on_load_global = flag_true_if_should_unpremultiply;
}

extern void stbi_convert_iphone_png_to_rgb(int flag_true_if_should_convert) {
   stbi__de_iphone_flag_global = flag_true_if_should_convert;
}

    struct TH_2 {
static int stbi__unpremultiply_on_load_local, stbi__unpremultiply_on_load_set;
static int stbi__de_iphone_flag_local, stbi__de_iphone_flag_set;
    }

static foreach(mem; __traits(allMembers, TH_2))
{
    mixin("alias ", mem, " = TH_2.", mem, ";");
}


extern void stbi__unpremultiply_on_load_thread(int flag_true_if_should_unpremultiply) {
   stbi__unpremultiply_on_load_local = flag_true_if_should_unpremultiply;
   stbi__unpremultiply_on_load_set = 1;
}

extern void stbi_convert_iphone_png_to_rgb_thread(int flag_true_if_should_convert) {
   stbi__de_iphone_flag_local = flag_true_if_should_convert;
   stbi__de_iphone_flag_set = 1;
}

/*enum stbi__unpremultiply_on_load =  (stbi__unpremultiply_on_load_set           
                                       ? stbi__unpremultiply_on_load_local      
                                       : stbi__unpremultiply_on_load_global);







enum stbi__de_iphone_flag =  (stbi__de_iphone_flag_set                         
                                ? stbi__de_iphone_flag_local                    
                                : stbi__de_iphone_flag_global);
*/






private void stbi__de_iphone(stbi__png* z) {
   stbi__context* s = z.s;
   stbi__uint32 i = void, pixel_count = s.img_x * s.img_y;
   stbi_uc* p = z.out_;

   if (s.img_out_n == 3) { // convert bgr to rgb
      for (i=0; i < pixel_count; ++i) {
         stbi_uc t = p[0];
         p[0] = p[2];
         p[2] = t;
         p += 3;
      }
   } else {
      assert(s.img_out_n == 4);
      if ((stbi__unpremultiply_on_load_set ? stbi__unpremultiply_on_load_local : stbi__unpremultiply_on_load_global)) {
         // convert bgr to rgb and unpremultiply
         for (i=0; i < pixel_count; ++i) {
            stbi_uc a = p[3];
            stbi_uc t = p[0];
            if (a) {
               stbi_uc half = a / 2;
               p[0] = cast(ubyte)((p[2] * 255 + half) / a);
               p[1] = cast(ubyte)((p[1] * 255 + half) / a);
               p[2] = cast(ubyte)(( t * 255 + half) / a);
            } else {
               p[0] = p[2];
               p[2] = t;
            }
            p += 4;
         }
      } else {
         // convert bgr to rgb
         for (i=0; i < pixel_count; ++i) {
            stbi_uc t = p[0];
            p[0] = p[2];
            p[2] = t;
            p += 4;
         }
      }
   }
}

enum string STBI__PNG_TYPE(string a,string b,string c,string d) = `  (((unsigned) (a) << 24) + ((unsigned) (b) << 16) + ((unsigned) (c) << 8) + (unsigned) (d))`;


private int stbi__parse_png_file(stbi__png* z, int scan, int req_comp) {
   stbi_uc[1024] palette = void; stbi_uc pal_img_n = 0;
   stbi_uc has_trans = 0; stbi_uc[3] tc = 0;
   stbi__uint16[3] tc16 = void;
   stbi__uint32 ioff = 0, idata_limit = 0, i = void, pal_len = 0;
   int first = 1, k = void, interlace = 0, color = 0, is_iphone = 0;
   stbi__context* s = z.s;

   z.expanded = null;
   z.idata = null;
   z.out_ = null;

   if (!stbi__check_png_header(s)) return 0;

   if (scan == STBI__SCAN_type) return 1;

   for (;;) {
      stbi__pngchunk c = stbi__get_chunk_header(s);
      switch (c.type) {
         case ((cast(uint) ('C') << 24) + (cast(uint) ('g') << 16) + (cast(uint) ('B') << 8) + cast(uint) ('I')):
            is_iphone = 1;
            stbi__skip(s, c.length);
            break;
         case ((cast(uint) ('I') << 24) + (cast(uint) ('H') << 16) + (cast(uint) ('D') << 8) + cast(uint) ('R')): {
            int comp = void, filter = void;
            if (!first) return stbi__err("multiple IHDR");
            first = 0;
            if (c.length != 13) return stbi__err("bad IHDR len");
            s.img_x = stbi__get32be(s);
            s.img_y = stbi__get32be(s);
            if (s.img_y > (1 << 24)) return stbi__err("too large");
            if (s.img_x > (1 << 24)) return stbi__err("too large");
            z.depth = stbi__get8(s); if (z.depth != 1 && z.depth != 2 && z.depth != 4 && z.depth != 8 && z.depth != 16) return stbi__err("1/2/4/8/16-bit only");
            color = stbi__get8(s); if (color > 6) return stbi__err("bad ctype");
            if (color == 3 && z.depth == 16) return stbi__err("bad ctype");
            if (color == 3) pal_img_n = 3; else if (color & 1) return stbi__err("bad ctype");
            comp = stbi__get8(s); if (comp) return stbi__err("bad comp method");
            filter= stbi__get8(s); if (filter) return stbi__err("bad filter method");
            interlace = stbi__get8(s); if (interlace>1) return stbi__err("bad interlace method");
            if (!s.img_x || !s.img_y) return stbi__err("0-pixel image");
            if (!pal_img_n) {
               s.img_n = (color & 2 ? 3 : 1) + (color & 4 ? 1 : 0);
               if ((1 << 30) / s.img_x / s.img_n < s.img_y) return stbi__err("too large");
               if (scan == STBI__SCAN_header) return 1;
            } else {
               // if paletted, then pal_n is our final components, and
               // img_n is # components to decompress/filter.
               s.img_n = 1;
               if ((1 << 30) / s.img_x / 4 < s.img_y) return stbi__err("too large");
               // if SCAN_header, have to scan to see if we have a tRNS
            }
            break;
         }

         case ((cast(uint) ('P') << 24) + (cast(uint) ('L') << 16) + (cast(uint) ('T') << 8) + cast(uint) ('E')): {
            if (first) return stbi__err("first not IHDR");
            if (c.length > 256*3) return stbi__err("invalid PLTE");
            pal_len = c.length / 3;
            if (pal_len * 3 != c.length) return stbi__err("invalid PLTE");
            for (i=0; i < pal_len; ++i) {
               palette[i*4+0] = stbi__get8(s);
               palette[i*4+1] = stbi__get8(s);
               palette[i*4+2] = stbi__get8(s);
               palette[i*4+3] = 255;
            }
            break;
         }

         case ((cast(uint) ('t') << 24) + (cast(uint) ('R') << 16) + (cast(uint) ('N') << 8) + cast(uint) ('S')): {
            if (first) return stbi__err("first not IHDR");
            if (z.idata) return stbi__err("tRNS after IDAT");
            if (pal_img_n) {
               if (scan == STBI__SCAN_header) { s.img_n = 4; return 1; }
               if (pal_len == 0) return stbi__err("tRNS before PLTE");
               if (c.length > pal_len) return stbi__err("bad tRNS len");
               pal_img_n = 4;
               for (i=0; i < c.length; ++i)
                  palette[i*4+3] = stbi__get8(s);
            } else {
               if (!(s.img_n & 1)) return stbi__err("tRNS with alpha");
               if (c.length != cast(stbi__uint32) s.img_n*2) return stbi__err("bad tRNS len");
               has_trans = 1;
               if (z.depth == 16) {
                  for (k = 0; k < s.img_n; ++k) tc16[k] = cast(stbi__uint16)stbi__get16be(s); // copy the values as-is
               } else {
                  for (k = 0; k < s.img_n; ++k) tc[k] = cast(stbi_uc)((stbi__get16be(s) & 255) * stbi__depth_scale_table[z.depth]); // non 8-bit images will be larger
               }
            }
            break;
         }

         case ((cast(uint) ('I') << 24) + (cast(uint) ('D') << 16) + (cast(uint) ('A') << 8) + cast(uint) ('T')): {
            if (first) return stbi__err("first not IHDR");
            if (pal_img_n && !pal_len) return stbi__err("no PLTE");
            if (scan == STBI__SCAN_header) { s.img_n = pal_img_n; return 1; }
            if (cast(int)(ioff + c.length) < cast(int)ioff) return 0;
            if (ioff + c.length > idata_limit) {
               stbi__uint32 idata_limit_old = idata_limit;
               stbi_uc* p = void;
               if (idata_limit == 0) idata_limit = c.length > 4096 ? c.length : 4096;
               while (ioff + c.length > idata_limit)
                  idata_limit *= 2;
               cast(void)idata_limit_old.sizeof;
               p = cast(stbi_uc*) realloc(z.idata,idata_limit); if (p == null) return stbi__err("outofmem");
               z.idata = p;
            }
            if (!stbi__getn(s, z.idata+ioff,c.length)) return stbi__err("outofdata");
            ioff += c.length;
            break;
         }

         case ((cast(uint) ('I') << 24) + (cast(uint) ('E') << 16) + (cast(uint) ('N') << 8) + cast(uint) ('D')): {
            stbi__uint32 raw_len = void, bpl = void;
            if (first) return stbi__err("first not IHDR");
            if (scan != STBI__SCAN_load) return 1;
            if (z.idata == null) return stbi__err("no IDAT");
            // initial guess for decoded data size to avoid unnecessary reallocs
            bpl = (s.img_x * z.depth + 7) / 8; // bytes per line, per component
            raw_len = bpl * s.img_y * s.img_n /* pixels */ + s.img_y /* filter mode per row */;
            z.expanded = cast(stbi_uc*) stbi_zlib_decode_malloc_guesssize_headerflag(cast(char*) z.idata, ioff, raw_len, cast(int*) &raw_len, !is_iphone);
            if (z.expanded == null) return 0; // zlib should set error
            free(z.idata); z.idata = null;
            if ((req_comp == s.img_n+1 && req_comp != 3 && !pal_img_n) || has_trans)
               s.img_out_n = s.img_n+1;
            else
               s.img_out_n = s.img_n;
            if (!stbi__create_png_image(z, z.expanded, raw_len, s.img_out_n, z.depth, color, interlace)) return 0;
            if (has_trans) {
               if (z.depth == 16) {
                  if (!stbi__compute_transparency16(z, tc16, s.img_out_n)) return 0;
               } else {
                  if (!stbi__compute_transparency(z, tc, s.img_out_n)) return 0;
               }
            }
            if (is_iphone && (stbi__de_iphone_flag_set ? stbi__de_iphone_flag_local : stbi__de_iphone_flag_global) && s.img_out_n > 2)
               stbi__de_iphone(z);
            if (pal_img_n) {
               // pal_img_n == 3 or 4
               s.img_n = pal_img_n; // record the actual colors we had
               s.img_out_n = pal_img_n;
               if (req_comp >= 3) s.img_out_n = req_comp;
               if (!stbi__expand_png_palette(z, palette.ptr, pal_len, s.img_out_n))
                  return 0;
            } else if (has_trans) {
               // non-paletted image with tRNS -> source image has (constant) alpha
               ++s.img_n;
            }
            free(z.expanded); z.expanded = null;
            // end of PNG chunk, read and skip CRC
            stbi__get32be(s);
            return 1;
         }

         default:
            // if critical, fail
            if (first) return stbi__err("first not IHDR");
            if ((c.type & (1 << 29)) == 0) {
               version (STBI_NO_FAILURE_STRINGS) {} else {

               // not threadsafe
               static char[25] invalid_chunk = "XXXX PNG chunk not known\0";
               invalid_chunk[0] = (cast(stbi_uc) ((c.type >> 24) & 255));
               invalid_chunk[1] = (cast(stbi_uc) ((c.type >> 16) & 255));
               invalid_chunk[2] = (cast(stbi_uc) ((c.type >> 8) & 255));
               invalid_chunk[3] = (cast(stbi_uc) ((c.type >> 0) & 255));
               }

               return stbi__err(invalid_chunk.ptr);
            }
            stbi__skip(s, c.length);
            break;
      }
      // end of PNG chunk, read and skip CRC
      stbi__get32be(s);
   }
}

private void* stbi__do_png(stbi__png* p, int* x, int* y, int* n, int req_comp, stbi__result_info* ri) {
   void* result = null;
   if (req_comp < 0 || req_comp > 4) return (cast(ubyte*)cast(size_t) (stbi__err("bad req_comp")?null:null));
   if (stbi__parse_png_file(p, STBI__SCAN_load, req_comp)) {
      if (p.depth <= 8)
         ri.bits_per_channel = 8;
      else if (p.depth == 16)
         ri.bits_per_channel = 16;
      else
         return (cast(ubyte*)cast(size_t) (stbi__err("bad bits_per_channel")?null:null));
      result = p.out_;
      p.out_ = null;
      if (req_comp && req_comp != p.s.img_out_n) {
         if (ri.bits_per_channel == 8)
            result = stbi__convert_format(cast(ubyte*) result, p.s.img_out_n, req_comp, p.s.img_x, p.s.img_y);
         else
            result = stbi__convert_format16(cast(stbi__uint16*) result, p.s.img_out_n, req_comp, p.s.img_x, p.s.img_y);
         p.s.img_out_n = req_comp;
         if (result == null) return result;
      }
      *x = p.s.img_x;
      *y = p.s.img_y;
      if (n) *n = p.s.img_n;
   }
   free(p.out_); p.out_ = null;
   free(p.expanded); p.expanded = null;
   free(p.idata); p.idata = null;

   return result;
}

private void* stbi__png_load(stbi__context* s, int* x, int* y, int* comp, int req_comp, stbi__result_info* ri) {
   stbi__png p = void;
   p.s = s;
   return stbi__do_png(&p, x,y,comp,req_comp, ri);
}

private int stbi__png_test(stbi__context* s) {
   int r = void;
   r = stbi__check_png_header(s);
   stbi__rewind(s);
   return r;
}

private int stbi__png_info_raw(stbi__png* p, int* x, int* y, int* comp) {
   if (!stbi__parse_png_file(p, STBI__SCAN_header, 0)) {
      stbi__rewind( p.s );
      return 0;
   }
   if (x) *x = p.s.img_x;
   if (y) *y = p.s.img_y;
   if (comp) *comp = p.s.img_n;
   return 1;
}

private int stbi__png_info(stbi__context* s, int* x, int* y, int* comp) {
   stbi__png p = void;
   p.s = s;
   return stbi__png_info_raw(&p, x, y, comp);
}

private int stbi__png_is16(stbi__context* s) {
   stbi__png p = void;
   p.s = s;
   if (!stbi__png_info_raw(&p, null, null, null))
    return 0;
   if (p.depth != 16) {
      stbi__rewind(p.s);
      return 0;
   }
   return 1;
}
}


// Microsoft/Windows BMP image

version (STBI_NO_BMP) {} else {
}

// Targa Truevision - TGA
// by Jonathan Dummer
version (STBI_NO_TGA) {} else {
}

// *************************************************************************************************
// Photoshop PSD loader -- PD by Thatcher Ulrich, integration by Nicolas Schulz, tweaked by STB

version (STBI_NO_PSD) {} else {
}

// *************************************************************************************************
// Softimage PIC loader
// by Tom Seddon
//
// See http://softimage.wiki.softimage.com/index.php/INFO:_PIC_file_format
// See http://ozviz.wasp.uwa.edu.au/~pbourke/dataformats/softimagepic/

version (STBI_NO_PIC) {} else {
}

// *************************************************************************************************
// GIF loader -- public domain by Jean-Marc Lienher -- simplified/shrunk by stb

version (STBI_NO_GIF) {} else {

struct _Stbi__gif_lzw {
   stbi__int16 prefix;
   stbi_uc first;
   stbi_uc suffix;
}alias stbi__gif_lzw = _Stbi__gif_lzw;

struct _Stbi__gif {
   int w, h;
   stbi_uc* out_; // output buffer (always 4 components)
   stbi_uc* background; // The current "background" as far as a gif is concerned
   stbi_uc* history;
   int flags, bgindex, ratio, transparent, eflags;
   stbi_uc[4][256] pal;
   stbi_uc[4][256] lpal;
   stbi__gif_lzw[8192] codes;
   stbi_uc* color_table;
   int parse, step;
   int lflags;
   int start_x, start_y;
   int max_x, max_y;
   int cur_x, cur_y;
   int line_size;
   int delay;
}alias stbi__gif = _Stbi__gif;

private int stbi__gif_test_raw(stbi__context* s) {
   int sz = void;
   if (stbi__get8(s) != 'G' || stbi__get8(s) != 'I' || stbi__get8(s) != 'F' || stbi__get8(s) != '8') return 0;
   sz = stbi__get8(s);
   if (sz != '9' && sz != '7') return 0;
   if (stbi__get8(s) != 'a') return 0;
   return 1;
}

private int stbi__gif_test(stbi__context* s) {
   int r = stbi__gif_test_raw(s);
   stbi__rewind(s);
   return r;
}

private void stbi__gif_parse_colortable(stbi__context* s, stbi_uc[4][256] pal, int num_entries, int transp) {
   int i = void;
   for (i=0; i < num_entries; ++i) {
      pal[i][2] = stbi__get8(s);
      pal[i][1] = stbi__get8(s);
      pal[i][0] = stbi__get8(s);
      pal[i][3] = transp == i ? 0 : 255;
   }
}

private int stbi__gif_header(stbi__context* s, stbi__gif* g, int* comp, int is_info) {
   stbi_uc version_ = void;
   if (stbi__get8(s) != 'G' || stbi__get8(s) != 'I' || stbi__get8(s) != 'F' || stbi__get8(s) != '8')
      return stbi__err("not GIF");

   version_ = stbi__get8(s);
   if (version_ != '7' && version_ != '9') return stbi__err("not GIF");
   if (stbi__get8(s) != 'a') return stbi__err("not GIF");

   stbi__g_failure_reason = "";
   g.w = stbi__get16le(s);
   g.h = stbi__get16le(s);
   g.flags = stbi__get8(s);
   g.bgindex = stbi__get8(s);
   g.ratio = stbi__get8(s);
   g.transparent = -1;

   if (g.w > (1 << 24)) return stbi__err("too large");
   if (g.h > (1 << 24)) return stbi__err("too large");

   if (comp != null) *comp = 4; // can't actually tell whether it's 3 or 4 until we parse the comments

   if (is_info) return 1;

   if (g.flags & 0x80)
      stbi__gif_parse_colortable(s,g.pal, 2 << (g.flags & 7), -1);

   return 1;
}

private int stbi__gif_info_raw(stbi__context* s, int* x, int* y, int* comp) {
   stbi__gif* g = cast(stbi__gif*) stbi__malloc(stbi__gif.sizeof);
   if (!g) return stbi__err("outofmem");
   if (!stbi__gif_header(s, g, comp, 1)) {
      free(g);
      stbi__rewind( s );
      return 0;
   }
   if (x) *x = g.w;
   if (y) *y = g.h;
   free(g);
   return 1;
}

private void stbi__out_gif_code(stbi__gif* g, stbi__uint16 code) {
   stbi_uc* p = void, c = void;
   int idx = void;

   // recurse to decode the prefixes, since the linked-list is backwards,
   // and working backwards through an interleaved image would be nasty
   if (g.codes[code].prefix >= 0)
      stbi__out_gif_code(g, g.codes[code].prefix);

   if (g.cur_y >= g.max_y) return;

   idx = g.cur_x + g.cur_y;
   p = &g.out_[idx];
   g.history[idx / 4] = 1;

   c = &g.color_table[g.codes[code].suffix * 4];
   if (c[3] > 128) { // don't render transparent pixels;
      p[0] = c[2];
      p[1] = c[1];
      p[2] = c[0];
      p[3] = c[3];
   }
   g.cur_x += 4;

   if (g.cur_x >= g.max_x) {
      g.cur_x = g.start_x;
      g.cur_y += g.step;

      while (g.cur_y >= g.max_y && g.parse > 0) {
         g.step = (1 << g.parse) * g.line_size;
         g.cur_y = g.start_y + (g.step >> 1);
         --g.parse;
      }
   }
}

private stbi_uc* stbi__process_gif_raster(stbi__context* s, stbi__gif* g) {
   stbi_uc lzw_cs = void;
   stbi__int32 len = void, init_code = void;
   stbi__uint32 first = void;
   stbi__int32 codesize = void, codemask = void, avail = void, oldcode = void, bits = void, valid_bits = void, clear = void;
   stbi__gif_lzw* p = void;

   lzw_cs = stbi__get8(s);
   if (lzw_cs > 12) return null;
   clear = 1 << lzw_cs;
   first = 1;
   codesize = lzw_cs + 1;
   codemask = (1 << codesize) - 1;
   bits = 0;
   valid_bits = 0;
   for (init_code = 0; init_code < clear; init_code++) {
      g.codes[init_code].prefix = -1;
      g.codes[init_code].first = cast(stbi_uc) init_code;
      g.codes[init_code].suffix = cast(stbi_uc) init_code;
   }

   // support no starting clear code
   avail = clear+2;
   oldcode = -1;

   len = 0;
   for(;;) {
      if (valid_bits < codesize) {
         if (len == 0) {
            len = stbi__get8(s); // start new block
            if (len == 0)
               return g.out_;
         }
         --len;
         bits |= cast(stbi__int32) stbi__get8(s) << valid_bits;
         valid_bits += 8;
      } else {
         stbi__int32 code = bits & codemask;
         bits >>= codesize;
         valid_bits -= codesize;
         // @OPTIMIZE: is there some way we can accelerate the non-clear path?
         if (code == clear) { // clear code
            codesize = lzw_cs + 1;
            codemask = (1 << codesize) - 1;
            avail = clear + 2;
            oldcode = -1;
            first = 0;
         } else if (code == clear + 1) { // end of stream code
            stbi__skip(s, len);
            while ((len = stbi__get8(s)) > 0)
               stbi__skip(s,len);
            return g.out_;
         } else if (code <= avail) {
            if (first) {
               return (cast(ubyte*)cast(size_t) (stbi__err("no clear code")?null:null));
            }

            if (oldcode >= 0) {
               p = &g.codes[avail++];
               if (avail > 8192) {
                  return (cast(ubyte*)cast(size_t) (stbi__err("too many codes")?null:null));
               }

               p.prefix = cast(stbi__int16) oldcode;
               p.first = g.codes[oldcode].first;
               p.suffix = (code == avail) ? p.first : g.codes[code].first;
            } else if (code == avail)
               return (cast(ubyte*)cast(size_t) (stbi__err("illegal code in raster")?null:null));

            stbi__out_gif_code(g, cast(stbi__uint16) code);

            if ((avail & codemask) == 0 && avail <= 0x0FFF) {
               codesize++;
               codemask = (1 << codesize) - 1;
            }

            oldcode = code;
         } else {
            return (cast(ubyte*)cast(size_t) (stbi__err("illegal code in raster")?null:null));
         }
      }
   }
}

// this function is designed to support animated gifs, although stb_image doesn't support it
// two back is the image from two frames ago, used for a very specific disposal format
private stbi_uc* stbi__gif_load_next(stbi__context* s, stbi__gif* g, int* comp, int req_comp, stbi_uc* two_back) {
   int dispose = void;
   int first_frame = void;
   int pi = void;
   int pcount = void;
   cast(void)req_comp.sizeof;

   // on first frame, any non-written pixels get the background colour (non-transparent)
   first_frame = 0;
   if (g.out_ == null) {
      if (!stbi__gif_header(s, g, comp,0)) return null; // stbi__g_failure_reason set by stbi__gif_header
      if (!stbi__mad3sizes_valid(4, g.w, g.h, 0))
         return (cast(ubyte*)cast(size_t) (stbi__err("too large")?null:null));
      pcount = g.w * g.h;
      g.out_ = cast(stbi_uc*) stbi__malloc(4 * pcount);
      g.background = cast(stbi_uc*) stbi__malloc(4 * pcount);
      g.history = cast(stbi_uc*) stbi__malloc(pcount);
      if (!g.out_ || !g.background || !g.history)
         return (cast(ubyte*)cast(size_t) (stbi__err("outofmem")?null:null));

      // image is treated as "transparent" at the start - ie, nothing overwrites the current background;
      // background colour is only used for pixels that are not rendered first frame, after that "background"
      // color refers to the color that was there the previous frame.
      memset(g.out_, 0x00, 4 * pcount);
      memset(g.background, 0x00, 4 * pcount); // state of the background (starts transparent)
      memset(g.history, 0x00, pcount); // pixels that were affected previous frame
      first_frame = 1;
   } else {
      // second frame - how do we dispose of the previous one?
      dispose = (g.eflags & 0x1C) >> 2;
      pcount = g.w * g.h;

      if ((dispose == 3) && (two_back == null)) {
         dispose = 2; // if I don't have an image to revert back to, default to the old background
      }

      if (dispose == 3) { // use previous graphic
         for (pi = 0; pi < pcount; ++pi) {
            if (g.history[pi]) {
               memcpy( &g.out_[pi * 4], &two_back[pi * 4], 4 );
            }
         }
      } else if (dispose == 2) {
         // restore what was changed last frame to background before that frame;
         for (pi = 0; pi < pcount; ++pi) {
            if (g.history[pi]) {
               memcpy( &g.out_[pi * 4], &g.background[pi * 4], 4 );
            }
         }
      } else {
         // This is a non-disposal case eithe way, so just
         // leave the pixels as is, and they will become the new background
         // 1: do not dispose
         // 0:  not specified.
      }

      // background is what out is after the undoing of the previou frame;
      memcpy( g.background, g.out_, 4 * g.w * g.h );
   }

   // clear my history;
   memset( g.history, 0x00, g.w * g.h ); // pixels that were affected previous frame

   for (;;) {
      int tag = stbi__get8(s);
      switch (tag) {
         case 0x2C: /* Image Descriptor */
         {
            stbi__int32 x = void, y = void, w = void, h = void;
            stbi_uc* o = void;

            x = stbi__get16le(s);
            y = stbi__get16le(s);
            w = stbi__get16le(s);
            h = stbi__get16le(s);
            if (((x + w) > (g.w)) || ((y + h) > (g.h)))
               return (cast(ubyte*)cast(size_t) (stbi__err("bad Image Descriptor")?null:null));

            g.line_size = g.w * 4;
            g.start_x = x * 4;
            g.start_y = y * g.line_size;
            g.max_x = g.start_x + w * 4;
            g.max_y = g.start_y + h * g.line_size;
            g.cur_x = g.start_x;
            g.cur_y = g.start_y;

            // if the width of the specified rectangle is 0, that means
            // we may not see *any* pixels or the image is malformed;
            // to make sure this is caught, move the current y down to
            // max_y (which is what out_gif_code checks).
            if (w == 0)
               g.cur_y = g.max_y;

            g.lflags = stbi__get8(s);

            if (g.lflags & 0x40) {
               g.step = 8 * g.line_size; // first interlaced spacing
               g.parse = 3;
            } else {
               g.step = g.line_size;
               g.parse = 0;
            }

            if (g.lflags & 0x80) {
               stbi__gif_parse_colortable(s,g.lpal, 2 << (g.lflags & 7), g.eflags & 0x01 ? g.transparent : -1);
               g.color_table = cast(stbi_uc*) g.lpal;
            } else if (g.flags & 0x80) {
               g.color_table = cast(stbi_uc*) g.pal;
            } else
               return (cast(ubyte*)cast(size_t) (stbi__err("missing color table")?null:null));

            o = stbi__process_gif_raster(s, g);
            if (!o) return null;

            // if this was the first frame,
            pcount = g.w * g.h;
            if (first_frame && (g.bgindex > 0)) {
               // if first frame, any pixel not drawn to gets the background color
               for (pi = 0; pi < pcount; ++pi) {
                  if (g.history[pi] == 0) {
                     g.pal[g.bgindex][3] = 255; // just in case it was made transparent, undo that; It will be reset next frame if need be;
                     memcpy( &g.out_[pi * 4], &g.pal[g.bgindex], 4 );
                  }
               }
            }

            return o;
         }

         case 0x21: // Comment Extension.
         {
            int len = void;
            int ext = stbi__get8(s);
            if (ext == 0xF9) { // Graphic Control Extension.
               len = stbi__get8(s);
               if (len == 4) {
                  g.eflags = stbi__get8(s);
                  g.delay = 10 * stbi__get16le(s); // delay - 1/100th of a second, saving as 1/1000ths.

                  // unset old transparent
                  if (g.transparent >= 0) {
                     g.pal[g.transparent][3] = 255;
                  }
                  if (g.eflags & 0x01) {
                     g.transparent = stbi__get8(s);
                     if (g.transparent >= 0) {
                        g.pal[g.transparent][3] = 0;
                     }
                  } else {
                     // don't need transparent
                     stbi__skip(s, 1);
                     g.transparent = -1;
                  }
               } else {
                  stbi__skip(s, len);
                  break;
               }
            }
            while ((len = stbi__get8(s)) != 0) {
               stbi__skip(s, len);
            }
            break;
         }

         case 0x3B: // gif stream termination code
            return cast(stbi_uc*) s; // using '1' causes warning on some compilers

         default:
            return (cast(ubyte*)cast(size_t) (stbi__err("unknown code")?null:null));
      }
   }
}

private void* stbi__load_gif_main_outofmem(stbi__gif* g, stbi_uc* out_, int** delays) {
   free(g.out_);
   free(g.history);
   free(g.background);

   if (out_) free(out_);
   if (delays && *delays) free(*delays);
   return (cast(ubyte*)cast(size_t) (stbi__err("outofmem")?null:null));
}

private void* stbi__load_gif_main(stbi__context* s, int** delays, int* x, int* y, int* z, int* comp, int req_comp) {
   if (stbi__gif_test(s)) {
      int layers = 0;
      stbi_uc* u = null;
      stbi_uc* out_ = null;
      stbi_uc* two_back = null;
      stbi__gif g = void;
      int stride = void;
      int out_size = 0;
      int delays_size = 0;

      cast(void)out_size.sizeof;
      cast(void)delays_size.sizeof;

      memset(&g, 0, g.sizeof);
      if (delays) {
         *delays = null;
      }

      do {
         u = stbi__gif_load_next(s, &g, comp, req_comp, two_back);
         if (u == cast(stbi_uc*) s) u = null; // end of animated gif marker

         if (u) {
            *x = g.w;
            *y = g.h;
            ++layers;
            stride = g.w * g.h * 4;

            if (out_) {
               void* tmp = cast(stbi_uc*) realloc(out_,layers * stride);
               if (!tmp)
                  return stbi__load_gif_main_outofmem(&g, out_, delays);
               else {
                   out_ = cast(stbi_uc*) tmp;
                   out_size = layers * stride;
               }

               if (delays) {
                  int* new_delays = cast(int*) realloc(*delays,int.sizeof * layers);
                  if (!new_delays)
                     return stbi__load_gif_main_outofmem(&g, out_, delays);
                  *delays = new_delays;
                  delays_size = layers * int(int.sizeof);
               }
            } else {
               out_ = cast(stbi_uc*)stbi__malloc( layers * stride );
               if (!out_)
                  return stbi__load_gif_main_outofmem(&g, out_, delays);
               out_size = layers * stride;
               if (delays) {
                  *delays = cast(int*) stbi__malloc( layers * int.sizeof );
                  if (!*delays)
                     return stbi__load_gif_main_outofmem(&g, out_, delays);
                  delays_size = layers * int(int.sizeof);
               }
            }
            memcpy( out_ + ((layers - 1) * stride), u, stride );
            if (layers >= 2) {
               two_back = out_ - 2 * stride;
            }

            if (delays) {
               (*delays)[layers - 1U] = g.delay;
            }
         }
      } while (u != null);

      // free temp buffer;
      free(g.out_);
      free(g.history);
      free(g.background);

      // do the final conversion after loading everything;
      if (req_comp && req_comp != 4)
         out_ = stbi__convert_format(out_, 4, req_comp, layers * g.w, g.h);

      *z = layers;
      return out_;
   } else {
      return (cast(ubyte*)cast(size_t) (stbi__err("not GIF")?null:null));
   }
}

private void* stbi__gif_load(stbi__context* s, int* x, int* y, int* comp, int req_comp, stbi__result_info* ri) {
   stbi_uc* u = null;
   stbi__gif g = void;
   memset(&g, 0, g.sizeof);
   cast(void)ri.sizeof;

   u = stbi__gif_load_next(s, &g, comp, req_comp, null);
   if (u == cast(stbi_uc*) s) u = null; // end of animated gif marker
   if (u) {
      *x = g.w;
      *y = g.h;

      // moved conversion to after successful load so that the same
      // can be done for multiple frames.
      if (req_comp && req_comp != 4)
         u = stbi__convert_format(u, 4, req_comp, g.w, g.h);
   } else if (g.out_) {
      // if there was an error and we allocated an image buffer, free it!
      free(g.out_);
   }

   // free buffers needed for multiple frame loading;
   free(g.history);
   free(g.background);

   return u;
}

private int stbi__gif_info(stbi__context* s, int* x, int* y, int* comp) {
   return stbi__gif_info_raw(s,x,y,comp);
}
}


// *************************************************************************************************
// Radiance RGBE HDR loader
// originally by Nicolas Schulz
version (STBI_NO_HDR) {} else {

private int stbi__hdr_test_core(stbi__context* s, const(char)* signature) {
   int i = void;
   for (i=0; signature[i]; ++i)
      if (stbi__get8(s) != signature[i])
          return 0;
   stbi__rewind(s);
   return 1;
}

private int stbi__hdr_test(stbi__context* s) {
   int r = stbi__hdr_test_core(s, "#?RADIANCE\n");
   stbi__rewind(s);
   if(!r) {
       r = stbi__hdr_test_core(s, "#?RGBE\n");
       stbi__rewind(s);
   }
   return r;
}

enum STBI__HDR_BUFLEN =  1024;

private char* stbi__hdr_gettoken(stbi__context* z, char* buffer) {
   int len = 0;
   char c = '\0';

   c = cast(char) stbi__get8(z);

   while (!stbi__at_eof(z) && c != '\n') {
      buffer[len++] = c;
      if (len == 1024 -1) {
         // flush to end of line
         while (!stbi__at_eof(z) && stbi__get8(z) != '\n')
            {}
         break;
      }
      c = cast(char) stbi__get8(z);
   }

   buffer[len] = 0;
   return buffer;
}

private void stbi__hdr_convert(float* output, stbi_uc* input, int req_comp) {
   if ( input[3] != 0 ) {
      float f1 = void;
      // Exponent
      f1 = cast(float) ldexp(1.0f, input[3] - cast(int)(128 + 8));
      if (req_comp <= 2)
         output[0] = (input[0] + input[1] + input[2]) * f1 / 3;
      else {
         output[0] = input[0] * f1;
         output[1] = input[1] * f1;
         output[2] = input[2] * f1;
      }
      if (req_comp == 2) output[1] = 1;
      if (req_comp == 4) output[3] = 1;
   } else {
      switch (req_comp) {
         case 4: output[3] = 1; goto case; /* fallthrough */
         case 3: output[0] = output[1] = output[2] = 0;
                 break;
         case 2: output[1] = 1; goto case; /* fallthrough */
         case 1: output[0] = 0;
                 break;
      default: break;}
   }
}

private float* stbi__hdr_load(stbi__context* s, int* x, int* y, int* comp, int req_comp, stbi__result_info* ri) {
   char[1024] buffer = void;
   char* token = void;
   int valid = 0;
   int width = void, height = void;
   stbi_uc* scanline = void;
   float* hdr_data = void;
   int len = void;
   ubyte count = void, value = void;
   int i = void, j = void, k = void, c1 = void, c2 = void, z = void;
   const(char)* headerToken = void;
   cast(void)ri.sizeof;

   // Check identifier
   headerToken = stbi__hdr_gettoken(s,buffer.ptr);
   if (strcmp(headerToken, "#?RADIANCE") != 0 && strcmp(headerToken, "#?RGBE") != 0)
      return (cast(float*)cast(size_t) (stbi__err("not HDR")?null:null));

   // Parse header
   for(;;) {
      token = stbi__hdr_gettoken(s,buffer.ptr);
      if (token[0] == 0) break;
      if (strcmp(token, "FORMAT=32-bit_rle_rgbe") == 0) valid = 1;
   }

   if (!valid) return (cast(float*)cast(size_t) (stbi__err("unsupported format")?null:null));

   // Parse width and height
   // can't use sscanf() if we're not using stdio!
   token = stbi__hdr_gettoken(s,buffer.ptr);
   if (strncmp(token, "-Y ", 3)) return (cast(float*)cast(size_t) (stbi__err("unsupported data layout")?null:null));
   token += 3;
   height = cast(int) strtol(token, &token, 10);
   while (*token == ' ') ++token;
   if (strncmp(token, "+X ", 3)) return (cast(float*)cast(size_t) (stbi__err("unsupported data layout")?null:null));
   token += 3;
   width = cast(int) strtol(token, null, 10);

   if (height > (1 << 24)) return (cast(float*)cast(size_t) (stbi__err("too large")?null:null));
   if (width > (1 << 24)) return (cast(float*)cast(size_t) (stbi__err("too large")?null:null));

   *x = width;
   *y = height;

   if (comp) *comp = 3;
   if (req_comp == 0) req_comp = 3;

   if (!stbi__mad4sizes_valid(width, height, req_comp, float.sizeof, 0))
      return (cast(float*)cast(size_t) (stbi__err("too large")?null:null));

   // Read data
   hdr_data = cast(float*) stbi__malloc_mad4(width, height, req_comp, float.sizeof, 0);
   if (!hdr_data)
      return (cast(float*)cast(size_t) (stbi__err("outofmem")?null:null));

   // Load image data
   // image data is stored as some number of sca
   if ( width < 8 || width >= 32768) {
      // Read flat data
      for (j=0; j < height; ++j) {
         for (i=0; i < width; ++i) {
           main_decode_loop:
            stbi_uc[4] rgbe = void;
            stbi__getn(s, rgbe.ptr, 4);
            stbi__hdr_convert(hdr_data + j * width * req_comp + i * req_comp, rgbe.ptr, req_comp);
         }
      }
   } else {
      // Read RLE-encoded data
      scanline = null;

      for (j = 0; j < height; ++j) {
         c1 = stbi__get8(s);
         c2 = stbi__get8(s);
         len = stbi__get8(s);
         if (c1 != 2 || c2 != 2 || (len & 0x80)) {
            // not run-length encoded, so we have to actually use THIS data as a decoded
            // pixel (note this can't be a valid pixel--one of RGB must be >= 128)
            stbi_uc[4] rgbe = void;
            rgbe[0] = cast(stbi_uc) c1;
            rgbe[1] = cast(stbi_uc) c2;
            rgbe[2] = cast(stbi_uc) len;
            rgbe[3] = cast(stbi_uc) stbi__get8(s);
            stbi__hdr_convert(hdr_data, rgbe.ptr, req_comp);
            i = 1;
            j = 0;
            free(scanline);
            goto main_decode_loop; // yes, this makes no sense
         }
         len <<= 8;
         len |= stbi__get8(s);
         if (len != width) { free(hdr_data); free(scanline); return (cast(float*)cast(size_t) (stbi__err("invalid decoded scanline length")?null:null)); }
         if (scanline == null) {
            scanline = cast(stbi_uc*) stbi__malloc_mad2(width, 4, 0);
            if (!scanline) {
               free(hdr_data);
               return (cast(float*)cast(size_t) (stbi__err("outofmem")?null:null));
            }
         }

         for (k = 0; k < 4; ++k) {
            int nleft = void;
            i = 0;
            while ((nleft = width - i) > 0) {
               count = stbi__get8(s);
               if (count > 128) {
                  // Run
                  value = stbi__get8(s);
                  count -= 128;
                  if (count > nleft) { free(hdr_data); free(scanline); return (cast(float*)cast(size_t) (stbi__err("corrupt")?null:null)); }
                  for (z = 0; z < count; ++z)
                     scanline[i++ * 4 + k] = value;
               } else {
                  // Dump
                  if (count > nleft) { free(hdr_data); free(scanline); return (cast(float*)cast(size_t) (stbi__err("corrupt")?null:null)); }
                  for (z = 0; z < count; ++z)
                     scanline[i++ * 4 + k] = stbi__get8(s);
               }
            }
         }
         for (i=0; i < width; ++i)
            stbi__hdr_convert(hdr_data+(j*width + i)*req_comp, scanline + i*4, req_comp);
      }
      if (scanline)
         free(scanline);
   }

   return hdr_data;
}

private int stbi__hdr_info(stbi__context* s, int* x, int* y, int* comp) {
   char[1024] buffer = void;
   char* token = void;
   int valid = 0;
   int dummy = void;

   if (!x) x = &dummy;
   if (!y) y = &dummy;
   if (!comp) comp = &dummy;

   if (stbi__hdr_test(s) == 0) {
       stbi__rewind( s );
       return 0;
   }

   for(;;) {
      token = stbi__hdr_gettoken(s,buffer.ptr);
      if (token[0] == 0) break;
      if (strcmp(token, "FORMAT=32-bit_rle_rgbe") == 0) valid = 1;
   }

   if (!valid) {
       stbi__rewind( s );
       return 0;
   }
   token = stbi__hdr_gettoken(s,buffer.ptr);
   if (strncmp(token, "-Y ", 3)) {
       stbi__rewind( s );
       return 0;
   }
   token += 3;
   *y = cast(int) strtol(token, &token, 10);
   while (*token == ' ') ++token;
   if (strncmp(token, "+X ", 3)) {
       stbi__rewind( s );
       return 0;
   }
   token += 3;
   *x = cast(int) strtol(token, null, 10);
   *comp = 3;
   return 1;
}
} // STBI_NO_HDR


version (STBI_NO_BMP) {} else {
}

version (STBI_NO_PSD) {} else {
}

version (STBI_NO_PIC) {} else {
}

// *************************************************************************************************
// Portable Gray Map and Portable Pixel Map loader
// by Ken Miller
//
// PGM: http://netpbm.sourceforge.net/doc/pgm.html
// PPM: http://netpbm.sourceforge.net/doc/ppm.html
//
// Known limitations:
//    Does not support comments in the header section
//    Does not support ASCII image data (formats P2 and P3)

version (STBI_NO_PNM) {} else {
}

private int stbi__info_main(stbi__context* s, int* x, int* y, int* comp) {
   version (STBI_NO_JPEG) {} else {





   }

   version (STBI_NO_PNG) {} else {

   if (stbi__png_info(s, x, y, comp)) return 1;
   }


   version (STBI_NO_GIF) {} else {

   if (stbi__gif_info(s, x, y, comp)) return 1;
   }


   version (STBI_NO_BMP) {} else {





   }

   version (STBI_NO_PSD) {} else {





   }

   version (STBI_NO_PIC) {} else {





   }

   version (STBI_NO_PNM) {} else {





   }

   version (STBI_NO_HDR) {} else {

   if (stbi__hdr_info(s, x, y, comp)) return 1;
   }


   // test tga last because it's a crappy test!
   version (STBI_NO_TGA) {} else {






   }
   return stbi__err("unknown image type");
}

private int stbi__is_16_main(stbi__context* s) {
   version (STBI_NO_PNG) {} else {

   if (stbi__png_is16(s)) return 1;
   }


   version (STBI_NO_PSD) {} else {





   }

   version (STBI_NO_PNM) {} else {





   }
   return 0;
}

version (STBI_NO_STDIO) {} else {

extern int stbi_info(const(char)* filename, int* x, int* y, int* comp) {
    FILE* f = stbi__fopen(filename, "rb");
    int result = void;
    if (!f) return stbi__err("can't fopen");
    result = stbi_info_from_file(f, x, y, comp);
    fclose(f);
    return result;
}

extern int stbi_info_from_file(FILE* f, int* x, int* y, int* comp) {
   int r = void;
   stbi__context s = void;
   c_long pos = ftell(f);
   stbi__start_file(&s, f);
   r = stbi__info_main(&s,x,y,comp);
   fseek(f,pos,SEEK_SET);
   return r;
}

extern int stbi_is_16_bit(const(char)* filename) {
    FILE* f = stbi__fopen(filename, "rb");
    int result = void;
    if (!f) return stbi__err("can't fopen");
    result = stbi_is_16_bit_from_file(f);
    fclose(f);
    return result;
}

extern int stbi_is_16_bit_from_file(FILE* f) {
   int r = void;
   stbi__context s = void;
   c_long pos = ftell(f);
   stbi__start_file(&s, f);
   r = stbi__is_16_main(&s);
   fseek(f,pos,SEEK_SET);
   return r;
}
} // !STBI_NO_STDIO


extern int stbi_info_from_memory(const(stbi_uc)* buffer, int len, int* x, int* y, int* comp) {
   stbi__context s = void;
   stbi__start_mem(&s,buffer,len);
   return stbi__info_main(&s,x,y,comp);
}

extern int stbi_info_from_callbacks(const(stbi_io_callbacks)* c, void* user, int* x, int* y, int* comp) {
   stbi__context s = void;
   stbi__start_callbacks(&s, cast(stbi_io_callbacks*) c, user);
   return stbi__info_main(&s,x,y,comp);
}

extern int stbi_is_16_bit_from_memory(const(stbi_uc)* buffer, int len) {
   stbi__context s = void;
   stbi__start_mem(&s,buffer,len);
   return stbi__is_16_main(&s);
}

extern int stbi_is_16_bit_from_callbacks(const(stbi_io_callbacks)* c, void* user) {
   stbi__context s = void;
   stbi__start_callbacks(&s, cast(stbi_io_callbacks*) c, user);
   return stbi__is_16_main(&s);
}

} // STB_IMAGE_IMPLEMENTATION


/*
   revision history:
      2.20  (2019-02-07) support utf8 filenames in Windows; fix warnings and platform ifdefs
      2.19  (2018-02-11) fix warning
      2.18  (2018-01-30) fix warnings
      2.17  (2018-01-29) change sbti__shiftsigned to avoid clang -O2 bug
                         1-bit BMP
                         *_is_16_bit api
                         avoid warnings
      2.16  (2017-07-23) all functions have 16-bit variants;
                         STBI_NO_STDIO works again;
                         compilation fixes;
                         fix rounding in unpremultiply;
                         optimize vertical flip;
                         disable raw_len validation;
                         documentation fixes
      2.15  (2017-03-18) fix png-1,2,4 bug; now all Imagenet JPGs decode;
                         warning fixes; disable run-time SSE detection on gcc;
                         uniform handling of optional "return" values;
                         thread-safe initialization of zlib tables
      2.14  (2017-03-03) remove deprecated STBI_JPEG_OLD; fixes for Imagenet JPGs
      2.13  (2016-11-29) add 16-bit API, only supported for PNG right now
      2.12  (2016-04-02) fix typo in 2.11 PSD fix that caused crashes
      2.11  (2016-04-02) allocate large structures on the stack
                         remove white matting for transparent PSD
                         fix reported channel count for PNG & BMP
                         re-enable SSE2 in non-gcc 64-bit
                         support RGB-formatted JPEG
                         read 16-bit PNGs (only as 8-bit)
      2.10  (2016-01-22) avoid warning introduced in 2.09 by STBI_REALLOC_SIZED
      2.09  (2016-01-16) allow comments in PNM files
                         16-bit-per-pixel TGA (not bit-per-component)
                         info() for TGA could break due to .hdr handling
                         info() for BMP to shares code instead of sloppy parse
                         can use STBI_REALLOC_SIZED if allocator doesn't support realloc
                         code cleanup
      2.08  (2015-09-13) fix to 2.07 cleanup, reading RGB PSD as RGBA
      2.07  (2015-09-13) fix compiler warnings
                         partial animated GIF support
                         limited 16-bpc PSD support
                         #ifdef unused functions
                         bug with < 92 byte PIC,PNM,HDR,TGA
      2.06  (2015-04-19) fix bug where PSD returns wrong '*comp' value
      2.05  (2015-04-19) fix bug in progressive JPEG handling, fix warning
      2.04  (2015-04-15) try to re-enable SIMD on MinGW 64-bit
      2.03  (2015-04-12) extra corruption checking (mmozeiko)
                         stbi_set_flip_vertically_on_load (nguillemot)
                         fix NEON support; fix mingw support
      2.02  (2015-01-19) fix incorrect assert, fix warning
      2.01  (2015-01-17) fix various warnings; suppress SIMD on gcc 32-bit without -msse2
      2.00b (2014-12-25) fix STBI_MALLOC in progressive JPEG
      2.00  (2014-12-25) optimize JPG, including x86 SSE2 & NEON SIMD (ryg)
                         progressive JPEG (stb)
                         PGM/PPM support (Ken Miller)
                         STBI_MALLOC,STBI_REALLOC,STBI_FREE
                         GIF bugfix -- seemingly never worked
                         STBI_NO_*, STBI_ONLY_*
      1.48  (2014-12-14) fix incorrectly-named assert()
      1.47  (2014-12-14) 1/2/4-bit PNG support, both direct and paletted (Omar Cornut & stb)
                         optimize PNG (ryg)
                         fix bug in interlaced PNG with user-specified channel count (stb)
      1.46  (2014-08-26)
              fix broken tRNS chunk (colorkey-style transparency) in non-paletted PNG
      1.45  (2014-08-16)
              fix MSVC-ARM internal compiler error by wrapping malloc
      1.44  (2014-08-07)
              various warning fixes from Ronny Chevalier
      1.43  (2014-07-15)
              fix MSVC-only compiler problem in code changed in 1.42
      1.42  (2014-07-09)
              don't define _CRT_SECURE_NO_WARNINGS (affects user code)
              fixes to stbi__cleanup_jpeg path
              added STBI_ASSERT to avoid requiring assert.h
      1.41  (2014-06-25)
              fix search&replace from 1.36 that messed up comments/error messages
      1.40  (2014-06-22)
              fix gcc struct-initialization warning
      1.39  (2014-06-15)
              fix to TGA optimization when req_comp != number of components in TGA;
              fix to GIF loading because BMP wasn't rewinding (whoops, no GIFs in my test suite)
              add support for BMP version 5 (more ignored fields)
      1.38  (2014-06-06)
              suppress MSVC warnings on integer casts truncating values
              fix accidental rename of 'skip' field of I/O
      1.37  (2014-06-04)
              remove duplicate typedef
      1.36  (2014-06-03)
              convert to header file single-file library
              if de-iphone isn't set, load iphone images color-swapped instead of returning NULL
      1.35  (2014-05-27)
              various warnings
              fix broken STBI_SIMD path
              fix bug where stbi_load_from_file no longer left file pointer in correct place
              fix broken non-easy path for 32-bit BMP (possibly never used)
              TGA optimization by Arseny Kapoulkine
      1.34  (unknown)
              use STBI_NOTUSED in stbi__resample_row_generic(), fix one more leak in tga failure case
      1.33  (2011-07-14)
              make stbi_is_hdr work in STBI_NO_HDR (as specified), minor compiler-friendly improvements
      1.32  (2011-07-13)
              support for "info" function for all supported filetypes (SpartanJ)
      1.31  (2011-06-20)
              a few more leak fixes, bug in PNG handling (SpartanJ)
      1.30  (2011-06-11)
              added ability to load files via callbacks to accomidate custom input streams (Ben Wenger)
              removed deprecated format-specific test/load functions
              removed support for installable file formats (stbi_loader) -- would have been broken for IO callbacks anyway
              error cases in bmp and tga give messages and don't leak (Raymond Barbiero, grisha)
              fix inefficiency in decoding 32-bit BMP (David Woo)
      1.29  (2010-08-16)
              various warning fixes from Aurelien Pocheville
      1.28  (2010-08-01)
              fix bug in GIF palette transparency (SpartanJ)
      1.27  (2010-08-01)
              cast-to-stbi_uc to fix warnings
      1.26  (2010-07-24)
              fix bug in file buffering for PNG reported by SpartanJ
      1.25  (2010-07-17)
              refix trans_data warning (Won Chun)
      1.24  (2010-07-12)
              perf improvements reading from files on platforms with lock-heavy fgetc()
              minor perf improvements for jpeg
              deprecated type-specific functions so we'll get feedback if they're needed
              attempt to fix trans_data warning (Won Chun)
      1.23    fixed bug in iPhone support
      1.22  (2010-07-10)
              removed image *writing* support
              stbi_info support from Jetro Lauha
              GIF support from Jean-Marc Lienher
              iPhone PNG-extensions from James Brown
              warning-fixes from Nicolas Schulz and Janez Zemva (i.stbi__err. Janez (U+017D)emva)
      1.21    fix use of 'stbi_uc' in header (reported by jon blow)
      1.20    added support for Softimage PIC, by Tom Seddon
      1.19    bug in interlaced PNG corruption check (found by ryg)
      1.18  (2008-08-02)
              fix a threading bug (local mutable static)
      1.17    support interlaced PNG
      1.16    major bugfix - stbi__convert_format converted one too many pixels
      1.15    initialize some fields for thread safety
      1.14    fix threadsafe conversion bug
              header-file-only version (#define STBI_HEADER_FILE_ONLY before including)
      1.13    threadsafe
      1.12    const qualifiers in the API
      1.11    Support installable IDCT, colorspace conversion routines
      1.10    Fixes for 64-bit (don't use "unsigned long")
              optimized upsampling by Fabian "ryg" Giesen
      1.09    Fix format-conversion for PSD code (bad global variables!)
      1.08    Thatcher Ulrich's PSD code integrated by Nicolas Schulz
      1.07    attempt to fix C++ warning/errors again
      1.06    attempt to fix C++ warning/errors again
      1.05    fix TGA loading to return correct *comp and use good luminance calc
      1.04    default float alpha is 1, not 255; use 'void *' for stbi_image_free
      1.03    bugfixes to STBI_NO_STDIO, STBI_NO_HDR
      1.02    support for (subset of) HDR files, float interface for preferred access to them
      1.01    fix bug: possible bug in handling right-side up bmps... not sure
              fix bug: the stbi__bmp_load() and stbi__tga_load() functions didn't work at all
      1.00    interface to zlib that skips zlib header
      0.99    correct handling of alpha in palette
      0.98    TGA loader by lonesock; dynamically add loaders (untested)
      0.97    jpeg errors on too large a file; also catch another malloc failure
      0.96    fix detection of invalid v value - particleman@mollyrocket forum
      0.95    during header scan, seek to markers in case of padding
      0.94    STBI_NO_STDIO to disable stdio usage; rename all #defines the same
      0.93    handle jpegtran output; verbose errors
      0.92    read 4,8,16,24,32-bit BMP files of several formats
      0.91    output 24-bit Windows 3.0 BMP files
      0.90    fix a few more warnings; bump version number to approach 1.0
      0.61    bugfixes due to Marc LeBlanc, Christopher Lloyd
      0.60    fix compiling as c++
      0.59    fix warnings: merge Dave Moore's -Wall fixes
      0.58    fix bug: zlib uncompressed mode len/nlen was wrong endian
      0.57    fix bug: jpg last huffman symbol before marker was >9 bits but less than 16 available
      0.56    fix bug: zlib uncompressed mode len vs. nlen
      0.55    fix bug: restart_interval not initialized to 0
      0.54    allow NULL for 'int *comp'
      0.53    fix bug in png 3->4; speedup png decoding
      0.52    png handles req_comp=3,4 directly; minor cleanup; jpeg comments
      0.51    obey req_comp requests, 1-component jpegs return as 1-component,
              on 'test' only check type, not whether we support this variant
      0.50  (2006-11-19)
              first released version
*/


/*
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2017 Sean Barrett
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
*/
