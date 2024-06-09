/**********************************************************************************************
*
*   raylib v4.0 - A simple and easy-to-use library to enjoy videogames programming (www.raylib.com)
*
*   FEATURES:
*       - NO external dependencies, all required libraries included with raylib
*       - Multiplatform: Windows, Linux, FreeBSD, OpenBSD, NetBSD, DragonFly,
*                        MacOS, Haiku, Android, Raspberry Pi, DRM native, HTML5.
*       - Written in plain C code (C99) in PascalCase/camelCase notation
*       - Hardware accelerated with OpenGL (1.1, 2.1, 3.3, 4.3 or ES2 - choose at compile)
*       - Unique OpenGL abstraction layer (usable as standalone module): [rlgl]
*       - Multiple Fonts formats supported (TTF, XNA fonts, AngelCode fonts)
*       - Outstanding texture formats support, including compressed formats (DXT, ETC, ASTC)
*       - Full 3d support for 3d Shapes, Models, Billboards, Heightmaps and more!
*       - Flexible Materials system, supporting classic maps and PBR maps
*       - Animated 3D models supported (skeletal bones animation) (IQM)
*       - Shaders support, including Model shaders and Postprocessing shaders
*       - Powerful math module for Vector, Matrix and Quaternion operations: [raymath]
*       - Audio loading and playing with streaming support (WAV, OGG, MP3, FLAC, XM, MOD)
*       - VR stereo rendering with configurable HMD device parameters
*       - Bindings to multiple programming languages available!
*
*   NOTES:
*       - One default Font is loaded on InitWindow()->LoadFontDefault() [core, text]
*       - One default Texture2D is loaded on rlglInit(), 1x1 white pixel R8G8B8A8 [rlgl] (OpenGL 3.3 or ES2)
*       - One default Shader is loaded on rlglInit()->rlLoadShaderDefault() [rlgl] (OpenGL 3.3 or ES2)
*       - One default RenderBatch is loaded on rlglInit()->rlLoadRenderBatch() [rlgl] (OpenGL 3.3 or ES2)
*
*   DEPENDENCIES (included):
*       [rcore] rglfw (Camilla Löwy - github.com/glfw/glfw) for window/context management and input (PLATFORM_DESKTOP)
*       [rlgl] glad (David Herberth - github.com/Dav1dde/glad) for OpenGL 3.3 extensions loading (PLATFORM_DESKTOP)
*       [raudio] miniaudio (David Reid - github.com/mackron/miniaudio) for audio device/context management
*
*   OPTIONAL DEPENDENCIES (included):
*       [rcore] msf_gif (Miles Fogle) for GIF recording
*       [rcore] sinfl (Micha Mettke) for DEFLATE decompression algorythm
*       [rcore] sdefl (Micha Mettke) for DEFLATE compression algorythm
*       [rtextures] stb_image (Sean Barret) for images loading (BMP, TGA, PNG, JPEG, HDR...)
*       [rtextures] stb_image_write (Sean Barret) for image writing (BMP, TGA, PNG, JPG)
*       [rtextures] stb_image_resize (Sean Barret) for image resizing algorithms
*       [rtext] stb_truetype (Sean Barret) for ttf fonts loading
*       [rtext] stb_rect_pack (Sean Barret) for rectangles packing
*       [rmodels] par_shapes (Philip Rideout) for parametric 3d shapes generation
*       [rmodels] tinyobj_loader_c (Syoyo Fujita) for models loading (OBJ, MTL)
*       [rmodels] cgltf (Johannes Kuhlmann) for models loading (glTF)
*       [raudio] dr_wav (David Reid) for WAV audio file loading
*       [raudio] dr_flac (David Reid) for FLAC audio file loading
*       [raudio] dr_mp3 (David Reid) for MP3 audio file loading
*       [raudio] stb_vorbis (Sean Barret) for OGG audio loading
*       [raudio] jar_xm (Joshua Reisenauer) for XM audio module loading
*       [raudio] jar_mod (Joshua Reisenauer) for MOD audio module loading
*
*
*   LICENSE: zlib/libpng
*
*   raylib is licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software:
*
*   Copyright (c) 2013-2021 Ramon Santamaria (@raysan5)
*
*   This software is provided "as-is", without any express or implied warranty. In no event
*   will the authors be held liable for any damages arising from the use of this software.
*
*   Permission is granted to anyone to use this software for any purpose, including commercial
*   applications, and to alter it and redistribute it freely, subject to the following restrictions:
*
*     1. The origin of this software must not be misrepresented; you must not claim that you
*     wrote the original software. If you use this software in a product, an acknowledgment
*     in the product documentation would be appreciated but is not required.
*
*     2. Altered source versions must be plainly marked as such, and must not be misrepresented
*     as being the original software.
*
*     3. This notice may not be removed or altered from any source distribution.
*
**********************************************************************************************/

module raylib;
import core.stdc.config;
import core.stdc.stdarg;
import std.math;

extern (C) @nogc nothrow:

// Required for: va_list - Only used by TraceLogCallback

enum RAYLIB_VERSION = "4.0";

// Function specifiers in case library is build/used as a shared library (Windows)
// NOTE: Microsoft specifiers to tell compiler that symbols are imported/exported from a .dll

// We are building the library as a Win32 shared library (.dll)

// We are using the library as a Win32 shared library (.dll) // Functions defined as 'extern' by default (implicit specifiers)

//----------------------------------------------------------------------------------
// Some basic Defines
//----------------------------------------------------------------------------------

deprecated("Use std.math.PI instead.") enum PI = 3.14159265358979323846f;

enum DEG2RAD = std.math.PI / 180.0f;

enum RAD2DEG = 180.0f / std.math.PI;

// NOTE: We set some defines with some data types declared by raylib
// Other modules (raymath, rlgl) also require some of those types, so,
// to be able to use those other modules as standalone (not depending on raylib)
// this defines are very useful for internal check and avoid type (re)definitions

// Some Basic Colors
// NOTE: Custom raylib color palette for amazing visuals on WHITE background
enum LIGHTGRAY  = Color( 200, 200, 200, 255 );   // Light Gray
enum GRAY       = Color( 130, 130, 130, 255 );   // Gray
enum DARKGRAY   = Color( 80, 80, 80, 255 );      // Dark Gray
enum YELLOW     = Color( 253, 249, 0, 255 );     // Yellow
enum GOLD       = Color( 255, 203, 0, 255 );     // Gold
enum ORANGE     = Color( 255, 161, 0, 255 );     // Orange
enum PINK       = Color( 255, 109, 194, 255 );   // Pink
enum RED        = Color( 230, 41, 55, 255 );     // Red
enum MAROON     = Color( 190, 33, 55, 255 );     // Maroon
enum GREEN      = Color( 0, 228, 48, 255 );      // Green
enum LIME       = Color( 0, 158, 47, 255 );      // Lime
enum DARKGREEN  = Color( 0, 117, 44, 255 );      // Dark Green
enum SKYBLUE    = Color( 102, 191, 255, 255 );   // Sky Blue
enum BLUE       = Color( 0, 121, 241, 255 );     // Blue
enum DARKBLUE   = Color( 0, 82, 172, 255 );      // Dark Blue
enum PURPLE     = Color( 200, 122, 255, 255 );   // Purple
enum VIOLET     = Color( 135, 60, 190, 255 );    // Violet
enum DARKPURPLE = Color( 112, 31, 126, 255 );    // Dark Purple
enum BEIGE      = Color( 211, 176, 131, 255 );   // Beige
enum BROWN      = Color( 127, 106, 79, 255 );    // Brown
enum DARKBROWN  = Color( 76, 63, 47, 255 );      // Dark Brown

enum WHITE      = Color( 255, 255, 255, 255 );   // White
enum BLACK      = Color( 0, 0, 0, 255 );         // Black
enum BLANK      = Color( 0, 0, 0, 0 );           // Blank (Transparent)
enum MAGENTA    = Color( 255, 0, 255, 255 );     // Magenta
enum RAYWHITE   = Color( 245, 245, 245, 255 );   // My own White (raylib logo)

//----------------------------------------------------------------------------------
// Structures Definition
//----------------------------------------------------------------------------------
// Boolean type

// Vector2, 2 components
struct Vector2
{
    float x = 0; // Vector x component
    float y = 0; // Vector y component
}

// Vector3, 3 components
struct Vector3
{
    float x = 0; // Vector x component
    float y = 0; // Vector y component
    float z = 0; // Vector z component
}

// Vector4, 4 components
struct Vector4
{
    float x = 0; // Vector x component
    float y = 0; // Vector y component
    float z = 0; // Vector z component
    float w = 0; // Vector w component
}

// Quaternion, 4 components (Vector4 alias)
alias Quaternion = Vector4;

// Matrix, 4x4 components, column major, OpenGL style, right handed
struct Matrix
{
    float m0 = 0;
    float m4 = 0;
    float m8 = 0;
    float m12 = 0; // Matrix first row (4 components)
    float m1 = 0;
    float m5 = 0;
    float m9 = 0;
    float m13 = 0; // Matrix second row (4 components)
    float m2 = 0;
    float m6 = 0;
    float m10 = 0;
    float m14 = 0; // Matrix third row (4 components)
    float m3 = 0;
    float m7 = 0;
    float m11 = 0;
    float m15 = 0; // Matrix fourth row (4 components)
}

// Color, 4 components, R8G8B8A8 (32bit)
struct Color
{
    ubyte r; // Color red value
    ubyte g; // Color green value
    ubyte b; // Color blue value
    ubyte a; // Color alpha value
}

// Rectangle, 4 components
struct Rectangle
{
    float x = 0; // Rectangle top-left corner position x
    float y = 0; // Rectangle top-left corner position y
    float width = 0; // Rectangle width
    float height = 0; // Rectangle height
}

// Image, pixel data stored in CPU memory (RAM)
struct Image
{
    void* data; // Image raw data
    int width; // Image base width
    int height; // Image base height
    int mipmaps; // Mipmap levels, 1 by default
    int format; // Data format (PixelFormat type)
}

// Texture, tex data stored in GPU memory (VRAM)
struct Texture
{
    uint id; // OpenGL texture id
    int width; // Texture base width
    int height; // Texture base height
    int mipmaps; // Mipmap levels, 1 by default
    int format; // Data format (PixelFormat type)
}

// Texture2D, same as Texture
alias Texture2D = Texture;

// TextureCubemap, same as Texture
alias TextureCubemap = Texture;

// RenderTexture, fbo for texture rendering
struct RenderTexture
{
    uint id; // OpenGL framebuffer object id
    Texture texture; // Color buffer attachment texture
    Texture depth; // Depth buffer attachment texture
}

// RenderTexture2D, same as RenderTexture
alias RenderTexture2D = RenderTexture;

// NPatchInfo, n-patch layout info
struct NPatchInfo
{
    Rectangle source; // Texture source rectangle
    int left; // Left border offset
    int top; // Top border offset
    int right; // Right border offset
    int bottom; // Bottom border offset
    int layout; // Layout of the n-patch: 3x3, 1x3 or 3x1
}

// GlyphInfo, font characters glyphs info
struct GlyphInfo
{
    int value; // Character value (Unicode)
    int offsetX; // Character offset X when drawing
    int offsetY; // Character offset Y when drawing
    int advanceX; // Character advance position X
    Image image; // Character image data
}

// Font, font texture and GlyphInfo array data
struct Font
{
    int baseSize; // Base size (default chars height)
    int glyphCount; // Number of glyph characters
    int glyphPadding; // Padding around the glyph characters
    Texture2D texture; // Texture atlas containing the glyphs
    Rectangle* recs; // Rectangles in texture for the glyphs
    GlyphInfo* glyphs; // Glyphs info data
}

// Camera, defines position/orientation in 3d space
struct Camera3D
{
    Vector3 position; // Camera position
    Vector3 target; // Camera target it looks-at
    Vector3 up; // Camera up vector (rotation over its axis)
    float fovy = 0; // Camera field-of-view apperture in Y (degrees) in perspective, used as near plane width in orthographic
    int projection; // Camera projection: CAMERA_PERSPECTIVE or CAMERA_ORTHOGRAPHIC
}

