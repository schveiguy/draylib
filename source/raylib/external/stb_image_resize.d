module raylib.external.stb_image_resize;
template EnumMixin(Enum) if (is(Enum == enum))
{
    enum EnumMixin = () {
        assert(__ctfe);
        string result;
        foreach(m; __traits(allMembers, Enum))
        {
            result ~= "alias " ~ m ~ " = " ~ Enum.stringof ~ "." ~ m ~ ";";
        }
        return result;
    }();
}

@nogc nothrow:
extern(C): __gshared:
version = STB_IMAGE_RESIZE_IMPLEMENTATION;

/* stb_image_resize - v0.97 - public domain image resizing
   by Jorge L Rodriguez (@VinoBS) - 2014
   http://github.com/nothings/stb

   Written with emphasis on usability, portability, and efficiency. (No
   SIMD or threads, so it be easily outperformed by libs that use those.)
   Only scaling and translation is supported, no rotations or shears.
   Easy API downsamples w/Mitchell filter, upsamples w/cubic interpolation.

   COMPILING & LINKING
      In one C/C++ file that #includes this file, do this:
         #define STB_IMAGE_RESIZE_IMPLEMENTATION
      before the #include. That will create the implementation in that file.

   QUICKSTART
      stbir_resize_uint8(      input_pixels , in_w , in_h , 0,
                               output_pixels, out_w, out_h, 0, num_channels)
      stbir_resize_float(...)
      stbir_resize_uint8_srgb( input_pixels , in_w , in_h , 0,
                               output_pixels, out_w, out_h, 0,
                               num_channels , alpha_chan  , 0)
      stbir_resize_uint8_srgb_edgemode(
                               input_pixels , in_w , in_h , 0,
                               output_pixels, out_w, out_h, 0,
                               num_channels , alpha_chan  , 0, STBIR_EDGE_CLAMP)
                                                            // WRAP/REFLECT/ZERO

   FULL API
      See the "header file" section of the source for API documentation.

   ADDITIONAL DOCUMENTATION

      SRGB & FLOATING POINT REPRESENTATION
         The sRGB functions presume IEEE floating point. If you do not have
         IEEE floating point, define STBIR_NON_IEEE_FLOAT. This will use
         a slower implementation.

      MEMORY ALLOCATION
         The resize functions here perform a single memory allocation using
         malloc. To control the memory allocation, before the #include that
         triggers the implementation, do:

            #define STBIR_MALLOC(size,context) ...
            #define STBIR_FREE(ptr,context)   ...

         Each resize function makes exactly one call to malloc/free, so to use
         temp memory, store the temp memory in the context and return that.

      ASSERT
         Define STBIR_ASSERT(boolval) to override assert() and not use assert.h

      OPTIMIZATION
         Define STBIR_SATURATE_INT to compute clamp values in-range using
         integer operations instead of float operations. This may be faster
         on some platforms.

      DEFAULT FILTERS
         For functions which don't provide explicit control over what filters
         to use, you can change the compile-time defaults with

            #define STBIR_DEFAULT_FILTER_UPSAMPLE     STBIR_FILTER_something
            #define STBIR_DEFAULT_FILTER_DOWNSAMPLE   STBIR_FILTER_something

         See stbir_filter in the header-file section for the list of filters.

      NEW FILTERS
         A number of 1D filter kernels are used. For a list of
         supported filters see the stbir_filter enum. To add a new filter,
         write a filter function and add it to stbir__filter_info_table.

      PROGRESS
         For interactive use with slow resize operations, you can install
         a progress-report callback:

            #define STBIR_PROGRESS_REPORT(val)   some_func(val)

         The parameter val is a float which goes from 0 to 1 as progress is made.

         For example:

            static void my_progress_report(float progress);
            #define STBIR_PROGRESS_REPORT(val) my_progress_report(val)

            #define STB_IMAGE_RESIZE_IMPLEMENTATION
            #include "stb_image_resize.h"

            static void my_progress_report(float progress)
            {
               printf("Progress: %f%%\n", progress*100);
            }

      MAX CHANNELS
         If your image has more than 64 channels, define STBIR_MAX_CHANNELS
         to the max you'll have.

      ALPHA CHANNEL
         Most of the resizing functions provide the ability to control how
         the alpha channel of an image is processed. The important things
         to know about this:

         1. The best mathematically-behaved version of alpha to use is
         called "premultiplied alpha", in which the other color channels
         have had the alpha value multiplied in. If you use premultiplied
         alpha, linear filtering (such as image resampling done by this
         library, or performed in texture units on GPUs) does the "right
         thing". While premultiplied alpha is standard in the movie CGI
         industry, it is still uncommon in the videogame/real-time world.

         If you linearly filter non-premultiplied alpha, strange effects
         occur. (For example, the 50/50 average of 99% transparent bright green
         and 1% transparent black produces 50% transparent dark green when
         non-premultiplied, whereas premultiplied it produces 50%
         transparent near-black. The former introduces green energy
         that doesn't exist in the source image.)

         2. Artists should not edit premultiplied-alpha images; artists
         want non-premultiplied alpha images. Thus, art tools generally output
         non-premultiplied alpha images.

         3. You will get best results in most cases by converting images
         to premultiplied alpha before processing them mathematically.

         4. If you pass the flag STBIR_FLAG_ALPHA_PREMULTIPLIED, the
         resizer does not do anything special for the alpha channel;
         it is resampled identically to other channels. This produces
         the correct results for premultiplied-alpha images, but produces
         less-than-ideal results for non-premultiplied-alpha images.

         5. If you do not pass the flag STBIR_FLAG_ALPHA_PREMULTIPLIED,
         then the resizer weights the contribution of input pixels
         based on their alpha values, or, equivalently, it multiplies
         the alpha value into the color channels, resamples, then divides
         by the resultant alpha value. Input pixels which have alpha=0 do
         not contribute at all to output pixels unless _all_ of the input
         pixels affecting that output pixel have alpha=0, in which case
         the result for that pixel is the same as it would be without
         STBIR_FLAG_ALPHA_PREMULTIPLIED. However, this is only true for
         input images in integer formats. For input images in float format,
         input pixels with alpha=0 have no effect, and output pixels
         which have alpha=0 will be 0 in all channels. (For float images,
         you can manually achieve the same result by adding a tiny epsilon
         value to the alpha channel of every image, and then subtracting
         or clamping it at the end.)

         6. You can suppress the behavior described in #5 and make
         all-0-alpha pixels have 0 in all channels by #defining
         STBIR_NO_ALPHA_EPSILON.

         7. You can separately control whether the alpha channel is
         interpreted as linear or affected by the colorspace. By default
         it is linear; you almost never want to apply the colorspace.
         (For example, graphics hardware does not apply sRGB conversion
         to the alpha channel.)

   CONTRIBUTORS
      Jorge L Rodriguez: Implementation
      Sean Barrett: API design, optimizations
      Aras Pranckevicius: bugfix
      Nathan Reed: warning fixes

   REVISIONS
      0.97 (2020-02-02) fixed warning
      0.96 (2019-03-04) fixed warnings
      0.95 (2017-07-23) fixed warnings
      0.94 (2017-03-18) fixed warnings
      0.93 (2017-03-03) fixed bug with certain combinations of heights
      0.92 (2017-01-02) fix integer overflow on large (>2GB) images
      0.91 (2016-04-02) fix warnings; fix handling of subpixel regions
      0.90 (2014-09-17) first released version

   LICENSE
     See end of file for license information.

   TODO
      Don't decode all of the image data when only processing a partial tile
      Don't use full-width decode buffers when only processing a partial tile
      When processing wide images, break processing into tiles so data fits in L1 cache
      Installable filters?
      Resize that respects alpha test coverage
         (Reference code: FloatImage::alphaTestCoverage and FloatImage::scaleAlphaToCoverage:
         https://code.google.com/p/nvidia-texture-tools/source/browse/trunk/src/nvimage/FloatImage.cpp )
*/

 

version (_MSC_VER) {







} else {
public import core.stdc.stdint;
alias stbir_uint8 = ubyte;
alias stbir_uint16 = ushort;
alias stbir_uint32 = uint;
}


//////////////////////////////////////////////////////////////////////////////
//
// Easy-to-use API:
//
//     * "input pixels" points to an array of image data with 'num_channels' channels (e.g. RGB=3, RGBA=4)
//     * input_w is input image width (x-axis), input_h is input image height (y-axis)
//     * stride is the offset between successive rows of image data in memory, in bytes. you can
//       specify 0 to mean packed continuously in memory
//     * alpha channel is treated identically to other channels.
//     * colorspace is linear or sRGB as specified by function name
//     * returned result is 1 for success or 0 in case of an error.
//       #define STBIR_ASSERT() to trigger an assert on parameter validation errors.
//     * Memory required grows approximately linearly with input and output size, but with
//       discontinuities at input_w == output_w and input_h == output_h.
//     * These functions use a "default" resampling filter defined at compile time. To change the filter,
//       you can change the compile-time defaults by #defining STBIR_DEFAULT_FILTER_UPSAMPLE
//       and STBIR_DEFAULT_FILTER_DOWNSAMPLE, or you can use the medium-complexity API.

extern int stbir_resize_uint8(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels);

extern int stbir_resize_float(const(float)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, float* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels);


// The following functions interpret image data as gamma-corrected sRGB.
// Specify STBIR_ALPHA_CHANNEL_NONE if you have no alpha channel,
// or otherwise provide the index of the alpha channel. Flags value
// of 0 will probably do the right thing if you're not sure what
// the flags mean.

enum STBIR_ALPHA_CHANNEL_NONE =       -1;


// Set this flag if your texture has premultiplied alpha. Otherwise, stbir will
// use alpha-weighted resampling (effectively premultiplying, resampling,
// then unpremultiplying).
enum STBIR_FLAG_ALPHA_PREMULTIPLIED =    (1 << 0);

// The specified alpha channel should be handled as gamma-corrected value even
// when doing sRGB operations.
enum STBIR_FLAG_ALPHA_USES_COLORSPACE =  (1 << 1);


extern int stbir_resize_uint8_srgb(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags);


enum _Stbir_edge {
    STBIR_EDGE_CLAMP = 1,
    STBIR_EDGE_REFLECT = 2,
    STBIR_EDGE_WRAP = 3,
    STBIR_EDGE_ZERO = 4,
}alias stbir_edge = _Stbir_edge;

mixin(EnumMixin!stbir_edge);


// This function adds the ability to specify how requests to sample off the edge of the image are handled.
extern int stbir_resize_uint8_srgb_edgemode(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode);

//////////////////////////////////////////////////////////////////////////////
//
// Medium-complexity API
//
// This extends the easy-to-use API as follows:
//
//     * Alpha-channel can be processed separately
//       * If alpha_channel is not STBIR_ALPHA_CHANNEL_NONE
//         * Alpha channel will not be gamma corrected (unless flags&STBIR_FLAG_GAMMA_CORRECT)
//         * Filters will be weighted by alpha channel (unless flags&STBIR_FLAG_ALPHA_PREMULTIPLIED)
//     * Filter can be selected explicitly
//     * uint16 image type
//     * sRGB colorspace available for all types
//     * context parameter for passing to STBIR_MALLOC

