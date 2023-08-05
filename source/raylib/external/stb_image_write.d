module raylib.external.stb_image_write;
@nogc nothrow:
extern(C): __gshared:

private template HasVersion(string versionId) {
	mixin("version("~versionId~") {enum HasVersion = true;} else {enum HasVersion = false;}");
}
version = STB_IMAGE_WRITE_IMPLEMENTATION;

/* stb_image_write - v1.16 - public domain - http://nothings.org/stb
   writes out PNG/BMP/TGA/JPEG/HDR images to C stdio - Sean Barrett 2010-2015
                                     no warranty implied; use at your own risk

   Before #including,

       #define STB_IMAGE_WRITE_IMPLEMENTATION

   in the file that you want to have the implementation.

   Will probably not work correctly with strict-aliasing optimizations.

ABOUT:

   This header file is a library for writing images to C stdio or a callback.

   The PNG output is not optimal; it is 20-50% larger than the file
   written by a decent optimizing implementation; though providing a custom
   zlib compress function (see STBIW_ZLIB_COMPRESS) can mitigate that.
   This library is designed for source code compactness and simplicity,
   not optimal image file size or run-time performance.

BUILDING:

   You can #define STBIW_ASSERT(x) before the #include to avoid using assert.h.
   You can #define STBIW_MALLOC(), STBIW_REALLOC(), and STBIW_FREE() to replace
   malloc,realloc,free.
   You can #define STBIW_MEMMOVE() to replace memmove()
   You can #define STBIW_ZLIB_COMPRESS to use a custom zlib-style compress function
   for PNG compression (instead of the builtin one), it must have the following signature:
   unsigned char * my_compress(unsigned char *data, int data_len, int *out_len, int quality);
   The returned data will be freed with STBIW_FREE() (free() by default),
   so it must be heap allocated with STBIW_MALLOC() (malloc() by default),

UNICODE:

   If compiling for Windows and you wish to use Unicode filenames, compile
   with
       #define STBIW_WINDOWS_UTF8
   and pass utf8-encoded filenames. Call stbiw_convert_wchar_to_utf8 to convert
   Windows wchar_t filenames to utf8.

USAGE:

   There are five functions, one for each image file format:

     int stbi_write_png(char const *filename, int w, int h, int comp, const void *data, int stride_in_bytes);
     int stbi_write_bmp(char const *filename, int w, int h, int comp, const void *data);
     int stbi_write_tga(char const *filename, int w, int h, int comp, const void *data);
     int stbi_write_jpg(char const *filename, int w, int h, int comp, const void *data, int quality);
     int stbi_write_hdr(char const *filename, int w, int h, int comp, const float *data);

     void stbi_flip_vertically_on_write(int flag); // flag is non-zero to flip data vertically

   There are also five equivalent functions that use an arbitrary write function. You are
   expected to open/close your file-equivalent before and after calling these:

     int stbi_write_png_to_func(stbi_write_func *func, void *context, int w, int h, int comp, const void  *data, int stride_in_bytes);
     int stbi_write_bmp_to_func(stbi_write_func *func, void *context, int w, int h, int comp, const void  *data);
     int stbi_write_tga_to_func(stbi_write_func *func, void *context, int w, int h, int comp, const void  *data);
     int stbi_write_hdr_to_func(stbi_write_func *func, void *context, int w, int h, int comp, const float *data);
     int stbi_write_jpg_to_func(stbi_write_func *func, void *context, int x, int y, int comp, const void *data, int quality);

   where the callback is:
      void stbi_write_func(void *context, void *data, int size);

   You can configure it with these global variables:
      int stbi_write_tga_with_rle;             // defaults to true; set to 0 to disable RLE
      int stbi_write_png_compression_level;    // defaults to 8; set to higher for more compression
      int stbi_write_force_png_filter;         // defaults to -1; set to 0..5 to force a filter mode


   You can define STBI_WRITE_NO_STDIO to disable the file variant of these
   functions, so the library will not use stdio.h at all. However, this will
   also disable HDR writing, because it requires stdio for formatted output.

   Each function returns 0 on failure and non-0 on success.

   The functions create an image file defined by the parameters. The image
   is a rectangle of pixels stored from left-to-right, top-to-bottom.
   Each pixel contains 'comp' channels of data stored interleaved with 8-bits
   per channel, in the following order: 1=Y, 2=YA, 3=RGB, 4=RGBA. (Y is
   monochrome color.) The rectangle is 'w' pixels wide and 'h' pixels tall.
   The *data pointer points to the first byte of the top-left-most pixel.
   For PNG, "stride_in_bytes" is the distance in bytes from the first byte of
   a row of pixels to the first byte of the next row of pixels.

   PNG creates output files with the same number of components as the input.
   The BMP format expands Y to RGB in the file format and does not
   output alpha.

   PNG supports writing rectangles of data even when the bytes storing rows of
   data are not consecutive in memory (e.g. sub-rectangles of a larger image),
   by supplying the stride between the beginning of adjacent rows. The other
   formats do not. (Thus you cannot write a native-format BMP through the BMP
   writer, both because it is in BGR order and because it may have padding
   at the end of the line.)

   PNG allows you to set the deflate compression level by setting the global
   variable 'stbi_write_png_compression_level' (it defaults to 8).

   HDR expects linear float data. Since the format is always 32-bit rgb(e)
   data, alpha (if provided) is discarded, and for monochrome data it is
   replicated across all three channels.

   TGA supports RLE or non-RLE compressed data. To use non-RLE-compressed
   data, set the global variable 'stbi_write_tga_with_rle' to 0.

   JPEG does ignore alpha channels in input data; quality is between 1 and 100.
   Higher quality looks better but results in a bigger image.
   JPEG baseline (no JPEG progressive).

CREDITS:


   Sean Barrett           -    PNG/BMP/TGA
   Baldur Karlsson        -    HDR
   Jean-Sebastien Guay    -    TGA monochrome
   Tim Kelsey             -    misc enhancements
   Alan Hickman           -    TGA RLE
   Emmanuel Julien        -    initial file IO callback implementation
   Jon Olick              -    original jo_jpeg.cpp code
   Daniel Gibson          -    integrate JPEG, allow external zlib
   Aarni Koskela          -    allow choosing PNG filter

   bugfixes:
      github:Chribba
      Guillaume Chereau
      github:jry2
      github:romigrou
      Sergio Gonzalez
      Jonas Karlsson
      Filip Wasil
      Thatcher Ulrich
      github:poppolopoppo
      Patrick Boettcher
      github:xeekworx
      Cap Petschulat
      Simon Rodriguez
      Ivan Tikhonov
      github:ignotion
      Adam Schackart
      Andrew Kensler

LICENSE

  See end of file for license information.

*/

 

public import core.stdc.stdlib;

version (STBI_WRITE_NO_STDIO) {} else {

extern int stbi_write_png(const(char)* filename, int w, int h, int comp, const(void)* data, int stride_in_bytes);
extern int stbi_write_bmp(const(char)* filename, int w, int h, int comp, const(void)* data);
extern int stbi_write_tga(const(char)* filename, int w, int h, int comp, const(void)* data);
extern int stbi_write_hdr(const(char)* filename, int w, int h, int comp, const(float)* data);
extern int stbi_write_jpg(const(char)* filename, int x, int y, int comp, const(void)* data, int quality);

version (STBIW_WINDOWS_UTF8) {





}
}


alias stbi_write_func = void function(void *context, void *data, int size);

extern int stbi_write_png_to_func(stbi_write_func func, void* context, int w, int h, int comp, const(void)* data, int stride_in_bytes);
extern int stbi_write_bmp_to_func(stbi_write_func func, void* context, int w, int h, int comp, const(void)* data);
extern int stbi_write_tga_to_func(stbi_write_func func, void* context, int w, int h, int comp, const(void)* data);
extern int stbi_write_hdr_to_func(stbi_write_func func, void* context, int w, int h, int comp, const(float)* data);
extern int stbi_write_jpg_to_func(stbi_write_func func, void* context, int x, int y, int comp, const(void)* data, int quality);

extern void stbi_flip_vertically_on_write(int flip_boolean);

//INCLUDE_STB_IMAGE_WRITE_H