alias Camera = Camera3D; // Camera type fallback, defaults to Camera3D

// Camera2D, defines position/orientation in 2d space
struct Camera2D
{
    Vector2 offset; // Camera offset (displacement from target)
    Vector2 target; // Camera target (rotation and zoom origin)
    float rotation = 0; // Camera rotation in degrees
    float zoom = 0; // Camera zoom (scaling), should be 1.0f by default
}

// Mesh, vertex data and vao/vbo
struct Mesh
{
    int vertexCount; // Number of vertices stored in arrays
    int triangleCount; // Number of triangles stored (indexed or not)

    // Vertex attributes data
    float* vertices; // Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
    float* texcoords; // Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
    float* texcoords2; // Vertex second texture coordinates (useful for lightmaps) (shader-location = 5)
    float* normals; // Vertex normals (XYZ - 3 components per vertex) (shader-location = 2)
    float* tangents; // Vertex tangents (XYZW - 4 components per vertex) (shader-location = 4)
    ubyte* colors; // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
    ushort* indices; // Vertex indices (in case vertex data comes indexed)

    // Animation vertex data
    float* animVertices; // Animated vertex positions (after bones transformations)
    float* animNormals; // Animated normals (after bones transformations)
    ubyte* boneIds; // Vertex bone ids, max 255 bone ids, up to 4 bones influence by vertex (skinning)
    float* boneWeights; // Vertex bone weight, up to 4 bones influence by vertex (skinning)

    // OpenGL identifiers
    uint vaoId; // OpenGL Vertex Array Object id
    uint* vboId; // OpenGL Vertex Buffer Objects id (default vertex data)
}

// Shader
struct Shader
{
    uint id; // Shader program id
    int* locs; // Shader locations array (RL_MAX_SHADER_LOCATIONS)
}

// MaterialMap
struct MaterialMap
{
    Texture2D texture; // Material map texture
    Color color; // Material map color
    float value = 0; // Material map value
}

// Material, includes shader and maps
struct Material
{
    Shader shader; // Material shader
    MaterialMap* maps; // Material maps array (MAX_MATERIAL_MAPS)
    float[4] params = 0; // Material generic parameters (if required)
}

// Transform, vectex transformation data
struct Transform
{
    Vector3 translation; // Translation
    Quaternion rotation; // Rotation
    Vector3 scale; // Scale
}

// Bone, skeletal animation bone
struct BoneInfo
{
    char[32] name; // Bone name
    int parent; // Bone parent
}

// Model, meshes, materials and animation data
struct Model
{
    Matrix transform; // Local transform matrix

    int meshCount; // Number of meshes
    int materialCount; // Number of materials
    Mesh* meshes; // Meshes array
    Material* materials; // Materials array
    int* meshMaterial; // Mesh material number

    // Animation data
    int boneCount; // Number of bones
    BoneInfo* bones; // Bones information (skeleton)
    Transform* bindPose; // Bones base transformation (pose)
}

// ModelAnimation
struct ModelAnimation
{
    int boneCount; // Number of bones
    int frameCount; // Number of animation frames
    BoneInfo* bones; // Bones information (skeleton)
    Transform** framePoses; // Poses array by frame
}

// Ray, ray for raycasting
struct Ray
{
    Vector3 position; // Ray position (origin)
    Vector3 direction; // Ray direction
}

// RayCollision, ray hit information
struct RayCollision
{
    bool hit; // Did the ray hit something?
    float distance = 0; // Distance to nearest hit
    Vector3 point; // Point of nearest hit
    Vector3 normal; // Surface normal of hit
}

// BoundingBox
struct BoundingBox
{
    Vector3 min; // Minimum vertex box-corner
    Vector3 max; // Maximum vertex box-corner
}

// Wave, audio wave data
struct Wave
{
    uint frameCount; // Total number of frames (considering channels)
    uint sampleRate; // Frequency (samples per second)
    uint sampleSize; // Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    uint channels; // Number of channels (1-mono, 2-stereo, ...)
    void* data; // Buffer data pointer
}

struct rAudioBuffer;

// AudioStream, custom audio stream
struct AudioStream
{
    rAudioBuffer* buffer; // Pointer to internal data used by the audio system

    uint sampleRate; // Frequency (samples per second)
    uint sampleSize; // Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    uint channels; // Number of channels (1-mono, 2-stereo, ...)
}

// Sound
struct Sound
{
    AudioStream stream; // Audio stream
    uint frameCount; // Total number of frames (considering channels)
}

// Music, audio stream, anything longer than ~10 seconds should be streamed
struct Music
{
    AudioStream stream; // Audio stream
    uint frameCount; // Total number of frames (considering channels)
    bool looping; // Music looping enable

    int ctxType; // Type of music context (audio filetype)
    void* ctxData; // Audio context data, depends on type
}

// VrDeviceInfo, Head-Mounted-Display device parameters
struct VrDeviceInfo
{
    int hResolution; // Horizontal resolution in pixels
    int vResolution; // Vertical resolution in pixels
    float hScreenSize = 0; // Horizontal size in meters
    float vScreenSize = 0; // Vertical size in meters
    float vScreenCenter = 0; // Screen center in meters
    float eyeToScreenDistance = 0; // Distance between eye and display in meters
    float lensSeparationDistance = 0; // Lens separation distance in meters
    float interpupillaryDistance = 0; // IPD (distance between pupils) in meters
    float[4] lensDistortionValues = 0; // Lens distortion constant parameters
    float[4] chromaAbCorrection = 0; // Chromatic aberration correction parameters
}

// VrStereoConfig, VR stereo rendering configuration for simulator
struct VrStereoConfig
{
    Matrix[2] projection; // VR projection matrices (per eye)
    Matrix[2] viewOffset; // VR view offset matrices (per eye)
    float[2] leftLensCenter = 0; // VR left lens center
    float[2] rightLensCenter = 0; // VR right lens center
    float[2] leftScreenCenter = 0; // VR left screen center
    float[2] rightScreenCenter = 0; // VR right screen center
    float[2] scale = 0; // VR distortion scale
    float[2] scaleIn = 0; // VR distortion scale in
}

//----------------------------------------------------------------------------------
// Enumerators Definition
//----------------------------------------------------------------------------------
// System/Window config flags
// NOTE: Every bit registers one state (use it with bit masks)
// By default all flags are set to 0
enum ConfigFlags
{
    FLAG_VSYNC_HINT = 0x00000040, // Set to try enabling V-Sync on GPU
    FLAG_FULLSCREEN_MODE = 0x00000002, // Set to run program in fullscreen
    FLAG_WINDOW_RESIZABLE = 0x00000004, // Set to allow resizable window
    FLAG_WINDOW_UNDECORATED = 0x00000008, // Set to disable window decoration (frame and buttons)
    FLAG_WINDOW_HIDDEN = 0x00000080, // Set to hide window
    FLAG_WINDOW_MINIMIZED = 0x00000200, // Set to minimize window (iconify)
    FLAG_WINDOW_MAXIMIZED = 0x00000400, // Set to maximize window (expanded to monitor)
    FLAG_WINDOW_UNFOCUSED = 0x00000800, // Set to window non focused
    FLAG_WINDOW_TOPMOST = 0x00001000, // Set to window always on top
    FLAG_WINDOW_ALWAYS_RUN = 0x00000100, // Set to allow windows running while minimized
    FLAG_WINDOW_TRANSPARENT = 0x00000010, // Set to allow transparent framebuffer
    FLAG_WINDOW_HIGHDPI = 0x00002000, // Set to support HighDPI
    FLAG_MSAA_4X_HINT = 0x00000020, // Set to try enabling MSAA 4X
    FLAG_INTERLACED_HINT = 0x00010000 // Set to try enabling interlaced video format (for V3D)
}

// Trace log level
// NOTE: Organized by priority level
enum TraceLogLevel
{
    LOG_ALL = 0, // Display all logs
    LOG_TRACE = 1, // Trace logging, intended for internal use only
    LOG_DEBUG = 2, // Debug logging, used for internal debugging, it should be disabled on release builds
    LOG_INFO = 3, // Info logging, used for program execution info
    LOG_WARNING = 4, // Warning logging, used on recoverable failures
    LOG_ERROR = 5, // Error logging, used on unrecoverable failures
    LOG_FATAL = 6, // Fatal logging, used to abort program: exit(EXIT_FAILURE)
    LOG_NONE = 7 // Disable logging
}

// Keyboard keys (US keyboard layout)
// NOTE: Use GetKeyPressed() to allow redefining
// required keys for alternative layouts
enum KeyboardKey
{
    KEY_NULL = 0, // Key: NULL, used for no key pressed
    // Alphanumeric keys
    KEY_APOSTROPHE = 39, // Key: '
    KEY_COMMA = 44, // Key: ,
    KEY_MINUS = 45, // Key: -
    KEY_PERIOD = 46, // Key: .
    KEY_SLASH = 47, // Key: /
    KEY_ZERO = 48, // Key: 0
    KEY_ONE = 49, // Key: 1
    KEY_TWO = 50, // Key: 2
    KEY_THREE = 51, // Key: 3
    KEY_FOUR = 52, // Key: 4
    KEY_FIVE = 53, // Key: 5
    KEY_SIX = 54, // Key: 6
    KEY_SEVEN = 55, // Key: 7
    KEY_EIGHT = 56, // Key: 8
    KEY_NINE = 57, // Key: 9
    KEY_SEMICOLON = 59, // Key: ;
    KEY_EQUAL = 61, // Key: =
    KEY_A = 65, // Key: A | a
    KEY_B = 66, // Key: B | b
    KEY_C = 67, // Key: C | c
    KEY_D = 68, // Key: D | d
    KEY_E = 69, // Key: E | e
    KEY_F = 70, // Key: F | f
    KEY_G = 71, // Key: G | g
    KEY_H = 72, // Key: H | h
    KEY_I = 73, // Key: I | i
    KEY_J = 74, // Key: J | j
    KEY_K = 75, // Key: K | k
    KEY_L = 76, // Key: L | l
    KEY_M = 77, // Key: M | m
    KEY_N = 78, // Key: N | n
    KEY_O = 79, // Key: O | o
    KEY_P = 80, // Key: P | p
    KEY_Q = 81, // Key: Q | q
    KEY_R = 82, // Key: R | r
    KEY_S = 83, // Key: S | s
    KEY_T = 84, // Key: T | t
    KEY_U = 85, // Key: U | u
    KEY_V = 86, // Key: V | v
    KEY_W = 87, // Key: W | w
    KEY_X = 88, // Key: X | x
    KEY_Y = 89, // Key: Y | y
    KEY_Z = 90, // Key: Z | z
    KEY_LEFT_BRACKET = 91, // Key: [
    KEY_BACKSLASH = 92, // Key: '\'
    KEY_RIGHT_BRACKET = 93, // Key: ]
    KEY_GRAVE = 96, // Key: `
    // Function keys
    KEY_SPACE = 32, // Key: Space
    KEY_ESCAPE = 256, // Key: Esc
    KEY_ENTER = 257, // Key: Enter
    KEY_TAB = 258, // Key: Tab
    KEY_BACKSPACE = 259, // Key: Backspace
    KEY_INSERT = 260, // Key: Ins
    KEY_DELETE = 261, // Key: Del
    KEY_RIGHT = 262, // Key: Cursor right
    KEY_LEFT = 263, // Key: Cursor left
    KEY_DOWN = 264, // Key: Cursor down
    KEY_UP = 265, // Key: Cursor up
    KEY_PAGE_UP = 266, // Key: Page up
    KEY_PAGE_DOWN = 267, // Key: Page down
    KEY_HOME = 268, // Key: Home
    KEY_END = 269, // Key: End
    KEY_CAPS_LOCK = 280, // Key: Caps lock
    KEY_SCROLL_LOCK = 281, // Key: Scroll down
    KEY_NUM_LOCK = 282, // Key: Num lock
    KEY_PRINT_SCREEN = 283, // Key: Print screen
    KEY_PAUSE = 284, // Key: Pause
    KEY_F1 = 290, // Key: F1
    KEY_F2 = 291, // Key: F2
    KEY_F3 = 292, // Key: F3
    KEY_F4 = 293, // Key: F4
    KEY_F5 = 294, // Key: F5
    KEY_F6 = 295, // Key: F6
    KEY_F7 = 296, // Key: F7
    KEY_F8 = 297, // Key: F8
    KEY_F9 = 298, // Key: F9
    KEY_F10 = 299, // Key: F10
    KEY_F11 = 300, // Key: F11
    KEY_F12 = 301, // Key: F12
    KEY_LEFT_SHIFT = 340, // Key: Shift left
    KEY_LEFT_CONTROL = 341, // Key: Control left
    KEY_LEFT_ALT = 342, // Key: Alt left
    KEY_LEFT_SUPER = 343, // Key: Super left
    KEY_RIGHT_SHIFT = 344, // Key: Shift right
    KEY_RIGHT_CONTROL = 345, // Key: Control right
    KEY_RIGHT_ALT = 346, // Key: Alt right
    KEY_RIGHT_SUPER = 347, // Key: Super right
    KEY_KB_MENU = 348, // Key: KB menu
    // Keypad keys
    KEY_KP_0 = 320, // Key: Keypad 0
    KEY_KP_1 = 321, // Key: Keypad 1
    KEY_KP_2 = 322, // Key: Keypad 2
    KEY_KP_3 = 323, // Key: Keypad 3
    KEY_KP_4 = 324, // Key: Keypad 4
    KEY_KP_5 = 325, // Key: Keypad 5
    KEY_KP_6 = 326, // Key: Keypad 6
    KEY_KP_7 = 327, // Key: Keypad 7
    KEY_KP_8 = 328, // Key: Keypad 8
    KEY_KP_9 = 329, // Key: Keypad 9
    KEY_KP_DECIMAL = 330, // Key: Keypad .
    KEY_KP_DIVIDE = 331, // Key: Keypad /
    KEY_KP_MULTIPLY = 332, // Key: Keypad *
    KEY_KP_SUBTRACT = 333, // Key: Keypad -
    KEY_KP_ADD = 334, // Key: Keypad +
    KEY_KP_ENTER = 335, // Key: Keypad Enter
    KEY_KP_EQUAL = 336, // Key: Keypad =
    // Android key buttons
    KEY_BACK = 4, // Key: Android back button
    KEY_MENU = 82, // Key: Android menu button
    KEY_VOLUME_UP = 24, // Key: Android volume up button
    KEY_VOLUME_DOWN = 25 // Key: Android volume down button
}