enum _Stbir_filter {
    STBIR_FILTER_DEFAULT = 0, // use same filter type that easy-to-use API chooses
    STBIR_FILTER_BOX = 1, // A trapezoid w/1-pixel wide ramps, same result as box for integer scale ratios
    STBIR_FILTER_TRIANGLE = 2, // On upsampling, produces same results as bilinear texture filtering
    STBIR_FILTER_CUBICBSPLINE = 3, // The cubic b-spline (aka Mitchell-Netrevalli with B=1,C=0), gaussian-esque
    STBIR_FILTER_CATMULLROM = 4, // An interpolating cubic spline
    STBIR_FILTER_MITCHELL = 5, // Mitchell-Netrevalli filter with B=1/3, C=1/3
}alias stbir_filter = _Stbir_filter;

mixin(EnumMixin!stbir_filter);

enum _Stbir_colorspace {
    STBIR_COLORSPACE_LINEAR,
    STBIR_COLORSPACE_SRGB,

    STBIR_MAX_COLORSPACES,
}alias stbir_colorspace = _Stbir_colorspace;

mixin(EnumMixin!stbir_colorspace);

// The following functions are all identical except for the type of the image data

extern int stbir_resize_uint8_generic(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, void* alloc_context);

extern int stbir_resize_uint16_generic(const(stbir_uint16)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, stbir_uint16* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, void* alloc_context);

extern int stbir_resize_float_generic(const(float)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, float* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, void* alloc_context);



//////////////////////////////////////////////////////////////////////////////
//
// Full-complexity API
//
// This extends the medium API as follows:
//
//       * uint32 image type
//     * not typesafe
//     * separate filter types for each axis
//     * separate edge modes for each axis
//     * can specify scale explicitly for subpixel correctness
//     * can specify image source tile using texture coordinates

enum _Stbir_datatype {
    STBIR_TYPE_UINT8 ,
    STBIR_TYPE_UINT16,
    STBIR_TYPE_UINT32,
    STBIR_TYPE_FLOAT ,

    STBIR_MAX_TYPES
}alias stbir_datatype = _Stbir_datatype;

mixin(EnumMixin!stbir_datatype);

extern int stbir_resize(const(void)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, void* output_pixels, int output_w, int output_h, int output_stride_in_bytes, stbir_datatype datatype, int num_channels, int alpha_channel, int flags, stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, stbir_filter filter_horizontal, stbir_filter filter_vertical, stbir_colorspace space, void* alloc_context);

extern int stbir_resize_subpixel(const(void)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, void* output_pixels, int output_w, int output_h, int output_stride_in_bytes, stbir_datatype datatype, int num_channels, int alpha_channel, int flags, stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, stbir_filter filter_horizontal, stbir_filter filter_vertical, stbir_colorspace space, void* alloc_context, float x_scale, float y_scale, float x_offset, float y_offset);

extern int stbir_resize_region(const(void)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, void* output_pixels, int output_w, int output_h, int output_stride_in_bytes, stbir_datatype datatype, int num_channels, int alpha_channel, int flags, stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, stbir_filter filter_horizontal, stbir_filter filter_vertical, stbir_colorspace space, void* alloc_context, float s0, float t0, float s1, float t1);
// (s0, t0) & (s1, t1) are the top-left and bottom right corner (uv addressing style: [0, 1]x[0, 1]) of a region of the input image to use.

//
//
////   end header file   /////////////////////////////////////////////////////
 // STBIR_INCLUDE_STB_IMAGE_RESIZE_H