version (STB_IMAGE_WRITE_IMPLEMENTATION) {


version (Windows) {
}

version (STBI_WRITE_NO_STDIO) {} else {

public import core.stdc.stdio;
} // STBI_WRITE_NO_STDIO


public import core.stdc.stdarg;
public import core.stdc.stdlib;

public import core.stdc.string;
public import core.stdc.math;

static if (HasVersion!"STBIW_MALLOC" && HasVersion!"STBIW_FREE" && (HasVersion!"STBIW_REALLOC" || HasVersion!"STBIW_REALLOC_SIZED")) {





} else static if (!HasVersion!"STBIW_MALLOC" && !HasVersion!"STBIW_FREE" && !HasVersion!"STBIW_REALLOC" && !HasVersion!"STBIW_REALLOC_SIZED") {
// ok
} else {







}

version (STBIW_MALLOC) {} else {

enum string STBIW_MALLOC(string sz) = `        malloc(sz)`;

enum string STBIW_REALLOC(string p,string newsz) = `  realloc(p,newsz)`;

enum string STBIW_FREE(string p) = `           free(p)`;

}


version (STBIW_REALLOC_SIZED) {} else {

enum string STBIW_REALLOC_SIZED(string p,string oldsz,string newsz) = ` STBIW_REALLOC(p,newsz)`;

}



version (STBIW_MEMMOVE) {} else {

enum string STBIW_MEMMOVE(string a,string b,string sz) = ` memmove(a,b,sz)`;

}



version (STBIW_ASSERT) {} else {

public import core.stdc.assert_;
enum string STBIW_ASSERT(string x) = ` assert(x)`;

}


enum string STBIW_UCHAR(string x) = ` (unsigned char) ((x) & 0xff)`;


version (STB_IMAGE_WRITE_STATIC) {







} else {
int stbi_write_png_compression_level = 8;
int stbi_write_tga_with_rle = 1;
int stbi_write_force_png_filter = -1;
}


private int stbi__flip_vertically_on_write = 0;

extern void stbi_flip_vertically_on_write(int flag)
{
   stbi__flip_vertically_on_write = flag;
}

struct _Stbi__write_context {
   stbi_write_func func;
   void* context;
   ubyte[64] buffer;
   int buf_used;
}alias stbi__write_context = _Stbi__write_context;

// initialize a callback-based context
private void stbi__start_write_callbacks(stbi__write_context* s, stbi_write_func c, void* context)
{
   s.func = c;
   s.context = context;
}

version (STBI_WRITE_NO_STDIO) {} else {


private void stbi__stdio_write(void* context, void* data, int size)
{
   fwrite(data,1,size,cast(FILE*) context);
}

static if (HasVersion!"Windows" && HasVersion!"STBIW_WINDOWS_UTF8") {
}

private FILE* stbiw__fopen(const(char)* filename, const(char)* mode)
{
   FILE* f = void;
static if (HasVersion!"Windows" && HasVersion!"STBIW_WINDOWS_UTF8") {
} else {
   f = fopen(filename, mode);
}

   return f;
}

private int stbi__start_write_file(stbi__write_context* s, const(char)* filename)
{
   FILE* f = stbiw__fopen(filename, "wb");
   stbi__start_write_callbacks(s, &stbi__stdio_write, cast(void*) f);
   return f != null;
}

private void stbi__end_write_file(stbi__write_context* s)
{
   fclose(cast(FILE*)s.context);
}

} // !STBI_WRITE_NO_STDIO


alias stbiw_uint32 = uint;
alias stb_image_write_test = int[stbiw_uint32.sizeof==4 ? 1 : -1];

private void stbiw__writefv(stbi__write_context* s, const(char)* fmt, va_list v)
{
   while (*fmt) {
      switch (*fmt++) {
         case ' ': break;
         case '1': { ubyte x = cast(ubyte) ((va_arg!int(v)) & 0xff);
                     s.func(s.context,&x,1);
                     break; }
         case '2': { int x = va_arg!int(v);
                     ubyte[2] b = void;
                     b[0] = cast(ubyte) ((x) & 0xff);
                     b[1] = cast(ubyte) ((x>>8) & 0xff);
                     s.func(s.context,b.ptr,2);
                     break; }
         case '4': { stbiw_uint32 x = va_arg!int(v);
                     ubyte[4] b = void;
                     b[0]=cast(ubyte) ((x) & 0xff);
                     b[1]=cast(ubyte) ((x>>8) & 0xff);
                     b[2]=cast(ubyte) ((x>>16) & 0xff);
                     b[3]=cast(ubyte) ((x>>24) & 0xff);
                     s.func(s.context,b.ptr,4);
                     break; }
         default:
            assert(0);
            //return;
      }
   }
}

private void stbiw__writef(stbi__write_context* s, const(char)* fmt, ...)
{
   va_list v = void;
   va_start(v, fmt);
   stbiw__writefv(s, fmt, v);
   va_end(v);
}

private void stbiw__write_flush(stbi__write_context* s)
{
   if (s.buf_used) {
      s.func(s.context, &s.buffer, s.buf_used);
      s.buf_used = 0;
   }
}

private void stbiw__putc(stbi__write_context* s, ubyte c)
{
   s.func(s.context, &c, 1);
}

private void stbiw__write1(stbi__write_context* s, ubyte a)
{
   if (cast(size_t)s.buf_used + 1 > typeof(s.buffer).sizeof)
      stbiw__write_flush(s);
   s.buffer[s.buf_used++] = a;
}

private void stbiw__write3(stbi__write_context* s, ubyte a, ubyte b, ubyte c)
{
   int n = void;
   if (cast(size_t)s.buf_used + 3 > typeof(s.buffer).sizeof)
      stbiw__write_flush(s);
   n = s.buf_used;
   s.buf_used = n+3;
   s.buffer[n+0] = a;
   s.buffer[n+1] = b;
   s.buffer[n+2] = c;
}

private void stbiw__write_pixel(stbi__write_context* s, int rgb_dir, int comp, int write_alpha, int expand_mono, ubyte* d)
{
   ubyte[3] bg = [ 255, 0, 255], px = void;
   int k = void;

   if (write_alpha < 0)
      stbiw__write1(s, d[comp - 1]);

   switch (comp) {
      case 2: // 2 pixels = mono + alpha, alpha is written separately, so same as 1-channel case
      case 1:
         if (expand_mono)
            stbiw__write3(s, d[0], d[0], d[0]); // monochrome bmp
         else
            stbiw__write1(s, d[0]); // monochrome TGA
         break;
      case 4:
         if (!write_alpha) {
            // composite against pink background
            for (k = 0; k < 3; ++k)
               px[k] = cast(ubyte)(bg[k] + ((d[k] - bg[k]) * d[3]) / 255);
            stbiw__write3(s, px[1 - rgb_dir], px[1], px[1 + rgb_dir]);
            break;
         }
         goto case;/* FALLTHROUGH */
      case 3:
         stbiw__write3(s, d[1 - rgb_dir], d[1], d[1 + rgb_dir]);
         break;
   default: break;}
   if (write_alpha > 0)
      stbiw__write1(s, d[comp - 1]);
}

private void stbiw__write_pixels(stbi__write_context* s, int rgb_dir, int vdir, int x, int y, int comp, void* data, int write_alpha, int scanline_pad, int expand_mono)
{
   stbiw_uint32 zero = 0;
   int i = void, j = void, j_end = void;

   if (y <= 0)
      return;

   if (stbi__flip_vertically_on_write)
      vdir *= -1;

   if (vdir < 0) {
      j_end = -1; j = y-1;
   } else {
      j_end = y; j = 0;
   }

   for (; j != j_end; j += vdir) {
      for (i=0; i < x; ++i) {
         ubyte* d = cast(ubyte*) data + (j*x+i)*comp;
         stbiw__write_pixel(s, rgb_dir, comp, write_alpha, expand_mono, d);
      }
      stbiw__write_flush(s);
      s.func(s.context, &zero, scanline_pad);
   }
}

private int stbiw__outfile(stbi__write_context* s, int rgb_dir, int vdir, int x, int y, int comp, int expand_mono, void* data, int alpha, int pad, const(char)* fmt, ...)
{
   if (y < 0 || x < 0) {
      return 0;
   } else {
      va_list v = void;
      va_start(v, fmt);
      stbiw__writefv(s, fmt, v);
      va_end(v);
      stbiw__write_pixels(s,rgb_dir,vdir,x,y,comp,data,alpha,pad, expand_mono);
      return 1;
   }
}

private int stbi_write_bmp_core(stbi__write_context* s, int x, int y, int comp, const(void)* data)
{
   if (comp != 4) {
      // write RGB bitmap
      int pad = (-x*3) & 3;
      return stbiw__outfile(s,-1,-1,x,y,comp,1,cast(void*) data,0,pad,
              "11 4 22 4" ~ "4 44 22 444444",
              'B', 'M', 14+40+(x*3+pad)*y, 0,0, 14+40, // file header
               40, x,y, 1,24, 0,0,0,0,0,0); // bitmap header
   } else {
      // RGBA bitmaps need a v4 header
      // use BI_BITFIELDS mode with 32bpp and alpha mask
      // (straight BI_RGB with alpha mask doesn't work in most readers)
      return stbiw__outfile(s,-1,-1,x,y,comp,1,cast(void*)data,1,0,
         "11 4 22 4" ~ "4 44 22 444444 4444 4 444 444 444 444",
         'B', 'M', 14+108+x*y*4, 0, 0, 14+108, // file header
         108, x,y, 1,32, 3,0,0,0,0,0, 0xff0000,0xff00,0xff,0xff000000u, 0, 0,0,0, 0,0,0, 0,0,0, 0,0,0); // bitmap V4 header
   }
}

extern int stbi_write_bmp_to_func(stbi_write_func func, void* context, int x, int y, int comp, const(void)* data)
{
   auto s = stbi__write_context.init; // = { 0 };
   stbi__start_write_callbacks(&s, func, context);
   return stbi_write_bmp_core(&s, x, y, comp, data);
}

version (STBI_WRITE_NO_STDIO) {} else {

extern int stbi_write_bmp(const(char)* filename, int x, int y, int comp, const(void)* data)
{
   auto s = stbi__write_context.init; // = { 0 };
   if (stbi__start_write_file(&s,filename)) {
      int r = stbi_write_bmp_core(&s, x, y, comp, data);
      stbi__end_write_file(&s);
      return r;
   } else
      return 0;
}
} //!STBI_WRITE_NO_STDIO


private int stbi_write_tga_core(stbi__write_context* s, int x, int y, int comp, void* data)
{
   int has_alpha = (comp == 2 || comp == 4);
   int colorbytes = has_alpha ? comp-1 : comp;
   int format = colorbytes < 2 ? 3 : 2; // 3 color channels (RGB/RGBA) = 2, 1 color channel (Y/YA) = 3

   if (y < 0 || x < 0)
      return 0;

   if (!stbi_write_tga_with_rle) {
      return stbiw__outfile(s, -1, -1, x, y, comp, 0, cast(void*) data, has_alpha, 0,
         "111 221 2222 11", 0, 0, format, 0, 0, 0, 0, 0, x, y, (colorbytes + has_alpha) * 8, has_alpha * 8);
   } else {
      int i = void, j = void, k = void;
      int jend = void, jdir = void;

      stbiw__writef(s, "111 221 2222 11", 0,0,format+8, 0,0,0, 0,0,x,y, (colorbytes + has_alpha) * 8, has_alpha * 8);

      if (stbi__flip_vertically_on_write) {
         j = 0;
         jend = y;
         jdir = 1;
      } else {
         j = y-1;
         jend = -1;
         jdir = -1;
      }
      for (; j != jend; j += jdir) {
         ubyte* row = cast(ubyte*) data + j * x * comp;
         int len = void;

         for (i = 0; i < x; i += len) {
            ubyte* begin = row + i * comp;
            int diff = 1;
            len = 1;

            if (i < x - 1) {
               ++len;
               diff = memcmp(begin, row + (i + 1) * comp, comp);
               if (diff) {
                  const(ubyte)* prev = begin;
                  for (k = i + 2; k < x && len < 128; ++k) {
                     if (memcmp(prev, row + k * comp, comp)) {
                        prev += comp;
                        ++len;
                     } else {
                        --len;
                        break;
                     }
                  }
               } else {
                  for (k = i + 2; k < x && len < 128; ++k) {
                     if (!memcmp(begin, row + k * comp, comp)) {
                        ++len;
                     } else {
                        break;
                     }
                  }
               }
            }

            if (diff) {
               ubyte header = cast(ubyte) ((len - 1) & 0xff);
               stbiw__write1(s, header);
               for (k = 0; k < len; ++k) {
                  stbiw__write_pixel(s, -1, comp, has_alpha, 0, begin + k * comp);
               }
            } else {
               ubyte header = cast(ubyte) ((len - 129) & 0xff);
               stbiw__write1(s, header);
               stbiw__write_pixel(s, -1, comp, has_alpha, 0, begin);
            }
         }
      }
      stbiw__write_flush(s);
   }
   return 1;
}

extern int stbi_write_tga_to_func(stbi_write_func func, void* context, int x, int y, int comp, const(void)* data)
{
   auto s = stbi__write_context.init; // = { 0 };
   stbi__start_write_callbacks(&s, func, context);
   return stbi_write_tga_core(&s, x, y, comp, cast(void*) data);
}

version (STBI_WRITE_NO_STDIO) {} else {

extern int stbi_write_tga(const(char)* filename, int x, int y, int comp, const(void)* data)
{
   auto s = stbi__write_context.init; // = { 0 };
   if (stbi__start_write_file(&s,filename)) {
      int r = stbi_write_tga_core(&s, x, y, comp, cast(void*) data);
      stbi__end_write_file(&s);
      return r;
   } else
      return 0;
}
}


// *************************************************************************************************
// Radiance RGBE HDR writer
// by Baldur Karlsson

enum string stbiw__max(string a, string b) = `  ((a) > (b) ? (a) : (b))`;


version (STBI_WRITE_NO_STDIO) {} else {


private void stbiw__linear_to_rgbe(ubyte* rgbe, float* linear)
{
   int exponent = void;
   float maxcomp = ((linear[0]) > (((linear[1]) > (linear[2]) ? (linear[1]) : (linear[2]))) ? (linear[0]) : (((linear[1]) > (linear[2]) ? (linear[1]) : (linear[2]))));

   if (maxcomp < 1e-32f) {
      rgbe[0] = rgbe[1] = rgbe[2] = rgbe[3] = 0;
   } else {
      float normalize = cast(float) frexp(maxcomp, &exponent) * 256.0f/maxcomp;

      rgbe[0] = cast(ubyte)(linear[0] * normalize);
      rgbe[1] = cast(ubyte)(linear[1] * normalize);
      rgbe[2] = cast(ubyte)(linear[2] * normalize);
      rgbe[3] = cast(ubyte)(exponent + 128);
   }
}

private void stbiw__write_run_data(stbi__write_context* s, int length, ubyte databyte)
{
   ubyte lengthbyte = cast(ubyte) ((length+128) & 0xff);
   assert(length+128 <= 255);
   s.func(s.context, &lengthbyte, 1);
   s.func(s.context, &databyte, 1);
}

private void stbiw__write_dump_data(stbi__write_context* s, int length, ubyte* data)
{
   ubyte lengthbyte = cast(ubyte) ((length) & 0xff);
   assert(length <= 128); // inconsistent with spec but consistent with official code
   s.func(s.context, &lengthbyte, 1);
   s.func(s.context, data, length);
}

private void stbiw__write_hdr_scanline(stbi__write_context* s, int width, int ncomp, ubyte* scratch, float* scanline)
{
   ubyte[4] scanlineheader = [ 2, 2, 0, 0 ];
   ubyte[4] rgbe = void;
   float[3] linear = void;
   int x = void;

   scanlineheader[2] = (width&0xff00)>>8;
   scanlineheader[3] = (width&0x00ff);

   /* skip RLE for images too small or large */
   if (width < 8 || width >= 32768) {
      for (x=0; x < width; x++) {
         switch (ncomp) {
            case 4: /* fallthrough */
            case 3: linear[2] = scanline[x*ncomp + 2];
                    linear[1] = scanline[x*ncomp + 1];
                    linear[0] = scanline[x*ncomp + 0];
                    break;
            default:
                    linear[0] = linear[1] = linear[2] = scanline[x*ncomp + 0];
                    break;
         }
         stbiw__linear_to_rgbe(rgbe.ptr, linear.ptr);
         s.func(s.context, rgbe.ptr, 4);
      }
   } else {
      int c = void, r = void;
      /* encode into scratch buffer */
      for (x=0; x < width; x++) {
         switch(ncomp) {
            case 4: /* fallthrough */
            case 3: linear[2] = scanline[x*ncomp + 2];
                    linear[1] = scanline[x*ncomp + 1];
                    linear[0] = scanline[x*ncomp + 0];
                    break;
            default:
                    linear[0] = linear[1] = linear[2] = scanline[x*ncomp + 0];
                    break;
         }
         stbiw__linear_to_rgbe(rgbe.ptr, linear.ptr);
         scratch[x + width*0] = rgbe[0];
         scratch[x + width*1] = rgbe[1];
         scratch[x + width*2] = rgbe[2];
         scratch[x + width*3] = rgbe[3];
      }

      s.func(s.context, scanlineheader.ptr, 4);

      /* RLE each component separately */
      for (c=0; c < 4; c++) {
         ubyte* comp = &scratch[width*c];

         x = 0;
         while (x < width) {
            // find first run
            r = x;
            while (r+2 < width) {
               if (comp[r] == comp[r+1] && comp[r] == comp[r+2])
                  break;
               ++r;
            }
            if (r+2 >= width)
               r = width;
            // dump up to first run
            while (x < r) {
               int len = r-x;
               if (len > 128) len = 128;
               stbiw__write_dump_data(s, len, &comp[x]);
               x += len;
            }
            // if there's a run, output it
            if (r+2 < width) { // same test as what we break out of in search loop, so only true if we break'd
               // find next byte after run
               while (r < width && comp[r] == comp[x])
                  ++r;
               // output run up to r
               while (x < r) {
                  int len = r-x;
                  if (len > 127) len = 127;
                  stbiw__write_run_data(s, len, comp[x]);
                  x += len;
               }
            }
         }
      }
   }
}

private int stbi_write_hdr_core(stbi__write_context* s, int x, int y, int comp, float* data)
{
   if (y <= 0 || x <= 0 || data == null)
      return 0;
   else {
      // Each component is stored separately. Allocate scratch space for full output scanline.
      ubyte* scratch = cast(ubyte*) malloc(x*4);
      int i = void, len = void;
      char[128] buffer = void;
      char["#?RADIANCE\n# Written by stb_image_write.h\nFORMAT=32-bit_rle_rgbe\n".length]
          header = 
          "#?RADIANCE\n# Written by stb_image_write.h\nFORMAT=32-bit_rle_rgbe\n";
      s.func(s.context, header.ptr, header.length);

version (__STDC_LIB_EXT1__) {





} else {
      len = sprintf(buffer.ptr, "EXPOSURE=          1.0000000000000\n\n-Y %d +X %d\n", y, x);
}

      s.func(s.context, buffer.ptr, len);

      for(i=0; i < y; i++)
         stbiw__write_hdr_scanline(s, x, comp, scratch, data + comp*x*(stbi__flip_vertically_on_write ? y-1-i : i));
      free(scratch);
      return 1;
   }
}

extern int stbi_write_hdr_to_func(stbi_write_func func, void* context, int x, int y, int comp, const(float)* data)
{
   auto s = stbi__write_context.init; // = { 0 };
   stbi__start_write_callbacks(&s, func, context);
   return stbi_write_hdr_core(&s, x, y, comp, cast(float*) data);
}

extern int stbi_write_hdr(const(char)* filename, int x, int y, int comp, const(float)* data)
{
   auto s = stbi__write_context.init; // = { 0 };
   if (stbi__start_write_file(&s,filename)) {
      int r = stbi_write_hdr_core(&s, x, y, comp, cast(float*) data);
      stbi__end_write_file(&s);
      return r;
   } else
      return 0;
}
} // STBI_WRITE_NO_STDIO



//////////////////////////////////////////////////////////////////////////////
//
// PNG writer
//

version (STBIW_ZLIB_COMPRESS) {} else {

// stretchy buffer; stbiw__sbpush() == vector<>::push_back() -- stbiw__sbcount() == vector<>::size()
enum string stbiw__sbraw(string a) = ` ((int *) (void *) (a) - 2)`;

enum string stbiw__sbm(string a) = `   stbiw__sbraw(a)[0]`;

enum string stbiw__sbn(string a) = `   stbiw__sbraw(a)[1]`;


enum string stbiw__sbneedgrow(string a,string n) = `  ((a)==0 || stbiw__sbn(a)+n >= stbiw__sbm(a))`;

enum string stbiw__sbmaybegrow(string a,string n) = ` (stbiw__sbneedgrow(a,(n)) ? stbiw__sbgrow(a,n) : 0)`;

enum string stbiw__sbgrow(string a,string n) = `  stbiw__sbgrowf((void **) &(a), (n), sizeof(*(a)))`;


enum string stbiw__sbpush(string a, string v) = `      (stbiw__sbmaybegrow(a,1), (a)[stbiw__sbn(a)++] = (v))`;

enum string stbiw__sbcount(string a) = `        ((a) ? stbiw__sbn(a) : 0)`;

enum string stbiw__sbfree(string a) = `         ((a) ? STBIW_FREE(stbiw__sbraw(a)),0 : 0)`;


private void* stbiw__sbgrowf(void** arr, int increment, int itemsize)
{
   int m = *arr ? 2*(cast(int*) cast(void*) (*arr) - 2)[0]+increment : increment+1;
   void* p = realloc(*arr ? (cast(int*) cast(void*) (*arr) - 2) : null,itemsize * m + int.sizeof *2);
   assert(p);
   if (p) {
      if (!*arr) (cast(int*) p)[1] = 0;
      *arr = cast(void*) (cast(int*) p + 2);
      (cast(int*) cast(void*) (*arr) - 2)[0] = m;
   }
   return *arr;
}

private ubyte* stbiw__zlib_flushf(ubyte* data, uint* bitbuffer, int* bitcount)
{
   while (*bitcount >= 8) {
      ((((data)==null || (cast(int*) cast(void*) (data) - 2)[1]+(1) >= (cast(int*) cast(void*) (data) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(data), (1), typeof(*(data)).sizeof) : null), (data)[(cast(int*) cast(void*) (data) - 2)[1]++] = (cast(ubyte) ((*bitbuffer) & 0xff)));
      *bitbuffer >>= 8;
      *bitcount -= 8;
   }
   return data;
}

private int stbiw__zlib_bitrev(int code, int codebits)
{
   int res = 0;
   while (codebits--) {
      res = (res << 1) | (code & 1);
      code >>= 1;
   }
   return res;
}

private uint stbiw__zlib_countm(ubyte* a, ubyte* b, int limit)
{
   int i = void;
   for (i=0; i < limit && i < 258; ++i)
      if (a[i] != b[i]) break;
   return i;
}

private uint stbiw__zhash(ubyte* data)
{
   stbiw_uint32 hash = data[0] + (data[1] << 8) + (data[2] << 16);
   hash ^= hash << 3;
   hash += hash >> 5;
   hash ^= hash << 4;
   hash += hash >> 17;
   hash ^= hash << 25;
   hash += hash >> 6;
   return hash;
}

enum string stbiw__zlib_flush() = ` (out = stbiw__zlib_flushf(out, &bitbuf, &bitcount))`;

enum string stbiw__zlib_add(string code,string codebits) = ` \
      (bitbuf |= (code) << bitcount, bitcount += (codebits), stbiw__zlib_flush())`;




enum string stbiw__zlib_huffa(string b,string c) = `  stbiw__zlib_add(stbiw__zlib_bitrev(b,c),c)`;

// default huffman tables
enum string stbiw__zlib_huff1(string n) = `  stbiw__zlib_huffa(0x30 + (n), 8)`;

enum string stbiw__zlib_huff2(string n) = `  stbiw__zlib_huffa(0x190 + (n)-144, 9)`;

enum string stbiw__zlib_huff3(string n) = `  stbiw__zlib_huffa(0 + (n)-256,7)`;

enum string stbiw__zlib_huff4(string n) = `  stbiw__zlib_huffa(0xc0 + (n)-280,8)`;

enum string stbiw__zlib_huff(string n) = `  ((n) <= 143 ? stbiw__zlib_huff1(n) : (n) <= 255 ? stbiw__zlib_huff2(n) : (n) <= 279 ? stbiw__zlib_huff3(n) : stbiw__zlib_huff4(n))`;

enum string stbiw__zlib_huffb(string n) = ` ((n) <= 143 ? stbiw__zlib_huff1(n) : stbiw__zlib_huff2(n))`;


enum stbiw__ZHASH =   16384;


} // STBIW_ZLIB_COMPRESS


extern ubyte* stbi_zlib_compress(ubyte* data, int data_len, int* out_len, int quality)
{
version (STBIW_ZLIB_COMPRESS) {






} else { // use builtin
   static ushort[30] lengthc = [ 3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258, 259 ];
   static ubyte[29] lengtheb = [ 0,0,0,0,0,0,0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0 ];
   static ushort[31] distc = [ 1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577, 32768 ];
   static ubyte[30] disteb = [ 0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13 ];
   uint bitbuf = 0;
   int i = void, j = void, bitcount = 0;
   ubyte* out_ = null;
   ubyte*** hash_table = cast(ubyte***) malloc(16384 * (ubyte**).sizeof);
   if (hash_table == null)
      return null;
   if (quality < 5) quality = 5;

   ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (0x78)); // DEFLATE 32K window
   ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (0x5e)); // FLEVEL = 1
   (bitbuf |= (1) << bitcount, bitcount += (1), (out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount))); // BFINAL = 1
   (bitbuf |= (1) << bitcount, bitcount += (2), (out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount))); // BTYPE = 1 -- fixed huffman

   for (i=0; i < 16384; ++i)
      hash_table[i] = null;

   i=0;
   while (i < data_len-3) {
      // hash next 3 bytes of data to be compressed
      int h = stbiw__zhash(data+i)&(16384 -1), best = 3;
      ubyte* bestloc = null;
      ubyte** hlist = hash_table[h];
      int n = ((hlist) ? (cast(int*) cast(void*) (hlist) - 2)[1] : 0);
      for (j=0; j < n; ++j) {
         if (hlist[j]-data > i-32768) { // if entry lies within window
            int d = stbiw__zlib_countm(hlist[j], data+i, data_len-i);
            if (d >= best) { best=d; bestloc=hlist[j]; }
         }
      }
      // when hash table entry is too long, delete half the entries
      if (hash_table[h] && (cast(int*) cast(void*) (hash_table[h]) - 2)[1] == 2*quality) {
         memmove(hash_table[h],hash_table[h]+quality,(hash_table[h][0]).sizeof*quality);
         (cast(int*) cast(void*) (hash_table[h]) - 2)[1] = quality;
      }
      ((((hash_table[h])==null || (cast(int*) cast(void*) (hash_table[h]) - 2)[1]+(1) >= (cast(int*) cast(void*) (hash_table[h]) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(hash_table[h]), (1), typeof(*(hash_table[h])).sizeof) : null), (hash_table[h])[(cast(int*) cast(void*) (hash_table[h]) - 2)[1]++] = (data+i));

      if (bestloc) {
         // "lazy matching" - check match at *next* byte, and if it's better, do cur byte as literal
         h = stbiw__zhash(data+i+1)&(16384 -1);
         hlist = hash_table[h];
         n = ((hlist) ? (cast(int*) cast(void*) (hlist) - 2)[1] : 0);
         for (j=0; j < n; ++j) {
            if (hlist[j]-data > i-32767) {
               int e = stbiw__zlib_countm(hlist[j], data+i+1, data_len-i-1);
               if (e > best) { // if next match is better, bail on current match
                  bestloc = null;
                  break;
               }
            }
         }
      }

      if (bestloc) {
         int d = cast(int) (data+i - bestloc); // distance back
         assert(d <= 32767 && best <= 258);
         for (j=0; best > lengthc[j+1]-1; ++j){}
         (j+257) <= 143 ? () {
              bitbuf |= (stbiw__zlib_bitrev(0x30 + (j+257),8)) << bitcount;
              bitcount += (8);
              return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
          }()
          : (j+257) <= 255 ? (){
              bitbuf |= (stbiw__zlib_bitrev(0x190 + (j+257)-144,9)) << bitcount;
              bitcount += (9);
              return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
          }()
          : (j+257) <= 279 ? () {
              bitbuf |= (stbiw__zlib_bitrev(0 + (j+257)-256,7)) << bitcount;
              bitcount += (7);
              return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
          }()
          : () {
              bitbuf |= (stbiw__zlib_bitrev(0xc0 + (j+257)-280,8)) << bitcount;
              bitcount += (8);
              return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
          }();
         if (lengtheb[j]) (bitbuf |= (best - lengthc[j]) << bitcount, bitcount += (lengtheb[j]), (out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount)));
         for (j=0; d > distc[j+1]-1; ++j){}
         (bitbuf |= (stbiw__zlib_bitrev(j,5)) << bitcount, bitcount += (5), (out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount)));
         if (disteb[j]) (bitbuf |= (d - distc[j]) << bitcount, bitcount += (disteb[j]), (out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount)));
         i += best;
      } else {
         (data[i]) <= 143 ? () {
             bitbuf |= (stbiw__zlib_bitrev(0x30 + (data[i]),8)) << bitcount;
             bitcount += (8);
             return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
         }()
         : () {
             bitbuf |= (stbiw__zlib_bitrev(0x190 + (data[i])-144,9)) << bitcount;
             bitcount += (9);
             return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
         }();
         ++i;
      }
   }
   // write out final bytes
   for (;i < data_len; ++i)
      (data[i]) <= 143 ? () {
          bitbuf |= (stbiw__zlib_bitrev(0x30 + (data[i]),8)) << bitcount;
          bitcount += (8);
          return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
      }()
      : () {
          bitbuf |= (stbiw__zlib_bitrev(0x190 + (data[i])-144,9)) << bitcount;
          bitcount += (9);
          return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
      }();
   (256) <= 143 ? () {
       bitbuf |= (stbiw__zlib_bitrev(0x30 + (256),8)) << bitcount;
       bitcount += (8);
       return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
   }()
   : (256) <= 255 ? (){
       bitbuf |= (stbiw__zlib_bitrev(0x190 + (256)-144,9)) << bitcount;
       bitcount += (9);
       return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
   }()
   : (256) <= 279 ? (){
       bitbuf |= (stbiw__zlib_bitrev(0 + (256)-256,7)) << bitcount;
       bitcount += (7);
       return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
   }()
   : () {
       bitbuf |= (stbiw__zlib_bitrev(0xc0 + (256)-280,8)) << bitcount;
       bitcount += (8);
       return out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount);
   }(); // end of block
   // pad with 0 bits to byte boundary
   while (bitcount)
      (bitbuf |= (0) << bitcount, bitcount += (1), (out_ = stbiw__zlib_flushf(out_, &bitbuf, &bitcount)));

   for (i=0; i < 16384; ++i)
       if(hash_table[i])
           free((cast(int*) cast(void*) (hash_table[i]) - 2));
   free(hash_table);

   // store uncompressed instead if compression was worse
   if ((cast(int*) cast(void*) (out_) - 2)[1] > data_len + 2 + ((data_len+32766)/32767)*5) {
      (cast(int*) cast(void*) (out_) - 2)[1] = 2; // truncate to DEFLATE 32K window and FLEVEL = 1
      for (j = 0; j < data_len;) {
         int blocklen = data_len - j;
         if (blocklen > 32767) blocklen = 32767;
         ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (data_len - j == blocklen)); // BFINAL = ?, BTYPE = 0 -- no compression
         ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((blocklen) & 0xff))); // LEN
         ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((blocklen >> 8) & 0xff)));
         ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((~blocklen) & 0xff))); // NLEN
         ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((~blocklen >> 8) & 0xff)));
         memcpy(out_+(cast(int*) cast(void*) (out_) - 2)[1], data+j, blocklen);
         (cast(int*) cast(void*) (out_) - 2)[1] += blocklen;
         j += blocklen;
      }
   }

   {
      // compute adler32 on input
      uint s1 = 1, s2 = 0;
      int blocklen = cast(int) (data_len % 5552);
      j=0;
      while (j < data_len) {
         for (i=0; i < blocklen; ++i) { s1 += data[j+i]; s2 += s1; }
         s1 %= 65521; s2 %= 65521;
         j += blocklen;
         blocklen = 5552;
      }
      ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((s2 >> 8) & 0xff)));
      ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((s2) & 0xff)));
      ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((s1 >> 8) & 0xff)));
      ((((out_)==null || (cast(int*) cast(void*) (out_) - 2)[1]+(1) >= (cast(int*) cast(void*) (out_) - 2)[0]) ? stbiw__sbgrowf(cast(void**) &(out_), (1), typeof(*(out_)).sizeof) : null), (out_)[(cast(int*) cast(void*) (out_) - 2)[1]++] = (cast(ubyte) ((s1) & 0xff)));
   }
   *out_len = (cast(int*) cast(void*) (out_) - 2)[1];
   // make returned pointer freeable
   memmove((cast(int*) cast(void*) (out_) - 2),out_,*out_len);
   return cast(ubyte*) (cast(int*) cast(void*) (out_) - 2);
} // STBIW_ZLIB_COMPRESS

}