// Add backwards compatibility support for deprecated names
enum MOUSE_LEFT_BUTTON = MouseButton.MOUSE_BUTTON_LEFT;
enum MOUSE_RIGHT_BUTTON = MouseButton.MOUSE_BUTTON_RIGHT;
enum MOUSE_MIDDLE_BUTTON = MouseButton.MOUSE_BUTTON_MIDDLE;

// Mouse buttons
enum MouseButton
{
    MOUSE_BUTTON_LEFT = 0, // Mouse button left
    MOUSE_BUTTON_RIGHT = 1, // Mouse button right
    MOUSE_BUTTON_MIDDLE = 2, // Mouse button middle (pressed wheel)
    MOUSE_BUTTON_SIDE = 3, // Mouse button side (advanced mouse device)
    MOUSE_BUTTON_EXTRA = 4, // Mouse button extra (advanced mouse device)
    MOUSE_BUTTON_FORWARD = 5, // Mouse button fordward (advanced mouse device)
    MOUSE_BUTTON_BACK = 6 // Mouse button back (advanced mouse device)
}

// Mouse cursor
enum MouseCursor
{
    MOUSE_CURSOR_DEFAULT = 0, // Default pointer shape
    MOUSE_CURSOR_ARROW = 1, // Arrow shape
    MOUSE_CURSOR_IBEAM = 2, // Text writing cursor shape
    MOUSE_CURSOR_CROSSHAIR = 3, // Cross shape
    MOUSE_CURSOR_POINTING_HAND = 4, // Pointing hand cursor
    MOUSE_CURSOR_RESIZE_EW = 5, // Horizontal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NS = 6, // Vertical resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NWSE = 7, // Top-left to bottom-right diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NESW = 8, // The top-right to bottom-left diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_ALL = 9, // The omni-directional resize/move cursor shape
    MOUSE_CURSOR_NOT_ALLOWED = 10 // The operation-not-allowed shape
}

// Gamepad buttons
enum GamepadButton
{
    GAMEPAD_BUTTON_UNKNOWN = 0, // Unknown button, just for error checking
    GAMEPAD_BUTTON_LEFT_FACE_UP = 1, // Gamepad left DPAD up button
    GAMEPAD_BUTTON_LEFT_FACE_RIGHT = 2, // Gamepad left DPAD right button
    GAMEPAD_BUTTON_LEFT_FACE_DOWN = 3, // Gamepad left DPAD down button
    GAMEPAD_BUTTON_LEFT_FACE_LEFT = 4, // Gamepad left DPAD left button
    GAMEPAD_BUTTON_RIGHT_FACE_UP = 5, // Gamepad right button up (i.e. PS3: Triangle, Xbox: Y)
    GAMEPAD_BUTTON_RIGHT_FACE_RIGHT = 6, // Gamepad right button right (i.e. PS3: Square, Xbox: X)
    GAMEPAD_BUTTON_RIGHT_FACE_DOWN = 7, // Gamepad right button down (i.e. PS3: Cross, Xbox: A)
    GAMEPAD_BUTTON_RIGHT_FACE_LEFT = 8, // Gamepad right button left (i.e. PS3: Circle, Xbox: B)
    GAMEPAD_BUTTON_LEFT_TRIGGER_1 = 9, // Gamepad top/back trigger left (first), it could be a trailing button
    GAMEPAD_BUTTON_LEFT_TRIGGER_2 = 10, // Gamepad top/back trigger left (second), it could be a trailing button
    GAMEPAD_BUTTON_RIGHT_TRIGGER_1 = 11, // Gamepad top/back trigger right (one), it could be a trailing button
    GAMEPAD_BUTTON_RIGHT_TRIGGER_2 = 12, // Gamepad top/back trigger right (second), it could be a trailing button
    GAMEPAD_BUTTON_MIDDLE_LEFT = 13, // Gamepad center buttons, left one (i.e. PS3: Select)
    GAMEPAD_BUTTON_MIDDLE = 14, // Gamepad center buttons, middle one (i.e. PS3: PS, Xbox: XBOX)
    GAMEPAD_BUTTON_MIDDLE_RIGHT = 15, // Gamepad center buttons, right one (i.e. PS3: Start)
    GAMEPAD_BUTTON_LEFT_THUMB = 16, // Gamepad joystick pressed button left
    GAMEPAD_BUTTON_RIGHT_THUMB = 17 // Gamepad joystick pressed button right
}

// Gamepad axis
enum GamepadAxis
{
    GAMEPAD_AXIS_LEFT_X = 0, // Gamepad left stick X axis
    GAMEPAD_AXIS_LEFT_Y = 1, // Gamepad left stick Y axis
    GAMEPAD_AXIS_RIGHT_X = 2, // Gamepad right stick X axis
    GAMEPAD_AXIS_RIGHT_Y = 3, // Gamepad right stick Y axis
    GAMEPAD_AXIS_LEFT_TRIGGER = 4, // Gamepad back trigger left, pressure level: [1..-1]
    GAMEPAD_AXIS_RIGHT_TRIGGER = 5 // Gamepad back trigger right, pressure level: [1..-1]
}

// Material map index
enum MaterialMapIndex
{
    MATERIAL_MAP_ALBEDO = 0, // Albedo material (same as: MATERIAL_MAP_DIFFUSE)
    MATERIAL_MAP_METALNESS = 1, // Metalness material (same as: MATERIAL_MAP_SPECULAR)
    MATERIAL_MAP_NORMAL = 2, // Normal material
    MATERIAL_MAP_ROUGHNESS = 3, // Roughness material
    MATERIAL_MAP_OCCLUSION = 4, // Ambient occlusion material
    MATERIAL_MAP_EMISSION = 5, // Emission material
    MATERIAL_MAP_HEIGHT = 6, // Heightmap material
    MATERIAL_MAP_CUBEMAP = 7, // Cubemap material (NOTE: Uses GL_TEXTURE_CUBE_MAP)
    MATERIAL_MAP_IRRADIANCE = 8, // Irradiance material (NOTE: Uses GL_TEXTURE_CUBE_MAP)
    MATERIAL_MAP_PREFILTER = 9, // Prefilter material (NOTE: Uses GL_TEXTURE_CUBE_MAP)
    MATERIAL_MAP_BRDF = 10 // Brdf material
}

enum MATERIAL_MAP_DIFFUSE = MaterialMapIndex.MATERIAL_MAP_ALBEDO;
enum MATERIAL_MAP_SPECULAR = MaterialMapIndex.MATERIAL_MAP_METALNESS;

// Shader location index
enum ShaderLocationIndex
{
    SHADER_LOC_VERTEX_POSITION = 0, // Shader location: vertex attribute: position
    SHADER_LOC_VERTEX_TEXCOORD01 = 1, // Shader location: vertex attribute: texcoord01
    SHADER_LOC_VERTEX_TEXCOORD02 = 2, // Shader location: vertex attribute: texcoord02
    SHADER_LOC_VERTEX_NORMAL = 3, // Shader location: vertex attribute: normal
    SHADER_LOC_VERTEX_TANGENT = 4, // Shader location: vertex attribute: tangent
    SHADER_LOC_VERTEX_COLOR = 5, // Shader location: vertex attribute: color
    SHADER_LOC_MATRIX_MVP = 6, // Shader location: matrix uniform: model-view-projection
    SHADER_LOC_MATRIX_VIEW = 7, // Shader location: matrix uniform: view (camera transform)
    SHADER_LOC_MATRIX_PROJECTION = 8, // Shader location: matrix uniform: projection
    SHADER_LOC_MATRIX_MODEL = 9, // Shader location: matrix uniform: model (transform)
    SHADER_LOC_MATRIX_NORMAL = 10, // Shader location: matrix uniform: normal
    SHADER_LOC_VECTOR_VIEW = 11, // Shader location: vector uniform: view
    SHADER_LOC_COLOR_DIFFUSE = 12, // Shader location: vector uniform: diffuse color
    SHADER_LOC_COLOR_SPECULAR = 13, // Shader location: vector uniform: specular color
    SHADER_LOC_COLOR_AMBIENT = 14, // Shader location: vector uniform: ambient color
    SHADER_LOC_MAP_ALBEDO = 15, // Shader location: sampler2d texture: albedo (same as: SHADER_LOC_MAP_DIFFUSE)
    SHADER_LOC_MAP_METALNESS = 16, // Shader location: sampler2d texture: metalness (same as: SHADER_LOC_MAP_SPECULAR)
    SHADER_LOC_MAP_NORMAL = 17, // Shader location: sampler2d texture: normal
    SHADER_LOC_MAP_ROUGHNESS = 18, // Shader location: sampler2d texture: roughness
    SHADER_LOC_MAP_OCCLUSION = 19, // Shader location: sampler2d texture: occlusion
    SHADER_LOC_MAP_EMISSION = 20, // Shader location: sampler2d texture: emission
    SHADER_LOC_MAP_HEIGHT = 21, // Shader location: sampler2d texture: height
    SHADER_LOC_MAP_CUBEMAP = 22, // Shader location: samplerCube texture: cubemap
    SHADER_LOC_MAP_IRRADIANCE = 23, // Shader location: samplerCube texture: irradiance
    SHADER_LOC_MAP_PREFILTER = 24, // Shader location: samplerCube texture: prefilter
    SHADER_LOC_MAP_BRDF = 25, // Shader location: sampler2d texture: brdf
    SHADER_LOC_MAP_DIFFUSE = SHADER_LOC_MAP_ALBEDO,
    SHADER_LOC_MAP_SPECULAR = SHADER_LOC_MAP_METALNESS
}