version (STB_IMAGE_RESIZE_IMPLEMENTATION) {


version (STBIR_ASSERT) {} else {

public import core.stdc.assert_;
enum string STBIR_ASSERT(string x) = ` assert(x)`;

}


// For memset
public import core.stdc.string;

public import core.stdc.math;

version (STBIR_MALLOC) {} else {

public import core.stdc.stdlib;
// use comma operator to evaluate c, to avoid "unused parameter" warnings
enum string STBIR_MALLOC(string size,string c) = ` ((void)(c), malloc(size))`;

enum string STBIR_FREE(string ptr,string c) = `    ((void)(c), free(ptr))`;

}


version (_MSC_VER) {} else {

version (none) {







} else {
version = stbir__inline;

}

} version (_MSC_VER) {







}


// should produce compiler error if size is wrong
alias stbir__validate_uint32 = ubyte[stbir_uint32.sizeof == 4 ? 1 : -1];

version (_MSC_VER) {







} else {
enum string STBIR__NOTUSED(string v) = `  (void)sizeof(v)`;

}


enum string STBIR__ARRAY_SIZE(string a) = ` (sizeof((a))/sizeof((a)[0]))`;


enum STBIR_DEFAULT_FILTER_UPSAMPLE =    STBIR_FILTER_CATMULLROM;




enum STBIR_DEFAULT_FILTER_DOWNSAMPLE =  STBIR_FILTER_MITCHELL;




version (STBIR_PROGRESS_REPORT) {} else {

//#define STBIR_PROGRESS_REPORT(float_0_to_1)

}


enum STBIR_MAX_CHANNELS = 64;




static if (STBIR_MAX_CHANNELS > 65536) {








}

// This value is added to alpha just before premultiplication to avoid
// zeroing out color values. It is equivalent to 2^-80. If you don't want
// that behavior (it may interfere if you have floating point images with
// very small alpha values) then you can define STBIR_NO_ALPHA_EPSILON to
// disable it.
enum STBIR_ALPHA_EPSILON = (float(1) / (1 << 20) / (1 << 20) / (1 << 20) / (1 << 20));






version (_MSC_VER) {







} else {
enum string STBIR__UNUSED_PARAM(string v) = `  (void)sizeof(v)`;

}


// must match stbir_datatype
private ubyte[5] stbir__type_size = [
    1, // STBIR_TYPE_UINT8
    2, // STBIR_TYPE_UINT16
    4, // STBIR_TYPE_UINT32
    4, // STBIR_TYPE_FLOAT
];

// Kernel function centered at 0
alias stbir__kernel_fn = float function(float x, float scale);
alias stbir__support_fn = float function(float scale);

struct _Stbir__filter_info {
    stbir__kernel_fn kernel;
    stbir__support_fn support;
}alias stbir__filter_info = _Stbir__filter_info;

// When upsampling, the contributors are which source pixels contribute.
// When downsampling, the contributors are which destination pixels are contributed to.
struct _Stbir__contributors {
    int n0; // First contributing pixel
    int n1; // Last contributing pixel
}alias stbir__contributors = _Stbir__contributors;

struct _Stbir__info {
    const(void)* input_data;
    int input_w;
    int input_h;
    int input_stride_bytes;

    void* output_data;
    int output_w;
    int output_h;
    int output_stride_bytes;

    float s0 = 0, t0 = 0, s1 = 0, t1 = 0;

    float horizontal_shift = 0; // Units: output pixels
    float vertical_shift = 0; // Units: output pixels
    float horizontal_scale = 0;
    float vertical_scale = 0;

    int channels;
    int alpha_channel;
    stbir_uint32 flags;
    stbir_datatype type;
    stbir_filter horizontal_filter;
    stbir_filter vertical_filter;
    stbir_edge edge_horizontal;
    stbir_edge edge_vertical;
    stbir_colorspace colorspace;

    stbir__contributors* horizontal_contributors;
    float* horizontal_coefficients;

    stbir__contributors* vertical_contributors;
    float* vertical_coefficients;

    int decode_buffer_pixels;
    float* decode_buffer;

    float* horizontal_buffer;

    // cache these because ceil/floor are inexplicably showing up in profile
    int horizontal_coefficient_width;
    int vertical_coefficient_width;
    int horizontal_filter_pixel_width;
    int vertical_filter_pixel_width;
    int horizontal_filter_pixel_margin;
    int vertical_filter_pixel_margin;
    int horizontal_num_contributors;
    int vertical_num_contributors;

    int ring_buffer_length_bytes; // The length of an individual entry in the ring buffer. The total number of ring buffers is stbir__get_filter_pixel_width(filter)
    int ring_buffer_num_entries; // Total number of entries in the ring buffer.
    int ring_buffer_first_scanline;
    int ring_buffer_last_scanline;
    int ring_buffer_begin_index; // first_scanline is at this index in the ring buffer
    float* ring_buffer;

    float* encode_buffer; // A temporary buffer to store floats so we don't lose precision while we do multiply-adds.

    int horizontal_contributors_size;
    int horizontal_coefficients_size;
    int vertical_contributors_size;
    int vertical_coefficients_size;
    int decode_buffer_size;
    int horizontal_buffer_size;
    int ring_buffer_size;
    int encode_buffer_size;
}alias stbir__info = _Stbir__info;


private const(float) stbir__max_uint8_as_float = 255.0f;
private const(float) stbir__max_uint16_as_float = 65535.0f;
private const(double) stbir__max_uint32_as_float = 4294967295.0;


private int stbir__min(int a, int b)
{
    return a < b ? a : b;
}

private float stbir__saturate(float x)
{
    if (x < 0)
        return 0;

    if (x > 1)
        return 1;

    return x;
}

version (STBIR_SATURATE_INT) {
}

private float[256] stbir__srgb_uchar_to_linear_float = [
    0.000000f, 0.000304f, 0.000607f, 0.000911f, 0.001214f, 0.001518f, 0.001821f, 0.002125f, 0.002428f, 0.002732f, 0.003035f,
    0.003347f, 0.003677f, 0.004025f, 0.004391f, 0.004777f, 0.005182f, 0.005605f, 0.006049f, 0.006512f, 0.006995f, 0.007499f,
    0.008023f, 0.008568f, 0.009134f, 0.009721f, 0.010330f, 0.010960f, 0.011612f, 0.012286f, 0.012983f, 0.013702f, 0.014444f,
    0.015209f, 0.015996f, 0.016807f, 0.017642f, 0.018500f, 0.019382f, 0.020289f, 0.021219f, 0.022174f, 0.023153f, 0.024158f,
    0.025187f, 0.026241f, 0.027321f, 0.028426f, 0.029557f, 0.030713f, 0.031896f, 0.033105f, 0.034340f, 0.035601f, 0.036889f,
    0.038204f, 0.039546f, 0.040915f, 0.042311f, 0.043735f, 0.045186f, 0.046665f, 0.048172f, 0.049707f, 0.051269f, 0.052861f,
    0.054480f, 0.056128f, 0.057805f, 0.059511f, 0.061246f, 0.063010f, 0.064803f, 0.066626f, 0.068478f, 0.070360f, 0.072272f,
    0.074214f, 0.076185f, 0.078187f, 0.080220f, 0.082283f, 0.084376f, 0.086500f, 0.088656f, 0.090842f, 0.093059f, 0.095307f,
    0.097587f, 0.099899f, 0.102242f, 0.104616f, 0.107023f, 0.109462f, 0.111932f, 0.114435f, 0.116971f, 0.119538f, 0.122139f,
    0.124772f, 0.127438f, 0.130136f, 0.132868f, 0.135633f, 0.138432f, 0.141263f, 0.144128f, 0.147027f, 0.149960f, 0.152926f,
    0.155926f, 0.158961f, 0.162029f, 0.165132f, 0.168269f, 0.171441f, 0.174647f, 0.177888f, 0.181164f, 0.184475f, 0.187821f,
    0.191202f, 0.194618f, 0.198069f, 0.201556f, 0.205079f, 0.208637f, 0.212231f, 0.215861f, 0.219526f, 0.223228f, 0.226966f,
    0.230740f, 0.234551f, 0.238398f, 0.242281f, 0.246201f, 0.250158f, 0.254152f, 0.258183f, 0.262251f, 0.266356f, 0.270498f,
    0.274677f, 0.278894f, 0.283149f, 0.287441f, 0.291771f, 0.296138f, 0.300544f, 0.304987f, 0.309469f, 0.313989f, 0.318547f,
    0.323143f, 0.327778f, 0.332452f, 0.337164f, 0.341914f, 0.346704f, 0.351533f, 0.356400f, 0.361307f, 0.366253f, 0.371238f,
    0.376262f, 0.381326f, 0.386430f, 0.391573f, 0.396755f, 0.401978f, 0.407240f, 0.412543f, 0.417885f, 0.423268f, 0.428691f,
    0.434154f, 0.439657f, 0.445201f, 0.450786f, 0.456411f, 0.462077f, 0.467784f, 0.473532f, 0.479320f, 0.485150f, 0.491021f,
    0.496933f, 0.502887f, 0.508881f, 0.514918f, 0.520996f, 0.527115f, 0.533276f, 0.539480f, 0.545725f, 0.552011f, 0.558340f,
    0.564712f, 0.571125f, 0.577581f, 0.584078f, 0.590619f, 0.597202f, 0.603827f, 0.610496f, 0.617207f, 0.623960f, 0.630757f,
    0.637597f, 0.644480f, 0.651406f, 0.658375f, 0.665387f, 0.672443f, 0.679543f, 0.686685f, 0.693872f, 0.701102f, 0.708376f,
    0.715694f, 0.723055f, 0.730461f, 0.737911f, 0.745404f, 0.752942f, 0.760525f, 0.768151f, 0.775822f, 0.783538f, 0.791298f,
    0.799103f, 0.806952f, 0.814847f, 0.822786f, 0.830770f, 0.838799f, 0.846873f, 0.854993f, 0.863157f, 0.871367f, 0.879622f,
    0.887923f, 0.896269f, 0.904661f, 0.913099f, 0.921582f, 0.930111f, 0.938686f, 0.947307f, 0.955974f, 0.964686f, 0.973445f,
    0.982251f, 0.991102f, 1.0f
];

private float stbir__srgb_to_linear(float f)
{
    if (f <= 0.04045f)
        return f / 12.92f;
    else
        return cast(float)pow((f + 0.055f) / 1.055f, 2.4f);
}

private float stbir__linear_to_srgb(float f)
{
    if (f <= 0.0031308f)
        return f * 12.92f;
    else
        return 1.055f * cast(float)pow(f, 1 / 2.4f) - 0.055f;
}

version (STBIR_NON_IEEE_FLOAT) {} else {

// From https://gist.github.com/rygorous/2203834

union _Stbir__FP32 {
    stbir_uint32 u;
    float f;
}alias stbir__FP32 = _Stbir__FP32;

private const(stbir_uint32)[104] fp32_to_srgb8_tab4 = [
    0x0073000d, 0x007a000d, 0x0080000d, 0x0087000d, 0x008d000d, 0x0094000d, 0x009a000d, 0x00a1000d,
    0x00a7001a, 0x00b4001a, 0x00c1001a, 0x00ce001a, 0x00da001a, 0x00e7001a, 0x00f4001a, 0x0101001a,
    0x010e0033, 0x01280033, 0x01410033, 0x015b0033, 0x01750033, 0x018f0033, 0x01a80033, 0x01c20033,
    0x01dc0067, 0x020f0067, 0x02430067, 0x02760067, 0x02aa0067, 0x02dd0067, 0x03110067, 0x03440067,
    0x037800ce, 0x03df00ce, 0x044600ce, 0x04ad00ce, 0x051400ce, 0x057b00c5, 0x05dd00bc, 0x063b00b5,
    0x06970158, 0x07420142, 0x07e30130, 0x087b0120, 0x090b0112, 0x09940106, 0x0a1700fc, 0x0a9500f2,
    0x0b0f01cb, 0x0bf401ae, 0x0ccb0195, 0x0d950180, 0x0e56016e, 0x0f0d015e, 0x0fbc0150, 0x10630143,
    0x11070264, 0x1238023e, 0x1357021d, 0x14660201, 0x156601e9, 0x165a01d3, 0x174401c0, 0x182401af,
    0x18fe0331, 0x1a9602fe, 0x1c1502d2, 0x1d7e02ad, 0x1ed4028d, 0x201a0270, 0x21520256, 0x227d0240,
    0x239f0443, 0x25c003fe, 0x27bf03c4, 0x29a10392, 0x2b6a0367, 0x2d1d0341, 0x2ebe031f, 0x304d0300,
    0x31d105b0, 0x34a80555, 0x37520507, 0x39d504c5, 0x3c37048b, 0x3e7c0458, 0x40a8042a, 0x42bd0401,
    0x44c20798, 0x488e071e, 0x4c1c06b6, 0x4f76065d, 0x52a50610, 0x55ac05cc, 0x5892058f, 0x5b590559,
    0x5e0c0a23, 0x631c0980, 0x67db08f6, 0x6c55087f, 0x70940818, 0x74a007bd, 0x787d076c, 0x7c330723,
];

private stbir_uint8 stbir__linear_to_srgb_uchar(float in_)
{
    static const(stbir__FP32) almostone = { 0x3f7fffff }; // 1-eps
    static const(stbir__FP32) minval = { (127-13) << 23 };
    stbir_uint32 tab = void, bias = void, scale = void, t = void;
    stbir__FP32 f = void;

    // Clamp to [2^(-13), 1-eps]; these two values map to 0 and 1, respectively.
    // The tests are carefully written so that NaNs map to 0, same as in the reference
    // implementation.
    if (!(in_ > minval.f)) // written this way to catch NaNs
        in_ = minval.f;
    if (in_ > almostone.f)
        in_ = almostone.f;

    // Do the table lookup and unpack bias, scale
    f.f = in_;
    tab = fp32_to_srgb8_tab4[(f.u - minval.u) >> 20];
    bias = (tab >> 16) << 9;
    scale = tab & 0xffff;

    // Grab next-highest mantissa bits and perform linear interpolation
    t = (f.u >> 12) & 0xff;
    return cast(ubyte) ((bias + scale*t) >> 16);
}

} version (STBIR_NON_IEEE_FLOAT) {
}

private float stbir__filter_trapezoid(float x, float scale)
{
    float halfscale = scale / 2;
    float t = 0.5f + halfscale;
    assert(scale <= 1);

    x = cast(float)fabs(x);

    if (x >= t)
        return 0;
    else
    {
        float r = 0.5f - halfscale;
        if (x <= r)
            return 1;
        else
            return (t - x) / scale;
    }
}

private float stbir__support_trapezoid(float scale)
{
    assert(scale <= 1);
    return 0.5f + scale / 2;
}

private float stbir__filter_triangle(float x, float s)
{
    cast(void)s.sizeof;

    x = cast(float)fabs(x);

    if (x <= 1.0f)
        return 1 - x;
    else
        return 0;
}

private float stbir__filter_cubic(float x, float s)
{
    cast(void)s.sizeof;

    x = cast(float)fabs(x);

    if (x < 1.0f)
        return (4 + x*x*(3*x - 6))/6;
    else if (x < 2.0f)
        return (8 + x*(-12 + x*(6 - x)))/6;

    return (0.0f);
}

private float stbir__filter_catmullrom(float x, float s)
{
    cast(void)s.sizeof;

    x = cast(float)fabs(x);

    if (x < 1.0f)
        return 1 - x*x*(2.5f - 1.5f*x);
    else if (x < 2.0f)
        return 2 - x*(4 + x*(0.5f*x - 2.5f));

    return (0.0f);
}

private float stbir__filter_mitchell(float x, float s)
{
    cast(void)s.sizeof;

    x = cast(float)fabs(x);

    if (x < 1.0f)
        return (16 + x*x*(21 * x - 36))/18;
    else if (x < 2.0f)
        return (32 + x*(-60 + x*(36 - 7*x)))/18;

    return (0.0f);
}

private float stbir__support_zero(float s)
{
    cast(void)s.sizeof;
    return 0;
}

private float stbir__support_one(float s)
{
    cast(void)s.sizeof;
    return 1;
}

private float stbir__support_two(float s)
{
    cast(void)s.sizeof;
    return 2;
}

private stbir__filter_info[7] stbir__filter_info_table = [
        { null, &stbir__support_zero },
        { &stbir__filter_trapezoid, &stbir__support_trapezoid },
        { &stbir__filter_triangle, &stbir__support_one },
        { &stbir__filter_cubic, &stbir__support_two },
        { &stbir__filter_catmullrom, &stbir__support_two },
        { &stbir__filter_mitchell, &stbir__support_two },
];

              private int stbir__use_upsampling(float ratio)
{
    return ratio > 1;
}

              private int stbir__use_width_upsampling(stbir__info* stbir_info)
{
    return stbir__use_upsampling(stbir_info.horizontal_scale);
}

              private int stbir__use_height_upsampling(stbir__info* stbir_info)
{
    return stbir__use_upsampling(stbir_info.vertical_scale);
}

// This is the maximum number of input samples that can affect an output sample
// with the given filter
private int stbir__get_filter_pixel_width(stbir_filter filter, float scale)
{
    assert(filter != 0);
    assert(filter < stbir__filter_info_table.length);

    if (stbir__use_upsampling(scale))
        return cast(int)ceil(stbir__filter_info_table[filter].support(1/scale) * 2);
    else
        return cast(int)ceil(stbir__filter_info_table[filter].support(scale) * 2 / scale);
}

// This is how much to expand buffers to account for filters seeking outside
// the image boundaries.
private int stbir__get_filter_pixel_margin(stbir_filter filter, float scale)
{
    return stbir__get_filter_pixel_width(filter, scale) / 2;
}

private int stbir__get_coefficient_width(stbir_filter filter, float scale)
{
    if (stbir__use_upsampling(scale))
        return cast(int)ceil(stbir__filter_info_table[filter].support(1 / scale) * 2);
    else
        return cast(int)ceil(stbir__filter_info_table[filter].support(scale) * 2);
}

private int stbir__get_contributors(float scale, stbir_filter filter, int input_size, int output_size)
{
    if (stbir__use_upsampling(scale))
        return output_size;
    else
        return (input_size + stbir__get_filter_pixel_margin(filter, scale) * 2);
}

private int stbir__get_total_horizontal_coefficients(stbir__info* info)
{
    return info.horizontal_num_contributors
         * stbir__get_coefficient_width (info.horizontal_filter, info.horizontal_scale);
}

private int stbir__get_total_vertical_coefficients(stbir__info* info)
{
    return info.vertical_num_contributors
         * stbir__get_coefficient_width (info.vertical_filter, info.vertical_scale);
}

private stbir__contributors* stbir__get_contributor(stbir__contributors* contributors, int n)
{
    return &contributors[n];
}

// For perf reasons this code is duplicated in stbir__resample_horizontal_upsample/downsample,
// if you change it here change it there too.
private float* stbir__get_coefficient(float* coefficients, stbir_filter filter, float scale, int n, int c)
{
    int width = stbir__get_coefficient_width(filter, scale);
    return &coefficients[width*n + c];
}

private int stbir__edge_wrap_slow(stbir_edge edge, int n, int max)
{
    switch (edge)
    {
    case STBIR_EDGE_ZERO:
        return 0; // we'll decode the wrong pixel here, and then overwrite with 0s later

    case STBIR_EDGE_CLAMP:
        if (n < 0)
            return 0;

        if (n >= max)
            return max - 1;

        return n; // NOTREACHED

    case STBIR_EDGE_REFLECT:
    {
        if (n < 0)
        {
            if (n < max)
                return -n;
            else
                return max - 1;
        }

        if (n >= max)
        {
            int max2 = max * 2;
            if (n >= max2)
                return 0;
            else
                return max2 - n - 1;
        }

        return n; // NOTREACHED
    }

    case STBIR_EDGE_WRAP:
        if (n >= 0)
            return (n % max);
        else
        {
            int m = (-n) % max;

            if (m != 0)
                m = max - m;

            return (m);
        }
        // NOTREACHED

    default:
        assert(!"Unimplemented edge type");
        return 0;
    }
}

              private int stbir__edge_wrap(stbir_edge edge, int n, int max)
{
    // avoid per-pixel switch
    if (n >= 0 && n < max)
        return n;
    return stbir__edge_wrap_slow(edge, n, max);
}

// What input pixels contribute to this output pixel?
private void stbir__calculate_sample_range_upsample(int n, float out_filter_radius, float scale_ratio, float out_shift, int* in_first_pixel, int* in_last_pixel, float* in_center_of_out)
{
    float out_pixel_center = cast(float)n + 0.5f;
    float out_pixel_influence_lowerbound = out_pixel_center - out_filter_radius;
    float out_pixel_influence_upperbound = out_pixel_center + out_filter_radius;

    float in_pixel_influence_lowerbound = (out_pixel_influence_lowerbound + out_shift) / scale_ratio;
    float in_pixel_influence_upperbound = (out_pixel_influence_upperbound + out_shift) / scale_ratio;

    *in_center_of_out = (out_pixel_center + out_shift) / scale_ratio;
    *in_first_pixel = cast(int)(floor(in_pixel_influence_lowerbound + 0.5));
    *in_last_pixel = cast(int)(floor(in_pixel_influence_upperbound - 0.5));
}

// What output pixels does this input pixel contribute to?
private void stbir__calculate_sample_range_downsample(int n, float in_pixels_radius, float scale_ratio, float out_shift, int* out_first_pixel, int* out_last_pixel, float* out_center_of_in)
{
    float in_pixel_center = cast(float)n + 0.5f;
    float in_pixel_influence_lowerbound = in_pixel_center - in_pixels_radius;
    float in_pixel_influence_upperbound = in_pixel_center + in_pixels_radius;

    float out_pixel_influence_lowerbound = in_pixel_influence_lowerbound * scale_ratio - out_shift;
    float out_pixel_influence_upperbound = in_pixel_influence_upperbound * scale_ratio - out_shift;

    *out_center_of_in = in_pixel_center * scale_ratio - out_shift;
    *out_first_pixel = cast(int)(floor(out_pixel_influence_lowerbound + 0.5));
    *out_last_pixel = cast(int)(floor(out_pixel_influence_upperbound - 0.5));
}

private void stbir__calculate_coefficients_upsample(stbir_filter filter, float scale, int in_first_pixel, int in_last_pixel, float in_center_of_out, stbir__contributors* contributor, float* coefficient_group)
{
    int i = void;
    float total_filter = 0;
    float filter_scale = void;

    assert(in_last_pixel - in_first_pixel <= cast(int)ceil(stbir__filter_info_table[filter].support(1/scale) * 2)); // Taken directly from stbir__get_coefficient_width() which we can't call because we don't know if we're horizontal or vertical.

    contributor.n0 = in_first_pixel;
    contributor.n1 = in_last_pixel;

    assert(contributor.n1 >= contributor.n0);

    for (i = 0; i <= in_last_pixel - in_first_pixel; i++)
    {
        float in_pixel_center = cast(float)(i + in_first_pixel) + 0.5f;
        coefficient_group[i] = stbir__filter_info_table[filter].kernel(in_center_of_out - in_pixel_center, 1 / scale);

        // If the coefficient is zero, skip it. (Don't do the <0 check here, we want the influence of those outside pixels.)
        if (i == 0 && !coefficient_group[i])
        {
            contributor.n0 = ++in_first_pixel;
            i--;
            continue;
        }

        total_filter += coefficient_group[i];
    }

    // NOTE(fg): Not actually true in general, nor is there any reason to expect it should be.
    // It would be true in exact math but is at best approximately true in floating-point math,
    // and it would not make sense to try and put actual bounds on this here because it depends
    // on the image aspect ratio which can get pretty extreme.
    //STBIR_ASSERT(stbir__filter_info_table[filter].kernel((float)(in_last_pixel + 1) + 0.5f - in_center_of_out, 1/scale) == 0);

    assert(total_filter > 0.9);
    assert(total_filter < 1.1f); // Make sure it's not way off.

    // Make sure the sum of all coefficients is 1.
    filter_scale = 1 / total_filter;

    for (i = 0; i <= in_last_pixel - in_first_pixel; i++)
        coefficient_group[i] *= filter_scale;

    for (i = in_last_pixel - in_first_pixel; i >= 0; i--)
    {
        if (coefficient_group[i])
            break;

        // This line has no weight. We can skip it.
        contributor.n1 = contributor.n0 + i - 1;
    }
}

private void stbir__calculate_coefficients_downsample(stbir_filter filter, float scale_ratio, int out_first_pixel, int out_last_pixel, float out_center_of_in, stbir__contributors* contributor, float* coefficient_group)
{
    int i = void;

    assert(out_last_pixel - out_first_pixel <= cast(int)ceil(stbir__filter_info_table[filter].support(scale_ratio) * 2)); // Taken directly from stbir__get_coefficient_width() which we can't call because we don't know if we're horizontal or vertical.

    contributor.n0 = out_first_pixel;
    contributor.n1 = out_last_pixel;

    assert(contributor.n1 >= contributor.n0);

    for (i = 0; i <= out_last_pixel - out_first_pixel; i++)
    {
        float out_pixel_center = cast(float)(i + out_first_pixel) + 0.5f;
        float x = out_pixel_center - out_center_of_in;
        coefficient_group[i] = stbir__filter_info_table[filter].kernel(x, scale_ratio) * scale_ratio;
    }

    // NOTE(fg): Not actually true in general, nor is there any reason to expect it should be.
    // It would be true in exact math but is at best approximately true in floating-point math,
    // and it would not make sense to try and put actual bounds on this here because it depends
    // on the image aspect ratio which can get pretty extreme.
    //STBIR_ASSERT(stbir__filter_info_table[filter].kernel((float)(out_last_pixel + 1) + 0.5f - out_center_of_in, scale_ratio) == 0);

    for (i = out_last_pixel - out_first_pixel; i >= 0; i--)
    {
        if (coefficient_group[i])
            break;

        // This line has no weight. We can skip it.
        contributor.n1 = contributor.n0 + i - 1;
    }
}

private void stbir__normalize_downsample_coefficients(stbir__contributors* contributors, float* coefficients, stbir_filter filter, float scale_ratio, int input_size, int output_size)
{
    int num_contributors = stbir__get_contributors(scale_ratio, filter, input_size, output_size);
    int num_coefficients = stbir__get_coefficient_width(filter, scale_ratio);
    int i = void, j = void;
    int skip = void;

    for (i = 0; i < output_size; i++)
    {
        float scale = void;
        float total = 0;

        for (j = 0; j < num_contributors; j++)
        {
            if (i >= contributors[j].n0 && i <= contributors[j].n1)
            {
                float coefficient = *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i - contributors[j].n0);
                total += coefficient;
            }
            else if (i < contributors[j].n0)
                break;
        }

        assert(total > 0.9f);
        assert(total < 1.1f);

        scale = 1 / total;

        for (j = 0; j < num_contributors; j++)
        {
            if (i >= contributors[j].n0 && i <= contributors[j].n1)
                *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i - contributors[j].n0) *= scale;
            else if (i < contributors[j].n0)
                break;
        }
    }

    // Optimize: Skip zero coefficients and contributions outside of image bounds.
    // Do this after normalizing because normalization depends on the n0/n1 values.
    for (j = 0; j < num_contributors; j++)
    {
        int range = void, max = void, width = void;

        skip = 0;
        while (*stbir__get_coefficient(coefficients, filter, scale_ratio, j, skip) == 0)
            skip++;

        contributors[j].n0 += skip;

        while (contributors[j].n0 < 0)
        {
            contributors[j].n0++;
            skip++;
        }

        range = contributors[j].n1 - contributors[j].n0 + 1;
        max = stbir__min(num_coefficients, range);

        width = stbir__get_coefficient_width(filter, scale_ratio);
        for (i = 0; i < max; i++)
        {
            if (i + skip >= width)
                break;

            *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i) = *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i + skip);
        }

        continue;
    }

    // Using min to avoid writing into invalid pixels.
    for (i = 0; i < num_contributors; i++)
        contributors[i].n1 = stbir__min(contributors[i].n1, output_size - 1);
}