private uint stbiw__crc32(ubyte* buffer, int len)
{
version (STBIW_CRC32) {





} else {
   static uint[256] crc_table = [
      0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
      0x0eDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
      0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
      0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
      0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
      0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
      0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
      0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
      0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
      0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
      0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E, 0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
      0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
      0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
      0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
      0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
      0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
      0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
      0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
      0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
      0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
      0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
      0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
      0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
      0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
      0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
      0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
      0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
      0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
      0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
      0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
      0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
      0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94, 0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D
   ];

   uint crc = ~0u;
   int i = void;
   for (i=0; i < len; ++i)
      crc = (crc >> 8) ^ crc_table[buffer[i] ^ (crc & 0xff)];
   return ~crc;
}

}

enum string stbiw__wpng4(string o,string a,string b,string c,string d) = ` ((o)[0]=STBIW_UCHAR(a),(o)[1]=STBIW_UCHAR(b),(o)[2]=STBIW_UCHAR(c),(o)[3]=STBIW_UCHAR(d),(o)+=4)`;

enum string stbiw__wp32(string data,string v) = ` stbiw__wpng4(data, (v)>>24,(v)>>16,(v)>>8,(v));`;

enum string stbiw__wptag(string data,string s) = ` stbiw__wpng4(data, s[0],s[1],s[2],s[3])`;


