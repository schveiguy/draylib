#include "config.h"         // Defines module configuration flags
                            //
// Support only desired texture formats on stb_image
#if !defined(SUPPORT_FILEFORMAT_BMP)
    #define STBI_NO_BMP
#endif
#if !defined(SUPPORT_FILEFORMAT_PNG)
    #define STBI_NO_PNG
#endif
#if !defined(SUPPORT_FILEFORMAT_TGA)
    #define STBI_NO_TGA
#endif
#if !defined(SUPPORT_FILEFORMAT_JPG)
    #define STBI_NO_JPEG        // Image format .jpg and .jpeg
#endif
#if !defined(SUPPORT_FILEFORMAT_PSD)
    #define STBI_NO_PSD
#endif
#if !defined(SUPPORT_FILEFORMAT_GIF)
    #define STBI_NO_GIF
#endif
#if !defined(SUPPORT_FILEFORMAT_PIC)
    #define STBI_NO_PIC
#endif
#if !defined(SUPPORT_FILEFORMAT_HDR)
    #define STBI_NO_HDR
#endif

// Image fileformats not supported by default
#define STBI_NO_PIC
#define STBI_NO_PNM             // Image format .ppm and .pgm

#if defined(__TINYC__)
    #define STBI_NO_SIMD
#endif

#define STB_IMAGE_IMPLEMENTATION
#include "external/stb_image.h"         // Required for: stbi_load_from_file()
                                        // NOTE: Used to read image data (multiple formats support)

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "external/stb_image_write.h"   // Required for: stbi_write_*()

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "external/stb_image_resize.h"  // Required for: stbir_resize_uint8() [ImageResize()]