// Shader uniform data type
enum ShaderUniformDataType
{
    SHADER_UNIFORM_FLOAT = 0, // Shader uniform type: float
    SHADER_UNIFORM_VEC2 = 1, // Shader uniform type: vec2 (2 float)
    SHADER_UNIFORM_VEC3 = 2, // Shader uniform type: vec3 (3 float)
    SHADER_UNIFORM_VEC4 = 3, // Shader uniform type: vec4 (4 float)
    SHADER_UNIFORM_INT = 4, // Shader uniform type: int
    SHADER_UNIFORM_IVEC2 = 5, // Shader uniform type: ivec2 (2 int)
    SHADER_UNIFORM_IVEC3 = 6, // Shader uniform type: ivec3 (3 int)
    SHADER_UNIFORM_IVEC4 = 7, // Shader uniform type: ivec4 (4 int)
    SHADER_UNIFORM_SAMPLER2D = 8 // Shader uniform type: sampler2d
}

// Shader attribute data types
enum ShaderAttributeDataType
{
    SHADER_ATTRIB_FLOAT = 0, // Shader attribute type: float
    SHADER_ATTRIB_VEC2 = 1, // Shader attribute type: vec2 (2 float)
    SHADER_ATTRIB_VEC3 = 2, // Shader attribute type: vec3 (3 float)
    SHADER_ATTRIB_VEC4 = 3 // Shader attribute type: vec4 (4 float)
}

// Pixel formats
// NOTE: Support depends on OpenGL version and platform
enum PixelFormat
{
    PIXELFORMAT_UNCOMPRESSED_GRAYSCALE = 1, // 8 bit per pixel (no alpha)
    PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA = 2, // 8*2 bpp (2 channels)
    PIXELFORMAT_UNCOMPRESSED_R5G6B5 = 3, // 16 bpp
    PIXELFORMAT_UNCOMPRESSED_R8G8B8 = 4, // 24 bpp
    PIXELFORMAT_UNCOMPRESSED_R5G5B5A1 = 5, // 16 bpp (1 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R4G4B4A4 = 6, // 16 bpp (4 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 = 7, // 32 bpp
    PIXELFORMAT_UNCOMPRESSED_R32 = 8, // 32 bpp (1 channel - float)
    PIXELFORMAT_UNCOMPRESSED_R32G32B32 = 9, // 32*3 bpp (3 channels - float)
    PIXELFORMAT_UNCOMPRESSED_R32G32B32A32 = 10, // 32*4 bpp (4 channels - float)
    PIXELFORMAT_COMPRESSED_DXT1_RGB = 11, // 4 bpp (no alpha)
    PIXELFORMAT_COMPRESSED_DXT1_RGBA = 12, // 4 bpp (1 bit alpha)
    PIXELFORMAT_COMPRESSED_DXT3_RGBA = 13, // 8 bpp
    PIXELFORMAT_COMPRESSED_DXT5_RGBA = 14, // 8 bpp
    PIXELFORMAT_COMPRESSED_ETC1_RGB = 15, // 4 bpp
    PIXELFORMAT_COMPRESSED_ETC2_RGB = 16, // 4 bpp
    PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA = 17, // 8 bpp
    PIXELFORMAT_COMPRESSED_PVRT_RGB = 18, // 4 bpp
    PIXELFORMAT_COMPRESSED_PVRT_RGBA = 19, // 4 bpp
    PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA = 20, // 8 bpp
    PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA = 21 // 2 bpp
}

// Texture parameters: filter mode
// NOTE 1: Filtering considers mipmaps if available in the texture
// NOTE 2: Filter is accordingly set for minification and magnification
enum TextureFilter
{
    TEXTURE_FILTER_POINT = 0, // No filter, just pixel aproximation
    TEXTURE_FILTER_BILINEAR = 1, // Linear filtering
    TEXTURE_FILTER_TRILINEAR = 2, // Trilinear filtering (linear with mipmaps)
    TEXTURE_FILTER_ANISOTROPIC_4X = 3, // Anisotropic filtering 4x
    TEXTURE_FILTER_ANISOTROPIC_8X = 4, // Anisotropic filtering 8x
    TEXTURE_FILTER_ANISOTROPIC_16X = 5 // Anisotropic filtering 16x
}

// Texture parameters: wrap mode
enum TextureWrap
{
    TEXTURE_WRAP_REPEAT = 0, // Repeats texture in tiled mode
    TEXTURE_WRAP_CLAMP = 1, // Clamps texture to edge pixel in tiled mode
    TEXTURE_WRAP_MIRROR_REPEAT = 2, // Mirrors and repeats the texture in tiled mode
    TEXTURE_WRAP_MIRROR_CLAMP = 3 // Mirrors and clamps to border the texture in tiled mode
}

// Cubemap layouts
enum CubemapLayout
{
    CUBEMAP_LAYOUT_AUTO_DETECT = 0, // Automatically detect layout type
    CUBEMAP_LAYOUT_LINE_VERTICAL = 1, // Layout is defined by a vertical line with faces
    CUBEMAP_LAYOUT_LINE_HORIZONTAL = 2, // Layout is defined by an horizontal line with faces
    CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR = 3, // Layout is defined by a 3x4 cross with cubemap faces
    CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE = 4, // Layout is defined by a 4x3 cross with cubemap faces
    CUBEMAP_LAYOUT_PANORAMA = 5 // Layout is defined by a panorama image (equirectangular map)
}

// Font type, defines generation method
enum FontType
{
    FONT_DEFAULT = 0, // Default font generation, anti-aliased
    FONT_BITMAP = 1, // Bitmap font generation, no anti-aliasing
    FONT_SDF = 2 // SDF font generation, requires external shader
}

// Color blending modes (pre-defined)
enum BlendMode
{
    BLEND_ALPHA = 0, // Blend textures considering alpha (default)
    BLEND_ADDITIVE = 1, // Blend textures adding colors
    BLEND_MULTIPLIED = 2, // Blend textures multiplying colors
    BLEND_ADD_COLORS = 3, // Blend textures adding colors (alternative)
    BLEND_SUBTRACT_COLORS = 4, // Blend textures subtracting colors (alternative)
    BLEND_CUSTOM = 5 // Belnd textures using custom src/dst factors (use rlSetBlendMode())
}

// Gesture
// NOTE: It could be used as flags to enable only some gestures
enum Gesture
{
    GESTURE_NONE = 0, // No gesture
    GESTURE_TAP = 1, // Tap gesture
    GESTURE_DOUBLETAP = 2, // Double tap gesture
    GESTURE_HOLD = 4, // Hold gesture
    GESTURE_DRAG = 8, // Drag gesture
    GESTURE_SWIPE_RIGHT = 16, // Swipe right gesture
    GESTURE_SWIPE_LEFT = 32, // Swipe left gesture
    GESTURE_SWIPE_UP = 64, // Swipe up gesture
    GESTURE_SWIPE_DOWN = 128, // Swipe down gesture
    GESTURE_PINCH_IN = 256, // Pinch in gesture
    GESTURE_PINCH_OUT = 512 // Pinch out gesture
}

// Camera system modes
enum CameraMode
{
    CAMERA_CUSTOM = 0, // Custom camera
    CAMERA_FREE = 1, // Free camera
    CAMERA_ORBITAL = 2, // Orbital camera
    CAMERA_FIRST_PERSON = 3, // First person camera
    CAMERA_THIRD_PERSON = 4 // Third person camera
}

// Camera projection
enum CameraProjection
{
    CAMERA_PERSPECTIVE = 0, // Perspective projection
    CAMERA_ORTHOGRAPHIC = 1 // Orthographic projection
}

// N-patch layout
enum NPatchLayout
{
    NPATCH_NINE_PATCH = 0, // Npatch layout: 3x3 tiles
    NPATCH_THREE_PATCH_VERTICAL = 1, // Npatch layout: 1x3 tiles
    NPATCH_THREE_PATCH_HORIZONTAL = 2 // Npatch layout: 3x1 tiles
}

// Callbacks to hook some internal functions
// WARNING: This callbacks are intended for advance users
alias TraceLogCallback = void function (int logLevel, const(char)* text, va_list args); // Logging: Redirect trace log messages
alias LoadFileDataCallback = ubyte* function (const(char)* fileName, uint* bytesRead); // FileIO: Load binary data
alias SaveFileDataCallback = bool function (const(char)* fileName, void* data, uint bytesToWrite); // FileIO: Save binary data
alias LoadFileTextCallback = char* function (const(char)* fileName); // FileIO: Load text data
alias SaveFileTextCallback = bool function (const(char)* fileName, char* text); // FileIO: Save text data

//------------------------------------------------------------------------------------
// Global Variables Definition
//------------------------------------------------------------------------------------
// It's lonely here...

//------------------------------------------------------------------------------------
// Window and Graphics Device Functions (Module: core)
//------------------------------------------------------------------------------------

// Prevents name mangling of functions

// Window-related functions
public import raylib.rcore : InitWindow, WindowShouldClose, CloseWindow,
       IsWindowReady, IsWindowFullscreen, IsWindowHidden, IsWindowMinimized,
       IsWindowMaximized, IsWindowFocused, IsWindowResized, IsWindowState;
//void InitWindow (int width, int height, const(char)* title); // Initialize window and OpenGL context
//bool WindowShouldClose (); // Check if KEY_ESCAPE pressed or Close icon pressed
//void CloseWindow (); // Close window and unload OpenGL context
//bool IsWindowReady (); // Check if window has been initialized successfully
//bool IsWindowFullscreen (); // Check if window is currently fullscreen
//bool IsWindowHidden (); // Check if window is currently hidden (only PLATFORM_DESKTOP)
//bool IsWindowMinimized (); // Check if window is currently minimized (only PLATFORM_DESKTOP)
//bool IsWindowMaximized (); // Check if window is currently maximized (only PLATFORM_DESKTOP)
//bool IsWindowFocused (); // Check if window is currently focused (only PLATFORM_DESKTOP)
//bool IsWindowResized (); // Check if window has been resized last frame
//bool IsWindowState (uint flag); // Check if one specific window flag is enabled

public import raylib.rcore: SetWindowState, ClearWindowState, ToggleFullscreen,
       MaximizeWindow, MinimizeWindow, RestoreWindow, SetWindowIcon,
       SetWindowTitle, SetWindowPosition, SetWindowMonitor, SetWindowMinSize,
       SetWindowSize, GetWindowHandle;
//void SetWindowState (uint flags); // Set window configuration state using flags
//void ClearWindowState (uint flags); // Clear window configuration state flags
//void ToggleFullscreen (); // Toggle window state: fullscreen/windowed (only PLATFORM_DESKTOP)
//void MaximizeWindow (); // Set window state: maximized, if resizable (only PLATFORM_DESKTOP)
//void MinimizeWindow (); // Set window state: minimized, if resizable (only PLATFORM_DESKTOP)
//void RestoreWindow (); // Set window state: not minimized/maximized (only PLATFORM_DESKTOP)
//void SetWindowIcon (Image image); // Set icon for window (only PLATFORM_DESKTOP)
//void SetWindowTitle (const(char)* title); // Set title for window (only PLATFORM_DESKTOP)
//void SetWindowPosition (int x, int y); // Set window position on screen (only PLATFORM_DESKTOP)
//void SetWindowMonitor (int monitor); // Set monitor for the current window (fullscreen mode)
//void SetWindowMinSize (int width, int height); // Set window minimum dimensions (for FLAG_WINDOW_RESIZABLE)
//void SetWindowSize (int width, int height); // Set window dimensions
//void* GetWindowHandle (); // Get native window handle

public import raylib.rcore : GetScreenWidth, GetScreenHeight;
//int GetScreenWidth (); // Get current screen width
//int GetScreenHeight (); // Get current screen height
int GetMonitorCount (); // Get number of connected monitors
int GetCurrentMonitor (); // Get current connected monitor
Vector2 GetMonitorPosition (int monitor); // Get specified monitor position
int GetMonitorWidth (int monitor); // Get specified monitor width (max available by monitor)
int GetMonitorHeight (int monitor); // Get specified monitor height (max available by monitor)
int GetMonitorPhysicalWidth (int monitor); // Get specified monitor physical width in millimetres
int GetMonitorPhysicalHeight (int monitor); // Get specified monitor physical height in millimetres
int GetMonitorRefreshRate (int monitor); // Get specified monitor refresh rate
Vector2 GetWindowPosition (); // Get window position XY on monitor
Vector2 GetWindowScaleDPI (); // Get window scale DPI factor
const(char)* GetMonitorName (int monitor); // Get the human-readable, UTF-8 encoded name of the primary monitor
void SetClipboardText (const(char)* text); // Set clipboard text content
const(char)* GetClipboardText (); // Get clipboard text content