private void stbiw__wpcrc(ubyte** data, int len)
{
   uint crc = stbiw__crc32(*data - len - 4, len+4);
   ((*data)[0]=cast(ubyte) (((crc)>>24) & 0xff),(*data)[1]=cast(ubyte) (((crc)>>16) & 0xff),(*data)[2]=cast(ubyte) (((crc)>>8) & 0xff),(*data)[3]=cast(ubyte) (((crc)) & 0xff),(*data)+=4);{}
}

private ubyte stbiw__paeth(int a, int b, int c)
{
   int p = a + b - c, pa = abs(p-a), pb = abs(p-b), pc = abs(p-c);
   if (pa <= pb && pa <= pc) return cast(ubyte) ((a) & 0xff);
   if (pb <= pc) return cast(ubyte) ((b) & 0xff);
   return cast(ubyte) ((c) & 0xff);
}

// @OPTIMIZE: provide an option that always forces left-predict or paeth predict
private void stbiw__encode_png_line(ubyte* pixels, int stride_bytes, int width, int height, int y, int n, int filter_type, char* line_buffer)
{
   static int[5] mapping = [ 0,1,2,3,4 ];
   static int[5] firstmap = [ 0,1,0,5,6 ];
   int* mymap = (y != 0) ? mapping.ptr : firstmap.ptr;
   int i = void;
   int type = mymap[filter_type];
   ubyte* z = pixels + stride_bytes * (stbi__flip_vertically_on_write ? height-1-y : y);
   int signed_stride = stbi__flip_vertically_on_write ? -stride_bytes : stride_bytes;

   if (type==0) {
      memcpy(line_buffer, z, width*n);
      return;
   }

   // first loop isn't optimized since it's just one pixel
   for (i = 0; i < n; ++i) {
      switch (type) {
         case 1: line_buffer[i] = z[i]; break;
         case 2: line_buffer[i] = cast(char)(z[i] - z[i-signed_stride]); break;
         case 3: line_buffer[i] = cast(char)(z[i] - (z[i-signed_stride]>>1)); break;
         case 4: line_buffer[i] = cast(char) (z[i] - stbiw__paeth(0,z[i-signed_stride],0)); break;
         case 5: line_buffer[i] = z[i]; break;
         case 6: line_buffer[i] = z[i]; break;
      default: break;}
   }
   switch (type) {
      case 1: for (i=n; i < width*n; ++i) line_buffer[i] = cast(char)(z[i] - z[i-n]); break;
      case 2: for (i=n; i < width*n; ++i) line_buffer[i] = cast(char)(z[i] - z[i-signed_stride]); break;
      case 3: for (i=n; i < width*n; ++i) line_buffer[i] = cast(char)(z[i] - ((z[i-n] + z[i-signed_stride])>>1)); break;
      case 4: for (i=n; i < width*n; ++i) line_buffer[i] = cast(char)(z[i] - stbiw__paeth(z[i-n], z[i-signed_stride], z[i-signed_stride-n])); break;
      case 5: for (i=n; i < width*n; ++i) line_buffer[i] = cast(char)(z[i] - (z[i-n]>>1)); break;
      case 6: for (i=n; i < width*n; ++i) line_buffer[i] = cast(char)(z[i] - stbiw__paeth(z[i-n], 0,0)); break;
   default: break;}
}