// Each scan line uses the same kernel values so we should calculate the kernel
// values once and then we can use them for every scan line.
private void stbir__calculate_filters(stbir__contributors* contributors, float* coefficients, stbir_filter filter, float scale_ratio, float shift, int input_size, int output_size)
{
    int n = void;
    int total_contributors = stbir__get_contributors(scale_ratio, filter, input_size, output_size);

    if (stbir__use_upsampling(scale_ratio))
    {
        float out_pixels_radius = stbir__filter_info_table[filter].support(1 / scale_ratio) * scale_ratio;

        // Looping through out pixels
        for (n = 0; n < total_contributors; n++)
        {
            float in_center_of_out = void; // Center of the current out pixel in the in pixel space
            int in_first_pixel = void, in_last_pixel = void;

            stbir__calculate_sample_range_upsample(n, out_pixels_radius, scale_ratio, shift, &in_first_pixel, &in_last_pixel, &in_center_of_out);

            stbir__calculate_coefficients_upsample(filter, scale_ratio, in_first_pixel, in_last_pixel, in_center_of_out, stbir__get_contributor(contributors, n), stbir__get_coefficient(coefficients, filter, scale_ratio, n, 0));
        }
    }
    else
    {
        float in_pixels_radius = stbir__filter_info_table[filter].support(scale_ratio) / scale_ratio;

        // Looping through in pixels
        for (n = 0; n < total_contributors; n++)
        {
            float out_center_of_in = void; // Center of the current out pixel in the in pixel space
            int out_first_pixel = void, out_last_pixel = void;
            int n_adjusted = n - stbir__get_filter_pixel_margin(filter, scale_ratio);

            stbir__calculate_sample_range_downsample(n_adjusted, in_pixels_radius, scale_ratio, shift, &out_first_pixel, &out_last_pixel, &out_center_of_in);

            stbir__calculate_coefficients_downsample(filter, scale_ratio, out_first_pixel, out_last_pixel, out_center_of_in, stbir__get_contributor(contributors, n), stbir__get_coefficient(coefficients, filter, scale_ratio, n, 0));
        }

        stbir__normalize_downsample_coefficients(contributors, coefficients, filter, scale_ratio, input_size, output_size);
    }
}