// Custom frame control functions
// NOTE: Those functions are intended for advance users that want full control over the frame processing
// By default EndDrawing() does this job: draws everything + SwapScreenBuffer() + manage frame timming + PollInputEvents()
// To avoid that behaviour and control frame processes manually, enable in config.h: SUPPORT_CUSTOM_FRAME_CONTROL
void SwapScreenBuffer (); // Swap back buffer with front buffer (screen drawing)
void PollInputEvents (); // Register all input events
void WaitTime (float ms); // Wait for some milliseconds (halt program execution)

// Cursor-related functions
void ShowCursor (); // Shows cursor
void HideCursor (); // Hides cursor
bool IsCursorHidden (); // Check if cursor is not visible
void EnableCursor (); // Enables cursor (unlock cursor)
void DisableCursor (); // Disables cursor (lock cursor)
bool IsCursorOnScreen (); // Check if cursor is on the screen

// Drawing-related functions
void ClearBackground (Color color); // Set background color (framebuffer clear color)
void BeginDrawing (); // Setup canvas (framebuffer) to start drawing
void EndDrawing (); // End canvas drawing and swap buffers (double buffering)
void BeginMode2D (Camera2D camera); // Begin 2D mode with custom camera (2D)
void EndMode2D (); // Ends 2D mode with custom camera
void BeginMode3D (Camera3D camera); // Begin 3D mode with custom camera (3D)
void EndMode3D (); // Ends 3D mode and returns to default 2D orthographic mode
void BeginTextureMode (RenderTexture2D target); // Begin drawing to render texture
void EndTextureMode (); // Ends drawing to render texture
void BeginShaderMode (Shader shader); // Begin custom shader drawing
void EndShaderMode (); // End custom shader drawing (use default shader)
void BeginBlendMode (int mode); // Begin blending mode (alpha, additive, multiplied, subtract, custom)
void EndBlendMode (); // End blending mode (reset to default: alpha blending)
void BeginScissorMode (int x, int y, int width, int height); // Begin scissor mode (define screen area for following drawing)
void EndScissorMode (); // End scissor mode
void BeginVrStereoMode (VrStereoConfig config); // Begin stereo rendering (requires VR simulator)
void EndVrStereoMode (); // End stereo rendering (requires VR simulator)

// VR stereo config functions for VR simulator
VrStereoConfig LoadVrStereoConfig (VrDeviceInfo device); // Load VR stereo config for VR simulator device parameters
void UnloadVrStereoConfig (VrStereoConfig config); // Unload VR stereo config

// Shader management functions
// NOTE: Shader functionality is not available on OpenGL 1.1
Shader LoadShader (const(char)* vsFileName, const(char)* fsFileName); // Load shader from files and bind default locations
Shader LoadShaderFromMemory (const(char)* vsCode, const(char)* fsCode); // Load shader from code strings and bind default locations
int GetShaderLocation (Shader shader, const(char)* uniformName); // Get shader uniform location
int GetShaderLocationAttrib (Shader shader, const(char)* attribName); // Get shader attribute location
void SetShaderValue (Shader shader, int locIndex, const(void)* value, int uniformType); // Set shader uniform value
void SetShaderValueV (Shader shader, int locIndex, const(void)* value, int uniformType, int count); // Set shader uniform value vector
void SetShaderValueMatrix (Shader shader, int locIndex, Matrix mat); // Set shader uniform value (matrix 4x4)
void SetShaderValueTexture (Shader shader, int locIndex, Texture2D texture); // Set shader uniform value for texture (sampler2d)
void UnloadShader (Shader shader); // Unload shader from GPU memory (VRAM)

// Screen-space-related functions
Ray GetMouseRay (Vector2 mousePosition, Camera camera); // Get a ray trace from mouse position
Matrix GetCameraMatrix (Camera camera); // Get camera transform matrix (view matrix)
Matrix GetCameraMatrix2D (Camera2D camera); // Get camera 2d transform matrix
Vector2 GetWorldToScreen (Vector3 position, Camera camera); // Get the screen space position for a 3d world space position
Vector2 GetWorldToScreenEx (Vector3 position, Camera camera, int width, int height); // Get size position for a 3d world space position
Vector2 GetWorldToScreen2D (Vector2 position, Camera2D camera); // Get the screen space position for a 2d camera world space position
Vector2 GetScreenToWorld2D (Vector2 position, Camera2D camera); // Get the world space position for a 2d camera screen space position

// Timing-related functions
void SetTargetFPS (int fps); // Set target FPS (maximum)
int GetFPS (); // Get current FPS
float GetFrameTime (); // Get time in seconds for last frame drawn (delta time)
double GetTime (); // Get elapsed time in seconds since InitWindow()

// Misc. functions
int GetRandomValue (int min, int max); // Get a random value between min and max (both included)
void SetRandomSeed (uint seed); // Set the seed for the random number generator
void TakeScreenshot (const(char)* fileName); // Takes a screenshot of current screen (filename extension defines format)
void SetConfigFlags (uint flags); // Setup init configuration flags (view FLAGS)

void TraceLog (int logLevel, const(char)* text, ...); // Show trace log messages (LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR...)
void SetTraceLogLevel (int logLevel); // Set the current threshold (minimum) log level
void* MemAlloc (int size); // Internal memory allocator
void* MemRealloc (void* ptr, int size); // Internal memory reallocator
void MemFree (void* ptr); // Internal memory free

// Set custom callbacks
// WARNING: Callbacks setup is intended for advance users
void SetTraceLogCallback (TraceLogCallback callback); // Set custom trace log
void SetLoadFileDataCallback (LoadFileDataCallback callback); // Set custom file binary data loader
void SetSaveFileDataCallback (SaveFileDataCallback callback); // Set custom file binary data saver
void SetLoadFileTextCallback (LoadFileTextCallback callback); // Set custom file text data loader
void SetSaveFileTextCallback (SaveFileTextCallback callback); // Set custom file text data saver

// Files management functions
ubyte* LoadFileData (const(char)* fileName, uint* bytesRead); // Load file data as byte array (read)
void UnloadFileData (ubyte* data); // Unload file data allocated by LoadFileData()
bool SaveFileData (const(char)* fileName, void* data, uint bytesToWrite); // Save data to file from byte array (write), returns true on success
char* LoadFileText (const(char)* fileName); // Load text data from file (read), returns a '\0' terminated string
void UnloadFileText (char* text); // Unload file text data allocated by LoadFileText()
bool SaveFileText (const(char)* fileName, char* text); // Save text data to file (write), string must be '\0' terminated, returns true on success
bool FileExists (const(char)* fileName); // Check if file exists
bool DirectoryExists (const(char)* dirPath); // Check if a directory path exists
bool IsFileExtension (const(char)* fileName, const(char)* ext); // Check file extension (including point: .png, .wav)
const(char)* GetFileExtension (const(char)* fileName); // Get pointer to extension for a filename string (includes dot: '.png')
const(char)* GetFileName (const(char)* filePath); // Get pointer to filename for a path string
const(char)* GetFileNameWithoutExt (const(char)* filePath); // Get filename string without extension (uses static string)
const(char)* GetDirectoryPath (const(char)* filePath); // Get full path for a given fileName with path (uses static string)
const(char)* GetPrevDirectoryPath (const(char)* dirPath); // Get previous directory path for a given path (uses static string)
const(char)* GetWorkingDirectory (); // Get current working directory (uses static string)
char** GetDirectoryFiles (const(char)* dirPath, int* count); // Get filenames in a directory path (memory should be freed)
void ClearDirectoryFiles (); // Clear directory files paths buffers (free memory)
bool ChangeDirectory (const(char)* dir); // Change working directory, return true on success
bool IsFileDropped (); // Check if a file has been dropped into window
char** GetDroppedFiles (int* count); // Get dropped files names (memory should be freed)
void ClearDroppedFiles (); // Clear dropped files paths buffer (free memory)
c_long GetFileModTime (const(char)* fileName); // Get file modification time (last write time)

// Compression/Encoding functionality
ubyte* CompressData (ubyte* data, int dataLength, int* compDataLength); // Compress data (DEFLATE algorithm)
ubyte* DecompressData (ubyte* compData, int compDataLength, int* dataLength); // Decompress data (DEFLATE algorithm)
char* EncodeDataBase64 (const(ubyte)* data, int dataLength, int* outputLength); // Encode data to Base64 string
ubyte* DecodeDataBase64 (ubyte* data, int* outputLength); // Decode Base64 string data

// Persistent storage management
bool SaveStorageValue (uint position, int value); // Save integer value to storage file (to defined position), returns true on success
int LoadStorageValue (uint position); // Load integer value from storage file (from defined position)

void OpenURL (const(char)* url); // Open URL with default system browser (if available)

//------------------------------------------------------------------------------------
// Input Handling Functions (Module: core)
//------------------------------------------------------------------------------------

// Input-related functions: keyboard
bool IsKeyPressed (int key); // Check if a key has been pressed once
bool IsKeyDown (int key); // Check if a key is being pressed
bool IsKeyReleased (int key); // Check if a key has been released once
bool IsKeyUp (int key); // Check if a key is NOT being pressed
void SetExitKey (int key); // Set a custom key to exit program (default is ESC)
int GetKeyPressed (); // Get key pressed (keycode), call it multiple times for keys queued, returns 0 when the queue is empty
int GetCharPressed (); // Get char pressed (unicode), call it multiple times for chars queued, returns 0 when the queue is empty

// Input-related functions: gamepads
bool IsGamepadAvailable (int gamepad); // Check if a gamepad is available
const(char)* GetGamepadName (int gamepad); // Get gamepad internal name id
bool IsGamepadButtonPressed (int gamepad, int button); // Check if a gamepad button has been pressed once
bool IsGamepadButtonDown (int gamepad, int button); // Check if a gamepad button is being pressed
bool IsGamepadButtonReleased (int gamepad, int button); // Check if a gamepad button has been released once
bool IsGamepadButtonUp (int gamepad, int button); // Check if a gamepad button is NOT being pressed
int GetGamepadButtonPressed (); // Get the last gamepad button pressed
int GetGamepadAxisCount (int gamepad); // Get gamepad axis count for a gamepad
float GetGamepadAxisMovement (int gamepad, int axis); // Get axis movement value for a gamepad axis
int SetGamepadMappings (const(char)* mappings); // Set internal gamepad mappings (SDL_GameControllerDB)

// Input-related functions: mouse
bool IsMouseButtonPressed (int button); // Check if a mouse button has been pressed once
bool IsMouseButtonDown (int button); // Check if a mouse button is being pressed
bool IsMouseButtonReleased (int button); // Check if a mouse button has been released once
bool IsMouseButtonUp (int button); // Check if a mouse button is NOT being pressed
int GetMouseX (); // Get mouse position X
int GetMouseY (); // Get mouse position Y
Vector2 GetMousePosition (); // Get mouse position XY
Vector2 GetMouseDelta (); // Get mouse delta between frames
void SetMousePosition (int x, int y); // Set mouse position XY
void SetMouseOffset (int offsetX, int offsetY); // Set mouse offset
void SetMouseScale (float scaleX, float scaleY); // Set mouse scaling
float GetMouseWheelMove (); // Get mouse wheel movement Y
void SetMouseCursor (int cursor); // Set mouse cursor

// Input-related functions: touch
int GetTouchX (); // Get touch position X for touch point 0 (relative to screen size)
int GetTouchY (); // Get touch position Y for touch point 0 (relative to screen size)
Vector2 GetTouchPosition (int index); // Get touch position XY for a touch point index (relative to screen size)
int GetTouchPointId (int index); // Get touch point identifier for given index
int GetTouchPointCount (); // Get number of touch points