extern ubyte* stbi_write_png_to_mem(const(ubyte)* pixels, int stride_bytes, int x, int y, int n, int* out_len)
{
   int force_filter = stbi_write_force_png_filter;
   int[5] ctype = [ -1, 0, 4, 2, 6 ];
   ubyte[8] sig = [ 137,80,78,71,13,10,26,10 ];
   ubyte* out_ = void, o = void, filt = void, zlib = void;
   char* line_buffer = void;
   int j = void, zlen = void;

   if (stride_bytes == 0)
      stride_bytes = x * n;

   if (force_filter >= 5) {
      force_filter = -1;
   }

   filt = cast(ubyte*) malloc((x*n+1) * y); if (!filt) return null;
   line_buffer = cast(char*) malloc(x * n); if (!line_buffer) { free(filt); return null; }
   for (j=0; j < y; ++j) {
      int filter_type = void;
      if (force_filter > -1) {
         filter_type = force_filter;
         stbiw__encode_png_line(cast(ubyte*)(pixels), stride_bytes, x, y, j, n, force_filter, line_buffer);
      } else { // Estimate the best filter by running through all of them:
         int best_filter = 0, best_filter_val = 0x7fffffff, est = void, i = void;
         for (filter_type = 0; filter_type < 5; filter_type++) {
            stbiw__encode_png_line(cast(ubyte*)(pixels), stride_bytes, x, y, j, n, filter_type, line_buffer);

            // Estimate the entropy of the line using this filter; the less, the better.
            est = 0;
            for (i = 0; i < x*n; ++i) {
               est += abs(cast(char) line_buffer[i]);
            }
            if (est < best_filter_val) {
               best_filter_val = est;
               best_filter = filter_type;
            }
         }
         if (filter_type != best_filter) { // If the last iteration already got us the best filter, don't redo it
            stbiw__encode_png_line(cast(ubyte*)(pixels), stride_bytes, x, y, j, n, best_filter, line_buffer);
            filter_type = best_filter;
         }
      }
      // when we get here, filter_type contains the filter type, and line_buffer contains the data
      filt[j*(x*n+1)] = cast(ubyte) filter_type;
      memmove(filt+j*(x*n+1)+1,line_buffer,x*n);
   }
   free(line_buffer);
   zlib = stbi_zlib_compress(filt, y*( x*n+1), &zlen, stbi_write_png_compression_level);
   free(filt);
   if (!zlib) return null;

   // each tag requires 12 bytes of overhead
   out_ = cast(ubyte*) malloc(8 + 12+13 + 12+zlen + 12);
   if (!out_) return null;
   *out_len = 8 + 12+13 + 12+zlen + 12;

   o=out_;
   memmove(o,sig.ptr,8); o+= 8;
   ((o)[0]=cast(ubyte) (((13)>>24) & 0xff),(o)[1]=cast(ubyte) (((13)>>16) & 0xff),(o)[2]=cast(ubyte) (((13)>>8) & 0xff),(o)[3]=cast(ubyte) (((13)) & 0xff),(o)+=4);{} // header length
   ((o)[0]=cast(ubyte) (("IHDR"[0]) & 0xff),(o)[1]=cast(ubyte) (("IHDR"[1]) & 0xff),(o)[2]=cast(ubyte) (("IHDR"[2]) & 0xff),(o)[3]=cast(ubyte) (("IHDR"[3]) & 0xff),(o)+=4);
   ((o)[0]=cast(ubyte) (((x)>>24) & 0xff),(o)[1]=cast(ubyte) (((x)>>16) & 0xff),(o)[2]=cast(ubyte) (((x)>>8) & 0xff),(o)[3]=cast(ubyte) (((x)) & 0xff),(o)+=4);{}
   ((o)[0]=cast(ubyte) (((y)>>24) & 0xff),(o)[1]=cast(ubyte) (((y)>>16) & 0xff),(o)[2]=cast(ubyte) (((y)>>8) & 0xff),(o)[3]=cast(ubyte) (((y)) & 0xff),(o)+=4);{}
   *o++ = 8;
   *o++ = cast(ubyte) ((ctype[n]) & 0xff);
   *o++ = 0;
   *o++ = 0;
   *o++ = 0;
   stbiw__wpcrc(&o,13);

   ((o)[0]=cast(ubyte) (((zlen)>>24) & 0xff),(o)[1]=cast(ubyte) (((zlen)>>16) & 0xff),(o)[2]=cast(ubyte) (((zlen)>>8) & 0xff),(o)[3]=cast(ubyte) (((zlen)) & 0xff),(o)+=4);{}
   ((o)[0]=cast(ubyte) (("IDAT"[0]) & 0xff),(o)[1]=cast(ubyte) (("IDAT"[1]) & 0xff),(o)[2]=cast(ubyte) (("IDAT"[2]) & 0xff),(o)[3]=cast(ubyte) (("IDAT"[3]) & 0xff),(o)+=4);
   memmove(o,zlib,zlen);
   o += zlen;
   free(zlib);
   stbiw__wpcrc(&o, zlen);

   ((o)[0]=cast(ubyte) (((0)>>24) & 0xff),(o)[1]=cast(ubyte) (((0)>>16) & 0xff),(o)[2]=cast(ubyte) (((0)>>8) & 0xff),(o)[3]=cast(ubyte) (((0)) & 0xff),(o)+=4);{}
   ((o)[0]=cast(ubyte) (("IEND"[0]) & 0xff),(o)[1]=cast(ubyte) (("IEND"[1]) & 0xff),(o)[2]=cast(ubyte) (("IEND"[2]) & 0xff),(o)[3]=cast(ubyte) (("IEND"[3]) & 0xff),(o)+=4);
   stbiw__wpcrc(&o,0);

   assert(o == out_ + *out_len);

   return out_;
}