private float* stbir__get_decode_buffer(stbir__info* stbir_info)
{
    // The 0 index of the decode buffer starts after the margin. This makes
    // it okay to use negative indexes on the decode buffer.
    return &stbir_info.decode_buffer[stbir_info.horizontal_filter_pixel_margin * stbir_info.channels];
}

enum string STBIR__DECODE(string type, string colorspace) = ` ((int)(type) * (STBIR_MAX_COLORSPACES) + (int)(colorspace))`;


private void stbir__decode_scanline(stbir__info* stbir_info, int n)
{
    int c = void;
    int channels = stbir_info.channels;
    int alpha_channel = stbir_info.alpha_channel;
    int type = stbir_info.type;
    int colorspace = stbir_info.colorspace;
    int input_w = stbir_info.input_w;
    size_t input_stride_bytes = stbir_info.input_stride_bytes;
    float* decode_buffer = stbir__get_decode_buffer(stbir_info);
    stbir_edge edge_horizontal = stbir_info.edge_horizontal;
    stbir_edge edge_vertical = stbir_info.edge_vertical;
    size_t in_buffer_row_offset = stbir__edge_wrap(edge_vertical, n, stbir_info.input_h) * input_stride_bytes;
    const(void)* input_data = cast(char*) stbir_info.input_data + in_buffer_row_offset;
    int max_x = input_w + stbir_info.horizontal_filter_pixel_margin;
    int decode = (cast(int)(type) * (STBIR_MAX_COLORSPACES) + cast(int)(colorspace));

    int x = -stbir_info.horizontal_filter_pixel_margin;

    // special handling for STBIR_EDGE_ZERO because it needs to return an item that doesn't appear in the input,
    // and we want to avoid paying overhead on every pixel if not STBIR_EDGE_ZERO
    if (edge_vertical == STBIR_EDGE_ZERO && (n < 0 || n >= stbir_info.input_h))
    {
        for (; x < max_x; x++)
            for (c = 0; c < channels; c++)
                decode_buffer[x*channels + c] = 0;
        return;
    }

    switch (decode)
    {
    case (cast(int)(STBIR_TYPE_UINT8) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = (cast(float)(cast(const(ubyte)*)input_data)[input_pixel_index + c]) / stbir__max_uint8_as_float;
        }
        break;

    case (cast(int)(STBIR_TYPE_UINT8) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_uchar_to_linear_float[(cast(const(ubyte)*)input_data)[input_pixel_index + c]];

            if (!(stbir_info.flags&(1 << 1)))
                decode_buffer[decode_pixel_index + alpha_channel] = (cast(float)(cast(const(ubyte)*)input_data)[input_pixel_index + alpha_channel]) / stbir__max_uint8_as_float;
        }
        break;

    case (cast(int)(STBIR_TYPE_UINT16) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = (cast(float)(cast(const(ushort)*)input_data)[input_pixel_index + c]) / stbir__max_uint16_as_float;
        }
        break;

    case (cast(int)(STBIR_TYPE_UINT16) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_to_linear((cast(float)(cast(const(ushort)*)input_data)[input_pixel_index + c]) / stbir__max_uint16_as_float);

            if (!(stbir_info.flags&(1 << 1)))
                decode_buffer[decode_pixel_index + alpha_channel] = (cast(float)(cast(const(ushort)*)input_data)[input_pixel_index + alpha_channel]) / stbir__max_uint16_as_float;
        }
        break;

    case (cast(int)(STBIR_TYPE_UINT32) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = cast(float)((cast(double)(cast(const(uint)*)input_data)[input_pixel_index + c]) / stbir__max_uint32_as_float);
        }
        break;

    case (cast(int)(STBIR_TYPE_UINT32) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_to_linear(cast(float)((cast(double)(cast(const(uint)*)input_data)[input_pixel_index + c]) / stbir__max_uint32_as_float));

            if (!(stbir_info.flags&(1 << 1)))
                decode_buffer[decode_pixel_index + alpha_channel] = cast(float)((cast(double)(cast(const(uint)*)input_data)[input_pixel_index + alpha_channel]) / stbir__max_uint32_as_float);
        }
        break;

    case (cast(int)(STBIR_TYPE_FLOAT) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = (cast(const(float)*)input_data)[input_pixel_index + c];
        }
        break;

    case (cast(int)(STBIR_TYPE_FLOAT) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_to_linear((cast(const(float)*)input_data)[input_pixel_index + c]);

            if (!(stbir_info.flags&(1 << 1)))
                decode_buffer[decode_pixel_index + alpha_channel] = (cast(const(float)*)input_data)[input_pixel_index + alpha_channel];
        }

        break;

    default:
        assert(!"Unknown type/colorspace/channels combination.");
        break;
    }

    if (!(stbir_info.flags & (1 << 0)))
    {
        for (x = -stbir_info.horizontal_filter_pixel_margin; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;

            // If the alpha value is 0 it will clobber the color values. Make sure it's not.
            float alpha = decode_buffer[decode_pixel_index + alpha_channel];
version (STBIR_NO_ALPHA_EPSILON) {} else {

            if (stbir_info.type != STBIR_TYPE_FLOAT) {
                alpha += (cast(float)1 / (1 << 20) / (1 << 20) / (1 << 20) / (1 << 20));
                decode_buffer[decode_pixel_index + alpha_channel] = alpha;
            }
}

            for (c = 0; c < channels; c++)
            {
                if (c == alpha_channel)
                    continue;

                decode_buffer[decode_pixel_index + c] *= alpha;
            }
        }
    }

    if (edge_horizontal == STBIR_EDGE_ZERO)
    {
        for (x = -stbir_info.horizontal_filter_pixel_margin; x < 0; x++)
        {
            for (c = 0; c < channels; c++)
                decode_buffer[x*channels + c] = 0;
        }
        for (x = input_w; x < max_x; x++)
        {
            for (c = 0; c < channels; c++)
                decode_buffer[x*channels + c] = 0;
        }
    }
}

private float* stbir__get_ring_buffer_entry(float* ring_buffer, int index, int ring_buffer_length)
{
    return &ring_buffer[index * ring_buffer_length];
}

private float* stbir__add_empty_ring_buffer_entry(stbir__info* stbir_info, int n)
{
    int ring_buffer_index = void;
    float* ring_buffer = void;

    stbir_info.ring_buffer_last_scanline = n;

    if (stbir_info.ring_buffer_begin_index < 0)
    {
        ring_buffer_index = stbir_info.ring_buffer_begin_index = 0;
        stbir_info.ring_buffer_first_scanline = n;
    }
    else
    {
        ring_buffer_index = (stbir_info.ring_buffer_begin_index + (stbir_info.ring_buffer_last_scanline - stbir_info.ring_buffer_first_scanline)) % stbir_info.ring_buffer_num_entries;
        assert(ring_buffer_index != stbir_info.ring_buffer_begin_index);
    }

    ring_buffer = stbir__get_ring_buffer_entry(stbir_info.ring_buffer, ring_buffer_index, stbir_info.ring_buffer_length_bytes / int(float.sizeof));
    memset(ring_buffer, 0, stbir_info.ring_buffer_length_bytes);

    return ring_buffer;
}


private void stbir__resample_horizontal_upsample(stbir__info* stbir_info, float* output_buffer)
{
    int x = void, k = void;
    int output_w = stbir_info.output_w;
    int channels = stbir_info.channels;
    float* decode_buffer = stbir__get_decode_buffer(stbir_info);
    stbir__contributors* horizontal_contributors = stbir_info.horizontal_contributors;
    float* horizontal_coefficients = stbir_info.horizontal_coefficients;
    int coefficient_width = stbir_info.horizontal_coefficient_width;

    for (x = 0; x < output_w; x++)
    {
        int n0 = horizontal_contributors[x].n0;
        int n1 = horizontal_contributors[x].n1;

        int out_pixel_index = x * channels;
        int coefficient_group = coefficient_width * x;
        int coefficient_counter = 0;

        assert(n1 >= n0);
        assert(n0 >= -stbir_info.horizontal_filter_pixel_margin);
        assert(n1 >= -stbir_info.horizontal_filter_pixel_margin);
        assert(n0 < stbir_info.input_w + stbir_info.horizontal_filter_pixel_margin);
        assert(n1 < stbir_info.input_w + stbir_info.horizontal_filter_pixel_margin);

        switch (channels) {
            case 1:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 1;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    assert(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                }
                break;
            case 2:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 2;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    assert(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                }
                break;
            case 3:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 3;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    assert(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                }
                break;
            case 4:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 4;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    assert(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                    output_buffer[out_pixel_index + 3] += decode_buffer[in_pixel_index + 3] * coefficient;
                }
                break;
            default:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * channels;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    int c = void;
                    assert(coefficient != 0);
                    for (c = 0; c < channels; c++)
                        output_buffer[out_pixel_index + c] += decode_buffer[in_pixel_index + c] * coefficient;
                }
                break;
        }
    }
}

private void stbir__resample_horizontal_downsample(stbir__info* stbir_info, float* output_buffer)
{
    int x = void, k = void;
    int input_w = stbir_info.input_w;
    int channels = stbir_info.channels;
    float* decode_buffer = stbir__get_decode_buffer(stbir_info);
    stbir__contributors* horizontal_contributors = stbir_info.horizontal_contributors;
    float* horizontal_coefficients = stbir_info.horizontal_coefficients;
    int coefficient_width = stbir_info.horizontal_coefficient_width;
    int filter_pixel_margin = stbir_info.horizontal_filter_pixel_margin;
    int max_x = input_w + filter_pixel_margin * 2;

    assert(!stbir__use_width_upsampling(stbir_info));

    switch (channels) {
        case 1:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 1;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 1;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                }
            }
            break;

        case 2:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 2;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 2;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                }
            }
            break;

        case 3:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 3;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 3;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                }
            }
            break;

        case 4:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 4;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 4;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                    output_buffer[out_pixel_index + 3] += decode_buffer[in_pixel_index + 3] * coefficient;
                }
            }
            break;

        default:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * channels;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int c = void;
                    int out_pixel_index = k * channels;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    for (c = 0; c < channels; c++)
                        output_buffer[out_pixel_index + c] += decode_buffer[in_pixel_index + c] * coefficient;
                }
            }
            break;
    }
}