//------------------------------------------------------------------------------------
// Gestures and Touch Handling Functions (Module: rgestures)
//------------------------------------------------------------------------------------
void SetGesturesEnabled (uint flags); // Enable a set of gestures using flags
bool IsGestureDetected (int gesture); // Check if a gesture have been detected
int GetGestureDetected (); // Get latest detected gesture
float GetGestureHoldDuration (); // Get gesture hold time in milliseconds
Vector2 GetGestureDragVector (); // Get gesture drag vector
float GetGestureDragAngle (); // Get gesture drag angle
Vector2 GetGesturePinchVector (); // Get gesture pinch delta
float GetGesturePinchAngle (); // Get gesture pinch angle

//------------------------------------------------------------------------------------
// Camera System Functions (Module: rcamera)
//------------------------------------------------------------------------------------
void SetCameraMode (Camera camera, int mode); // Set camera mode (multiple camera modes available)
void UpdateCamera (Camera* camera); // Update camera position for selected mode

void SetCameraPanControl (int keyPan); // Set camera pan key to combine with mouse movement (free camera)
void SetCameraAltControl (int keyAlt); // Set camera alt key to combine with mouse movement (free camera)
void SetCameraSmoothZoomControl (int keySmoothZoom); // Set camera smooth zoom key to combine with mouse (free camera)
void SetCameraMoveControls (int keyFront, int keyBack, int keyRight, int keyLeft, int keyUp, int keyDown); // Set camera move controls (1st person and 3rd person cameras)

//------------------------------------------------------------------------------------
// Basic Shapes Drawing Functions (Module: shapes)
//------------------------------------------------------------------------------------
// Set texture and rectangle to be used on shapes drawing
// NOTE: It can be useful when using basic shapes and one single font,
// defining a font char white rectangle would allow drawing everything in a single draw call
void SetShapesTexture (Texture2D texture, Rectangle source); // Set texture and rectangle to be used on shapes drawing

// Basic shapes drawing functions
void DrawPixel (int posX, int posY, Color color); // Draw a pixel
void DrawPixelV (Vector2 position, Color color); // Draw a pixel (Vector version)
void DrawLine (int startPosX, int startPosY, int endPosX, int endPosY, Color color); // Draw a line
void DrawLineV (Vector2 startPos, Vector2 endPos, Color color); // Draw a line (Vector version)
void DrawLineEx (Vector2 startPos, Vector2 endPos, float thick, Color color); // Draw a line defining thickness
void DrawLineBezier (Vector2 startPos, Vector2 endPos, float thick, Color color); // Draw a line using cubic-bezier curves in-out
void DrawLineBezierQuad (Vector2 startPos, Vector2 endPos, Vector2 controlPos, float thick, Color color); // Draw line using quadratic bezier curves with a control point
void DrawLineBezierCubic (Vector2 startPos, Vector2 endPos, Vector2 startControlPos, Vector2 endControlPos, float thick, Color color); // Draw line using cubic bezier curves with 2 control points
void DrawLineStrip (Vector2* points, int pointCount, Color color); // Draw lines sequence
void DrawCircle (int centerX, int centerY, float radius, Color color); // Draw a color-filled circle
void DrawCircleSector (Vector2 center, float radius, float startAngle, float endAngle, int segments, Color color); // Draw a piece of a circle
void DrawCircleSectorLines (Vector2 center, float radius, float startAngle, float endAngle, int segments, Color color); // Draw circle sector outline
void DrawCircleGradient (int centerX, int centerY, float radius, Color color1, Color color2); // Draw a gradient-filled circle
void DrawCircleV (Vector2 center, float radius, Color color); // Draw a color-filled circle (Vector version)
void DrawCircleLines (int centerX, int centerY, float radius, Color color); // Draw circle outline
void DrawEllipse (int centerX, int centerY, float radiusH, float radiusV, Color color); // Draw ellipse
void DrawEllipseLines (int centerX, int centerY, float radiusH, float radiusV, Color color); // Draw ellipse outline
void DrawRing (Vector2 center, float innerRadius, float outerRadius, float startAngle, float endAngle, int segments, Color color); // Draw ring
void DrawRingLines (Vector2 center, float innerRadius, float outerRadius, float startAngle, float endAngle, int segments, Color color); // Draw ring outline
void DrawRectangle (int posX, int posY, int width, int height, Color color); // Draw a color-filled rectangle
void DrawRectangleV (Vector2 position, Vector2 size, Color color); // Draw a color-filled rectangle (Vector version)
void DrawRectangleRec (Rectangle rec, Color color); // Draw a color-filled rectangle
void DrawRectanglePro (Rectangle rec, Vector2 origin, float rotation, Color color); // Draw a color-filled rectangle with pro parameters
void DrawRectangleGradientV (int posX, int posY, int width, int height, Color color1, Color color2); // Draw a vertical-gradient-filled rectangle
void DrawRectangleGradientH (int posX, int posY, int width, int height, Color color1, Color color2); // Draw a horizontal-gradient-filled rectangle
void DrawRectangleGradientEx (Rectangle rec, Color col1, Color col2, Color col3, Color col4); // Draw a gradient-filled rectangle with custom vertex colors
void DrawRectangleLines (int posX, int posY, int width, int height, Color color); // Draw rectangle outline
void DrawRectangleLinesEx (Rectangle rec, float lineThick, Color color); // Draw rectangle outline with extended parameters
void DrawRectangleRounded (Rectangle rec, float roundness, int segments, Color color); // Draw rectangle with rounded edges
void DrawRectangleRoundedLines (Rectangle rec, float roundness, int segments, float lineThick, Color color); // Draw rectangle with rounded edges outline
void DrawTriangle (Vector2 v1, Vector2 v2, Vector2 v3, Color color); // Draw a color-filled triangle (vertex in counter-clockwise order!)
void DrawTriangleLines (Vector2 v1, Vector2 v2, Vector2 v3, Color color); // Draw triangle outline (vertex in counter-clockwise order!)
void DrawTriangleFan (Vector2* points, int pointCount, Color color); // Draw a triangle fan defined by points (first vertex is the center)
void DrawTriangleStrip (Vector2* points, int pointCount, Color color); // Draw a triangle strip defined by points
void DrawPoly (Vector2 center, int sides, float radius, float rotation, Color color); // Draw a regular polygon (Vector version)
void DrawPolyLines (Vector2 center, int sides, float radius, float rotation, Color color); // Draw a polygon outline of n sides
void DrawPolyLinesEx (Vector2 center, int sides, float radius, float rotation, float lineThick, Color color); // Draw a polygon outline of n sides with extended parameters

// Basic shapes collision detection functions
bool CheckCollisionRecs (Rectangle rec1, Rectangle rec2); // Check collision between two rectangles
bool CheckCollisionCircles (Vector2 center1, float radius1, Vector2 center2, float radius2); // Check collision between two circles
bool CheckCollisionCircleRec (Vector2 center, float radius, Rectangle rec); // Check collision between circle and rectangle
bool CheckCollisionPointRec (Vector2 point, Rectangle rec); // Check if point is inside rectangle
bool CheckCollisionPointCircle (Vector2 point, Vector2 center, float radius); // Check if point is inside circle
bool CheckCollisionPointTriangle (Vector2 point, Vector2 p1, Vector2 p2, Vector2 p3); // Check if point is inside a triangle
bool CheckCollisionLines (Vector2 startPos1, Vector2 endPos1, Vector2 startPos2, Vector2 endPos2, Vector2* collisionPoint); // Check the collision between two lines defined by two points each, returns collision point by reference
bool CheckCollisionPointLine (Vector2 point, Vector2 p1, Vector2 p2, int threshold); // Check if point belongs to line created between two points [p1] and [p2] with defined margin in pixels [threshold]
Rectangle GetCollisionRec (Rectangle rec1, Rectangle rec2); // Get collision rectangle for two rectangles collision

//------------------------------------------------------------------------------------
// Texture Loading and Drawing Functions (Module: textures)
//------------------------------------------------------------------------------------

// Image loading functions
// NOTE: This functions do not require GPU access
Image LoadImage (const(char)* fileName); // Load image from file into CPU memory (RAM)
Image LoadImageRaw (const(char)* fileName, int width, int height, int format, int headerSize); // Load image from RAW file data
Image LoadImageAnim (const(char)* fileName, int* frames); // Load image sequence from file (frames appended to image.data)
Image LoadImageFromMemory (const(char)* fileType, const(ubyte)* fileData, int dataSize); // Load image from memory buffer, fileType refers to extension: i.e. '.png'
Image LoadImageFromTexture (Texture2D texture); // Load image from GPU texture data
Image LoadImageFromScreen (); // Load image from screen buffer and (screenshot)
void UnloadImage (Image image); // Unload image from CPU memory (RAM)
bool ExportImage (Image image, const(char)* fileName); // Export image data to file, returns true on success
bool ExportImageAsCode (Image image, const(char)* fileName); // Export image as code file defining an array of bytes, returns true on success

// Image generation functions
Image GenImageColor (int width, int height, Color color); // Generate image: plain color
Image GenImageGradientV (int width, int height, Color top, Color bottom); // Generate image: vertical gradient
Image GenImageGradientH (int width, int height, Color left, Color right); // Generate image: horizontal gradient
Image GenImageGradientRadial (int width, int height, float density, Color inner, Color outer); // Generate image: radial gradient
Image GenImageChecked (int width, int height, int checksX, int checksY, Color col1, Color col2); // Generate image: checked
Image GenImageWhiteNoise (int width, int height, float factor); // Generate image: white noise
Image GenImageCellular (int width, int height, int tileSize); // Generate image: cellular algorithm, bigger tileSize means bigger cells

// Image manipulation functions
Image ImageCopy (Image image); // Create an image duplicate (useful for transformations)
Image ImageFromImage (Image image, Rectangle rec); // Create an image from another image piece
Image ImageText (const(char)* text, int fontSize, Color color); // Create an image from text (default font)
Image ImageTextEx (Font font, const(char)* text, float fontSize, float spacing, Color tint); // Create an image from text (custom sprite font)
void ImageFormat (Image* image, int newFormat); // Convert image data to desired format
void ImageToPOT (Image* image, Color fill); // Convert image to POT (power-of-two)
void ImageCrop (Image* image, Rectangle crop); // Crop an image to a defined rectangle
void ImageAlphaCrop (Image* image, float threshold); // Crop image depending on alpha value
void ImageAlphaClear (Image* image, Color color, float threshold); // Clear alpha channel to desired color
void ImageAlphaMask (Image* image, Image alphaMask); // Apply alpha mask to image
void ImageAlphaPremultiply (Image* image); // Premultiply alpha channel
void ImageResize (Image* image, int newWidth, int newHeight); // Resize image (Bicubic scaling algorithm)
void ImageResizeNN (Image* image, int newWidth, int newHeight); // Resize image (Nearest-Neighbor scaling algorithm)
void ImageResizeCanvas (Image* image, int newWidth, int newHeight, int offsetX, int offsetY, Color fill); // Resize canvas and fill with color
void ImageMipmaps (Image* image); // Compute all mipmap levels for a provided image
void ImageDither (Image* image, int rBpp, int gBpp, int bBpp, int aBpp); // Dither image data to 16bpp or lower (Floyd-Steinberg dithering)
void ImageFlipVertical (Image* image); // Flip image vertically
void ImageFlipHorizontal (Image* image); // Flip image horizontally
void ImageRotateCW (Image* image); // Rotate image clockwise 90deg
void ImageRotateCCW (Image* image); // Rotate image counter-clockwise 90deg
void ImageColorTint (Image* image, Color color); // Modify image color: tint
void ImageColorInvert (Image* image); // Modify image color: invert
void ImageColorGrayscale (Image* image); // Modify image color: grayscale
void ImageColorContrast (Image* image, float contrast); // Modify image color: contrast (-100 to 100)
void ImageColorBrightness (Image* image, int brightness); // Modify image color: brightness (-255 to 255)
void ImageColorReplace (Image* image, Color color, Color replace); // Modify image color: replace color
Color* LoadImageColors (Image image); // Load color data from image as a Color array (RGBA - 32bit)
Color* LoadImagePalette (Image image, int maxPaletteSize, int* colorCount); // Load colors palette from image as a Color array (RGBA - 32bit)
void UnloadImageColors (Color* colors); // Unload color data loaded with LoadImageColors()
void UnloadImagePalette (Color* colors); // Unload colors palette loaded with LoadImagePalette()
Rectangle GetImageAlphaBorder (Image image, float threshold); // Get image alpha border rectangle
Color GetImageColor (Image image, int x, int y); // Get image pixel color at (x, y) position