version (STBI_WRITE_NO_STDIO) {} else {

extern int stbi_write_png(const(char)* filename, int x, int y, int comp, const(void)* data, int stride_bytes)
{
   FILE* f = void;
   int len = void;
   ubyte* png = stbi_write_png_to_mem(cast(const(ubyte)*) data, stride_bytes, x, y, comp, &len);
   if (png == null) return 0;

   f = stbiw__fopen(filename, "wb");
   if (!f) { free(png); return 0; }
   fwrite(png, 1, len, f);
   fclose(f);
   free(png);
   return 1;
}
}


extern int stbi_write_png_to_func(stbi_write_func func, void* context, int x, int y, int comp, const(void)* data, int stride_bytes)
{
   int len = void;
   ubyte* png = stbi_write_png_to_mem(cast(const(ubyte)*) data, stride_bytes, x, y, comp, &len);
   if (png == null) return 0;
   func(context, png, len);
   free(png);
   return 1;
}


/* ***************************************************************************
 *
 * JPEG writer
 *
 * This is based on Jon Olick's jo_jpeg.cpp:
 * public domain Simple, Minimalistic JPEG writer - http://www.jonolick.com/code.html
 */

private const(ubyte)[64] stbiw__jpg_ZigZag = [ 0,1,5,6,14,15,27,28,2,4,7,13,16,26,29,42,3,8,12,17,25,30,41,43,9,11,18,
      24,31,40,44,53,10,19,23,32,39,45,52,54,20,22,33,38,46,51,55,60,21,34,37,47,50,56,59,61,35,36,48,49,57,58,62,63 ];

private void stbiw__jpg_writeBits(stbi__write_context* s, int* bitBufP, int* bitCntP, const(ushort)* bs) {
   int bitBuf = *bitBufP, bitCnt = *bitCntP;
   bitCnt += bs[1];
   bitBuf |= bs[0] << (24 - bitCnt);
   while(bitCnt >= 8) {
      ubyte c = (bitBuf >> 16) & 255;
      stbiw__putc(s, c);
      if(c == 255) {
         stbiw__putc(s, 0);
      }
      bitBuf <<= 8;
      bitCnt -= 8;
   }
   *bitBufP = bitBuf;
   *bitCntP = bitCnt;
}

private void stbiw__jpg_DCT(float* d0p, float* d1p, float* d2p, float* d3p, float* d4p, float* d5p, float* d6p, float* d7p) {
   float d0 = *d0p, d1 = *d1p, d2 = *d2p, d3 = *d3p, d4 = *d4p, d5 = *d5p, d6 = *d6p, d7 = *d7p;
   float z1 = void, z2 = void, z3 = void, z4 = void, z5 = void, z11 = void, z13 = void;

   float tmp0 = d0 + d7;
   float tmp7 = d0 - d7;
   float tmp1 = d1 + d6;
   float tmp6 = d1 - d6;
   float tmp2 = d2 + d5;
   float tmp5 = d2 - d5;
   float tmp3 = d3 + d4;
   float tmp4 = d3 - d4;

   // Even part
   float tmp10 = tmp0 + tmp3; // phase 2
   float tmp13 = tmp0 - tmp3;
   float tmp11 = tmp1 + tmp2;
   float tmp12 = tmp1 - tmp2;

   d0 = tmp10 + tmp11; // phase 3
   d4 = tmp10 - tmp11;

   z1 = (tmp12 + tmp13) * 0.707106781f; // c4
   d2 = tmp13 + z1; // phase 5
   d6 = tmp13 - z1;

   // Odd part
   tmp10 = tmp4 + tmp5; // phase 2
   tmp11 = tmp5 + tmp6;
   tmp12 = tmp6 + tmp7;

   // The rotator is modified from fig 4-8 to avoid extra negations.
   z5 = (tmp10 - tmp12) * 0.382683433f; // c6
   z2 = tmp10 * 0.541196100f + z5; // c2-c6
   z4 = tmp12 * 1.306562965f + z5; // c2+c6
   z3 = tmp11 * 0.707106781f; // c4

   z11 = tmp7 + z3; // phase 5
   z13 = tmp7 - z3;

   *d5p = z13 + z2; // phase 6
   *d3p = z13 - z2;
   *d1p = z11 + z4;
   *d7p = z11 - z4;

   *d0p = d0; *d2p = d2; *d4p = d4; *d6p = d6;
}

private void stbiw__jpg_calcBits(int val, ushort* bits) {
   int tmp1 = val < 0 ? -val : val;
   val = val < 0 ? val-1 : val;
   bits[1] = 1;
   while((tmp1 >>= 1) != 0) {
      ++bits[1];
   }
   bits[0] = cast(ushort)(val & ((1<<bits[1])-1));
}

private int stbiw__jpg_processDU(stbi__write_context* s, int* bitBuf, int* bitCnt, float* CDU, int du_stride, float* fdtbl, int DC, ref const(ushort)[2][256] HTDC, ref const(ushort)[2][256] HTAC) {
   const(ushort)[2] EOB = [ HTAC[0x00][0], HTAC[0x00][1] ];
   const(ushort)[2] M16zeroes = [ HTAC[0xF0][0], HTAC[0xF0][1] ];
   int dataOff = void, i = void, j = void, n = void, diff = void, end0pos = void, x = void, y = void;
   int[64] DU = void;

   // DCT rows
   for(dataOff=0, n=du_stride*8; dataOff<n; dataOff+=du_stride) {
      stbiw__jpg_DCT(&CDU[dataOff], &CDU[dataOff+1], &CDU[dataOff+2], &CDU[dataOff+3], &CDU[dataOff+4], &CDU[dataOff+5], &CDU[dataOff+6], &CDU[dataOff+7]);
   }
   // DCT columns
   for(dataOff=0; dataOff<8; ++dataOff) {
      stbiw__jpg_DCT(&CDU[dataOff], &CDU[dataOff+du_stride], &CDU[dataOff+du_stride*2], &CDU[dataOff+du_stride*3], &CDU[dataOff+du_stride*4],
                     &CDU[dataOff+du_stride*5], &CDU[dataOff+du_stride*6], &CDU[dataOff+du_stride*7]);
   }
   // Quantize/descale/zigzag the coefficients
   for(y = 0, j=0; y < 8; ++y) {
      for(x = 0; x < 8; ++x,++j) {
         float v = void;
         i = y*du_stride+x;
         v = CDU[i]*fdtbl[j];
         // DU[stbiw__jpg_ZigZag[j]] = (int)(v < 0 ? ceilf(v - 0.5f) : floorf(v + 0.5f));
         // ceilf() and floorf() are C99, not C89, but I /think/ they're not needed here anyway?
         DU[stbiw__jpg_ZigZag[j]] = cast(int)(v < 0 ? v - 0.5f : v + 0.5f);
      }
   }

   // Encode DC
   diff = DU[0] - DC;
   if (diff == 0) {
      stbiw__jpg_writeBits(s, bitBuf, bitCnt, HTDC[0].ptr);
   } else {
      ushort[2] bits = void;
      stbiw__jpg_calcBits(diff, bits.ptr);
      stbiw__jpg_writeBits(s, bitBuf, bitCnt, HTDC[bits[1]].ptr);
      stbiw__jpg_writeBits(s, bitBuf, bitCnt, bits.ptr);
   }
   // Encode ACs
   end0pos = 63;
   for(; (end0pos>0)&&(DU[end0pos]==0); --end0pos) {
   }
   // end0pos = first element in reverse order !=0
   if(end0pos == 0) {
      stbiw__jpg_writeBits(s, bitBuf, bitCnt, EOB.ptr);
      return DU[0];
   }
   for(i = 1; i <= end0pos; ++i) {
      int startpos = i;
      int nrzeroes = void;
      ushort[2] bits = void;
      for (; DU[i]==0 && i<=end0pos; ++i) {
      }
      nrzeroes = i-startpos;
      if ( nrzeroes >= 16 ) {
         int lng = nrzeroes>>4;
         int nrmarker = void;
         for (nrmarker=1; nrmarker <= lng; ++nrmarker)
            stbiw__jpg_writeBits(s, bitBuf, bitCnt, M16zeroes.ptr);
         nrzeroes &= 15;
      }
      stbiw__jpg_calcBits(DU[i], bits.ptr);
      stbiw__jpg_writeBits(s, bitBuf, bitCnt, HTAC[(nrzeroes<<4)+bits[1]].ptr);
      stbiw__jpg_writeBits(s, bitBuf, bitCnt, bits.ptr);
   }
   if(end0pos != 63) {
      stbiw__jpg_writeBits(s, bitBuf, bitCnt, EOB.ptr);
   }
   return DU[0];
}