private void stbir__decode_and_resample_upsample(stbir__info* stbir_info, int n)
{
    // Decode the nth scanline from the source image into the decode buffer.
    stbir__decode_scanline(stbir_info, n);

    // Now resample it into the ring buffer.
    if (stbir__use_width_upsampling(stbir_info))
        stbir__resample_horizontal_upsample(stbir_info, stbir__add_empty_ring_buffer_entry(stbir_info, n));
    else
        stbir__resample_horizontal_downsample(stbir_info, stbir__add_empty_ring_buffer_entry(stbir_info, n));

    // Now it's sitting in the ring buffer ready to be used as source for the vertical sampling.
}

private void stbir__decode_and_resample_downsample(stbir__info* stbir_info, int n)
{
    // Decode the nth scanline from the source image into the decode buffer.
    stbir__decode_scanline(stbir_info, n);

    memset(stbir_info.horizontal_buffer, 0, stbir_info.output_w * stbir_info.channels * float.sizeof);

    // Now resample it into the horizontal buffer.
    if (stbir__use_width_upsampling(stbir_info))
        stbir__resample_horizontal_upsample(stbir_info, stbir_info.horizontal_buffer);
    else
        stbir__resample_horizontal_downsample(stbir_info, stbir_info.horizontal_buffer);

    // Now it's sitting in the horizontal buffer ready to be distributed into the ring buffers.
}

// Get the specified scan line from the ring buffer.
private float* stbir__get_ring_buffer_scanline(int get_scanline, float* ring_buffer, int begin_index, int first_scanline, int ring_buffer_num_entries, int ring_buffer_length)
{
    int ring_buffer_index = (begin_index + (get_scanline - first_scanline)) % ring_buffer_num_entries;
    return stbir__get_ring_buffer_entry(ring_buffer, ring_buffer_index, ring_buffer_length);
}


private void stbir__encode_scanline(stbir__info* stbir_info, int num_pixels, void* output_buffer, float* encode_buffer, int channels, int alpha_channel, int decode)
{
    int x = void;
    int n = void;
    int num_nonalpha = void;
    stbir_uint16[64] nonalpha = void;

    if (!(stbir_info.flags&(1 << 0)))
    {
        for (x=0; x < num_pixels; ++x)
        {
            int pixel_index = x*channels;

            float alpha = encode_buffer[pixel_index + alpha_channel];
            float reciprocal_alpha = alpha ? 1.0f / alpha : 0;

            // unrolling this produced a 1% slowdown upscaling a large RGBA linear-space image on my machine - stb
            for (n = 0; n < channels; n++)
                if (n != alpha_channel)
                    encode_buffer[pixel_index + n] *= reciprocal_alpha;

            // We added in a small epsilon to prevent the color channel from being deleted with zero alpha.
            // Because we only add it for integer types, it will automatically be discarded on integer
            // conversion, so we don't need to subtract it back out (which would be problematic for
            // numeric precision reasons).
        }
    }

    // build a table of all channels that need colorspace correction, so
    // we don't perform colorspace correction on channels that don't need it.
    for (x = 0, num_nonalpha = 0; x < channels; ++x)
    {
        if (x != alpha_channel || (stbir_info.flags & (1 << 1)))
        {
            nonalpha[num_nonalpha++] = cast(stbir_uint16)x;
        }
    }

    enum string STBIR__ROUND_INT(string f) = `    ((int)          ((f)+0.5))`;

    enum string STBIR__ROUND_UINT(string f) = `   ((stbir_uint32) ((f)+0.5))`;


    version (STBIR__SATURATE_INT) {
    } else {
    enum string STBIR__ENCODE_LINEAR8(string f) = `   (unsigned char ) STBIR__ROUND_INT(stbir__saturate(f) * stbir__max_uint8_as_float )`;

    enum string STBIR__ENCODE_LINEAR16(string f) = `  (unsigned short) STBIR__ROUND_INT(stbir__saturate(f) * stbir__max_uint16_as_float)`;

    }


    switch (decode)
    {
        case (cast(int)(STBIR_TYPE_UINT8) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    (cast(ubyte*)output_buffer)[index] = cast(ubyte ) (cast(int) ((stbir__saturate(encode_buffer[index]) * stbir__max_uint8_as_float)+0.5));
                }
            }
            break;

        case (cast(int)(STBIR_TYPE_UINT8) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    (cast(ubyte*)output_buffer)[index] = stbir__linear_to_srgb_uchar(encode_buffer[index]);
                }

                if (!(stbir_info.flags & (1 << 1)))
                    (cast(ubyte*)output_buffer)[pixel_index + alpha_channel] = cast(ubyte ) (cast(int) ((stbir__saturate(encode_buffer[pixel_index+alpha_channel]) * stbir__max_uint8_as_float)+0.5));
            }
            break;

        case (cast(int)(STBIR_TYPE_UINT16) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    (cast(ushort*)output_buffer)[index] = cast(ushort) (cast(int) ((stbir__saturate(encode_buffer[index]) * stbir__max_uint16_as_float)+0.5));
                }
            }
            break;

        case (cast(int)(STBIR_TYPE_UINT16) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    (cast(ushort*)output_buffer)[index] = cast(ushort)(cast(int) ((stbir__linear_to_srgb(stbir__saturate(encode_buffer[index])) * stbir__max_uint16_as_float)+0.5));
                }

                if (!(stbir_info.flags&(1 << 1)))
                    (cast(ushort*)output_buffer)[pixel_index + alpha_channel] = cast(ushort) (cast(int) ((stbir__saturate(encode_buffer[pixel_index + alpha_channel]) * stbir__max_uint16_as_float)+0.5));
            }

            break;

        case (cast(int)(STBIR_TYPE_UINT32) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    (cast(uint*)output_buffer)[index] = cast(uint)(cast(stbir_uint32) (((cast(double)stbir__saturate(encode_buffer[index])) * stbir__max_uint32_as_float)+0.5));
                }
            }
            break;

        case (cast(int)(STBIR_TYPE_UINT32) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    (cast(uint*)output_buffer)[index] = cast(uint)(cast(stbir_uint32) (((cast(double)stbir__linear_to_srgb(stbir__saturate(encode_buffer[index]))) * stbir__max_uint32_as_float)+0.5));
                }

                if (!(stbir_info.flags&(1 << 1)))
                    (cast(uint*)output_buffer)[pixel_index + alpha_channel] = cast(uint)(cast(int) (((cast(double)stbir__saturate(encode_buffer[pixel_index + alpha_channel])) * stbir__max_uint32_as_float)+0.5));
            }
            break;

        case (cast(int)(STBIR_TYPE_FLOAT) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_LINEAR)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    (cast(float*)output_buffer)[index] = encode_buffer[index];
                }
            }
            break;

        case (cast(int)(STBIR_TYPE_FLOAT) * (STBIR_MAX_COLORSPACES) + cast(int)(STBIR_COLORSPACE_SRGB)):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    (cast(float*)output_buffer)[index] = stbir__linear_to_srgb(encode_buffer[index]);
                }

                if (!(stbir_info.flags&(1 << 1)))
                    (cast(float*)output_buffer)[pixel_index + alpha_channel] = encode_buffer[pixel_index + alpha_channel];
            }
            break;

        default:
            assert(!"Unknown type/colorspace/channels combination.");
            break;
    }
}

private void stbir__resample_vertical_upsample(stbir__info* stbir_info, int n)
{
    int x = void, k = void;
    int output_w = stbir_info.output_w;
    stbir__contributors* vertical_contributors = stbir_info.vertical_contributors;
    float* vertical_coefficients = stbir_info.vertical_coefficients;
    int channels = stbir_info.channels;
    int alpha_channel = stbir_info.alpha_channel;
    int type = stbir_info.type;
    int colorspace = stbir_info.colorspace;
    int ring_buffer_entries = stbir_info.ring_buffer_num_entries;
    void* output_data = stbir_info.output_data;
    float* encode_buffer = stbir_info.encode_buffer;
    int decode = (cast(int)(type) * (STBIR_MAX_COLORSPACES) + cast(int)(colorspace));
    int coefficient_width = stbir_info.vertical_coefficient_width;
    int coefficient_counter = void;
    int contributor = n;

    float* ring_buffer = stbir_info.ring_buffer;
    int ring_buffer_begin_index = stbir_info.ring_buffer_begin_index;
    int ring_buffer_first_scanline = stbir_info.ring_buffer_first_scanline;
    int ring_buffer_length = stbir_info.ring_buffer_length_bytes/int(float.sizeof);

    int n0 = void, n1 = void, output_row_start = void;
    int coefficient_group = coefficient_width * contributor;

    n0 = vertical_contributors[contributor].n0;
    n1 = vertical_contributors[contributor].n1;

    output_row_start = n * stbir_info.output_stride_bytes;

    assert(stbir__use_height_upsampling(stbir_info));

    memset(encode_buffer, 0, output_w * float.sizeof * channels);

    // I tried reblocking this for better cache usage of encode_buffer
    // (using x_outer, k, x_inner), but it lost speed. -- stb

    coefficient_counter = 0;
    switch (channels) {
        case 1:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, ring_buffer_entries, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 1;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                }
            }
            break;
        case 2:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, ring_buffer_entries, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 2;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                    encode_buffer[in_pixel_index + 1] += ring_buffer_entry[in_pixel_index + 1] * coefficient;
                }
            }
            break;
        case 3:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, ring_buffer_entries, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 3;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                    encode_buffer[in_pixel_index + 1] += ring_buffer_entry[in_pixel_index + 1] * coefficient;
                    encode_buffer[in_pixel_index + 2] += ring_buffer_entry[in_pixel_index + 2] * coefficient;
                }
            }
            break;
        case 4:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, ring_buffer_entries, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 4;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                    encode_buffer[in_pixel_index + 1] += ring_buffer_entry[in_pixel_index + 1] * coefficient;
                    encode_buffer[in_pixel_index + 2] += ring_buffer_entry[in_pixel_index + 2] * coefficient;
                    encode_buffer[in_pixel_index + 3] += ring_buffer_entry[in_pixel_index + 3] * coefficient;
                }
            }
            break;
        default:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, ring_buffer_entries, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * channels;
                    int c = void;
                    for (c = 0; c < channels; c++)
                        encode_buffer[in_pixel_index + c] += ring_buffer_entry[in_pixel_index + c] * coefficient;
                }
            }
            break;
    }
    stbir__encode_scanline(stbir_info, output_w, cast(char*) output_data + output_row_start, encode_buffer, channels, alpha_channel, decode);
}