// Image drawing functions
// NOTE: Image software-rendering functions (CPU)
void ImageClearBackground (Image* dst, Color color); // Clear image background with given color
void ImageDrawPixel (Image* dst, int posX, int posY, Color color); // Draw pixel within an image
void ImageDrawPixelV (Image* dst, Vector2 position, Color color); // Draw pixel within an image (Vector version)
void ImageDrawLine (Image* dst, int startPosX, int startPosY, int endPosX, int endPosY, Color color); // Draw line within an image
void ImageDrawLineV (Image* dst, Vector2 start, Vector2 end, Color color); // Draw line within an image (Vector version)
void ImageDrawCircle (Image* dst, int centerX, int centerY, int radius, Color color); // Draw circle within an image
void ImageDrawCircleV (Image* dst, Vector2 center, int radius, Color color); // Draw circle within an image (Vector version)
void ImageDrawRectangle (Image* dst, int posX, int posY, int width, int height, Color color); // Draw rectangle within an image
void ImageDrawRectangleV (Image* dst, Vector2 position, Vector2 size, Color color); // Draw rectangle within an image (Vector version)
void ImageDrawRectangleRec (Image* dst, Rectangle rec, Color color); // Draw rectangle within an image
void ImageDrawRectangleLines (Image* dst, Rectangle rec, int thick, Color color); // Draw rectangle lines within an image
void ImageDraw (Image* dst, Image src, Rectangle srcRec, Rectangle dstRec, Color tint); // Draw a source image within a destination image (tint applied to source)
void ImageDrawText (Image* dst, const(char)* text, int posX, int posY, int fontSize, Color color); // Draw text (using default font) within an image (destination)
void ImageDrawTextEx (Image* dst, Font font, const(char)* text, Vector2 position, float fontSize, float spacing, Color tint); // Draw text (custom sprite font) within an image (destination)

// Texture loading functions
// NOTE: These functions require GPU access
Texture2D LoadTexture (const(char)* fileName); // Load texture from file into GPU memory (VRAM)
Texture2D LoadTextureFromImage (Image image); // Load texture from image data
TextureCubemap LoadTextureCubemap (Image image, int layout); // Load cubemap from image, multiple image cubemap layouts supported
RenderTexture2D LoadRenderTexture (int width, int height); // Load texture for rendering (framebuffer)
void UnloadTexture (Texture2D texture); // Unload texture from GPU memory (VRAM)
void UnloadRenderTexture (RenderTexture2D target); // Unload render texture from GPU memory (VRAM)
void UpdateTexture (Texture2D texture, const(void)* pixels); // Update GPU texture with new data
void UpdateTextureRec (Texture2D texture, Rectangle rec, const(void)* pixels); // Update GPU texture rectangle with new data

// Texture configuration functions
void GenTextureMipmaps (Texture2D* texture); // Generate GPU mipmaps for a texture
void SetTextureFilter (Texture2D texture, int filter); // Set texture scaling filter mode
void SetTextureWrap (Texture2D texture, int wrap); // Set texture wrapping mode

// Texture drawing functions
void DrawTexture (Texture2D texture, int posX, int posY, Color tint); // Draw a Texture2D
void DrawTextureV (Texture2D texture, Vector2 position, Color tint); // Draw a Texture2D with position defined as Vector2
void DrawTextureEx (Texture2D texture, Vector2 position, float rotation, float scale, Color tint); // Draw a Texture2D with extended parameters
void DrawTextureRec (Texture2D texture, Rectangle source, Vector2 position, Color tint); // Draw a part of a texture defined by a rectangle
void DrawTextureQuad (Texture2D texture, Vector2 tiling, Vector2 offset, Rectangle quad, Color tint); // Draw texture quad with tiling and offset parameters
void DrawTextureTiled (Texture2D texture, Rectangle source, Rectangle dest, Vector2 origin, float rotation, float scale, Color tint); // Draw part of a texture (defined by a rectangle) with rotation and scale tiled into dest.
void DrawTexturePro (Texture2D texture, Rectangle source, Rectangle dest, Vector2 origin, float rotation, Color tint); // Draw a part of a texture defined by a rectangle with 'pro' parameters
void DrawTextureNPatch (Texture2D texture, NPatchInfo nPatchInfo, Rectangle dest, Vector2 origin, float rotation, Color tint); // Draws a texture (or part of it) that stretches or shrinks nicely
void DrawTexturePoly (Texture2D texture, Vector2 center, Vector2* points, Vector2* texcoords, int pointCount, Color tint); // Draw a textured polygon

// Color/pixel related functions
Color Fade (Color color, float alpha); // Get color with alpha applied, alpha goes from 0.0f to 1.0f
int ColorToInt (Color color); // Get hexadecimal value for a Color
Vector4 ColorNormalize (Color color); // Get Color normalized as float [0..1]
Color ColorFromNormalized (Vector4 normalized); // Get Color from normalized values [0..1]
Vector3 ColorToHSV (Color color); // Get HSV values for a Color, hue [0..360], saturation/value [0..1]
Color ColorFromHSV (float hue, float saturation, float value); // Get a Color from HSV values, hue [0..360], saturation/value [0..1]
Color ColorAlpha (Color color, float alpha); // Get color with alpha applied, alpha goes from 0.0f to 1.0f
Color ColorAlphaBlend (Color dst, Color src, Color tint); // Get src alpha-blended into dst color with tint
Color GetColor (uint hexValue); // Get Color structure from hexadecimal value
Color GetPixelColor (void* srcPtr, int format); // Get Color from a source pixel pointer of certain format
void SetPixelColor (void* dstPtr, Color color, int format); // Set color formatted into destination pixel pointer
int GetPixelDataSize (int width, int height, int format); // Get pixel data size in bytes for certain format

//------------------------------------------------------------------------------------
// Font Loading and Text Drawing Functions (Module: text)
//------------------------------------------------------------------------------------

// Font loading/unloading functions
Font GetFontDefault (); // Get the default Font
Font LoadFont (const(char)* fileName); // Load font from file into GPU memory (VRAM)
Font LoadFontEx (const(char)* fileName, int fontSize, int* fontChars, int glyphCount); // Load font from file with extended parameters
Font LoadFontFromImage (Image image, Color key, int firstChar); // Load font from Image (XNA style)
Font LoadFontFromMemory (const(char)* fileType, const(ubyte)* fileData, int dataSize, int fontSize, int* fontChars, int glyphCount); // Load font from memory buffer, fileType refers to extension: i.e. '.ttf'
GlyphInfo* LoadFontData (const(ubyte)* fileData, int dataSize, int fontSize, int* fontChars, int glyphCount, int type); // Load font data for further use
Image GenImageFontAtlas (const(GlyphInfo)* chars, Rectangle** recs, int glyphCount, int fontSize, int padding, int packMethod); // Generate image font atlas using chars info
void UnloadFontData (GlyphInfo* chars, int glyphCount); // Unload font chars info data (RAM)
void UnloadFont (Font font); // Unload Font from GPU memory (VRAM)

// Text drawing functions
void DrawFPS (int posX, int posY); // Draw current FPS
void DrawText (const(char)* text, int posX, int posY, int fontSize, Color color); // Draw text (using default font)
void DrawTextEx (Font font, const(char)* text, Vector2 position, float fontSize, float spacing, Color tint); // Draw text using font and additional parameters
void DrawTextPro (Font font, const(char)* text, Vector2 position, Vector2 origin, float rotation, float fontSize, float spacing, Color tint); // Draw text using Font and pro parameters (rotation)
void DrawTextCodepoint (Font font, int codepoint, Vector2 position, float fontSize, Color tint); // Draw one character (codepoint)

// Text font info functions
int MeasureText (const(char)* text, int fontSize); // Measure string width for default font
Vector2 MeasureTextEx (Font font, const(char)* text, float fontSize, float spacing); // Measure string size for Font
int GetGlyphIndex (Font font, int codepoint); // Get glyph index position in font for a codepoint (unicode character), fallback to '?' if not found
GlyphInfo GetGlyphInfo (Font font, int codepoint); // Get glyph font info data for a codepoint (unicode character), fallback to '?' if not found
Rectangle GetGlyphAtlasRec (Font font, int codepoint); // Get glyph rectangle in font atlas for a codepoint (unicode character), fallback to '?' if not found

// Text codepoints management functions (unicode characters)
int* LoadCodepoints (const(char)* text, int* count); // Load all codepoints from a UTF-8 text string, codepoints count returned by parameter
void UnloadCodepoints (int* codepoints); // Unload codepoints data from memory
int GetCodepointCount (const(char)* text); // Get total number of codepoints in a UTF-8 encoded string
int GetCodepoint (const(char)* text, int* bytesProcessed); // Get next codepoint in a UTF-8 encoded string, 0x3f('?') is returned on failure
const(char)* CodepointToUTF8 (int codepoint, int* byteSize); // Encode one codepoint into UTF-8 byte array (array length returned as parameter)
char* TextCodepointsToUTF8 (int* codepoints, int length); // Encode text as codepoints array into UTF-8 text string (WARNING: memory must be freed!)

// Text strings management functions (no UTF-8 strings, only byte chars)
// NOTE: Some strings allocate memory internally for returned strings, just be careful!
int TextCopy (char* dst, const(char)* src); // Copy one string to another, returns bytes copied
bool TextIsEqual (const(char)* text1, const(char)* text2); // Check if two text string are equal
uint TextLength (const(char)* text); // Get text length, checks for '\0' ending
const(char)* TextFormat (const(char)* text, ...); // Text formatting with variables (sprintf() style)
const(char)* TextSubtext (const(char)* text, int position, int length); // Get a piece of a text string
char* TextReplace (char* text, const(char)* replace, const(char)* by); // Replace text string (WARNING: memory must be freed!)
char* TextInsert (const(char)* text, const(char)* insert, int position); // Insert text in a position (WARNING: memory must be freed!)
const(char)* TextJoin (const(char*)* textList, int count, const(char)* delimiter); // Join text strings with delimiter
const(char*)* TextSplit (const(char)* text, char delimiter, int* count); // Split text into multiple strings
void TextAppend (char* text, const(char)* append, int* position); // Append text at specific position and move cursor!
int TextFindIndex (const(char)* text, const(char)* find); // Find first text occurrence within a string
const(char)* TextToUpper (const(char)* text); // Get upper case version of provided string
const(char)* TextToLower (const(char)* text); // Get lower case version of provided string
const(char)* TextToPascal (const(char)* text); // Get Pascal case notation version of provided string
int TextToInteger (const(char)* text); // Get integer value from text (negative values not supported)

//------------------------------------------------------------------------------------
// Basic 3d Shapes Drawing Functions (Module: models)
//------------------------------------------------------------------------------------