private int stbi_write_jpg_core(stbi__write_context* s, int width, int height, int comp, const(void)* data, int quality) {
   // Constants that don't pollute global namespace
   static const(ubyte)[17] std_dc_luminance_nrcodes = [0,0,1,5,1,1,1,1,1,1,0,0,0,0,0,0,0];
   static const(ubyte)[12] std_dc_luminance_values = [0,1,2,3,4,5,6,7,8,9,10,11];
   static const(ubyte)[17] std_ac_luminance_nrcodes = [0,0,2,1,3,3,2,4,3,5,5,4,4,0,0,1,0x7d];
   static const(ubyte)[162] std_ac_luminance_values = [
      0x01,0x02,0x03,0x00,0x04,0x11,0x05,0x12,0x21,0x31,0x41,0x06,0x13,0x51,0x61,0x07,0x22,0x71,0x14,0x32,0x81,0x91,0xa1,0x08,
      0x23,0x42,0xb1,0xc1,0x15,0x52,0xd1,0xf0,0x24,0x33,0x62,0x72,0x82,0x09,0x0a,0x16,0x17,0x18,0x19,0x1a,0x25,0x26,0x27,0x28,
      0x29,0x2a,0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x53,0x54,0x55,0x56,0x57,0x58,0x59,
      0x5a,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6a,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x83,0x84,0x85,0x86,0x87,0x88,0x89,
      0x8a,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xb2,0xb3,0xb4,0xb5,0xb6,
      0xb7,0xb8,0xb9,0xba,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9,0xda,0xe1,0xe2,
      0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9,0xfa
   ];
   static const(ubyte)[17] std_dc_chrominance_nrcodes = [0,0,3,1,1,1,1,1,1,1,1,1,0,0,0,0,0];
   static const(ubyte)[12] std_dc_chrominance_values = [0,1,2,3,4,5,6,7,8,9,10,11];
   static const(ubyte)[17] std_ac_chrominance_nrcodes = [0,0,2,1,2,4,4,3,4,7,5,4,4,0,1,2,0x77];
   static const(ubyte)[162] std_ac_chrominance_values = [
      0x00,0x01,0x02,0x03,0x11,0x04,0x05,0x21,0x31,0x06,0x12,0x41,0x51,0x07,0x61,0x71,0x13,0x22,0x32,0x81,0x08,0x14,0x42,0x91,
      0xa1,0xb1,0xc1,0x09,0x23,0x33,0x52,0xf0,0x15,0x62,0x72,0xd1,0x0a,0x16,0x24,0x34,0xe1,0x25,0xf1,0x17,0x18,0x19,0x1a,0x26,
      0x27,0x28,0x29,0x2a,0x35,0x36,0x37,0x38,0x39,0x3a,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x53,0x54,0x55,0x56,0x57,0x58,
      0x59,0x5a,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6a,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x82,0x83,0x84,0x85,0x86,0x87,
      0x88,0x89,0x8a,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xb2,0xb3,0xb4,
      0xb5,0xb6,0xb7,0xb8,0xb9,0xba,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9,0xda,
      0xe2,0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9,0xfa
   ];
   // Huffman tables
   static const(ushort)[2][256] YDC_HT = [ [0,2],[2,3],[3,3],[4,3],[5,3],[6,3],[14,4],[30,5],[62,6],[126,7],[254,8],[510,9]];
   static const(ushort)[2][256] UVDC_HT = [ [0,2],[1,2],[2,2],[6,3],[14,4],[30,5],[62,6],[126,7],[254,8],[510,9],[1022,10],[2046,11]];
   static const(ushort)[2][256] YAC_HT = [
      [10,4],[0,2],[1,2],[4,3],[11,4],[26,5],[120,7],[248,8],[1014,10],[65410,16],[65411,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [12,4],[27,5],[121,7],[502,9],[2038,11],[65412,16],[65413,16],[65414,16],[65415,16],[65416,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [28,5],[249,8],[1015,10],[4084,12],[65417,16],[65418,16],[65419,16],[65420,16],[65421,16],[65422,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [58,6],[503,9],[4085,12],[65423,16],[65424,16],[65425,16],[65426,16],[65427,16],[65428,16],[65429,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [59,6],[1016,10],[65430,16],[65431,16],[65432,16],[65433,16],[65434,16],[65435,16],[65436,16],[65437,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [122,7],[2039,11],[65438,16],[65439,16],[65440,16],[65441,16],[65442,16],[65443,16],[65444,16],[65445,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [123,7],[4086,12],[65446,16],[65447,16],[65448,16],[65449,16],[65450,16],[65451,16],[65452,16],[65453,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [250,8],[4087,12],[65454,16],[65455,16],[65456,16],[65457,16],[65458,16],[65459,16],[65460,16],[65461,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [504,9],[32704,15],[65462,16],[65463,16],[65464,16],[65465,16],[65466,16],[65467,16],[65468,16],[65469,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [505,9],[65470,16],[65471,16],[65472,16],[65473,16],[65474,16],[65475,16],[65476,16],[65477,16],[65478,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [506,9],[65479,16],[65480,16],[65481,16],[65482,16],[65483,16],[65484,16],[65485,16],[65486,16],[65487,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [1017,10],[65488,16],[65489,16],[65490,16],[65491,16],[65492,16],[65493,16],[65494,16],[65495,16],[65496,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [1018,10],[65497,16],[65498,16],[65499,16],[65500,16],[65501,16],[65502,16],[65503,16],[65504,16],[65505,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [2040,11],[65506,16],[65507,16],[65508,16],[65509,16],[65510,16],[65511,16],[65512,16],[65513,16],[65514,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [65515,16],[65516,16],[65517,16],[65518,16],[65519,16],[65520,16],[65521,16],[65522,16],[65523,16],[65524,16],[0,0],[0,0],[0,0],[0,0],[0,0],
      [2041,11],[65525,16],[65526,16],[65527,16],[65528,16],[65529,16],[65530,16],[65531,16],[65532,16],[65533,16],[65534,16],[0,0],[0,0],[0,0],[0,0],[0,0]
   ];
   static const(ushort)[2][256] UVAC_HT = [
      [0,2],[1,2],[4,3],[10,4],[24,5],[25,5],[56,6],[120,7],[500,9],[1014,10],[4084,12],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [11,4],[57,6],[246,8],[501,9],[2038,11],[4085,12],[65416,16],[65417,16],[65418,16],[65419,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [26,5],[247,8],[1015,10],[4086,12],[32706,15],[65420,16],[65421,16],[65422,16],[65423,16],[65424,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [27,5],[248,8],[1016,10],[4087,12],[65425,16],[65426,16],[65427,16],[65428,16],[65429,16],[65430,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [58,6],[502,9],[65431,16],[65432,16],[65433,16],[65434,16],[65435,16],[65436,16],[65437,16],[65438,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [59,6],[1017,10],[65439,16],[65440,16],[65441,16],[65442,16],[65443,16],[65444,16],[65445,16],[65446,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [121,7],[2039,11],[65447,16],[65448,16],[65449,16],[65450,16],[65451,16],[65452,16],[65453,16],[65454,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [122,7],[2040,11],[65455,16],[65456,16],[65457,16],[65458,16],[65459,16],[65460,16],[65461,16],[65462,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [249,8],[65463,16],[65464,16],[65465,16],[65466,16],[65467,16],[65468,16],[65469,16],[65470,16],[65471,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [503,9],[65472,16],[65473,16],[65474,16],[65475,16],[65476,16],[65477,16],[65478,16],[65479,16],[65480,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [504,9],[65481,16],[65482,16],[65483,16],[65484,16],[65485,16],[65486,16],[65487,16],[65488,16],[65489,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [505,9],[65490,16],[65491,16],[65492,16],[65493,16],[65494,16],[65495,16],[65496,16],[65497,16],[65498,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [506,9],[65499,16],[65500,16],[65501,16],[65502,16],[65503,16],[65504,16],[65505,16],[65506,16],[65507,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [2041,11],[65508,16],[65509,16],[65510,16],[65511,16],[65512,16],[65513,16],[65514,16],[65515,16],[65516,16],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],
      [16352,14],[65517,16],[65518,16],[65519,16],[65520,16],[65521,16],[65522,16],[65523,16],[65524,16],[65525,16],[0,0],[0,0],[0,0],[0,0],[0,0],
      [1018,10],[32707,15],[65526,16],[65527,16],[65528,16],[65529,16],[65530,16],[65531,16],[65532,16],[65533,16],[65534,16],[0,0],[0,0],[0,0],[0,0],[0,0]
   ];
   static const(int)[64] YQT = [16,11,10,16,24,40,51,61,12,12,14,19,26,58,60,55,14,13,16,24,40,57,69,56,14,17,22,29,51,87,80,62,18,22,
                             37,56,68,109,103,77,24,35,55,64,81,104,113,92,49,64,78,87,103,121,120,101,72,92,95,98,112,100,103,99];
   static const(int)[64] UVQT = [17,18,24,47,99,99,99,99,18,21,26,66,99,99,99,99,24,26,56,99,99,99,99,99,47,66,99,99,99,99,99,99,
                              99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99];
   static const(float)[8] aasf = [ 1.0f * 2.828427125f, 1.387039845f * 2.828427125f, 1.306562965f * 2.828427125f, 1.175875602f * 2.828427125f,
                                 1.0f * 2.828427125f, 0.785694958f * 2.828427125f, 0.541196100f * 2.828427125f, 0.275899379f * 2.828427125f ];

   int row = void, col = void, i = void, k = void, subsample = void;
   float[64] fdtbl_Y = void, fdtbl_UV = void;
   ubyte[64] YTable = void, UVTable = void;

   if(!data || !width || !height || comp > 4 || comp < 1) {
      return 0;
   }

   quality = quality ? quality : 90;
   subsample = quality <= 90 ? 1 : 0;
   quality = quality < 1 ? 1 : quality > 100 ? 100 : quality;
   quality = quality < 50 ? 5000 / quality : 200 - quality * 2;

   for(i = 0; i < 64; ++i) {
      int uvti = void, yti = (YQT[i]*quality+50)/100;
      YTable[stbiw__jpg_ZigZag[i]] = cast(ubyte) (yti < 1 ? 1 : yti > 255 ? 255 : yti);
      uvti = (UVQT[i]*quality+50)/100;
      UVTable[stbiw__jpg_ZigZag[i]] = cast(ubyte) (uvti < 1 ? 1 : uvti > 255 ? 255 : uvti);
   }

   for(row = 0, k = 0; row < 8; ++row) {
      for(col = 0; col < 8; ++col, ++k) {
         fdtbl_Y[k] = 1 / (YTable [stbiw__jpg_ZigZag[k]] * aasf[row] * aasf[col]);
         fdtbl_UV[k] = 1 / (UVTable[stbiw__jpg_ZigZag[k]] * aasf[row] * aasf[col]);
      }
   }

   // Write Headers
   {
      static const(ubyte)[25] head0 = [ 0xFF,0xD8,0xFF,0xE0,0,0x10,'J','F','I','F',0,1,1,0,0,1,0,1,0,0,0xFF,0xDB,0,0x84,0 ];
      static const(ubyte)[14] head2 = [ 0xFF,0xDA,0,0xC,3,1,0,2,0x11,3,0x11,0,0x3F,0 ];
      const(ubyte)[24] head1 = [ 0xFF,0xC0,0,0x11,8,cast(ubyte)(height>>8),cast(ubyte) ((height) & 0xff),cast(ubyte)(width>>8),cast(ubyte) ((width) & 0xff),
                                      3,1,cast(ubyte)(subsample?0x22:0x11),0,2,0x11,1,3,0x11,1,0xFF,0xC4,0x01,0xA2,0 ];
      s.func(s.context, cast(void*)head0, head0.sizeof);
      s.func(s.context, cast(void*)YTable, YTable.sizeof);
      stbiw__putc(s, 1);
      s.func(s.context, UVTable.ptr, UVTable.sizeof);
      s.func(s.context, cast(void*)head1, head1.sizeof);
      s.func(s.context, cast(void*)(std_dc_luminance_nrcodes.ptr+1), std_dc_luminance_nrcodes.length-1);
      s.func(s.context, cast(void*)std_dc_luminance_values, std_dc_luminance_values.sizeof);
      stbiw__putc(s, 0x10); // HTYACinfo
      s.func(s.context, cast(void*)(std_ac_luminance_nrcodes.ptr+1), std_ac_luminance_nrcodes.length-1);
      s.func(s.context, cast(void*)std_ac_luminance_values, std_ac_luminance_values.sizeof);
      stbiw__putc(s, 1); // HTUDCinfo
      s.func(s.context, cast(void*)(std_dc_chrominance_nrcodes.ptr+1), std_dc_chrominance_nrcodes.length-1);
      s.func(s.context, cast(void*)std_dc_chrominance_values, std_dc_chrominance_values.sizeof);
      stbiw__putc(s, 0x11); // HTUACinfo
      s.func(s.context, cast(void*)(std_ac_chrominance_nrcodes.ptr+1), std_ac_chrominance_nrcodes.length-1);
      s.func(s.context, cast(void*)std_ac_chrominance_values, std_ac_chrominance_values.sizeof);
      s.func(s.context, cast(void*)head2, head2.sizeof);
   }

   // Encode 8x8 macroblocks
   {
      static const(ushort)[2] fillBits = [0x7F, 7];
      int DCY = 0, DCU = 0, DCV = 0;
      int bitBuf = 0, bitCnt = 0;
      // comp == 2 is grey+alpha (alpha is ignored)
      int ofsG = comp > 2 ? 1 : 0, ofsB = comp > 2 ? 2 : 0;
      const(ubyte)* dataR = cast(const(ubyte)*)data;
      const(ubyte)* dataG = dataR + ofsG;
      const(ubyte)* dataB = dataR + ofsB;
      int x = void, y = void, pos = void;
      if(subsample) {
         for(y = 0; y < height; y += 16) {
            for(x = 0; x < width; x += 16) {
               float[256] Y = void, U = void, V = void;
               for(row = y, pos = 0; row < y+16; ++row) {
                  // row >= height => use last input row
                  int clamped_row = (row < height) ? row : height - 1;
                  int base_p = (stbi__flip_vertically_on_write ? (height-1-clamped_row) : clamped_row)*width*comp;
                  for(col = x; col < x+16; ++col, ++pos) {
                     // if col >= width => use pixel from last input column
                     int p = base_p + ((col < width) ? col : (width-1))*comp;
                     float r = dataR[p], g = dataG[p], b = dataB[p];
                     Y[pos]= +0.29900f*r + 0.58700f*g + 0.11400f*b - 128;
                     U[pos]= -0.16874f*r - 0.33126f*g + 0.50000f*b;
                     V[pos]= +0.50000f*r - 0.41869f*g - 0.08131f*b;
                  }
               }
               DCY = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, Y.ptr+0, 16, fdtbl_Y.ptr, DCY, YDC_HT, YAC_HT);
               DCY = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, Y.ptr+8, 16, fdtbl_Y.ptr, DCY, YDC_HT, YAC_HT);
               DCY = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, Y.ptr+128, 16, fdtbl_Y.ptr, DCY, YDC_HT, YAC_HT);
               DCY = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, Y.ptr+136, 16, fdtbl_Y.ptr, DCY, YDC_HT, YAC_HT);

               // subsample U,V
               {
                  float[64] subU = void, subV = void;
                  int yy = void, xx = void;
                  for(yy = 0, pos = 0; yy < 8; ++yy) {
                     for(xx = 0; xx < 8; ++xx, ++pos) {
                        int j = yy*32+xx*2;
                        subU[pos] = (U[j+0] + U[j+1] + U[j+16] + U[j+17]) * 0.25f;
                        subV[pos] = (V[j+0] + V[j+1] + V[j+16] + V[j+17]) * 0.25f;
                     }
                  }
                  DCU = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, subU.ptr, 8, fdtbl_UV.ptr, DCU, UVDC_HT, UVAC_HT);
                  DCV = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, subV.ptr, 8, fdtbl_UV.ptr, DCV, UVDC_HT, UVAC_HT);
               }
            }
         }
      } else {
         for(y = 0; y < height; y += 8) {
            for(x = 0; x < width; x += 8) {
               float[64] Y = void, U = void, V = void;
               for(row = y, pos = 0; row < y+8; ++row) {
                  // row >= height => use last input row
                  int clamped_row = (row < height) ? row : height - 1;
                  int base_p = (stbi__flip_vertically_on_write ? (height-1-clamped_row) : clamped_row)*width*comp;
                  for(col = x; col < x+8; ++col, ++pos) {
                     // if col >= width => use pixel from last input column
                     int p = base_p + ((col < width) ? col : (width-1))*comp;
                     float r = dataR[p], g = dataG[p], b = dataB[p];
                     Y[pos]= +0.29900f*r + 0.58700f*g + 0.11400f*b - 128;
                     U[pos]= -0.16874f*r - 0.33126f*g + 0.50000f*b;
                     V[pos]= +0.50000f*r - 0.41869f*g - 0.08131f*b;
                  }
               }

               DCY = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, Y.ptr, 8, fdtbl_Y.ptr, DCY, YDC_HT, YAC_HT);
               DCU = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, U.ptr, 8, fdtbl_UV.ptr, DCU, UVDC_HT, UVAC_HT);
               DCV = stbiw__jpg_processDU(s, &bitBuf, &bitCnt, V.ptr, 8, fdtbl_UV.ptr, DCV, UVDC_HT, UVAC_HT);
            }
         }
      }

      // Do the bit alignment of the EOI marker
      stbiw__jpg_writeBits(s, &bitBuf, &bitCnt, fillBits.ptr);
   }

   // EOI
   stbiw__putc(s, 0xFF);
   stbiw__putc(s, 0xD9);

   return 1;
}

extern int stbi_write_jpg_to_func(stbi_write_func func, void* context, int x, int y, int comp, const(void)* data, int quality)
{
   auto s = stbi__write_context.init; // = { 0 };
   stbi__start_write_callbacks(&s, func, context);
   return stbi_write_jpg_core(&s, x, y, comp, cast(void*) data, quality);
}


version (STBI_WRITE_NO_STDIO) {} else {

extern int stbi_write_jpg(const(char)* filename, int x, int y, int comp, const(void)* data, int quality)
{
   auto s = stbi__write_context.init; // = { 0 };
   if (stbi__start_write_file(&s,filename)) {
      int r = stbi_write_jpg_core(&s, x, y, comp, data, quality);
      stbi__end_write_file(&s);
      return r;
   } else
      return 0;
}
}


} // STB_IMAGE_WRITE_IMPLEMENTATION


/* Revision history
      1.16  (2021-07-11)
             make Deflate code emit uncompressed blocks when it would otherwise expand
             support writing BMPs with alpha channel
      1.15  (2020-07-13) unknown
      1.14  (2020-02-02) updated JPEG writer to downsample chroma channels
      1.13
      1.12
      1.11  (2019-08-11)

      1.10  (2019-02-07)
             support utf8 filenames in Windows; fix warnings and platform ifdefs
      1.09  (2018-02-11)
             fix typo in zlib quality API, improve STB_I_W_STATIC in C++
      1.08  (2018-01-29)
             add stbi__flip_vertically_on_write, external zlib, zlib quality, choose PNG filter
      1.07  (2017-07-24)
             doc fix
      1.06 (2017-07-23)
             writing JPEG (using Jon Olick's code)
      1.05   ???
      1.04 (2017-03-03)
             monochrome BMP expansion
      1.03   ???
      1.02 (2016-04-02)
             avoid allocating large structures on the stack
      1.01 (2016-01-16)
             STBIW_REALLOC_SIZED: support allocators with no realloc support
             avoid race-condition in crc initialization
             minor compile issues
      1.00 (2015-09-14)
             installable file IO function
      0.99 (2015-09-13)
             warning fixes; TGA rle support
      0.98 (2015-04-08)
             added STBIW_MALLOC, STBIW_ASSERT etc
      0.97 (2015-01-18)
             fixed HDR asserts, rewrote HDR rle logic
      0.96 (2015-01-17)
             add HDR output
             fix monochrome BMP
      0.95 (2014-08-17)
             add monochrome TGA output
      0.94 (2014-05-31)
             rename private functions to avoid conflicts with stb_image.h
      0.93 (2014-05-27)
             warning fixes
      0.92 (2010-08-01)
             casts to unsigned char to fix warnings
      0.91 (2010-07-17)
             first public release
      0.90   first internal release
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
