/*
HOW TO USE:

    In exactly one translation unit (.c or .cpp file), #define MSF_GIF_IMPL before including the header, like so:

    #define MSF_GIF_IMPL
    #include "msf_gif.h"

    Everywhere else, just include the header like normal.


USAGE EXAMPLE:

    int width = 480, height = 320, centisecondsPerFrame = 5, bitDepth = 16;
    MsfGifState gifState = {};
    // msf_gif_bgra_flag = true; //optionally, set this flag if your pixels are in BGRA format instead of RGBA
    // msf_gif_alpha_threshold = 128; //optionally, enable transparency (see function documentation below for details)
    msf_gif_begin(&gifState, width, height);
    msf_gif_frame(&gifState, ..., centisecondsPerFrame, bitDepth, width * 4); //frame 1
    msf_gif_frame(&gifState, ..., centisecondsPerFrame, bitDepth, width * 4); //frame 2
    msf_gif_frame(&gifState, ..., centisecondsPerFrame, bitDepth, width * 4); //frame 3, etc...
    MsfGifResult result = msf_gif_end(&gifState);
    if (result.data) {
        FILE * fp = fopen("MyGif.gif", "wb");
        fwrite(result.data, result.dataSize, 1, fp);
        fclose(fp);
    }
    msf_gif_free(result);

Detailed function documentation can be found in the header section below.


ERROR HANDLING:

    If memory allocation fails, the functions will signal the error via their return values.
    If one function call fails, the library will free all of its allocations,
    and all subsequent calls will safely no-op and return 0 until the next call to `msf_gif_begin()`.
    Therefore, it's safe to check only the return value of `msf_gif_end()`.


REPLACING MALLOC:

    This library uses malloc+realloc+free internally for memory allocation.
    To facilitate integration with custom memory allocators, these calls go through macros, which can be redefined.
    The expected function signature equivalents of the macros are as follows:

    void * MSF_GIF_MALLOC(void * context, size_t newSize)
    void * MSF_GIF_REALLOC(void * context, void * oldMemory, size_t oldSize, size_t newSize)
    void MSF_GIF_FREE(void * context, void * oldMemory, size_t oldSize)

    If your allocator needs a context pointer, you can set the `customAllocatorContext` field of the MsfGifState struct
    before calling msf_gif_begin(), and it will be passed to all subsequent allocator macro calls.

    The maximum number of bytes the library will allocate to encode a single gif is bounded by the following formula:
    `(2 * 1024 * 1024) + (width * height * 8) + ((1024 + width * height * 1.5) * 3 * frameCount)`
    The peak heap memory usage in bytes, if using a general-purpose heap allocator, is bounded by the following formula:
    `(2 * 1024 * 1024) + (width * height * 9.5) + 1024 + (16 * frameCount) + (2 * sizeOfResultingGif)


See end of file for license information.
*/
module raylib.external.msf_gif;
import core.stdc.config;

extern (C) @nogc nothrow:
package(raylib):

//version 2.2

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// HEADER                                                                                                           ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct MsfGifResult
{
    void* data;
    size_t dataSize;

    size_t allocSize; //internal use
    void* contextPointer; //internal use
}

struct MsfCookedFrame
{
    //internal use
    uint* pixels;
    int depth;
    int count;
    int rbits;
    int gbits;
    int bbits;
}

struct MsfGifBuffer
{
    MsfGifBuffer* next;
    size_t size;
    ubyte[1] data;
}

alias MsfGifFileWriteFunc = c_ulong function (const(void)* buffer, size_t size, size_t count, void* stream);

struct MsfGifState
{
    MsfGifFileWriteFunc fileWriteFunc;
    void* fileWriteData;
    MsfCookedFrame previousFrame;
    MsfCookedFrame currentFrame;
    short* lzwMem;
    MsfGifBuffer* listHead;
    MsfGifBuffer* listTail;
    int width;
    int height;
    void* customAllocatorContext;
    int framesSubmitted; //needed for transparency to work correctly (because we reach into the previous frame)
}