// Basic geometric 3D shapes drawing functions
void DrawLine3D (Vector3 startPos, Vector3 endPos, Color color); // Draw a line in 3D world space
void DrawPoint3D (Vector3 position, Color color); // Draw a point in 3D space, actually a small line
void DrawCircle3D (Vector3 center, float radius, Vector3 rotationAxis, float rotationAngle, Color color); // Draw a circle in 3D world space
void DrawTriangle3D (Vector3 v1, Vector3 v2, Vector3 v3, Color color); // Draw a color-filled triangle (vertex in counter-clockwise order!)
void DrawTriangleStrip3D (Vector3* points, int pointCount, Color color); // Draw a triangle strip defined by points
void DrawCube (Vector3 position, float width, float height, float length, Color color); // Draw cube
void DrawCubeV (Vector3 position, Vector3 size, Color color); // Draw cube (Vector version)
void DrawCubeWires (Vector3 position, float width, float height, float length, Color color); // Draw cube wires
void DrawCubeWiresV (Vector3 position, Vector3 size, Color color); // Draw cube wires (Vector version)
void DrawCubeTexture (Texture2D texture, Vector3 position, float width, float height, float length, Color color); // Draw cube textured
void DrawCubeTextureRec (Texture2D texture, Rectangle source, Vector3 position, float width, float height, float length, Color color); // Draw cube with a region of a texture
void DrawSphere (Vector3 centerPos, float radius, Color color); // Draw sphere
void DrawSphereEx (Vector3 centerPos, float radius, int rings, int slices, Color color); // Draw sphere with extended parameters
void DrawSphereWires (Vector3 centerPos, float radius, int rings, int slices, Color color); // Draw sphere wires
void DrawCylinder (Vector3 position, float radiusTop, float radiusBottom, float height, int slices, Color color); // Draw a cylinder/cone
void DrawCylinderEx (Vector3 startPos, Vector3 endPos, float startRadius, float endRadius, int sides, Color color); // Draw a cylinder with base at startPos and top at endPos
void DrawCylinderWires (Vector3 position, float radiusTop, float radiusBottom, float height, int slices, Color color); // Draw a cylinder/cone wires
void DrawCylinderWiresEx (Vector3 startPos, Vector3 endPos, float startRadius, float endRadius, int sides, Color color); // Draw a cylinder wires with base at startPos and top at endPos
void DrawPlane (Vector3 centerPos, Vector2 size, Color color); // Draw a plane XZ
void DrawRay (Ray ray, Color color); // Draw a ray line
void DrawGrid (int slices, float spacing); // Draw a grid (centered at (0, 0, 0))

//------------------------------------------------------------------------------------
// Model 3d Loading and Drawing Functions (Module: models)
//------------------------------------------------------------------------------------

// Model management functions
Model LoadModel (const(char)* fileName); // Load model from files (meshes and materials)
Model LoadModelFromMesh (Mesh mesh); // Load model from generated mesh (default material)
void UnloadModel (Model model); // Unload model (including meshes) from memory (RAM and/or VRAM)
void UnloadModelKeepMeshes (Model model); // Unload model (but not meshes) from memory (RAM and/or VRAM)
BoundingBox GetModelBoundingBox (Model model); // Compute model bounding box limits (considers all meshes)

// Model drawing functions
void DrawModel (Model model, Vector3 position, float scale, Color tint); // Draw a model (with texture if set)
void DrawModelEx (Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint); // Draw a model with extended parameters
void DrawModelWires (Model model, Vector3 position, float scale, Color tint); // Draw a model wires (with texture if set)
void DrawModelWiresEx (Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint); // Draw a model wires (with texture if set) with extended parameters
void DrawBoundingBox (BoundingBox box, Color color); // Draw bounding box (wires)
void DrawBillboard (Camera camera, Texture2D texture, Vector3 position, float size, Color tint); // Draw a billboard texture
void DrawBillboardRec (Camera camera, Texture2D texture, Rectangle source, Vector3 position, Vector2 size, Color tint); // Draw a billboard texture defined by source
void DrawBillboardPro (Camera camera, Texture2D texture, Rectangle source, Vector3 position, Vector3 up, Vector2 size, Vector2 origin, float rotation, Color tint); // Draw a billboard texture defined by source and rotation

// Mesh management functions
void UploadMesh (Mesh* mesh, bool dynamic); // Upload mesh vertex data in GPU and provide VAO/VBO ids
void UpdateMeshBuffer (Mesh mesh, int index, void* data, int dataSize, int offset); // Update mesh vertex data in GPU for a specific buffer index
void UnloadMesh (Mesh mesh); // Unload mesh data from CPU and GPU
void DrawMesh (Mesh mesh, Material material, Matrix transform); // Draw a 3d mesh with material and transform
void DrawMeshInstanced (Mesh mesh, Material material, Matrix* transforms, int instances); // Draw multiple mesh instances with material and different transforms
bool ExportMesh (Mesh mesh, const(char)* fileName); // Export mesh data to file, returns true on success
BoundingBox GetMeshBoundingBox (Mesh mesh); // Compute mesh bounding box limits
void GenMeshTangents (Mesh* mesh); // Compute mesh tangents
void GenMeshBinormals (Mesh* mesh); // Compute mesh binormals

// Mesh generation functions
Mesh GenMeshPoly (int sides, float radius); // Generate polygonal mesh
Mesh GenMeshPlane (float width, float length, int resX, int resZ); // Generate plane mesh (with subdivisions)
Mesh GenMeshCube (float width, float height, float length); // Generate cuboid mesh
Mesh GenMeshSphere (float radius, int rings, int slices); // Generate sphere mesh (standard sphere)
Mesh GenMeshHemiSphere (float radius, int rings, int slices); // Generate half-sphere mesh (no bottom cap)
Mesh GenMeshCylinder (float radius, float height, int slices); // Generate cylinder mesh
Mesh GenMeshCone (float radius, float height, int slices); // Generate cone/pyramid mesh
Mesh GenMeshTorus (float radius, float size, int radSeg, int sides); // Generate torus mesh
Mesh GenMeshKnot (float radius, float size, int radSeg, int sides); // Generate trefoil knot mesh
Mesh GenMeshHeightmap (Image heightmap, Vector3 size); // Generate heightmap mesh from image data
Mesh GenMeshCubicmap (Image cubicmap, Vector3 cubeSize); // Generate cubes-based map mesh from image data

// Material loading/unloading functions
Material* LoadMaterials (const(char)* fileName, int* materialCount); // Load materials from model file
Material LoadMaterialDefault (); // Load default material (Supports: DIFFUSE, SPECULAR, NORMAL maps)
void UnloadMaterial (Material material); // Unload material from GPU memory (VRAM)
void SetMaterialTexture (Material* material, int mapType, Texture2D texture); // Set texture for a material map type (MATERIAL_MAP_DIFFUSE, MATERIAL_MAP_SPECULAR...)
void SetModelMeshMaterial (Model* model, int meshId, int materialId); // Set material for a mesh

// Model animations loading/unloading functions
ModelAnimation* LoadModelAnimations (const(char)* fileName, uint* animCount); // Load model animations from file
void UpdateModelAnimation (Model model, ModelAnimation anim, int frame); // Update model animation pose
void UnloadModelAnimation (ModelAnimation anim); // Unload animation data
void UnloadModelAnimations (ModelAnimation* animations, uint count); // Unload animation array data
bool IsModelAnimationValid (Model model, ModelAnimation anim); // Check model animation skeleton match

// Collision detection functions
bool CheckCollisionSpheres (Vector3 center1, float radius1, Vector3 center2, float radius2); // Check collision between two spheres
bool CheckCollisionBoxes (BoundingBox box1, BoundingBox box2); // Check collision between two bounding boxes
bool CheckCollisionBoxSphere (BoundingBox box, Vector3 center, float radius); // Check collision between box and sphere
RayCollision GetRayCollisionSphere (Ray ray, Vector3 center, float radius); // Get collision info between ray and sphere
RayCollision GetRayCollisionBox (Ray ray, BoundingBox box); // Get collision info between ray and box
RayCollision GetRayCollisionModel (Ray ray, Model model); // Get collision info between ray and model
RayCollision GetRayCollisionMesh (Ray ray, Mesh mesh, Matrix transform); // Get collision info between ray and mesh
RayCollision GetRayCollisionTriangle (Ray ray, Vector3 p1, Vector3 p2, Vector3 p3); // Get collision info between ray and triangle
RayCollision GetRayCollisionQuad (Ray ray, Vector3 p1, Vector3 p2, Vector3 p3, Vector3 p4); // Get collision info between ray and quad

//------------------------------------------------------------------------------------
// Audio Loading and Playing Functions (Module: audio)
//------------------------------------------------------------------------------------

// Audio device management functions
void InitAudioDevice (); // Initialize audio device and context
void CloseAudioDevice (); // Close the audio device and context
bool IsAudioDeviceReady (); // Check if audio device has been initialized successfully
void SetMasterVolume (float volume); // Set master volume (listener)

// Wave/Sound loading/unloading functions
Wave LoadWave (const(char)* fileName); // Load wave data from file
Wave LoadWaveFromMemory (const(char)* fileType, const(ubyte)* fileData, int dataSize); // Load wave from memory buffer, fileType refers to extension: i.e. '.wav'
Sound LoadSound (const(char)* fileName); // Load sound from file
Sound LoadSoundFromWave (Wave wave); // Load sound from wave data
void UpdateSound (Sound sound, const(void)* data, int sampleCount); // Update sound buffer with new data
void UnloadWave (Wave wave); // Unload wave data
void UnloadSound (Sound sound); // Unload sound
bool ExportWave (Wave wave, const(char)* fileName); // Export wave data to file, returns true on success
bool ExportWaveAsCode (Wave wave, const(char)* fileName); // Export wave sample data to code (.h), returns true on success

// Wave/Sound management functions
void PlaySound (Sound sound); // Play a sound
void StopSound (Sound sound); // Stop playing a sound
void PauseSound (Sound sound); // Pause a sound
void ResumeSound (Sound sound); // Resume a paused sound
void PlaySoundMulti (Sound sound); // Play a sound (using multichannel buffer pool)
void StopSoundMulti (); // Stop any sound playing (using multichannel buffer pool)
int GetSoundsPlaying (); // Get number of sounds playing in the multichannel
bool IsSoundPlaying (Sound sound); // Check if a sound is currently playing
void SetSoundVolume (Sound sound, float volume); // Set volume for a sound (1.0 is max level)
void SetSoundPitch (Sound sound, float pitch); // Set pitch for a sound (1.0 is base level)
void WaveFormat (Wave* wave, int sampleRate, int sampleSize, int channels); // Convert wave data to desired format
Wave WaveCopy (Wave wave); // Copy a wave to a new wave
void WaveCrop (Wave* wave, int initSample, int finalSample); // Crop a wave to defined samples range
float* LoadWaveSamples (Wave wave); // Load samples data from wave as a floats array
void UnloadWaveSamples (float* samples); // Unload samples data loaded with LoadWaveSamples()

// Music management functions
Music LoadMusicStream (const(char)* fileName); // Load music stream from file
Music LoadMusicStreamFromMemory (const(char)* fileType, ubyte* data, int dataSize); // Load music stream from data
void UnloadMusicStream (Music music); // Unload music stream
void PlayMusicStream (Music music); // Start music playing
bool IsMusicStreamPlaying (Music music); // Check if music is playing
void UpdateMusicStream (Music music); // Updates buffers for music streaming
void StopMusicStream (Music music); // Stop music playing
void PauseMusicStream (Music music); // Pause music playing
void ResumeMusicStream (Music music); // Resume playing paused music
void SeekMusicStream (Music music, float position); // Seek music to a position (in seconds)
void SetMusicVolume (Music music, float volume); // Set volume for music (1.0 is max level)
void SetMusicPitch (Music music, float pitch); // Set pitch for a music (1.0 is base level)
float GetMusicTimeLength (Music music); // Get music time length (in seconds)
float GetMusicTimePlayed (Music music); // Get current music time played (in seconds)

// AudioStream management functions
AudioStream LoadAudioStream (uint sampleRate, uint sampleSize, uint channels); // Load audio stream (to stream raw audio pcm data)
void UnloadAudioStream (AudioStream stream); // Unload audio stream and free memory
void UpdateAudioStream (AudioStream stream, const(void)* data, int frameCount); // Update audio stream buffers with data
bool IsAudioStreamProcessed (AudioStream stream); // Check if any audio stream buffers requires refill
void PlayAudioStream (AudioStream stream); // Play audio stream
void PauseAudioStream (AudioStream stream); // Pause audio stream
void ResumeAudioStream (AudioStream stream); // Resume audio stream
bool IsAudioStreamPlaying (AudioStream stream); // Check if audio stream is playing
void StopAudioStream (AudioStream stream); // Stop audio stream
void SetAudioStreamVolume (AudioStream stream, float volume); // Set volume for audio stream (1.0 is max level)
void SetAudioStreamPitch (AudioStream stream, float pitch); // Set pitch for audio stream (1.0 is base level)
void SetAudioStreamBufferSizeDefault (int size); // Default size for new audio streams

// RAYLIB_H