private void stbir__resample_vertical_downsample(stbir__info* stbir_info, int n)
{
    int x = void, k = void;
    int output_w = stbir_info.output_w;
    stbir__contributors* vertical_contributors = stbir_info.vertical_contributors;
    float* vertical_coefficients = stbir_info.vertical_coefficients;
    int channels = stbir_info.channels;
    int ring_buffer_entries = stbir_info.ring_buffer_num_entries;
    float* horizontal_buffer = stbir_info.horizontal_buffer;
    int coefficient_width = stbir_info.vertical_coefficient_width;
    int contributor = n + stbir_info.vertical_filter_pixel_margin;

    float* ring_buffer = stbir_info.ring_buffer;
    int ring_buffer_begin_index = stbir_info.ring_buffer_begin_index;
    int ring_buffer_first_scanline = stbir_info.ring_buffer_first_scanline;
    int ring_buffer_length = stbir_info.ring_buffer_length_bytes/int(float.sizeof);
    int n0 = void, n1 = void;

    n0 = vertical_contributors[contributor].n0;
    n1 = vertical_contributors[contributor].n1;

    assert(!stbir__use_height_upsampling(stbir_info));

    for (k = n0; k <= n1; k++)
    {
        int coefficient_index = k - n0;
        int coefficient_group = coefficient_width * contributor;
        float coefficient = vertical_coefficients[coefficient_group + coefficient_index];

        float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, ring_buffer_entries, ring_buffer_length);

        switch (channels) {
            case 1:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 1;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                }
                break;
            case 2:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 2;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                    ring_buffer_entry[in_pixel_index + 1] += horizontal_buffer[in_pixel_index + 1] * coefficient;
                }
                break;
            case 3:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 3;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                    ring_buffer_entry[in_pixel_index + 1] += horizontal_buffer[in_pixel_index + 1] * coefficient;
                    ring_buffer_entry[in_pixel_index + 2] += horizontal_buffer[in_pixel_index + 2] * coefficient;
                }
                break;
            case 4:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 4;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                    ring_buffer_entry[in_pixel_index + 1] += horizontal_buffer[in_pixel_index + 1] * coefficient;
                    ring_buffer_entry[in_pixel_index + 2] += horizontal_buffer[in_pixel_index + 2] * coefficient;
                    ring_buffer_entry[in_pixel_index + 3] += horizontal_buffer[in_pixel_index + 3] * coefficient;
                }
                break;
            default:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * channels;

                    int c = void;
                    for (c = 0; c < channels; c++)
                        ring_buffer_entry[in_pixel_index + c] += horizontal_buffer[in_pixel_index + c] * coefficient;
                }
                break;
        }
    }
}

private void stbir__buffer_loop_upsample(stbir__info* stbir_info)
{
    int y = void;
    float scale_ratio = stbir_info.vertical_scale;
    float out_scanlines_radius = stbir__filter_info_table[stbir_info.vertical_filter].support(1/scale_ratio) * scale_ratio;

    assert(stbir__use_height_upsampling(stbir_info));

    for (y = 0; y < stbir_info.output_h; y++)
    {
        float in_center_of_out = 0; // Center of the current out scanline in the in scanline space
        int in_first_scanline = 0, in_last_scanline = 0;

        stbir__calculate_sample_range_upsample(y, out_scanlines_radius, scale_ratio, stbir_info.vertical_shift, &in_first_scanline, &in_last_scanline, &in_center_of_out);

        assert(in_last_scanline - in_first_scanline + 1 <= stbir_info.ring_buffer_num_entries);

        if (stbir_info.ring_buffer_begin_index >= 0)
        {
            // Get rid of whatever we don't need anymore.
            while (in_first_scanline > stbir_info.ring_buffer_first_scanline)
            {
                if (stbir_info.ring_buffer_first_scanline == stbir_info.ring_buffer_last_scanline)
                {
                    // We just popped the last scanline off the ring buffer.
                    // Reset it to the empty state.
                    stbir_info.ring_buffer_begin_index = -1;
                    stbir_info.ring_buffer_first_scanline = 0;
                    stbir_info.ring_buffer_last_scanline = 0;
                    break;
                }
                else
                {
                    stbir_info.ring_buffer_first_scanline++;
                    stbir_info.ring_buffer_begin_index = (stbir_info.ring_buffer_begin_index + 1) % stbir_info.ring_buffer_num_entries;
                }
            }
        }

        // Load in new ones.
        if (stbir_info.ring_buffer_begin_index < 0)
            stbir__decode_and_resample_upsample(stbir_info, in_first_scanline);

        while (in_last_scanline > stbir_info.ring_buffer_last_scanline)
            stbir__decode_and_resample_upsample(stbir_info, stbir_info.ring_buffer_last_scanline + 1);

        // Now all buffers should be ready to write a row of vertical sampling.
        stbir__resample_vertical_upsample(stbir_info, y);

                                                              {}
    }
}

private void stbir__empty_ring_buffer(stbir__info* stbir_info, int first_necessary_scanline)
{
    int output_stride_bytes = stbir_info.output_stride_bytes;
    int channels = stbir_info.channels;
    int alpha_channel = stbir_info.alpha_channel;
    int type = stbir_info.type;
    int colorspace = stbir_info.colorspace;
    int output_w = stbir_info.output_w;
    void* output_data = stbir_info.output_data;
    int decode = (cast(int)(type) * (STBIR_MAX_COLORSPACES) + cast(int)(colorspace));

    float* ring_buffer = stbir_info.ring_buffer;
    int ring_buffer_length = stbir_info.ring_buffer_length_bytes/int(float.sizeof);

    if (stbir_info.ring_buffer_begin_index >= 0)
    {
        // Get rid of whatever we don't need anymore.
        while (first_necessary_scanline > stbir_info.ring_buffer_first_scanline)
        {
            if (stbir_info.ring_buffer_first_scanline >= 0 && stbir_info.ring_buffer_first_scanline < stbir_info.output_h)
            {
                int output_row_start = stbir_info.ring_buffer_first_scanline * output_stride_bytes;
                float* ring_buffer_entry = stbir__get_ring_buffer_entry(ring_buffer, stbir_info.ring_buffer_begin_index, ring_buffer_length);
                stbir__encode_scanline(stbir_info, output_w, cast(char*) output_data + output_row_start, ring_buffer_entry, channels, alpha_channel, decode);
                                                                                                           {}
            }

            if (stbir_info.ring_buffer_first_scanline == stbir_info.ring_buffer_last_scanline)
            {
                // We just popped the last scanline off the ring buffer.
                // Reset it to the empty state.
                stbir_info.ring_buffer_begin_index = -1;
                stbir_info.ring_buffer_first_scanline = 0;
                stbir_info.ring_buffer_last_scanline = 0;
                break;
            }
            else
            {
                stbir_info.ring_buffer_first_scanline++;
                stbir_info.ring_buffer_begin_index = (stbir_info.ring_buffer_begin_index + 1) % stbir_info.ring_buffer_num_entries;
            }
        }
    }
}

private void stbir__buffer_loop_downsample(stbir__info* stbir_info)
{
    int y = void;
    float scale_ratio = stbir_info.vertical_scale;
    int output_h = stbir_info.output_h;
    float in_pixels_radius = stbir__filter_info_table[stbir_info.vertical_filter].support(scale_ratio) / scale_ratio;
    int pixel_margin = stbir_info.vertical_filter_pixel_margin;
    int max_y = stbir_info.input_h + pixel_margin;

    assert(!stbir__use_height_upsampling(stbir_info));

    for (y = -pixel_margin; y < max_y; y++)
    {
        float out_center_of_in = void; // Center of the current out scanline in the in scanline space
        int out_first_scanline = void, out_last_scanline = void;

        stbir__calculate_sample_range_downsample(y, in_pixels_radius, scale_ratio, stbir_info.vertical_shift, &out_first_scanline, &out_last_scanline, &out_center_of_in);

        assert(out_last_scanline - out_first_scanline + 1 <= stbir_info.ring_buffer_num_entries);

        if (out_last_scanline < 0 || out_first_scanline >= output_h)
            continue;

        stbir__empty_ring_buffer(stbir_info, out_first_scanline);

        stbir__decode_and_resample_downsample(stbir_info, y);

        // Load in new ones.
        if (stbir_info.ring_buffer_begin_index < 0)
            stbir__add_empty_ring_buffer_entry(stbir_info, out_first_scanline);

        while (out_last_scanline > stbir_info.ring_buffer_last_scanline)
            stbir__add_empty_ring_buffer_entry(stbir_info, stbir_info.ring_buffer_last_scanline + 1);

        // Now the horizontal buffer is ready to write to all ring buffer rows.
        stbir__resample_vertical_downsample(stbir_info, y);
    }

    stbir__empty_ring_buffer(stbir_info, stbir_info.output_h);
}

private void stbir__setup(stbir__info* info, int input_w, int input_h, int output_w, int output_h, int channels)
{
    info.input_w = input_w;
    info.input_h = input_h;
    info.output_w = output_w;
    info.output_h = output_h;
    info.channels = channels;
}

private void stbir__calculate_transform(stbir__info* info, float s0, float t0, float s1, float t1, float* transform)
{
    info.s0 = s0;
    info.t0 = t0;
    info.s1 = s1;
    info.t1 = t1;

    if (transform)
    {
        info.horizontal_scale = transform[0];
        info.vertical_scale = transform[1];
        info.horizontal_shift = transform[2];
        info.vertical_shift = transform[3];
    }
    else
    {
        info.horizontal_scale = (cast(float)info.output_w / info.input_w) / (s1 - s0);
        info.vertical_scale = (cast(float)info.output_h / info.input_h) / (t1 - t0);

        info.horizontal_shift = s0 * info.output_w / (s1 - s0);
        info.vertical_shift = t0 * info.output_h / (t1 - t0);
    }
}

private void stbir__choose_filter(stbir__info* info, stbir_filter h_filter, stbir_filter v_filter)
{
    if (h_filter == 0)
        h_filter = stbir__use_upsampling(info.horizontal_scale) ? STBIR_FILTER_CATMULLROM : STBIR_FILTER_MITCHELL;
    if (v_filter == 0)
        v_filter = stbir__use_upsampling(info.vertical_scale) ? STBIR_FILTER_CATMULLROM : STBIR_FILTER_MITCHELL;
    info.horizontal_filter = h_filter;
    info.vertical_filter = v_filter;
}

private stbir_uint32 stbir__calculate_memory(stbir__info* info)
{
    int pixel_margin = stbir__get_filter_pixel_margin(info.horizontal_filter, info.horizontal_scale);
    int filter_height = stbir__get_filter_pixel_width(info.vertical_filter, info.vertical_scale);

    info.horizontal_num_contributors = stbir__get_contributors(info.horizontal_scale, info.horizontal_filter, info.input_w, info.output_w);
    info.vertical_num_contributors = stbir__get_contributors(info.vertical_scale , info.vertical_filter , info.input_h, info.output_h);

    // One extra entry because floating point precision problems sometimes cause an extra to be necessary.
    info.ring_buffer_num_entries = filter_height + 1;

    info.horizontal_contributors_size = info.horizontal_num_contributors * int(stbir__contributors.sizeof);
    info.horizontal_coefficients_size = stbir__get_total_horizontal_coefficients(info) * int(float.sizeof);
    info.vertical_contributors_size = info.vertical_num_contributors * int(stbir__contributors.sizeof);
    info.vertical_coefficients_size = stbir__get_total_vertical_coefficients(info) * int(float.sizeof);
    info.decode_buffer_size = (info.input_w + pixel_margin * 2) * info.channels * int(float.sizeof);
    info.horizontal_buffer_size = info.output_w * info.channels * int(float.sizeof);
    info.ring_buffer_size = info.output_w * info.channels * info.ring_buffer_num_entries * int(float.sizeof);
    info.encode_buffer_size = info.output_w * info.channels * int(float.sizeof);

    assert(info.horizontal_filter != 0);
    assert(info.horizontal_filter < stbir__filter_info_table.length); // this now happens too late
    assert(info.vertical_filter != 0);
    assert(info.vertical_filter < stbir__filter_info_table.length); // this now happens too late

    if (stbir__use_height_upsampling(info))
        // The horizontal buffer is for when we're downsampling the height and we
        // can't output the result of sampling the decode buffer directly into the
        // ring buffers.
        info.horizontal_buffer_size = 0;
    else
        // The encode buffer is to retain precision in the height upsampling method
        // and isn't used when height downsampling.
        info.encode_buffer_size = 0;

    return info.horizontal_contributors_size + info.horizontal_coefficients_size
        + info.vertical_contributors_size + info.vertical_coefficients_size
        + info.decode_buffer_size + info.horizontal_buffer_size
        + info.ring_buffer_size + info.encode_buffer_size;
}