//__cplusplus

/**
 * @param width                Image width in pixels.
 * @param height               Image height in pixels.
 * @return                     Non-zero on success, 0 on error.
 */
int msf_gif_begin (MsfGifState* handle, int width, int height);

/**
 * @param pixelData            Pointer to raw framebuffer data. Rows must be contiguous in memory, in RGBA8 format
 *                             (or BGRA8 if you have set `msf_gif_bgra_flag = true`).
 *                             Note: This function does NOT free `pixelData`. You must free it yourself afterwards.
 * @param centiSecondsPerFrame How many hundredths of a second this frame should be displayed for.
 *                             Note: This being specified in centiseconds is a limitation of the GIF format.
 * @param maxBitDepth          Limits how many bits per pixel can be used when quantizing the gif.
 *                             The actual bit depth chosen for a given frame will be less than or equal to
 *                             the supplied maximum, depending on the variety of colors used in the frame.
 *                             `maxBitDepth` will be clamped between 1 and 16. The recommended default is 16.
 *                             Lowering this value can result in faster exports and smaller gifs,
 *                             but the quality may suffer.
 *                             Please experiment with this value to find what works best for your application.
 * @param pitchInBytes         The number of bytes from the beginning of one row of pixels to the beginning of the next.
 *                             If you want to flip the image, just pass in a negative pitch.
 * @return                     Non-zero on success, 0 on error.
 */
int msf_gif_frame (MsfGifState* handle, ubyte* pixelData, int centiSecondsPerFame, int maxBitDepth, int pitchInBytes);

/**
 * @return                     A block of memory containing the gif file data, or NULL on error.
 *                             You are responsible for freeing this via `msf_gif_free()`.
 */
MsfGifResult msf_gif_end (MsfGifState* handle);

/**
 * @param result                The MsfGifResult struct, verbatim as it was returned from `msf_gif_end()`.
 */
void msf_gif_free (MsfGifResult result);

//The gif format only supports 1-bit transparency, meaning a pixel will either be fully transparent or fully opaque.
//Pixels with an alpha value less than the alpha threshold will be treated as transparent.
//To enable exporting transparent gifs, set it to a value between 1 and 255 (inclusive) before calling msf_gif_frame().
//Setting it to 0 causes the alpha channel to be ignored. Its initial value is 0.
extern __gshared int msf_gif_alpha_threshold;

//Set `msf_gif_bgra_flag = true` before calling `msf_gif_frame()` if your pixels are in BGRA byte order instead of RBGA.
extern __gshared int msf_gif_bgra_flag;

//TO-FILE FUNCTIONS
//These functions are equivalent to the ones above, but they write results to a file incrementally,
//instead of building a buffer in memory. This can result in lower memory usage when saving large gifs,
//because memory usage is bounded by only the size of a single frame, and is not dependent on the number of frames.
//There is currently no reason to use these unless you are on a memory-constrained platform.
//If in doubt about which API to use, for now you should use the normal (non-file) functions above.
//The signature of MsfGifFileWriteFunc matches fwrite for convenience, so that you can use the C file API like so:
//  FILE * fp = fopen("MyGif.gif", "wb");
//  msf_gif_begin_to_file(&handle, width, height, (MsfGifFileWriteFunc) fwrite, (void *) fp);
//  msf_gif_frame_to_file(...)
//  msf_gif_end_to_file(&handle);
//  fclose(fp);
//If you use a custom file write function, you must take care to return the same values that fwrite() would return.
//Note that all three functions will potentially write to the file.
int msf_gif_begin_to_file (MsfGifState* handle, int width, int height, MsfGifFileWriteFunc func, void* filePointer);
int msf_gif_frame_to_file (MsfGifState* handle, ubyte* pixelData, int centiSecondsPerFame, int maxBitDepth, int pitchInBytes);
int msf_gif_end_to_file (MsfGifState* handle); //returns 0 on error and non-zero on success

//__cplusplus

//MSF_GIF_H