private int stbir__resize_allocated(stbir__info* info, const(void)* input_data, int input_stride_in_bytes, void* output_data, int output_stride_in_bytes, int alpha_channel, stbir_uint32 flags, stbir_datatype type, stbir_edge edge_horizontal, stbir_edge edge_vertical, stbir_colorspace colorspace, void* tempmem, size_t tempmem_size_in_bytes)
{
    size_t memory_required = stbir__calculate_memory(info);

    int width_stride_input = input_stride_in_bytes ? input_stride_in_bytes : info.channels * info.input_w * stbir__type_size[type];
    int width_stride_output = output_stride_in_bytes ? output_stride_in_bytes : info.channels * info.output_w * stbir__type_size[type];

version (STBIR_DEBUG_OVERWRITE_TEST) {
}

    assert(info.channels >= 0);
    assert(info.channels <= 64);

    if (info.channels < 0 || info.channels > 64)
        return 0;

    assert(info.horizontal_filter < stbir__filter_info_table.length);
    assert(info.vertical_filter < stbir__filter_info_table.length);

    if (info.horizontal_filter >= stbir__filter_info_table.length)
        return 0;
    if (info.vertical_filter >= stbir__filter_info_table.length)
        return 0;

    if (alpha_channel < 0)
        flags |= (1 << 1) | (1 << 0);

    if (!(flags&(1 << 1)) || !(flags&(1 << 0))) {
        assert(alpha_channel >= 0 && alpha_channel < info.channels);
    }

    if (alpha_channel >= info.channels)
        return 0;

    assert(tempmem);

    if (!tempmem)
        return 0;

    assert(tempmem_size_in_bytes >= memory_required);

    if (tempmem_size_in_bytes < memory_required)
        return 0;

    memset(tempmem, 0, tempmem_size_in_bytes);

    info.input_data = input_data;
    info.input_stride_bytes = width_stride_input;

    info.output_data = output_data;
    info.output_stride_bytes = width_stride_output;

    info.alpha_channel = alpha_channel;
    info.flags = flags;
    info.type = type;
    info.edge_horizontal = edge_horizontal;
    info.edge_vertical = edge_vertical;
    info.colorspace = colorspace;

    info.horizontal_coefficient_width = stbir__get_coefficient_width (info.horizontal_filter, info.horizontal_scale);
    info.vertical_coefficient_width = stbir__get_coefficient_width (info.vertical_filter , info.vertical_scale );
    info.horizontal_filter_pixel_width = stbir__get_filter_pixel_width (info.horizontal_filter, info.horizontal_scale);
    info.vertical_filter_pixel_width = stbir__get_filter_pixel_width (info.vertical_filter , info.vertical_scale );
    info.horizontal_filter_pixel_margin = stbir__get_filter_pixel_margin(info.horizontal_filter, info.horizontal_scale);
    info.vertical_filter_pixel_margin = stbir__get_filter_pixel_margin(info.vertical_filter , info.vertical_scale );

    info.ring_buffer_length_bytes = info.output_w * info.channels * int(float.sizeof);
    info.decode_buffer_pixels = info.input_w + info.horizontal_filter_pixel_margin * 2;

enum string STBIR__NEXT_MEMPTR(string current, string newtype) = ` (newtype*)(((unsigned char*)current) + current##_size)`;


    info.horizontal_contributors = cast(stbir__contributors*) tempmem;
    info.horizontal_coefficients = cast(float*)((cast(ubyte*)info.horizontal_contributors) + info.horizontal_contributors_size);
    info.vertical_contributors = cast(stbir__contributors*)((cast(ubyte*)info.horizontal_coefficients) + info.horizontal_coefficients_size);
    info.vertical_coefficients = cast(float*)((cast(ubyte*)info.vertical_contributors) + info.vertical_contributors_size);
    info.decode_buffer = cast(float*)((cast(ubyte*)info.vertical_coefficients) + info.vertical_coefficients_size);

    if (stbir__use_height_upsampling(info))
    {
        info.horizontal_buffer = null;
        info.ring_buffer = cast(float*)((cast(ubyte*)info.decode_buffer) + info.decode_buffer_size);
        info.encode_buffer = cast(float*)((cast(ubyte*)info.ring_buffer) + info.ring_buffer_size);

        assert(cast(size_t)cast(ubyte*)((cast(ubyte*)info.encode_buffer) + info.encode_buffer_size) == cast(size_t)tempmem + tempmem_size_in_bytes);
    }
    else
    {
        info.horizontal_buffer = cast(float*)((cast(ubyte*)info.decode_buffer) + info.decode_buffer_size);
        info.ring_buffer = cast(float*)((cast(ubyte*)info.horizontal_buffer) + info.horizontal_buffer_size);
        info.encode_buffer = null;

        assert(cast(size_t)cast(ubyte*)((cast(ubyte*)info.ring_buffer) + info.ring_buffer_size) == cast(size_t)tempmem + tempmem_size_in_bytes);
    }

    // This signals that the ring buffer is empty
    info.ring_buffer_begin_index = -1;

    stbir__calculate_filters(info.horizontal_contributors, info.horizontal_coefficients, info.horizontal_filter, info.horizontal_scale, info.horizontal_shift, info.input_w, info.output_w);
    stbir__calculate_filters(info.vertical_contributors, info.vertical_coefficients, info.vertical_filter, info.vertical_scale, info.vertical_shift, info.input_h, info.output_h);

                            {}

    if (stbir__use_height_upsampling(info))
        stbir__buffer_loop_upsample(info);
    else
        stbir__buffer_loop_downsample(info);

                            {}

version (STBIR_DEBUG_OVERWRITE_TEST) {








}

    return 1;
}


private int stbir__resize_arbitrary(void* alloc_context, const(void)* input_data, int input_w, int input_h, int input_stride_in_bytes, void* output_data, int output_w, int output_h, int output_stride_in_bytes, float s0, float t0, float s1, float t1, float* transform, int channels, int alpha_channel, stbir_uint32 flags, stbir_datatype type, stbir_filter h_filter, stbir_filter v_filter, stbir_edge edge_horizontal, stbir_edge edge_vertical, stbir_colorspace colorspace)
{
    stbir__info info = void;
    int result = void;
    size_t memory_required = void;
    void* extra_memory = void;

    stbir__setup(&info, input_w, input_h, output_w, output_h, channels);
    stbir__calculate_transform(&info, s0,t0,s1,t1,transform);
    stbir__choose_filter(&info, h_filter, v_filter);
    memory_required = stbir__calculate_memory(&info);
    extra_memory = malloc(memory_required);

    if (!extra_memory)
        return 0;

    result = stbir__resize_allocated(&info, input_data, input_stride_in_bytes,
                                            output_data, output_stride_in_bytes,
                                            alpha_channel, flags, type,
                                            edge_horizontal, edge_vertical,
                                            colorspace, extra_memory, memory_required);

    (cast(void)(alloc_context), free(extra_memory));

    return result;
}

extern int stbir_resize_uint8(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels)
{
    return stbir__resize_arbitrary(null, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,-1,0, STBIR_TYPE_UINT8, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_LINEAR);
}

extern int stbir_resize_float(const(float)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, float* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels)
{
    return stbir__resize_arbitrary(null, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,-1,0, STBIR_TYPE_FLOAT, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_LINEAR);
}

extern int stbir_resize_uint8_srgb(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags)
{
    return stbir__resize_arbitrary(null, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,alpha_channel,flags, STBIR_TYPE_UINT8, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB);
}

extern int stbir_resize_uint8_srgb_edgemode(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode)
{
    return stbir__resize_arbitrary(null, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,alpha_channel,flags, STBIR_TYPE_UINT8, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        edge_wrap_mode, edge_wrap_mode, STBIR_COLORSPACE_SRGB);
}

extern int stbir_resize_uint8_generic(const(ubyte)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, ubyte* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, void* alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,alpha_channel,flags, STBIR_TYPE_UINT8, filter, filter,
        edge_wrap_mode, edge_wrap_mode, space);
}

extern int stbir_resize_uint16_generic(const(stbir_uint16)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, stbir_uint16* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, void* alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,alpha_channel,flags, STBIR_TYPE_UINT16, filter, filter,
        edge_wrap_mode, edge_wrap_mode, space);
}


extern int stbir_resize_float_generic(const(float)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, float* output_pixels, int output_w, int output_h, int output_stride_in_bytes, int num_channels, int alpha_channel, int flags, stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, void* alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,alpha_channel,flags, STBIR_TYPE_FLOAT, filter, filter,
        edge_wrap_mode, edge_wrap_mode, space);
}


extern int stbir_resize(const(void)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, void* output_pixels, int output_w, int output_h, int output_stride_in_bytes, stbir_datatype datatype, int num_channels, int alpha_channel, int flags, stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, stbir_filter filter_horizontal, stbir_filter filter_vertical, stbir_colorspace space, void* alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,null,num_channels,alpha_channel,flags, datatype, filter_horizontal, filter_vertical,
        edge_mode_horizontal, edge_mode_vertical, space);
}


extern int stbir_resize_subpixel(const(void)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, void* output_pixels, int output_w, int output_h, int output_stride_in_bytes, stbir_datatype datatype, int num_channels, int alpha_channel, int flags, stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, stbir_filter filter_horizontal, stbir_filter filter_vertical, stbir_colorspace space, void* alloc_context, float x_scale, float y_scale, float x_offset, float y_offset)
{
    float[4] transform = void;
    transform[0] = x_scale;
    transform[1] = y_scale;
    transform[2] = x_offset;
    transform[3] = y_offset;
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,transform.ptr,num_channels,alpha_channel,flags, datatype, filter_horizontal, filter_vertical,
        edge_mode_horizontal, edge_mode_vertical, space);
}

extern int stbir_resize_region(const(void)* input_pixels, int input_w, int input_h, int input_stride_in_bytes, void* output_pixels, int output_w, int output_h, int output_stride_in_bytes, stbir_datatype datatype, int num_channels, int alpha_channel, int flags, stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, stbir_filter filter_horizontal, stbir_filter filter_vertical, stbir_colorspace space, void* alloc_context, float s0, float t0, float s1, float t1)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        s0,t0,s1,t1,null,num_channels,alpha_channel,flags, datatype, filter_horizontal, filter_vertical,
        edge_mode_horizontal, edge_mode_vertical, space);
}

} // STB_IMAGE_RESIZE_IMPLEMENTATION


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