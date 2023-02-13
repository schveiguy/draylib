module raylib.rcore;
import bindbc.glfw;
import raylib;
import raylib.config;
import raylib.raymath;
import raylib.rgestures;
import raylib.rlgl;
import raylib.external.msf_gif;
import raylib.external.sinfl;
import raylib.external.sdefl;

import core.stdc.stdlib;
import core.stdc.math;
import core.stdc.string;
import core.stdc.config;
import core.stdc.stdio;

// this is the entire public interface of sinfl, no need for a module.
version(Posix)
{
    import core.sys.posix.sys.stat;
    import core.sys.posix.time;
}
else version(Windows)
{
    import core.sys.windows.stat;
    alias stat_t = struct_stat;
}
else static assert(0, "Unknown Platform");

// define allocation functions
alias RL_MALLOC = malloc;
alias RL_CALLOC = calloc;
alias RL_REALLOC = realloc;
alias RL_FREE = free;

// for now, make everything extern(C) nothrow and @nogc

extern(C) nothrow @nogc:

version(Windows)
{
    // define windows-specific functions
    extern(Windows) uint timeBeginPeriod(uint uPeriod);
    extern(Windows) uint timeEndPeriod(uint uPeriod);
    extern(Windows) void Sleep(cpp_ulong msTimeout);

    // TODO find these definitions
    // #include <direct.h>
    alias GETCWD = _getcwd;
    alias CHDIR = _chdir;

    // TODO: rewrite this lib
    import raylib.external.dirent;
}
else version(Posix)
{
    import core.sys.posix.unistd;
    import core.sys.posix.dirent;
    alias GETCWD = getcwd;
    alias CHDIR = chdir;
}

// port of rcore.c
//
private {
    enum MAX_KEYBOARD_KEYS = 512;        // Maximum number of keyboard keys supported
    enum MAX_MOUSE_BUTTONS = 8;          // Maximum number of mouse buttons supported
    enum MAX_GAMEPADS = 4;               // Maximum number of gamepads supported
    enum MAX_GAMEPAD_AXIS = 8;           // Maximum number of axis supported (per gamepad)
    enum MAX_GAMEPAD_BUTTONS = 32;       // Maximum number of buttons supported (per gamepad)
    enum MAX_TOUCH_POINTS = 8;           // Maximum number of touch points supported
    enum MAX_KEY_PRESSED_QUEUE = 16;     // Maximum number of keys in the key input queue
    enum MAX_CHAR_PRESSED_QUEUE = 16;    // Maximum number of characters in the char input queue
    enum MAX_DIRECTORY_FILES = 512;
}

version(all) { // #if defined(SUPPORT_DEFAULT_FONT)
    void LoadFontDefault();          // [Module: text] Loads default font on InitWindow()
    void UnloadFontDefault();        // [Module: text] Unloads default font from GPU memory
}

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
version(none) // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
{
    private struct InputEventWorker{

        pthread_t threadId;             // Event reading thread id
        int fd;                         // File descriptor to the device it is assigned to
        int eventNum;                   // Number of 'event<N>' device
        Rectangle absRange;             // Range of values for absolute pointing devices (touchscreens)
        int touchSlot;                  // Hold the touch slot number of the currently being sent multitouch block
        bool isMouse;                   // True if device supports relative X Y movements
        bool isTouch;                   // True if device supports absolute X Y movements and has BTN_TOUCH
        bool isMultitouch;              // True if device supports multiple absolute movevents and has BTN_TOUCH
        bool isKeyboard;                // True if device has letter keycodes
        bool isGamepad;                 // True if device has gamepad buttons
    }
}

private struct Point {
    int x;
    int y;
}

private struct Size {
    uint width;
    uint height;
}

// Core global state context data
private struct CoreData {
    struct _Window {
        version(all) { //#if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
            GLFWwindow *handle;                 // GLFW window handle (graphic device)
        }
        version(none) { //#if defined(PLATFORM_RPI)
            EGL_DISPMANX_WINDOW_T handle;       // Native window handle (graphic device)
        }
        version(none) { //#if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
            version(none) { // #if defined(PLATFORM_DRM)
                int fd;                             // File descriptor for /dev/dri/...
                drmModeConnector *connector;        // Direct Rendering Manager (DRM) mode connector
                drmModeCrtc *crtc;                  // CRT Controller
                int modeIndex;                      // Index of the used mode of connector.modes
                /*struct*/ gbm_device *gbmDevice;       // GBM device
                /*struct*/ gbm_surface *gbmSurface;     // GBM surface
                /*struct*/ gbm_bo *prevBO;              // Previous GBM buffer object (during frame swapping)
                uint prevFB;                    // Previous GBM framebufer (during frame swapping)
            }
            EGLDisplay device;                  // Native display device (physical screen connection)
            EGLSurface surface;                 // Surface to draw on, framebuffers (connected to context)
            EGLContext context;                 // Graphic context, mode in which drawing can be done
            EGLConfig config;                   // Graphic config
        }
        const(char)* title;                  // Window text title const pointer
        uint flags;                 // Configuration flags (bit based), keeps window state
        bool ready;                         // Check if window has been initialized successfully
        bool fullscreen;                    // Check if fullscreen mode is enabled
        bool shouldClose;                   // Check if window set for closing
        bool resizedLastFrame;              // Check if window has been resized last frame

        Point position;                     // Window position on screen (required on fullscreen toggle)
        Size display;                       // Display width and height (monitor, device-screen, LCD, ...)
        Size screen;                        // Screen width and height (used render area)
        Size currentFbo;                    // Current render width and height (depends on active fbo)
        Size render;                        // Framebuffer width and height (render area, including black bars if required)
        Point renderOffset;                 // Offset from render area (must be divided by 2)
        Matrix screenScale;                 // Matrix to scale screen (framebuffer rendering)

        char **dropFilesPath;               // Store dropped files paths as strings
        int dropFileCount;                  // Count dropped files strings

    } _Window Window;
    version(none) {// #if defined(PLATFORM_ANDROID)
        struct _Android {
            bool appEnabled;                    // Flag to detect if app is active ** = true
            /*struct*/ android_app *app;            // Android activity
            /*struct*/ android_poll_source *source; // Android events polling source
            bool contextRebindRequired;         // Used to know context rebind required
        } _Android Android;
    }
    struct _Storage {
        const(char) *basePath;               // Base path for data storage
    } _Storage Storage;
    struct _Input {
        version(none) { // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
            InputEventWorker[10] eventWorker;   // List of worker threads for every monitored "/dev/input/event<N>"
        }
        struct _Keyboard {
            int exitKey;                    // Default exit key
            ubyte[MAX_KEYBOARD_KEYS] currentKeyState = 0;        // Registers current frame key state
            ubyte[MAX_KEYBOARD_KEYS] previousKeyState = 0;       // Registers previous frame key state

            int[MAX_KEY_PRESSED_QUEUE] keyPressedQueue;     // Input keys queue
            int keyPressedQueueCount;       // Input keys queue count

            int[MAX_CHAR_PRESSED_QUEUE] charPressedQueue;   // Input characters queue (unicode)
            int charPressedQueueCount;      // Input characters queue count

            version(none) { //#if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
                int defaultMode;                // Default keyboard mode
                version(none) { // #if defined(SUPPORT_SSH_KEYBOARD_RPI)
                    bool evtMode;                   // Keyboard in event mode
                }
                int defaultFileFlags;           // Default IO file flags
                /*struct*/ termios defaultSettings; // Default keyboard settings
                int fd;                         // File descriptor for the evdev keyboard
            }
        } _Keyboard Keyboard;
        struct _Mouse {
            Vector2 offset;                 // Mouse offset
            Vector2 scale;                  // Mouse scaling
            Vector2 currentPosition;        // Mouse position on screen
            Vector2 previousPosition;       // Previous mouse position

            int cursor;                     // Tracks current mouse cursor
            bool cursorHidden;              // Track if cursor is hidden
            bool cursorOnScreen;            // Tracks if cursor is inside client area

            ubyte[MAX_MOUSE_BUTTONS] currentButtonState = 0;     // Registers current mouse button state
            ubyte[MAX_MOUSE_BUTTONS] previousButtonState = 0;    // Registers previous mouse button state
            float currentWheelMove = 0;         // Registers current mouse wheel variation
            float previousWheelMove = 0;        // Registers previous mouse wheel variation
            version(none) { // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
                // NOTE: currentButtonState[] can't be written directly due to multithreading, app could miss the update
                char[MAX_MOUSE_BUTTONS] currentButtonStateEvdev = 0; // Holds the new mouse state for the next polling event to grab
            }
        } _Mouse Mouse;
        struct _Touch {
            int pointCount;                             // Number of touch points active
            int[MAX_TOUCH_POINTS] pointId;              // Point identifiers
            Vector2[MAX_TOUCH_POINTS] position;         // Touch position on screen
            char[MAX_TOUCH_POINTS] currentTouchState = 0;   // Registers current touch state
            char[MAX_TOUCH_POINTS] previousTouchState = 0;  // Registers previous touch state
        } _Touch Touch;
        struct _Gamepad {
            int lastButtonPressed;          // Register last gamepad button pressed
            int axisCount;                  // Register number of available gamepad axis
            bool[MAX_GAMEPADS] ready;       // Flag to know if gamepad is ready
            char[64][MAX_GAMEPADS] name = [0];    // Gamepad name holder
            ubyte[MAX_GAMEPAD_BUTTONS][MAX_GAMEPADS] currentButtonState = [0];     // Current gamepad buttons state
            ubyte[MAX_GAMEPAD_BUTTONS][MAX_GAMEPADS] previousButtonState = [0];    // Previous gamepad buttons state
            float[MAX_GAMEPAD_AXIS][MAX_GAMEPADS] axisState = [0];                // Gamepad axis state
            version(none) { // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
                pthread_t threadId;             // Gamepad reading thread id
                int[MAX_GAMEPADS] streamId;     // Gamepad device file descriptor
            }
        } _Gamepad Gamepad;
    } _Input Input;
    struct _Time {
        double current = 0;                     // Current time measure
        double previous = 0;                    // Previous time measure
        double update = 0;                      // Time measure for frame update
        double draw = 0;                        // Time measure for frame draw
        double frame = 0;                       // Time measure for one frame
        double target = 0;                      // Desired time for one frame, if 0 not applied
        version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
            cpp_ulonglong base;            // Base time measure for hi-res timer
        }
        uint frameCounter;          // Frame counter
    } _Time Time;
}

// easy way to export for C
mixin template ExportForC(string item) {
    mixin(`private auto _get_` ~ item ~ `() { return &` ~ item ~ `;}`);
}

private __gshared CoreData CORE;
mixin ExportForC!"CORE";
private __gshared int gifFrameCounter = 0;
mixin ExportForC!"gifFrameCounter";
private __gshared bool gifRecording = false;
mixin ExportForC!"gifRecording";
private __gshared MsfGifState gifState;
mixin ExportForC!"gifState";
version(all) { // #if defined(SUPPORT_SCREEN_CAPTURE)
    private __gshared int screenshotCounter = 0;
    mixin ExportForC!"screenshotCounter";
}

private __gshared char **dirFilesPath = null;
mixin ExportForC!"dirFilesPath";
private __gshared int dirFileCount = 0;
mixin ExportForC!"dirFileCount";

/// Initialize window and OpenGL context
/// NOTE: data parameter could be used to pass any kind of required data to the initialization
void InitWindow(int width, int height, const(char)* title)
{
    TraceLog(TraceLogLevel.LOG_INFO, "Initializing raylib (D port) %s", RAYLIB_VERSION.ptr);
    // initialize the D glfw library if dynamically loaded (this isn't used at the moment)
    /+GLFWSupport ret = loadGLFW();
    if(ret != glfwSupport) {
        import core.stdc.stdlib;

        if(ret == GLFWSupport.noLibrary) {
            // The GLFW shared library failed to load
            TraceLog(TraceLogLevel.LOG_FATAL, "Cannot load bindbc GLFW library -- no library");
            exit(1);
        }
        else if(GLFWSupport.badLibrary) {
            /*
               One or more symbols failed to load. The likely cause is that the shared library is for a lower version than bindbc-glfw was configured to load (via GLFW_31, GLFW_32 etc.)
             */
            TraceLog(TraceLogLevel.LOG_FATAL, "Cannot load bindbc GLFW library -- bad library");
            exit(1);
        }
    }+/

    if ((title != null) && (title[0] != 0)) CORE.Window.title = title;

    // Initialize required global values different than 0
    CORE.Input.Keyboard.exitKey = KeyboardKey.KEY_ESCAPE;
    CORE.Input.Mouse.scale = Vector2(1.0f, 1.0f);
    CORE.Input.Mouse.cursor = MouseCursor.MOUSE_CURSOR_ARROW;
    CORE.Input.Gamepad.lastButtonPressed = -1;

    version(none) { // #if defined(PLATFORM_ANDROID)
        CORE.Window.screen.width = width;
        CORE.Window.screen.height = height;
        CORE.Window.currentFbo.width = width;
        CORE.Window.currentFbo.height = height;

        // Set desired windows flags before initializing anything
        ANativeActivity_setWindowFlags(CORE.Android.app.activity, AWINDOW_FLAG_FULLSCREEN, 0);  //AWINDOW_FLAG_SCALED, AWINDOW_FLAG_DITHER

        int orientation = AConfiguration_getOrientation(CORE.Android.app.config);

        if (orientation == ACONFIGURATION_ORIENTATION_PORT) TraceLog(TraceLogLevel.LOG_INFO, "ANDROID: Window orientation set as portrait");
        else if (orientation == ACONFIGURATION_ORIENTATION_LAND) TraceLog(TraceLogLevel.LOG_INFO, "ANDROID: Window orientation set as landscape");

        // TODO: Automatic orientation doesn't seem to work
        if (width <= height)
        {
            AConfiguration_setOrientation(CORE.Android.app.config, ACONFIGURATION_ORIENTATION_PORT);
            TraceLog(TraceLogLevel.LOG_WARNING, "ANDROID: Window orientation changed to portrait");
        }
        else
        {
            AConfiguration_setOrientation(CORE.Android.app.config, ACONFIGURATION_ORIENTATION_LAND);
            TraceLog(TraceLogLevel.LOG_WARNING, "ANDROID: Window orientation changed to landscape");
        }

        //AConfiguration_getDensity(CORE.Android.app.config);
        //AConfiguration_getKeyboard(CORE.Android.app.config);
        //AConfiguration_getScreenSize(CORE.Android.app.config);
        //AConfiguration_getScreenLong(CORE.Android.app.config);

        // Initialize App command system
        // NOTE: On APP_CMD_INIT_WINDOW -> InitGraphicsDevice(), InitTimer(), LoadFontDefault()...
        CORE.Android.app.onAppCmd = AndroidCommandCallback;

        // Initialize input events system
        CORE.Android.app.onInputEvent = AndroidInputCallback;

        // Initialize assets manager
        InitAssetManager(CORE.Android.app.activity.assetManager, CORE.Android.app.activity.internalDataPath);

        // Initialize base path for storage
        CORE.Storage.basePath = CORE.Android.app.activity.internalDataPath;

        TraceLog(TraceLogLevel.LOG_INFO, "ANDROID: App initialized successfully");

        // Android ALooper_pollAll() variables
        int pollResult = 0;
        int pollEvents = 0;

        // Wait for window to be initialized (display and context)
        while (!CORE.Window.ready)
        {
            // Process events loop
            while ((pollResult = ALooper_pollAll(0, null, &pollEvents, cast(void**)&CORE.Android.source)) >= 0)
            {
                // Process this event
                if (CORE.Android.source != null) CORE.Android.source.process(CORE.Android.app, CORE.Android.source);

                // NOTE: Never close window, native activity is controlled by the system!
                //if (CORE.Android.app.destroyRequested != 0) CORE.Window.shouldClose = true;
            }
        }
    }
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        // Initialize graphics device (display device and OpenGL context)
        // NOTE: returns true if window and graphic device has been initialized successfully
        CORE.Window.ready = InitGraphicsDevice(width, height);

        // If graphic device is no properly initialized, we end program
        if (!CORE.Window.ready)
        {
            TraceLog(TraceLogLevel.LOG_FATAL, "Failed to initialize Graphic Device");
            return;
        }

        // Initialize hi-res timer
        InitTimer();

        // Initialize random seed
        import core.stdc.time : time;
        import core.stdc.stdlib : srand;
        srand(cast(uint)time(null));

        // Initialize base path for storage
        CORE.Storage.basePath = GetWorkingDirectory();

        version(all) { // #if defined(SUPPORT_DEFAULT_FONT)
            // Load default font
            // NOTE: External functions (defined in module: text)
            LoadFontDefault();
            Rectangle rec = GetFontDefault().recs[95];
            // NOTE: We setup a 1px padding on char rectangle to avoid pixel bleeding on MSAA filtering
            SetShapesTexture(GetFontDefault().texture, Rectangle(rec.x + 1, rec.y + 1, rec.width - 2, rec.height - 2));
        } else {
            // Set default texture and rectangle to be used for shapes drawing
            // NOTE: rlgl default texture is a 1x1 pixel UNCOMPRESSED_R8G8B8A8
            Texture2D texture = Texture2D(rlGetTextureIdDefault(), 1, 1, 1, PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
            SetShapesTexture(texture, Rectangle(0.0f, 0.0f, 1.0f, 1.0f));
        }
        version(all) { // #if defined(PLATFORM_DESKTOP)
            if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0)
            {
                // Set default font texture filter for HighDPI (blurry)
                SetTextureFilter(GetFontDefault().texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
            }
        }

        version(none) { // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
            // Initialize raw input system
            InitEvdevInput();   // Evdev inputs initialization
            InitGamepad();      // Gamepad init
            InitKeyboard();     // Keyboard init (stdin)
        }

        version(none) { // #if defined(PLATFORM_WEB)
            // Check fullscreen change events(note this is done on the window since most browsers don't support this on #canvas)
            //emscripten_set_fullscreenchange_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, null, 1, EmscriptenResizeCallback);
            // Check Resize event (note this is done on the window since most browsers don't support this on #canvas)
            emscripten_set_resize_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, null, 1, EmscriptenResizeCallback);
            // Trigger this once to get initial window sizing
            EmscriptenResizeCallback(EMSCRIPTEN_EVENT_RESIZE, null, null);
            // Support keyboard events
            //emscripten_set_keypress_callback("#canvas", null, 1, EmscriptenKeyboardCallback);
            //emscripten_set_keydown_callback("#canvas", null, 1, EmscriptenKeyboardCallback);

            // Support mouse events
            emscripten_set_click_callback("#canvas", null, 1, EmscriptenMouseCallback);

            // Support touch events
            emscripten_set_touchstart_callback("#canvas", null, 1, EmscriptenTouchCallback);
            emscripten_set_touchend_callback("#canvas", null, 1, EmscriptenTouchCallback);
            emscripten_set_touchmove_callback("#canvas", null, 1, EmscriptenTouchCallback);
            emscripten_set_touchcancel_callback("#canvas", null, 1, EmscriptenTouchCallback);

            // Support gamepad events (not provided by GLFW3 on emscripten)
            emscripten_set_gamepadconnected_callback(null, 1, EmscriptenGamepadCallback);
            emscripten_set_gamepaddisconnected_callback(null, 1, EmscriptenGamepadCallback);
        }

        CORE.Input.Mouse.currentPosition.x = CORE.Window.screen.width/2.0f;
        CORE.Input.Mouse.currentPosition.y = CORE.Window.screen.height/2.0f;

        version(none) { // #if defined(SUPPORT_EVENTS_AUTOMATION)
            events = cast(AutomationEvent *)malloc(MAX_CODE_AUTOMATION_EVENTS*AuthomationEvent.sizeof);
            CORE.Time.frameCounter = 0;
        }

    }        // PLATFORM_DESKTOP || PLATFORM_WEB || PLATFORM_RPI || PLATFORM_DRM
}

private bool InitGraphicsDevice(int width, int height)
{
    CORE.Window.screen.width = width;            // User desired width
    CORE.Window.screen.height = height;          // User desired height
    CORE.Window.screenScale = MatrixIdentity();  // No draw scaling required by default

    // NOTE: Framebuffer (render area - CORE.Window.render.width, CORE.Window.render.height) could include black bars...
    // ...in top-down or left-right to match display aspect ratio (no weird scalings)

    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        glfwSetErrorCallback(&ErrorCallback);
        /*
        // TODO: Setup GLFW custom allocators to match raylib ones
        const GLFWallocator allocator = {
        .allocate = MemAlloc,
        .deallocate = MemFree,
        .reallocate = MemRealloc,
        .user = null
        };

        glfwInitAllocator(&allocator);
         */
        version(OSX) { // #if defined(__APPLE__)
            glfwInitHint(GLFW_COCOA_CHDIR_RESOURCES, GLFW_FALSE);
        }

        if (!glfwInit())
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to initialize GLFW");
            return false;
        }

        // NOTE: Getting video modes is not implemented in emscripten GLFW3 version
        version(all) { // #if defined(PLATFORM_DESKTOP)
            // Find monitor resolution
            GLFWmonitor *monitor = glfwGetPrimaryMonitor();
            if (!monitor)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to get primary monitor");
                return false;
            }
            const GLFWvidmode *mode = glfwGetVideoMode(monitor);

            CORE.Window.display.width = mode.width;
            CORE.Window.display.height = mode.height;

            // Set screen width/height to the display width/height if they are 0
            if (CORE.Window.screen.width == 0) CORE.Window.screen.width = CORE.Window.display.width;
            if (CORE.Window.screen.height == 0) CORE.Window.screen.height = CORE.Window.display.height;
        }

        version(none) { // #if defined(PLATFORM_WEB)
            CORE.Window.display.width = CORE.Window.screen.width;
            CORE.Window.display.height = CORE.Window.screen.height;
        }

        glfwDefaultWindowHints();                       // Set default windows hints
        //glfwWindowHint(GLFW_RED_BITS, 8);             // Framebuffer red color component bits
        //glfwWindowHint(GLFW_GREEN_BITS, 8);           // Framebuffer green color component bits
        //glfwWindowHint(GLFW_BLUE_BITS, 8);            // Framebuffer blue color component bits
        //glfwWindowHint(GLFW_ALPHA_BITS, 8);           // Framebuffer alpha color component bits
        //glfwWindowHint(GLFW_DEPTH_BITS, 24);          // Depthbuffer bits
        //glfwWindowHint(GLFW_REFRESH_RATE, 0);         // Refresh rate for fullscreen window
        //glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API); // OpenGL API to use. Alternative: GLFW_OPENGL_ES_API
        //glfwWindowHint(GLFW_AUX_BUFFERS, 0);          // Number of auxiliar buffers

        // Check window creation flags
        if ((CORE.Window.flags & ConfigFlags.FLAG_FULLSCREEN_MODE) > 0) CORE.Window.fullscreen = true;

        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIDDEN) > 0) glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE); // Visible window
        else glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);     // Window initially hidden

        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_UNDECORATED) > 0) glfwWindowHint(GLFW_DECORATED, GLFW_FALSE); // Border and buttons on Window
        else glfwWindowHint(GLFW_DECORATED, GLFW_TRUE);   // Decorated window

        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_RESIZABLE) > 0) glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE); // Resizable window
        else glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);  // Avoid window being resizable

        // Disable FLAG_WINDOW_MINIMIZED, not supported on initialization
        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MINIMIZED) > 0) CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MINIMIZED;

        // Disable FLAG_WINDOW_MAXIMIZED, not supported on initialization
        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MAXIMIZED) > 0) CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MAXIMIZED;

        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_UNFOCUSED) > 0) glfwWindowHint(GLFW_FOCUSED, GLFW_FALSE);
        else glfwWindowHint(GLFW_FOCUSED, GLFW_TRUE);

        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_TOPMOST) > 0) glfwWindowHint(GLFW_FLOATING, GLFW_TRUE);
        else glfwWindowHint(GLFW_FLOATING, GLFW_FALSE);

        // NOTE: Some GLFW flags are not supported on HTML5
        version(all) { // #if defined(PLATFORM_DESKTOP)
            if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_TRANSPARENT) > 0) glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, GLFW_TRUE);     // Transparent framebuffer
            else glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, GLFW_FALSE);  // Opaque framebuffer

            if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0)
            {
                // Resize window content area based on the monitor content scale.
                // NOTE: This hint only has an effect on platforms where screen coordinates and pixels always map 1:1 such as Windows and X11.
                // On platforms like macOS the resolution of the framebuffer is changed independently of the window size.
                glfwWindowHint(GLFW_SCALE_TO_MONITOR, GLFW_TRUE);   // Scale content area based on the monitor content scale where window is placed on
                version(OSX) { // #if defined(__APPLE__)
                    glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, GLFW_TRUE);
                }
            }
            else glfwWindowHint(GLFW_SCALE_TO_MONITOR, GLFW_FALSE);
        }

        if (CORE.Window.flags & ConfigFlags.FLAG_MSAA_4X_HINT)
        {
            // NOTE: MSAA is only enabled for main framebuffer, not user-created FBOs
            TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Trying to enable MSAA x4");
            glfwWindowHint(GLFW_SAMPLES, 4);   // Tries to enable multisampling x4 (MSAA), default is 0
        }

        // NOTE: When asking for an OpenGL context version, most drivers provide highest supported version
        // with forward compatibility to older OpenGL versions.
        // For example, if using OpenGL 1.1, driver can provide a 4.3 context forward compatible.

        // Check selection OpenGL version
        if (rlGetVersion() == rlGlVersion.OPENGL_21)
        {
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);          // Choose OpenGL major version (just hint)
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);          // Choose OpenGL minor version (just hint)
        }
        else if (rlGetVersion() == rlGlVersion.OPENGL_33)
        {
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);          // Choose OpenGL major version (just hint)
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);          // Choose OpenGL minor version (just hint)
            glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // Profiles Hint: Only 3.3 and above!
            // Values: GLFW_OPENGL_CORE_PROFILE, GLFW_OPENGL_ANY_PROFILE, GLFW_OPENGL_COMPAT_PROFILE
            version(OSX) { // #if defined(__APPLE__)
                glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);  // OSX Requires fordward compatibility
            } else {
                glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_FALSE); // Fordward Compatibility Hint: Only 3.3 and above!
            }
            //glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE); // Request OpenGL DEBUG context
        }
        else if (rlGetVersion() == rlGlVersion.OPENGL_43)
        {
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);          // Choose OpenGL major version (just hint)
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);          // Choose OpenGL minor version (just hint)
            glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
            glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_FALSE);
            version(none) { // #if defined(RLGL_ENABLE_OPENGL_DEBUG_CONTEXT)
                glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE);   // Enable OpenGL Debug Context
            }
        }
        else if (rlGetVersion() == rlGlVersion.OPENGL_ES_20)                    // Request OpenGL ES 2.0 context
        {
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
            glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
            version(all) { // #if defined(PLATFORM_DESKTOP)
                glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
            } else {
                glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_NATIVE_CONTEXT_API);
            }
        }

        version(all) { // #if defined(PLATFORM_DESKTOP)
            // NOTE: GLFW 3.4+ defers initialization of the Joystick subsystem on the first call to any Joystick related functions.
            // Forcing this initialization here avoids doing it on PollInputEvents() called by EndDrawing() after first frame has been just drawn.
            // The initialization will still happen and possible delays still occur, but before the window is shown, which is a nicer experience.
            // REF: https://github.com/raysan5/raylib/issues/1554
            if (MAX_GAMEPADS > 0) glfwSetJoystickCallback(null);
        }

        if (CORE.Window.fullscreen)
        {
            // remember center for switchinging from fullscreen to window
            CORE.Window.position.x = CORE.Window.display.width/2 - CORE.Window.screen.width/2;
            CORE.Window.position.y = CORE.Window.display.height/2 - CORE.Window.screen.height/2;

            if (CORE.Window.position.x < 0) CORE.Window.position.x = 0;
            if (CORE.Window.position.y < 0) CORE.Window.position.y = 0;

            // Obtain recommended CORE.Window.display.width/CORE.Window.display.height from a valid videomode for the monitor
            int count = 0;
            const GLFWvidmode *modes = glfwGetVideoModes(glfwGetPrimaryMonitor(), &count);

            // Get closest video mode to desired CORE.Window.screen.width/CORE.Window.screen.height
            for (int i = 0; i < count; i++)
            {
                if (cast(uint)modes[i].width >= CORE.Window.screen.width)
                {
                    if (cast(uint)modes[i].height >= CORE.Window.screen.height)
                    {
                        CORE.Window.display.width = modes[i].width;
                        CORE.Window.display.height = modes[i].height;
                        break;
                    }
                }
            }

            version(all) { // #if defined(PLATFORM_DESKTOP)
                // If we are windowed fullscreen, ensures that window does not minimize when focus is lost
                if ((CORE.Window.screen.height == CORE.Window.display.height) && (CORE.Window.screen.width == CORE.Window.display.width))
                {
                    glfwWindowHint(GLFW_AUTO_ICONIFY, 0);
                }
            }
            TraceLog(TraceLogLevel.LOG_WARNING, "SYSTEM: Closest fullscreen videomode: %i x %i", CORE.Window.display.width, CORE.Window.display.height);

            // NOTE: ISSUE: Closest videomode could not match monitor aspect-ratio, for example,
            // for a desired screen size of 800x450 (16:9), closest supported videomode is 800x600 (4:3),
            // framebuffer is rendered correctly but once displayed on a 16:9 monitor, it gets stretched
            // by the sides to fit all monitor space...

            // Try to setup the most appropiate fullscreen framebuffer for the requested screenWidth/screenHeight
            // It considers device display resolution mode and setups a framebuffer with black bars if required (render size/offset)
            // Modified global variables: CORE.Window.screen.width/CORE.Window.screen.height - CORE.Window.render.width/CORE.Window.render.height - CORE.Window.renderOffset.x/CORE.Window.renderOffset.y - CORE.Window.screenScale
            // TODO: It is a quite cumbersome solution to display size vs requested size, it should be reviewed or removed...
            // HighDPI monitors are properly considered in a following similar function: SetupViewport()
            SetupFramebuffer(CORE.Window.display.width, CORE.Window.display.height);

            CORE.Window.handle = glfwCreateWindow(CORE.Window.display.width, CORE.Window.display.height, (CORE.Window.title != null)? CORE.Window.title : " ", glfwGetPrimaryMonitor(), null);

            // NOTE: Full-screen change, not working properly...
            //glfwSetWindowMonitor(CORE.Window.handle, glfwGetPrimaryMonitor(), 0, 0, CORE.Window.screen.width, CORE.Window.screen.height, GLFW_DONT_CARE);
        }
        else
        {
            // No-fullscreen window creation
            CORE.Window.handle = glfwCreateWindow(CORE.Window.screen.width, CORE.Window.screen.height, (CORE.Window.title != null)? CORE.Window.title : " ", null, null);

            if (CORE.Window.handle)
            {
                version(all) { // #if defined(PLATFORM_DESKTOP)
                    // Center window on screen
                    int windowPosX = CORE.Window.display.width/2 - CORE.Window.screen.width/2;
                    int windowPosY = CORE.Window.display.height/2 - CORE.Window.screen.height/2;

                    if (windowPosX < 0) windowPosX = 0;
                    if (windowPosY < 0) windowPosY = 0;

                    glfwSetWindowPos(CORE.Window.handle, windowPosX, windowPosY);
                }
                CORE.Window.render.width = CORE.Window.screen.width;
                CORE.Window.render.height = CORE.Window.screen.height;
            }
        }

        if (!CORE.Window.handle)
        {
            glfwTerminate();
            TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to initialize Window");
            return false;
        }

        // Set window callback events
        glfwSetWindowSizeCallback(CORE.Window.handle, &WindowSizeCallback);      // NOTE: Resizing not allowed by default!
        version(all) { // #if !defined(PLATFORM_WEB)
            glfwSetWindowMaximizeCallback(CORE.Window.handle, &WindowMaximizeCallback);
        }
        glfwSetWindowIconifyCallback(CORE.Window.handle, &WindowIconifyCallback);
        glfwSetWindowFocusCallback(CORE.Window.handle, &WindowFocusCallback);
        glfwSetDropCallback(CORE.Window.handle, &WindowDropCallback);
        // Set input callback events
        glfwSetKeyCallback(CORE.Window.handle, &KeyCallback);
        glfwSetCharCallback(CORE.Window.handle, &CharCallback);
        glfwSetMouseButtonCallback(CORE.Window.handle, &MouseButtonCallback);
        glfwSetCursorPosCallback(CORE.Window.handle, &MouseCursorPosCallback);   // Track mouse position changes
        glfwSetScrollCallback(CORE.Window.handle, &MouseScrollCallback);
        glfwSetCursorEnterCallback(CORE.Window.handle, &CursorEnterCallback);

        glfwMakeContextCurrent(CORE.Window.handle);

        version(all) { // #if !defined(PLATFORM_WEB)
            glfwSwapInterval(0);        // No V-Sync by default
        }

        // Try to enable GPU V-Sync, so frames are limited to screen refresh rate (60Hz -> 60 FPS)
        // NOTE: V-Sync can be enabled by graphic driver configuration
        if (CORE.Window.flags & ConfigFlags.FLAG_VSYNC_HINT)
        {
            // WARNING: It seems to hits a critical render path in Intel HD Graphics
            glfwSwapInterval(1);
            TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Trying to enable VSYNC");
        }

        int fbWidth = CORE.Window.screen.width;
        int fbHeight = CORE.Window.screen.height;

        version(all) { // #if defined(PLATFORM_DESKTOP)
            if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0)
            {
                // NOTE: On APPLE platforms system should manage window/input scaling and also framebuffer scaling
                // Framebuffer scaling should be activated with: glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, GLFW_TRUE);
                version(OSX) { // #if !defined(__APPLE__)
                    glfwGetFramebufferSize(CORE.Window.handle, &fbWidth, &fbHeight);

                    // Screen scaling matrix is required in case desired screen area is different than display area
                    CORE.Window.screenScale = MatrixScale(cast(float)fbWidth/CORE.Window.screen.width, cast(float)fbHeight/CORE.Window.screen.height, 1.0f);

                    // Mouse input scaling for the new screen size
                    SetMouseScale(cast(float)CORE.Window.screen.width/fbWidth, cast(float)CORE.Window.screen.height/fbHeight);
                }
            }
        }

        CORE.Window.render.width = fbWidth;
        CORE.Window.render.height = fbHeight;
        CORE.Window.currentFbo.width = fbWidth;
        CORE.Window.currentFbo.height = fbHeight;

        TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Device initialized successfully");
        TraceLog(TraceLogLevel.LOG_INFO, "    > Display size: %i x %i", CORE.Window.display.width, CORE.Window.display.height);
        TraceLog(TraceLogLevel.LOG_INFO, "    > Screen size:  %i x %i", CORE.Window.screen.width, CORE.Window.screen.height);
        TraceLog(TraceLogLevel.LOG_INFO, "    > Render size:  %i x %i", CORE.Window.render.width, CORE.Window.render.height);
        TraceLog(TraceLogLevel.LOG_INFO, "    > Viewport offsets: %i, %i", CORE.Window.renderOffset.x, CORE.Window.renderOffset.y);

    }  // PLATFORM_DESKTOP || PLATFORM_WEB

    version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        CORE.Window.fullscreen = true;
        CORE.Window.flags |= FLAG_FULLSCREEN_MODE;

        version(none) { // #if defined(PLATFORM_RPI)
            bcm_host_init();

            DISPMANX_ELEMENT_HANDLE_T dispmanElement = { 0 };
            DISPMANX_DISPLAY_HANDLE_T dispmanDisplay = { 0 };
            DISPMANX_UPDATE_HANDLE_T dispmanUpdate = { 0 };

            VC_RECT_T dstRect = { 0 };
            VC_RECT_T srcRect = { 0 };
        }

        version(none) { // #if defined(PLATFORM_DRM)
            CORE.Window.fd = -1;
            CORE.Window.connector = null;
            CORE.Window.modeIndex = -1;
            CORE.Window.crtc = null;
            CORE.Window.gbmDevice = null;
            CORE.Window.gbmSurface = null;
            CORE.Window.prevBO = null;
            CORE.Window.prevFB = 0;

            version(none) { // #if defined(DEFAULT_GRAPHIC_DEVICE_DRM)
                CORE.Window.fd = open(DEFAULT_GRAPHIC_DEVICE_DRM, O_RDWR);
            } else {
                TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: No graphic card set, trying platform-gpu-card");
                CORE.Window.fd = open("/dev/dri/by-path/platform-gpu-card",  O_RDWR); // VideoCore VI (Raspberry Pi 4)
                if ((-1 == CORE.Window.fd) || (drmModeGetResources(CORE.Window.fd) == null))
                {
                    TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Failed to open platform-gpu-card, trying card1");
                    CORE.Window.fd = open("/dev/dri/card1", O_RDWR); // Other Embedded
                }
                if ((-1 == CORE.Window.fd) || (drmModeGetResources(CORE.Window.fd) == null))
                {
                    TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Failed to open graphic card1, trying card0");
                    CORE.Window.fd = open("/dev/dri/card0", O_RDWR); // VideoCore IV (Raspberry Pi 1-3)
                }
            }
            if (-1 == CORE.Window.fd)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to open graphic card");
                return false;
            }

            drmModeRes *res = drmModeGetResources(CORE.Window.fd);
            if (!res)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed get DRM resources");
                return false;
            }

            TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: Connectors found: %i", res.count_connectors);
            for (size_t i = 0; i < res.count_connectors; i++)
            {
                TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: Connector index %i", i);
                drmModeConnector *con = drmModeGetConnector(CORE.Window.fd, res.connectors[i]);
                TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: Connector modes detected: %i", con.count_modes);
                if ((con.connection == DRM_MODE_CONNECTED) && (con.encoder_id))
                {
                    TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: DRM mode connected");
                    CORE.Window.connector = con;
                    break;
                }
                else
                {
                    TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: DRM mode NOT connected (deleting)");
                    drmModeFreeConnector(con);
                }
            }
            if (!CORE.Window.connector)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: No suitable DRM connector found");
                drmModeFreeResources(res);
                return false;
            }

            drmModeEncoder *enc = drmModeGetEncoder(CORE.Window.fd, CORE.Window.connector.encoder_id);
            if (!enc)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to get DRM mode encoder");
                drmModeFreeResources(res);
                return false;
            }

            CORE.Window.crtc = drmModeGetCrtc(CORE.Window.fd, enc.crtc_id);
            if (!CORE.Window.crtc)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to get DRM mode crtc");
                drmModeFreeEncoder(enc);
                drmModeFreeResources(res);
                return false;
            }

            // If InitWindow should use the current mode find it in the connector's mode list
            if ((CORE.Window.screen.width <= 0) || (CORE.Window.screen.height <= 0))
            {
                TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: Selecting DRM connector mode for current used mode...");

                CORE.Window.modeIndex = FindMatchingConnectorMode(CORE.Window.connector, &CORE.Window.crtc.mode);

                if (CORE.Window.modeIndex < 0)
                {
                    TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: No matching DRM connector mode found");
                    drmModeFreeEncoder(enc);
                    drmModeFreeResources(res);
                    return false;
                }

                CORE.Window.screen.width = CORE.Window.display.width;
                CORE.Window.screen.height = CORE.Window.display.height;
            }

            const bool allowInterlaced = CORE.Window.flags & FLAG_INTERLACED_HINT;
            const int fps = (CORE.Time.target > 0) ? (1.0/CORE.Time.target) : 60;
            // try to find an exact matching mode
            CORE.Window.modeIndex = FindExactConnectorMode(CORE.Window.connector, CORE.Window.screen.width, CORE.Window.screen.height, fps, allowInterlaced);
            // if nothing found, try to find a nearly matching mode
            if (CORE.Window.modeIndex < 0)
                CORE.Window.modeIndex = FindNearestConnectorMode(CORE.Window.connector, CORE.Window.screen.width, CORE.Window.screen.height, fps, allowInterlaced);
            // if nothing found, try to find an exactly matching mode including interlaced
            if (CORE.Window.modeIndex < 0)
                CORE.Window.modeIndex = FindExactConnectorMode(CORE.Window.connector, CORE.Window.screen.width, CORE.Window.screen.height, fps, true);
            // if nothing found, try to find a nearly matching mode including interlaced
            if (CORE.Window.modeIndex < 0)
                CORE.Window.modeIndex = FindNearestConnectorMode(CORE.Window.connector, CORE.Window.screen.width, CORE.Window.screen.height, fps, true);
            // if nothing found, there is no suitable mode
            if (CORE.Window.modeIndex < 0)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to find a suitable DRM connector mode");
                drmModeFreeEncoder(enc);
                drmModeFreeResources(res);
                return false;
            }

            CORE.Window.display.width = CORE.Window.connector.modes[CORE.Window.modeIndex].hdisplay;
            CORE.Window.display.height = CORE.Window.connector.modes[CORE.Window.modeIndex].vdisplay;

            TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Selected DRM connector mode %s (%ux%u%c@%u)", CORE.Window.connector.modes[CORE.Window.modeIndex].name,
                     CORE.Window.connector.modes[CORE.Window.modeIndex].hdisplay, CORE.Window.connector.modes[CORE.Window.modeIndex].vdisplay,
                     (CORE.Window.connector.modes[CORE.Window.modeIndex].flags & DRM_MODE_FLAG_INTERLACE) ? 'i' : 'p',
                     CORE.Window.connector.modes[CORE.Window.modeIndex].vrefresh);

            // Use the width and height of the surface for render
            CORE.Window.render.width = CORE.Window.screen.width;
            CORE.Window.render.height = CORE.Window.screen.height;

            drmModeFreeEncoder(enc);
            enc = null;

            drmModeFreeResources(res);
            res = null;

            CORE.Window.gbmDevice = gbm_create_device(CORE.Window.fd);
            if (!CORE.Window.gbmDevice)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to create GBM device");
                return false;
            }

            CORE.Window.gbmSurface = gbm_surface_create(CORE.Window.gbmDevice, CORE.Window.connector.modes[CORE.Window.modeIndex].hdisplay,
                                                        CORE.Window.connector.modes[CORE.Window.modeIndex].vdisplay, GBM_FORMAT_ARGB8888, GBM_BO_USE_SCANOUT | GBM_BO_USE_RENDERING);
            if (!CORE.Window.gbmSurface)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to create GBM surface");
                return false;
            }
        }

        EGLint samples = 0;
        EGLint sampleBuffer = 0;
        if (CORE.Window.flags & FLAG_MSAA_4X_HINT)
        {
            samples = 4;
            sampleBuffer = 1;
            TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Trying to enable MSAA x4");
        }

        version(none) { // #if defined(PLATFORM_DRM)
            enum EGLint[] _extras1 = [
                EGL_SURFACE_TYPE, EGL_WINDOW_BIT,          // Don't use it on Android!
            ];
            enum EGLint[] _extras2 = [
                EGL_ALPHA_SIZE, 8,        // ALPHA bit depth (required for transparent framebuffer)
            ];
        }
        version(none) { // #if defined(PLATFORM_DRM)
        }
        const EGLint[] framebufferAttribs =
            [
            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,     // Type of context support -> Required on RPI?
            ] ~ extras1 ~ [
            EGL_RED_SIZE, 8,            // RED color bit depth (alternative: 5)
            EGL_GREEN_SIZE, 8,          // GREEN color bit depth (alternative: 6)
            EGL_BLUE_SIZE, 8,           // BLUE color bit depth (alternative: 5)
            ] ~ extras2 ~ [
            //EGL_TRANSPARENT_TYPE, EGL_NONE, // Request transparent framebuffer (EGL_TRANSPARENT_RGB does not work on RPI)
            EGL_DEPTH_SIZE, 16,         // Depth buffer size (Required to use Depth testing!)
            //EGL_STENCIL_SIZE, 8,      // Stencil buffer size
            EGL_SAMPLE_BUFFERS, sampleBuffer,    // Activate MSAA
            EGL_SAMPLES, samples,       // 4x Antialiasing if activated (Free on MALI GPUs)
            EGL_NONE
            ];

        const EGLint[] contextAttribs =
            [
            EGL_CONTEXT_CLIENT_VERSION, 2,
            EGL_NONE
            ];

        version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
            EGLint numConfigs = 0;

            // Get an EGL device connection
            version(none) { // #if defined(PLATFORM_DRM)
                CORE.Window.device = eglGetDisplay(cast(EGLNativeDisplayType)CORE.Window.gbmDevice);
            } else {
                CORE.Window.device = eglGetDisplay(EGL_DEFAULT_DISPLAY);
            }
            if (CORE.Window.device == EGL_NO_DISPLAY)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to initialize EGL device");
                return false;
            }

            // Initialize the EGL device connection
            if (eglInitialize(CORE.Window.device, null, null) == EGL_FALSE)
            {
                // If all of the calls to eglInitialize returned EGL_FALSE then an error has occurred.
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to initialize EGL device");
                return false;
            }

            version(none) { // #if defined(PLATFORM_DRM)
                if (!eglChooseConfig(CORE.Window.device, null, null, 0, &numConfigs))
                {
                    TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to get EGL config count: 0x%x", eglGetError());
                    return false;
                }

                TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: EGL configs available: %d", numConfigs);

                EGLConfig *configs = RL_CALLOC(numConfigs, (*configs).sizeof);
                if (!configs)
                {
                    TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to get memory for EGL configs");
                    return false;
                }

                EGLint matchingNumConfigs = 0;
                if (!eglChooseConfig(CORE.Window.device, framebufferAttribs, configs, numConfigs, &matchingNumConfigs))
                {
                    TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to choose EGL config: 0x%x", eglGetError());
                    free(configs);
                    return false;
                }

                TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: EGL matching configs available: %d", matchingNumConfigs);

                // find the EGL config that matches the previously setup GBM format
                int found = 0;
                for (EGLint i = 0; i < matchingNumConfigs; ++i)
                {
                    EGLint id = 0;
                    if (!eglGetConfigAttrib(CORE.Window.device, configs[i], EGL_NATIVE_VISUAL_ID, &id))
                    {
                        TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to get EGL config attribute: 0x%x", eglGetError());
                        continue;
                    }

                    if (GBM_FORMAT_ARGB8888 == id)
                    {
                        TraceLog(TraceLogLevel.LOG_TRACE, "DISPLAY: Using EGL config: %d", i);
                        CORE.Window.config = configs[i];
                        found = 1;
                        break;
                    }
                }

                RL_FREE(configs);

                if (!found)
                {
                    TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to find a suitable EGL config");
                    return false;
                }
            } else {
                // Get an appropriate EGL framebuffer configuration
                eglChooseConfig(CORE.Window.device, framebufferAttribs, &CORE.Window.config, 1, &numConfigs);
            }

            // Set rendering API
            eglBindAPI(EGL_OPENGL_ES_API);

            // Create an EGL rendering context
            CORE.Window.context = eglCreateContext(CORE.Window.device, CORE.Window.config, EGL_NO_CONTEXT, contextAttribs);
            if (CORE.Window.context == EGL_NO_CONTEXT)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to create EGL context");
                return false;
            }
        }

        // Create an EGL window surface
        //---------------------------------------------------------------------------------
        version(none) { // #if defined(PLATFORM_ANDROID)
            EGLint displayFormat = 0;

            // EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is guaranteed to be accepted by ANativeWindow_setBuffersGeometry()
            // As soon as we picked a EGLConfig, we can safely reconfigure the ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID
            eglGetConfigAttrib(CORE.Window.device, CORE.Window.config, EGL_NATIVE_VISUAL_ID, &displayFormat);

            // At this point we need to manage render size vs screen size
            // NOTE: This function use and modify global module variables:
            //  -> CORE.Window.screen.width/CORE.Window.screen.height
            //  -> CORE.Window.render.width/CORE.Window.render.height
            //  -> CORE.Window.screenScale
            SetupFramebuffer(CORE.Window.display.width, CORE.Window.display.height);

            ANativeWindow_setBuffersGeometry(CORE.Android.app.window, CORE.Window.render.width, CORE.Window.render.height, displayFormat);
            //ANativeWindow_setBuffersGeometry(CORE.Android.app.window, 0, 0, displayFormat);       // Force use of native display size

            CORE.Window.surface = eglCreateWindowSurface(CORE.Window.device, CORE.Window.config, CORE.Android.app.window, null);
        }  // PLATFORM_ANDROID

        version(none) { // #if defined(PLATFORM_RPI)
            graphics_get_display_size(0, &CORE.Window.display.width, &CORE.Window.display.height);

            // Screen size security check
            if (CORE.Window.screen.width <= 0) CORE.Window.screen.width = CORE.Window.display.width;
            if (CORE.Window.screen.height <= 0) CORE.Window.screen.height = CORE.Window.display.height;

            // At this point we need to manage render size vs screen size
            // NOTE: This function use and modify global module variables:
            //  -> CORE.Window.screen.width/CORE.Window.screen.height
            //  -> CORE.Window.render.width/CORE.Window.render.height
            //  -> CORE.Window.screenScale
            SetupFramebuffer(CORE.Window.display.width, CORE.Window.display.height);

            dstRect.x = 0;
            dstRect.y = 0;
            dstRect.width = CORE.Window.display.width;
            dstRect.height = CORE.Window.display.height;

            srcRect.x = 0;
            srcRect.y = 0;
            srcRect.width = CORE.Window.render.width << 16;
            srcRect.height = CORE.Window.render.height << 16;

            // NOTE: RPI dispmanx windowing system takes care of source rectangle scaling to destination rectangle by hardware (no cost)
            // Take care that renderWidth/renderHeight fit on displayWidth/displayHeight aspect ratio

            VC_DISPMANX_ALPHA_T alpha = { 0 };
            alpha.flags = DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS;
            //alpha.flags = DISPMANX_FLAGS_ALPHA_FROM_SOURCE;       // TODO: Allow transparent framebuffer! -> FLAG_WINDOW_TRANSPARENT
            alpha.opacity = 255;    // Set transparency level for framebuffer, requires EGLAttrib: EGL_TRANSPARENT_TYPE
            alpha.mask = 0;

            dispmanDisplay = vc_dispmanx_display_open(0);   // LCD
            dispmanUpdate = vc_dispmanx_update_start(0);

            dispmanElement = vc_dispmanx_element_add(dispmanUpdate, dispmanDisplay, 0/*layer*/, &dstRect, 0/*src*/,
                                                     &srcRect, DISPMANX_PROTECTION_NONE, &alpha, 0/*clamp*/, DISPMANX_NO_ROTATE);

            CORE.Window.handle.element = dispmanElement;
            CORE.Window.handle.width = CORE.Window.render.width;
            CORE.Window.handle.height = CORE.Window.render.height;
            vc_dispmanx_update_submit_sync(dispmanUpdate);

            CORE.Window.surface = eglCreateWindowSurface(CORE.Window.device, CORE.Window.config, &CORE.Window.handle, null);

            const ubyte * renderer = glGetString(GL_RENDERER);
            if (renderer) TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Renderer name is: %s", renderer);
            else TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to get renderer name");
            //---------------------------------------------------------------------------------
        }  // PLATFORM_RPI

        version(none) { // #if defined(PLATFORM_DRM)
            CORE.Window.surface = eglCreateWindowSurface(CORE.Window.device, CORE.Window.config, cast(EGLNativeWindowType)CORE.Window.gbmSurface, null);
            if (EGL_NO_SURFACE == CORE.Window.surface)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to create EGL window surface: 0x%04x", eglGetError());
                return false;
            }

            // At this point we need to manage render size vs screen size
            // NOTE: This function use and modify global module variables:
            //  -> CORE.Window.screen.width/CORE.Window.screen.height
            //  -> CORE.Window.render.width/CORE.Window.render.height
            //  -> CORE.Window.screenScale
            SetupFramebuffer(CORE.Window.display.width, CORE.Window.display.height);
        } // PLATFORM_DRM

        // There must be at least one frame displayed before the buffers are swapped
        //eglSwapInterval(CORE.Window.device, 1);

        if (eglMakeCurrent(CORE.Window.device, CORE.Window.surface, CORE.Window.surface, CORE.Window.context) == EGL_FALSE)
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Failed to attach EGL rendering context to EGL surface");
            return false;
        }
        else
        {
            CORE.Window.render.width = CORE.Window.screen.width;
            CORE.Window.render.height = CORE.Window.screen.height;
            CORE.Window.currentFbo.width = CORE.Window.render.width;
            CORE.Window.currentFbo.height = CORE.Window.render.height;

            TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Device initialized successfully");
            TraceLog(TraceLogLevel.LOG_INFO, "    > Display size: %i x %i", CORE.Window.display.width, CORE.Window.display.height);
            TraceLog(TraceLogLevel.LOG_INFO, "    > Screen size:  %i x %i", CORE.Window.screen.width, CORE.Window.screen.height);
            TraceLog(TraceLogLevel.LOG_INFO, "    > Render size:  %i x %i", CORE.Window.render.width, CORE.Window.render.height);
            TraceLog(TraceLogLevel.LOG_INFO, "    > Viewport offsets: %i, %i", CORE.Window.renderOffset.x, CORE.Window.renderOffset.y);
        }
    }  // PLATFORM_ANDROID || PLATFORM_RPI || PLATFORM_DRM

    // Load OpenGL extensions
    // NOTE: GL procedures address loader is required to load extensions
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        rlLoadExtensions(&glfwGetProcAddress);
    } else {
        rlLoadExtensions(&eglGetProcAddress);
    }

    // Initialize OpenGL context (states and resources)
    // NOTE: CORE.Window.currentFbo.width and CORE.Window.currentFbo.height not used, just stored as globals in rlgl
    rlglInit(CORE.Window.currentFbo.width, CORE.Window.currentFbo.height);

    // Setup default viewport
    // NOTE: It updated CORE.Window.render.width and CORE.Window.render.height
    SetupViewport(CORE.Window.currentFbo.width, CORE.Window.currentFbo.height);

    ClearBackground(RAYWHITE);      // Default background color for raylib games :P

    version(none) { // #if defined(PLATFORM_ANDROID)
        CORE.Window.ready = true;
    }

    if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MINIMIZED) > 0) MinimizeWindow();

    return true;
}

// Set viewport for a provided width and height
private void SetupViewport(int width, int height)
{
    CORE.Window.render.width = width;
    CORE.Window.render.height = height;

    // Set viewport width and height
    // NOTE: We consider render size (scaled) and offset in case black bars are required and
    // render area does not match full display area (this situation is only applicable on fullscreen mode)
    version(OSX) { // #if defined(__APPLE__)
        float xScale = 1.0f, yScale = 1.0f;
        glfwGetWindowContentScale(CORE.Window.handle, &xScale, &yScale);
        rlViewport(cast(int)(CORE.Window.renderOffset.x/2*xScale), cast(int)(CORE.Window.renderOffset.y/2*yScale), cast(int)((CORE.Window.render.width)*xScale), cast(int)((CORE.Window.render.height)*yScale));
    }
    else { 
        rlViewport(CORE.Window.renderOffset.x/2, CORE.Window.renderOffset.y/2, CORE.Window.render.width, CORE.Window.render.height);
    }

    rlMatrixMode(RL_PROJECTION);        // Switch to projection matrix
    rlLoadIdentity();                   // Reset current matrix (projection)

    // Set orthographic projection to current framebuffer size
    // NOTE: Configured top-left corner as (0, 0)
    rlOrtho(0, CORE.Window.render.width, CORE.Window.render.height, 0, 0.0f, 1.0f);

    rlMatrixMode(RL_MODELVIEW);         // Switch back to modelview matrix
    rlLoadIdentity();                   // Reset current matrix (modelview)
}

// GLFW3 Error Callback, runs on GLFW3 error
version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
    private void ErrorCallback(int error, const char *description)
    {
        TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Error: %i Description: %s", error, description);
    }
}
// GLFW3 WindowSize Callback, runs when window is resizedLastFrame
// NOTE: Window resizing not allowed by default
private void WindowSizeCallback(GLFWwindow *window, int width, int height)
{
    // Reset viewport and projection matrix for new size
    SetupViewport(width, height);

    CORE.Window.currentFbo.width = width;
    CORE.Window.currentFbo.height = height;
    CORE.Window.resizedLastFrame = true;

    if (IsWindowFullscreen()) return;

    // Set current screen size
    version(OSX) { // #if defined(__APPLE__)
        CORE.Window.screen.width = width;
        CORE.Window.screen.height = height;
    } else {
        if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0)
        {
            Vector2 windowScaleDPI = GetWindowScaleDPI();

            CORE.Window.screen.width = cast(uint)(width/windowScaleDPI.x);
            CORE.Window.screen.height = cast(uint)(height/windowScaleDPI.y);
        }
        else
        {
            CORE.Window.screen.width = width;
            CORE.Window.screen.height = height;
        }
    }

    // NOTE: Postprocessing texture is not scaled to new size
}

version(all) { // #if !defined(PLATFORM_WEB)
    // GLFW3 WindowMaximize Callback, runs when window is maximized/restored
    private void WindowMaximizeCallback(GLFWwindow *window, int maximized)
    {
        if (maximized) CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_MAXIMIZED;  // The window was maximized
        else CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MAXIMIZED;           // The window was restored
    }
}

// GLFW3 WindowIconify Callback, runs when window is minimized/restored
private void WindowIconifyCallback(GLFWwindow *window, int iconified) @nogc nothrow
{
    if (iconified) CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_MINIMIZED;  // The window was iconified
    else CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MINIMIZED;           // The window was restored
}

// GLFW3 WindowFocus Callback, runs when window get/lose focus
private void WindowFocusCallback(GLFWwindow *window, int focused) @nogc nothrow
{
    if (focused) CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_UNFOCUSED;   // The window was focused
    else CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_UNFOCUSED;            // The window lost focus
}

// GLFW3 Window Drop Callback, runs when drop files into window
// NOTE: Paths are stored in dynamic memory for further retrieval
// Everytime new files are dropped, old ones are discarded
private void WindowDropCallback(GLFWwindow *window, int count, const(char *)*paths)
{
    import core.stdc.stdlib;
    import core.stdc.string;
    ClearDroppedFiles();

    CORE.Window.dropFilesPath = cast(char **)malloc(count*(char*).sizeof);

    for (int i = 0; i < count; i++)
    {
        CORE.Window.dropFilesPath[i] = cast(char *)malloc(MAX_FILEPATH_LENGTH*char.sizeof);
        strcpy(CORE.Window.dropFilesPath[i], paths[i]);
    }

    CORE.Window.dropFileCount = count;
}

// GLFW3 Char Key Callback, runs on key down (gets equivalent unicode char value)
private void CharCallback(GLFWwindow *window, uint key)
{
    //TraceLog(LOG_DEBUG, "Char Callback: KEY:%i(%c)", key, key);

    // NOTE: Registers any key down considering OS keyboard layout but
    // do not detects action events, those should be managed by user...
    // Ref: https://github.com/glfw/glfw/issues/668#issuecomment-166794907
    // Ref: https://www.glfw.org/docs/latest/input_guide.html#input_char

    // Check if there is space available in the queue
    if (CORE.Input.Keyboard.charPressedQueueCount < MAX_KEY_PRESSED_QUEUE)
    {
        // Add character to the queue
        CORE.Input.Keyboard.charPressedQueue[CORE.Input.Keyboard.charPressedQueueCount] = key;
        CORE.Input.Keyboard.charPressedQueueCount++;
    }
}

// GLFW3 Mouse Button Callback, runs on mouse button pressed
private void MouseButtonCallback(GLFWwindow *window, int button, int action, int mods)
{
    // WARNING: GLFW could only return GLFW_PRESS (1) or GLFW_RELEASE (0) for now,
    // but future releases may add more actions (i.e. GLFW_REPEAT)
    CORE.Input.Mouse.currentButtonState[button] = cast(char)action;

    version(all) { // #if defined(SUPPORT_GESTURES_SYSTEM) && defined(SUPPORT_MOUSE_GESTURES)         // PLATFORM_DESKTOP
        // Process mouse events as touches to be able to use mouse-gestures
        GestureEvent gestureEvent;

        // Register touch actions
        if ((CORE.Input.Mouse.currentButtonState[button] == 1) && (CORE.Input.Mouse.previousButtonState[button] == 0)) gestureEvent.touchAction = TouchAction.TOUCH_ACTION_DOWN;
        else if ((CORE.Input.Mouse.currentButtonState[button] == 0) && (CORE.Input.Mouse.previousButtonState[button] == 1)) gestureEvent.touchAction = TouchAction.TOUCH_ACTION_UP;

        // NOTE: TOUCH_ACTION_MOVE event is registered in MouseCursorPosCallback()

        // Assign a pointer ID
        gestureEvent.pointId[0] = 0;

        // Register touch points count
        gestureEvent.pointCount = 1;

        // Register touch points position, only one point registered
        gestureEvent.position[0] = GetMousePosition();

        // Normalize gestureEvent.position[0] for CORE.Window.screen.width and CORE.Window.screen.height
        gestureEvent.position[0].x /= cast(float)GetScreenWidth();
        gestureEvent.position[0].y /= cast(float)GetScreenHeight();

        // Gesture data is sent to gestures system for processing
        ProcessGestureEvent(gestureEvent);
    }
}

// GLFW3 Cursor Position Callback, runs on mouse move
private void MouseCursorPosCallback(GLFWwindow *window, double x, double y)
{
    CORE.Input.Mouse.currentPosition.x = x;
    CORE.Input.Mouse.currentPosition.y = y;
    CORE.Input.Touch.position[0] = CORE.Input.Mouse.currentPosition;

    version(all) { // #if defined(SUPPORT_GESTURES_SYSTEM) && defined(SUPPORT_MOUSE_GESTURES)         // PLATFORM_DESKTOP
    // Process mouse events as touches to be able to use mouse-gestures
        GestureEvent gestureEvent;

        gestureEvent.touchAction = TouchAction.TOUCH_ACTION_MOVE;

        // Assign a pointer ID
        gestureEvent.pointId[0] = 0;

        // Register touch points count
        gestureEvent.pointCount = 1;

        // Register touch points position, only one point registered
        gestureEvent.position[0] = CORE.Input.Touch.position[0];

        // Normalize gestureEvent.position[0] for CORE.Window.screen.width and CORE.Window.screen.height
        gestureEvent.position[0].x /= cast(float)GetScreenWidth();
        gestureEvent.position[0].y /= cast(float)GetScreenHeight();

        // Gesture data is sent to gestures system for processing
        ProcessGestureEvent(gestureEvent);
    }
}

// GLFW3 Srolling Callback, runs on mouse wheel
private void MouseScrollCallback(GLFWwindow *window, double xoffset, double yoffset)
{
    if (xoffset != 0.0) CORE.Input.Mouse.currentWheelMove = xoffset;
    else CORE.Input.Mouse.currentWheelMove = yoffset;
}

// GLFW3 CursorEnter Callback, when cursor enters the window
private void CursorEnterCallback(GLFWwindow *window, int enter)
{
    if (enter == true) CORE.Input.Mouse.cursorOnScreen = true;
    else CORE.Input.Mouse.cursorOnScreen = false;
}


/// Close window and unload OpenGL context
void CloseWindow()
{
    version(all) { //#if defined(SUPPORT_GIF_RECORDING)
        if (gifRecording)
        {
            MsfGifResult result = msf_gif_end(&gifState);
            msf_gif_free(result);
            gifRecording = false;
        }
    }

    version(all) { //#if defined(SUPPORT_DEFAULT_FONT)
        UnloadFontDefault();
    }

    rlglClose();                // De-init rlgl

    version(all) { //#if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        glfwDestroyWindow(CORE.Window.handle);
        glfwTerminate();
    }

    version(Win32) { //#if defined(_WIN32) && defined(SUPPORT_WINMM_HIGHRES_TIMER) && !defined(SUPPORT_BUSY_WAIT_LOOP)
        timeEndPeriod(1);           // Restore time period
    }

    version(none) { //#if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI)
        // Close surface, context and display
        if (CORE.Window.device != EGL_NO_DISPLAY)
        {
            eglMakeCurrent(CORE.Window.device, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

            if (CORE.Window.surface != EGL_NO_SURFACE)
            {
                eglDestroySurface(CORE.Window.device, CORE.Window.surface);
                CORE.Window.surface = EGL_NO_SURFACE;
            }

            if (CORE.Window.context != EGL_NO_CONTEXT)
            {
                eglDestroyContext(CORE.Window.device, CORE.Window.context);
                CORE.Window.context = EGL_NO_CONTEXT;
            }

            eglTerminate(CORE.Window.device);
            CORE.Window.device = EGL_NO_DISPLAY;
        }
    }

    version(none) { //#if defined(PLATFORM_DRM)
        if (CORE.Window.prevFB)
        {
            drmModeRmFB(CORE.Window.fd, CORE.Window.prevFB);
            CORE.Window.prevFB = 0;
        }

        if (CORE.Window.prevBO)
        {
            gbm_surface_release_buffer(CORE.Window.gbmSurface, CORE.Window.prevBO);
            CORE.Window.prevBO = null;
        }

        if (CORE.Window.gbmSurface)
        {
            gbm_surface_destroy(CORE.Window.gbmSurface);
            CORE.Window.gbmSurface = null;
        }

        if (CORE.Window.gbmDevice)
        {
            gbm_device_destroy(CORE.Window.gbmDevice);
            CORE.Window.gbmDevice = null;
        }

        if (CORE.Window.crtc)
        {
            if (CORE.Window.connector)
            {
                drmModeSetCrtc(CORE.Window.fd, CORE.Window.crtc.crtc_id, CORE.Window.crtc.buffer_id,
                               CORE.Window.crtc.x, CORE.Window.crtc.y, &CORE.Window.connector.connector_id, 1, &CORE.Window.crtc.mode);
                drmModeFreeConnector(CORE.Window.connector);
                CORE.Window.connector = null;
            }

            drmModeFreeCrtc(CORE.Window.crtc);
            CORE.Window.crtc = null;
        }

        if (CORE.Window.fd != -1)
        {
            close(CORE.Window.fd);
            CORE.Window.fd = -1;
        }

        // Close surface, context and display
        if (CORE.Window.device != EGL_NO_DISPLAY)
        {
            if (CORE.Window.surface != EGL_NO_SURFACE)
            {
                eglDestroySurface(CORE.Window.device, CORE.Window.surface);
                CORE.Window.surface = EGL_NO_SURFACE;
            }

            if (CORE.Window.context != EGL_NO_CONTEXT)
            {
                eglDestroyContext(CORE.Window.device, CORE.Window.context);
                CORE.Window.context = EGL_NO_CONTEXT;
            }

            eglTerminate(CORE.Window.device);
            CORE.Window.device = EGL_NO_DISPLAY;
        }
    }

    version(none) { //#if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        // Wait for mouse and gamepad threads to finish before closing
        // NOTE: Those threads should already have finished at this point
        // because they are controlled by CORE.Window.shouldClose variable
        CORE.Window.shouldClose = true;   // Added to force threads to exit when the close window is called

        // Close the evdev keyboard
        if (CORE.Input.Keyboard.fd != -1)
        {
            close(CORE.Input.Keyboard.fd);
            CORE.Input.Keyboard.fd = -1;
        }

        for (int i = 0; i < sizeof(CORE.Input.eventWorker)/sizeof(InputEventWorker); ++i)
        {
            if (CORE.Input.eventWorker[i].threadId)
            {
                pthread_join(CORE.Input.eventWorker[i].threadId, null);
            }
        }

        if (CORE.Input.Gamepad.threadId) pthread_join(CORE.Input.Gamepad.threadId, null);
    }

    version(none) { //#if defined(SUPPORT_EVENTS_AUTOMATION)
        free(events);
    }

    CORE.Window.ready = false;
    TraceLog(TraceLogLevel.LOG_INFO, "Window closed successfully".ptr);
}

/// Check if KEY_ESCAPE pressed or Close icon pressed
bool WindowShouldClose()
{
    version(none) { // #if defined(PLATFORM_WEB)
        // Emterpreter-Async required to run sync code
        // https://github.com/emscripten-core/emscripten/wiki/Emterpreter#emterpreter-async-run-synchronous-code
        // By default, this function is never called on a web-ready raylib example because we encapsulate
        // frame code in a UpdateDrawFrame() function, to allow browser manage execution asynchronously
        // but now emscripten allows sync code to be executed in an interpreted way, using emterpreter!
        emscripten_sleep(16);
        return false;
    }

    else version(all) { // #if defined(PLATFORM_DESKTOP)
        if (CORE.Window.ready)
        {
            // While window minimized, stop loop execution
            while (IsWindowState(ConfigFlags.FLAG_WINDOW_MINIMIZED) && !IsWindowState(ConfigFlags.FLAG_WINDOW_ALWAYS_RUN)) glfwWaitEvents();

            CORE.Window.shouldClose = cast(bool)glfwWindowShouldClose(CORE.Window.handle);

            // Reset close status for next frame
            glfwSetWindowShouldClose(CORE.Window.handle, GLFW_FALSE);

            return CORE.Window.shouldClose;
        }
        else return true;
    }

    else version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        if (CORE.Window.ready) return CORE.Window.shouldClose;
        else return true;
    }
}

/// Check if window has been initialized successfully
bool IsWindowReady()
{
    return CORE.Window.ready;
}

/// Check if window is currently fullscreen
bool IsWindowFullscreen()
{
    return CORE.Window.fullscreen;
}

/// Check if window is currently hidden
bool IsWindowHidden()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        return ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIDDEN) > 0);
    }
    else { // not an #else in C
        return false;
    }
}

/// Check if window has been minimized
bool IsWindowMinimized()
{
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        return ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MINIMIZED) > 0);
    }
    else {
        return false;
    }
}

/// Check if window has been maximized (only PLATFORM_DESKTOP)
bool IsWindowMaximized()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        return ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MAXIMIZED) > 0);
    }
    else {
        return false;
    }
}

/// Check if window has the focus
bool IsWindowFocused()
{
    version(all) { //#if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        return ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_UNFOCUSED) == 0);
    }
    else {
        return true;
    }
}

/// Check if window has been resizedLastFrame
bool IsWindowResized()
{
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        return CORE.Window.resizedLastFrame;
    }
    else {
        return false;
    }
}

/// Check if one specific window flag is enabled
bool IsWindowState(uint flag)
{
    return ((CORE.Window.flags & flag) > 0);
}

/// Toggle fullscreen mode (only PLATFORM_DESKTOP)
void ToggleFullscreen()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
                   // NOTE: glfwSetWindowMonitor() doesn't work properly (bugs)
        if (!CORE.Window.fullscreen)
        {
            // Store previous window position (in case we exit fullscreen)
            glfwGetWindowPos(CORE.Window.handle, &CORE.Window.position.x, &CORE.Window.position.y);

            int monitorCount = 0;
            GLFWmonitor** monitors = glfwGetMonitors(&monitorCount);

            int monitorIndex = GetCurrentMonitor();

            // Use current monitor, so we correctly get the display the window is on
            GLFWmonitor* monitor = monitorIndex < monitorCount ?  monitors[monitorIndex] : null;

            if (!monitor)
            {
                TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to get monitor");

                CORE.Window.fullscreen = false;          // Toggle fullscreen flag
                CORE.Window.flags &= ~ConfigFlags.FLAG_FULLSCREEN_MODE;

                glfwSetWindowMonitor(CORE.Window.handle, null, 0, 0, CORE.Window.screen.width, CORE.Window.screen.height, GLFW_DONT_CARE);
                return;
            }

            CORE.Window.fullscreen = true;          // Toggle fullscreen flag
            CORE.Window.flags |= ConfigFlags.FLAG_FULLSCREEN_MODE;

            glfwSetWindowMonitor(CORE.Window.handle, monitor, 0, 0, CORE.Window.screen.width, CORE.Window.screen.height, GLFW_DONT_CARE);
        }
        else
        {
            CORE.Window.fullscreen = false;          // Toggle fullscreen flag
            CORE.Window.flags &= ~ConfigFlags.FLAG_FULLSCREEN_MODE;

            glfwSetWindowMonitor(CORE.Window.handle, null, CORE.Window.position.x, CORE.Window.position.y, CORE.Window.screen.width, CORE.Window.screen.height, GLFW_DONT_CARE);
        }

        // Try to enable GPU V-Sync, so frames are limited to screen refresh rate (60Hz -> 60 FPS)
        // NOTE: V-Sync can be enabled by graphic driver configuration
        if (CORE.Window.flags & ConfigFlags.FLAG_VSYNC_HINT) glfwSwapInterval(1);
    }
    version(none) { // #if defined(PLATFORM_WEB)
        /+++++++++ DOES NOT PARSE IN D
        EM_ASM
            (
             // This strategy works well while using raylib minimal web shell for emscripten,
             // it re-scales the canvas to fullscreen using monitor resolution, for tools this
             // is a good strategy but maybe games prefer to keep current canvas resolution and
             // display it in fullscreen, adjusting monitor resolution if possible
             if (document.fullscreenElement) document.exitFullscreen();
             else Module.requestFullscreen(false, true);
            );
        ++++++++++/
        /*
           if (!CORE.Window.fullscreen)
           {
        // Option 1: Request fullscreen for the canvas element
        // This option does not seem to work at all
        //emscripten_request_fullscreen("#canvas", false);

        // Option 2: Request fullscreen for the canvas element with strategy
        // This option does not seem to work at all
        // Ref: https://github.com/emscripten-core/emscripten/issues/5124
        // EmscriptenFullscreenStrategy strategy = {
        // .scaleMode = EMSCRIPTEN_FULLSCREEN_SCALE_STRETCH, //EMSCRIPTEN_FULLSCREEN_SCALE_ASPECT,
        // .canvasResolutionScaleMode = EMSCRIPTEN_FULLSCREEN_CANVAS_SCALE_STDDEF,
        // .filteringMode = EMSCRIPTEN_FULLSCREEN_FILTERING_DEFAULT,
        // .canvasResizedCallback = EmscriptenWindowResizedCallback,
        // .canvasResizedCallbackUserData = null
        // };
        //emscripten_request_fullscreen_strategy("#canvas", EM_FALSE, &strategy);

        // Option 3: Request fullscreen for the canvas element with strategy
        // It works as expected but only inside the browser (client area)
        EmscriptenFullscreenStrategy strategy = {
        .scaleMode = EMSCRIPTEN_FULLSCREEN_SCALE_ASPECT,
        .canvasResolutionScaleMode = EMSCRIPTEN_FULLSCREEN_CANVAS_SCALE_STDDEF,
        .filteringMode = EMSCRIPTEN_FULLSCREEN_FILTERING_DEFAULT,
        .canvasResizedCallback = EmscriptenWindowResizedCallback,
        .canvasResizedCallbackUserData = null
        };
        emscripten_enter_soft_fullscreen("#canvas", &strategy);

        int width, height;
        emscripten_get_canvas_element_size("#canvas", &width, &height);
        TraceLog(TraceLogLevel.LOG_WARNING, "Emscripten: Enter fullscreen: Canvas size: %i x %i", width, height);
        }
        else
        {
        //emscripten_exit_fullscreen();
        emscripten_exit_soft_fullscreen();

        int width, height;
        emscripten_get_canvas_element_size("#canvas", &width, &height);
        TraceLog(TraceLogLevel.LOG_WARNING, "Emscripten: Exit fullscreen: Canvas size: %i x %i", width, height);
        }
         */

        CORE.Window.fullscreen = !CORE.Window.fullscreen;          // Toggle fullscreen flag
        CORE.Window.flags ^= ConfigFlags.FLAG_FULLSCREEN_MODE;
    }
    version(none) {  // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        TraceLog(TraceLogLevel.LOG_WARNING, "SYSTEM: Failed to toggle to windowed mode");
    }
}


/// Get current screen width
int GetScreenWidth()
{
    return CORE.Window.screen.width;
}

/// Get current screen height
int GetScreenHeight()
{
    return CORE.Window.screen.height;
}

/// Get current render width which is equal to screen width * dpi scale
int GetRenderWidth()
{
    return CORE.Window.render.width;
}

/// Get current screen height which is equal to screen height * dpi scale
int GetRenderHeight()
{
    return CORE.Window.render.height;
}

/// Set window state: maximized, if resizable (only PLATFORM_DESKTOP)
void MaximizeWindow()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        if (glfwGetWindowAttrib(CORE.Window.handle, GLFW_RESIZABLE) == GLFW_TRUE)
        {
            glfwMaximizeWindow(CORE.Window.handle);
            CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_MAXIMIZED;
        }
    }
}

/// Set window state: minimized (only PLATFORM_DESKTOP)
void MinimizeWindow()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        // NOTE: Following function launches callback that sets appropiate flag!
        glfwIconifyWindow(CORE.Window.handle);
    }
}

/// Set window state: not minimized/maximized (only PLATFORM_DESKTOP)
void RestoreWindow()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        if (glfwGetWindowAttrib(CORE.Window.handle, GLFW_RESIZABLE) == GLFW_TRUE)
        {
            // Restores the specified window if it was previously iconified (minimized) or maximized
            glfwRestoreWindow(CORE.Window.handle);
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MINIMIZED;
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MAXIMIZED;
        }
    }
}

/// Set window configuration state using flags
void SetWindowState(uint flags)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        // Check previous state and requested state to apply required changes
        // NOTE: In most cases the functions already change the flags internally

        // State change: FLAG_VSYNC_HINT
        if (((CORE.Window.flags & ConfigFlags.FLAG_VSYNC_HINT) != (flags & ConfigFlags.FLAG_VSYNC_HINT)) && ((flags & ConfigFlags.FLAG_VSYNC_HINT) > 0))
        {
            glfwSwapInterval(1);
            CORE.Window.flags |= ConfigFlags.FLAG_VSYNC_HINT;
        }

        // State change: FLAG_FULLSCREEN_MODE
        if ((CORE.Window.flags & ConfigFlags.FLAG_FULLSCREEN_MODE) != (flags & ConfigFlags.FLAG_FULLSCREEN_MODE))
        {
            ToggleFullscreen();     // NOTE: Window state flag updated inside function
        }

        // State change: FLAG_WINDOW_RESIZABLE
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_RESIZABLE) != (flags & ConfigFlags.FLAG_WINDOW_RESIZABLE)) && ((flags & ConfigFlags.FLAG_WINDOW_RESIZABLE) > 0))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_RESIZABLE, GLFW_TRUE);
            CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_RESIZABLE;
        }

        // State change: FLAG_WINDOW_UNDECORATED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_UNDECORATED) != (flags & ConfigFlags.FLAG_WINDOW_UNDECORATED)) && (flags & ConfigFlags.FLAG_WINDOW_UNDECORATED))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_DECORATED, GLFW_FALSE);
            CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_UNDECORATED;
        }

        // State change: FLAG_WINDOW_HIDDEN
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIDDEN) != (flags & ConfigFlags.FLAG_WINDOW_HIDDEN)) && ((flags & ConfigFlags.FLAG_WINDOW_HIDDEN) > 0))
        {
            glfwHideWindow(CORE.Window.handle);
            CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_HIDDEN;
        }

        // State change: FLAG_WINDOW_MINIMIZED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MINIMIZED) != (flags & ConfigFlags.FLAG_WINDOW_MINIMIZED)) && ((flags & ConfigFlags.FLAG_WINDOW_MINIMIZED) > 0))
        {
            //GLFW_ICONIFIED
            MinimizeWindow();       // NOTE: Window state flag updated inside function
        }

        // State change: FLAG_WINDOW_MAXIMIZED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MAXIMIZED) != (flags & ConfigFlags.FLAG_WINDOW_MAXIMIZED)) && ((flags & ConfigFlags.FLAG_WINDOW_MAXIMIZED) > 0))
        {
            //GLFW_MAXIMIZED
            MaximizeWindow();       // NOTE: Window state flag updated inside function
        }

        // State change: FLAG_WINDOW_UNFOCUSED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_UNFOCUSED) != (flags & ConfigFlags.FLAG_WINDOW_UNFOCUSED)) && ((flags & ConfigFlags.FLAG_WINDOW_UNFOCUSED) > 0))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_FOCUS_ON_SHOW, GLFW_FALSE);
            CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_UNFOCUSED;
        }

        // State change: FLAG_WINDOW_TOPMOST
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_TOPMOST) != (flags & ConfigFlags.FLAG_WINDOW_TOPMOST)) && ((flags & ConfigFlags.FLAG_WINDOW_TOPMOST) > 0))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_FLOATING, GLFW_TRUE);
            CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_TOPMOST;
        }

        // State change: FLAG_WINDOW_ALWAYS_RUN
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_ALWAYS_RUN) != (flags & ConfigFlags.FLAG_WINDOW_ALWAYS_RUN)) && ((flags & ConfigFlags.FLAG_WINDOW_ALWAYS_RUN) > 0))
        {
            CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_ALWAYS_RUN;
        }

        // The following states can not be changed after window creation

        // State change: FLAG_WINDOW_TRANSPARENT
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_TRANSPARENT) != (flags & ConfigFlags.FLAG_WINDOW_TRANSPARENT)) && ((flags & ConfigFlags.FLAG_WINDOW_TRANSPARENT) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "WINDOW: Framebuffer transparency can only by configured before window initialization");
        }

        // State change: FLAG_WINDOW_HIGHDPI
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) != (flags & ConfigFlags.FLAG_WINDOW_HIGHDPI)) && ((flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "WINDOW: High DPI can only by configured before window initialization");
        }

        // State change: FLAG_MSAA_4X_HINT
        if (((CORE.Window.flags & ConfigFlags.FLAG_MSAA_4X_HINT) != (flags & ConfigFlags.FLAG_MSAA_4X_HINT)) && ((flags & ConfigFlags.FLAG_MSAA_4X_HINT) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "WINDOW: MSAA can only by configured before window initialization");
        }

        // State change: FLAG_INTERLACED_HINT
        if (((CORE.Window.flags & ConfigFlags.FLAG_INTERLACED_HINT) != (flags & ConfigFlags.FLAG_INTERLACED_HINT)) && ((flags & ConfigFlags.FLAG_INTERLACED_HINT) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "RPI: Interlaced mode can only by configured before window initialization");
        }
    }
}

/// Clear window configuration state flags
void ClearWindowState(uint flags)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        // Check previous state and requested state to apply required changes
        // NOTE: In most cases the functions already change the flags internally

        // State change: FLAG_VSYNC_HINT
        if (((CORE.Window.flags & ConfigFlags.FLAG_VSYNC_HINT) > 0) && ((flags & ConfigFlags.FLAG_VSYNC_HINT) > 0))
        {
            glfwSwapInterval(0);
            CORE.Window.flags &= ~ConfigFlags.FLAG_VSYNC_HINT;
        }

        // State change: FLAG_FULLSCREEN_MODE
        if (((CORE.Window.flags & ConfigFlags.FLAG_FULLSCREEN_MODE) > 0) && ((flags & ConfigFlags.FLAG_FULLSCREEN_MODE) > 0))
        {
            ToggleFullscreen();     // NOTE: Window state flag updated inside function
        }

        // State change: FLAG_WINDOW_RESIZABLE
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_RESIZABLE) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_RESIZABLE) > 0))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_RESIZABLE, GLFW_FALSE);
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_RESIZABLE;
        }

        // State change: FLAG_WINDOW_UNDECORATED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_UNDECORATED) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_UNDECORATED) > 0))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_DECORATED, GLFW_TRUE);
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_UNDECORATED;
        }

        // State change: FLAG_WINDOW_HIDDEN
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIDDEN) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_HIDDEN) > 0))
        {
            glfwShowWindow(CORE.Window.handle);
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_HIDDEN;
        }

        // State change: FLAG_WINDOW_MINIMIZED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MINIMIZED) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_MINIMIZED) > 0))
        {
            RestoreWindow();       // NOTE: Window state flag updated inside function
        }

        // State change: FLAG_WINDOW_MAXIMIZED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_MAXIMIZED) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_MAXIMIZED) > 0))
        {
            RestoreWindow();       // NOTE: Window state flag updated inside function
        }

        // State change: FLAG_WINDOW_UNFOCUSED
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_UNFOCUSED) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_UNFOCUSED) > 0))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_FOCUS_ON_SHOW, GLFW_TRUE);
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_UNFOCUSED;
        }

        // State change: FLAG_WINDOW_TOPMOST
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_TOPMOST) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_TOPMOST) > 0))
        {
            glfwSetWindowAttrib(CORE.Window.handle, GLFW_FLOATING, GLFW_FALSE);
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_TOPMOST;
        }

        // State change: FLAG_WINDOW_ALWAYS_RUN
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_ALWAYS_RUN) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_ALWAYS_RUN) > 0))
        {
            CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_ALWAYS_RUN;
        }

        // The following states can not be changed after window creation

        // State change: FLAG_WINDOW_TRANSPARENT
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_TRANSPARENT) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_TRANSPARENT) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "WINDOW: Framebuffer transparency can only by configured before window initialization");
        }

        // State change: FLAG_WINDOW_HIGHDPI
        if (((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0) && ((flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "WINDOW: High DPI can only by configured before window initialization");
        }

        // State change: FLAG_MSAA_4X_HINT
        if (((CORE.Window.flags & ConfigFlags.FLAG_MSAA_4X_HINT) > 0) && ((flags & ConfigFlags.FLAG_MSAA_4X_HINT) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "WINDOW: MSAA can only by configured before window initialization");
        }

        // State change: FLAG_INTERLACED_HINT
        if (((CORE.Window.flags & ConfigFlags.FLAG_INTERLACED_HINT) > 0) && ((flags & ConfigFlags.FLAG_INTERLACED_HINT) > 0))
        {
            TraceLog(TraceLogLevel.LOG_WARNING, "RPI: Interlaced mode can only by configured before window initialization");
        }
    }
}

/// Set icon for window (only PLATFORM_DESKTOP)
/// NOTE: Image must be in RGBA format, 8bit per channel
void SetWindowIcon(Image image)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        if (image.format == PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8)
        {
            GLFWimage[1] icon;

            icon[0].width = image.width;
            icon[0].height = image.height;
            icon[0].pixels = cast(ubyte *)image.data;

            // NOTE 1: We only support one image icon
            // NOTE 2: The specified image data is copied before this function returns
            glfwSetWindowIcon(CORE.Window.handle, 1, &icon[0]);
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Window icon image must be in R8G8B8A8 pixel format");
    }
}

/// Set title for window (only PLATFORM_DESKTOP)
void SetWindowTitle(const char *title)
{
    CORE.Window.title = title;
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwSetWindowTitle(CORE.Window.handle, title);
    }
}

/// Set window position on screen (windowed mode)
void SetWindowPosition(int x, int y)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwSetWindowPos(CORE.Window.handle, x, y);
    }
}

/// Set monitor for the current window (fullscreen mode)
void SetWindowMonitor(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount = 0;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            TraceLog(TraceLogLevel.LOG_INFO, "GLFW: Selected fullscreen monitor: [%i] %s", monitor, glfwGetMonitorName(monitors[monitor]));

            const GLFWvidmode *mode = glfwGetVideoMode(monitors[monitor]);
            glfwSetWindowMonitor(CORE.Window.handle, monitors[monitor], 0, 0, mode.width, mode.height, mode.refreshRate);
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
}

/// Set window minimum dimensions (FLAG_WINDOW_RESIZABLE)
void SetWindowMinSize(int width, int height)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        const GLFWvidmode *mode = glfwGetVideoMode(glfwGetPrimaryMonitor());
        glfwSetWindowSizeLimits(CORE.Window.handle, width, height, mode.width, mode.height);
    }
}

/// Get native window handle
void *GetWindowHandle()
{
    version(Windows) { // #if defined(PLATFORM_DESKTOP) && defined(_WIN32)
        // NOTE: Returned handle is: void *HWND (windows.h)
        return glfwGetWin32Window(CORE.Window.handle);
    }
    else version(linux) { // #if defined(__linux__)
        // NOTE: Returned handle is: unsigned long Window (X.h)
        // typedef unsigned long XID;
        // typedef XID Window;
        //unsigned long id = (unsigned long)glfwGetX11Window(window);
        return null;    // TODO: Find a way to return value... cast to void *?
    }
    else version(OSX) { // #if defined(__APPLE__)
        // NOTE: Returned handle is: (objc_object *)
        return null;    // TODO: return (void *)glfwGetCocoaWindow(window);
    }
    else {
        return null;
    }
}

/// Set window dimensions
void SetWindowSize(int width, int height)
{
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        glfwSetWindowSize(CORE.Window.handle, width, height);
    }
    version(none) { // #if defined(PLATFORM_WEB)
        //emscripten_set_canvas_size(width, height);  // DEPRECATED!

        // TODO: Below functions should be used to replace previous one but they do not seem to work properly
        //emscripten_set_canvas_element_size("canvas", width, height);
        //emscripten_set_element_css_size("canvas", width, height);
    }
}

// Compute framebuffer size relative to screen size and display size
// NOTE: Global variables CORE.Window.render.width/CORE.Window.render.height and CORE.Window.renderOffset.x/CORE.Window.renderOffset.y can be modified
private void SetupFramebuffer(int width, int height)
{
    // Calculate CORE.Window.render.width and CORE.Window.render.height, we have the display size (input params) and the desired screen size (global var)
    if ((CORE.Window.screen.width > CORE.Window.display.width) || (CORE.Window.screen.height > CORE.Window.display.height))
    {
        TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Downscaling required: Screen size (%ix%i) is bigger than display size (%ix%i)", CORE.Window.screen.width, CORE.Window.screen.height, CORE.Window.display.width, CORE.Window.display.height);

        // Downscaling to fit display with border-bars
        float widthRatio = cast(float)CORE.Window.display.width/cast(float)CORE.Window.screen.width;
        float heightRatio = cast(float)CORE.Window.display.height/cast(float)CORE.Window.screen.height;

        if (widthRatio <= heightRatio)
        {
            CORE.Window.render.width = CORE.Window.display.width;
            CORE.Window.render.height = cast(int)round(cast(float)CORE.Window.screen.height*widthRatio);
            CORE.Window.renderOffset.x = 0;
            CORE.Window.renderOffset.y = (CORE.Window.display.height - CORE.Window.render.height);
        }
        else
        {
            CORE.Window.render.width = cast(int)round(cast(float)CORE.Window.screen.width*heightRatio);
            CORE.Window.render.height = CORE.Window.display.height;
            CORE.Window.renderOffset.x = (CORE.Window.display.width - CORE.Window.render.width);
            CORE.Window.renderOffset.y = 0;
        }

        // Screen scaling required
        float scaleRatio = cast(float)CORE.Window.render.width/cast(float)CORE.Window.screen.width;
        CORE.Window.screenScale = MatrixScale(scaleRatio, scaleRatio, 1.0f);

        // NOTE: We render to full display resolution!
        // We just need to calculate above parameters for downscale matrix and offsets
        CORE.Window.render.width = CORE.Window.display.width;
        CORE.Window.render.height = CORE.Window.display.height;

        TraceLog(TraceLogLevel.LOG_WARNING, "DISPLAY: Downscale matrix generated, content will be rendered at (%ix%i)", CORE.Window.render.width, CORE.Window.render.height);
    }
    else if ((CORE.Window.screen.width < CORE.Window.display.width) || (CORE.Window.screen.height < CORE.Window.display.height))
    {
        // Required screen size is smaller than display size
        TraceLog(TraceLogLevel.LOG_INFO, "DISPLAY: Upscaling required: Screen size (%ix%i) smaller than display size (%ix%i)", CORE.Window.screen.width, CORE.Window.screen.height, CORE.Window.display.width, CORE.Window.display.height);

        if ((CORE.Window.screen.width == 0) || (CORE.Window.screen.height == 0))
        {
            CORE.Window.screen.width = CORE.Window.display.width;
            CORE.Window.screen.height = CORE.Window.display.height;
        }

        // Upscaling to fit display with border-bars
        float displayRatio = cast(float)CORE.Window.display.width/cast(float)CORE.Window.display.height;
        float screenRatio = cast(float)CORE.Window.screen.width/cast(float)CORE.Window.screen.height;

        if (displayRatio <= screenRatio)
        {
            CORE.Window.render.width = CORE.Window.screen.width;
            CORE.Window.render.height = cast(int)round(cast(float)CORE.Window.screen.width/displayRatio);
            CORE.Window.renderOffset.x = 0;
            CORE.Window.renderOffset.y = (CORE.Window.render.height - CORE.Window.screen.height);
        }
        else
        {
            CORE.Window.render.width = cast(int)round(cast(float)CORE.Window.screen.height*displayRatio);
            CORE.Window.render.height = CORE.Window.screen.height;
            CORE.Window.renderOffset.x = (CORE.Window.render.width - CORE.Window.screen.width);
            CORE.Window.renderOffset.y = 0;
        }
    }
    else
    {
        CORE.Window.render.width = CORE.Window.screen.width;
        CORE.Window.render.height = CORE.Window.screen.height;
        CORE.Window.renderOffset.x = 0;
        CORE.Window.renderOffset.y = 0;
    }
}

// Initialize hi-resolution timer
private void InitTimer()
{
// Setting a higher resolution can improve the accuracy of time-out intervals in wait functions.
// However, it can also reduce overall system performance, because the thread scheduler switches tasks more often.
// High resolutions can also prevent the CPU power management system from entering power-saving modes.
// Setting a higher resolution does not improve the accuracy of the high-resolution performance counter.
    version(Windows) { // #if defined(_WIN32) && defined(SUPPORT_WINMM_HIGHRES_TIMER) && !defined(SUPPORT_BUSY_WAIT_LOOP)
        timeBeginPeriod(1);                 // Setup high-resolution timer to 1ms (granularity of 1-2 ms)
    }

    version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        timespec now;

        if (clock_gettime(CLOCK_MONOTONIC, &now) == 0)  // Success
        {
            CORE.Time.base = cast(cpp_ulonglong)(now.tv_sec*1000000000UL + now.tv_nsec);
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "TIMER: Hi-resolution timer not available");
    }

    CORE.Time.previous = GetTime();     // Get time as double
}

// GLFW3 Keyboard Callback, runs on key pressed
private void KeyCallback(GLFWwindow *window, int key, int scancode, int action, int mods)
{
    // WARNING: GLFW could return GLFW_REPEAT, we need to consider it as 1
    // to work properly with our implementation (IsKeyDown/IsKeyUp checks)
    // Issue with rcore.c allowing out of bounds indexes
    // (see https://github.com/raysan5/raylib/issues/2619)
    if(key < 0 || key >= MAX_KEYBOARD_KEYS)
    {
        TraceLog(TraceLogLevel.LOG_DEBUG, "SYSTEM: KeyCallback provided unknown keyboard key: %d", key);
        return;
    }
    if (action == GLFW_RELEASE) CORE.Input.Keyboard.currentKeyState[key] = 0;
    else CORE.Input.Keyboard.currentKeyState[key] = 1;

    // Check if there is space available in the key queue
    if ((CORE.Input.Keyboard.keyPressedQueueCount < MAX_KEY_PRESSED_QUEUE) && (action == GLFW_PRESS))
    {
        // Add character to the queue
        CORE.Input.Keyboard.keyPressedQueue[CORE.Input.Keyboard.keyPressedQueueCount] = key;
        CORE.Input.Keyboard.keyPressedQueueCount++;
    }
    
    // Check the exit key to set close window
    if ((key == CORE.Input.Keyboard.exitKey) && (action == GLFW_PRESS)) glfwSetWindowShouldClose(CORE.Window.handle, GLFW_TRUE);

    version(all) { // #if defined(SUPPORT_SCREEN_CAPTURE)
        if ((key == GLFW_KEY_F12) && (action == GLFW_PRESS))
        {
            version(all) { // #if defined(SUPPORT_GIF_RECORDING)
                if (mods == GLFW_MOD_CONTROL)
                {
                    if (gifRecording)
                    {
                        gifRecording = false;

                        MsfGifResult result = msf_gif_end(&gifState);

                        SaveFileData(TextFormat("%s/screenrec%03i.gif", CORE.Storage.basePath, screenshotCounter), result.data, cast(uint)result.dataSize);
                        msf_gif_free(result);

                        version(none) { // #if defined(PLATFORM_WEB)
                            // Download file from MEMFS (emscripten memory filesystem)
                            // saveFileFromMEMFSToDisk() function is defined in raylib/templates/web_shel/shell.html
                            emscripten_run_script(TextFormat("saveFileFromMEMFSToDisk('%s','%s')", TextFormat("screenrec%03i.gif", screenshotCounter - 1), TextFormat("screenrec%03i.gif", screenshotCounter - 1)));
                        }

                        TraceLog(TraceLogLevel.LOG_INFO, "SYSTEM: Finish animated GIF recording");
                    }
                    else
                    {
                        gifRecording = true;
                        gifFrameCounter = 0;

                        msf_gif_begin(&gifState, CORE.Window.screen.width, CORE.Window.screen.height);
                        screenshotCounter++;

                        TraceLog(TraceLogLevel.LOG_INFO, "SYSTEM: Start animated GIF recording: %s", TextFormat("screenrec%03i.gif", screenshotCounter));
                    }
                }
                else
                {
                    TakeScreenshot(TextFormat("screenshot%03i.png", screenshotCounter));
                    screenshotCounter++;
                }
            } // SUPPORT_GIF_RECORDING
            else // TODO: this repeated code was part of some C macro abuse, fix with a D mechanism.
            {
                TakeScreenshot(TextFormat("screenshot%03i.png", screenshotCounter));
                screenshotCounter++;
            }
        }
    } // SUPPORT_SCREEN_CAPTURE

    version(none) { // #if defined(SUPPORT_EVENTS_AUTOMATION)
        if ((key == GLFW_KEY_F11) && (action == GLFW_PRESS))
        {
            eventsRecording = !eventsRecording;

            // On finish recording, we export events into a file
            if (!eventsRecording) ExportAutomationEvents("eventsrec.rep");
        }
        else if ((key == GLFW_KEY_F9) && (action == GLFW_PRESS))
        {
            LoadAutomationEvents("eventsrec.rep");
            eventsPlaying = true;

            TraceLog(TraceLogLevel.LOG_WARNING, "eventsPlaying enabled!");
        }
    }
}

/// Get number of monitors
int GetMonitorCount()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        glfwGetMonitors(&monitorCount);
        return monitorCount;
    }

    else { 
        return 1;
    }
}

/// Get number of monitors
int GetCurrentMonitor()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor** monitors = glfwGetMonitors(&monitorCount);
        GLFWmonitor* monitor = null;

        if (monitorCount == 1) // easy out
            return 0;

        if (IsWindowFullscreen())
        {
            monitor = glfwGetWindowMonitor(CORE.Window.handle);
            for (int i = 0; i < monitorCount; i++)
            {
                if (monitors[i] == monitor)
                    return i;
            }
            return 0;
        }
        else
        {
            int x = 0;
            int y = 0;

            glfwGetWindowPos(CORE.Window.handle, &x, &y);

            for (int i = 0; i < monitorCount; i++)
            {
                int mx = 0;
                int my = 0;

                int width = 0;
                int height = 0;

                monitor = monitors[i];
                glfwGetMonitorWorkarea(monitor, &mx, &my, &width, &height);
                if (x >= mx && x <= (mx + width) && y >= my && y <= (my + height))
                    return i;
            }
        }
        return 0;
    }

    else {
        return 0;
    }
}

// Get selected monitor width
Vector2 GetMonitorPosition(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor** monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            int x, y;
            glfwGetMonitorPos(monitors[monitor], &x, &y);

            return Vector2( x, y );
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
    return Vector2(0, 0);
}

// Get selected monitor width (max available by monitor)
int GetMonitorWidth(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            int count = 0;
            const GLFWvidmode *modes = glfwGetVideoModes(monitors[monitor], &count);

            // We return the maximum resolution available, the last one in the modes array
            if (count > 0) return modes[count - 1].width;
            else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find video mode for selected monitor");
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
    return 0;
}

// Get selected monitor width (max available by monitor)
int GetMonitorHeight(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            int count = 0;
            const GLFWvidmode *modes = glfwGetVideoModes(monitors[monitor], &count);

            // We return the maximum resolution available, the last one in the modes array
            if (count > 0) return modes[count - 1].height;
            else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find video mode for selected monitor");
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
    return 0;
}

// Get selected monitor physical width in millimetres
int GetMonitorPhysicalWidth(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            int physicalWidth;
            glfwGetMonitorPhysicalSize(monitors[monitor], &physicalWidth, null);
            return physicalWidth;
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
    return 0;
}

// Get primary monitor physical height in millimetres
int GetMonitorPhysicalHeight(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            int physicalHeight;
            glfwGetMonitorPhysicalSize(monitors[monitor], null, &physicalHeight);
            return physicalHeight;
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
    return 0;
}

int GetMonitorRefreshRate(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            const GLFWvidmode *vidmode = glfwGetVideoMode(monitors[monitor]);
            return vidmode.refreshRate;
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
    version(none) { // #if defined(PLATFORM_DRM)
        if ((CORE.Window.connector) && (CORE.Window.modeIndex >= 0))
        {
            return CORE.Window.connector.modes[CORE.Window.modeIndex].vrefresh;
        }
    }
    return 0;
}

/// Get window position XY on monitor
extern(C)Vector2 GetWindowPosition()
{
    int x = 0;
    int y = 0;
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwGetWindowPos(CORE.Window.handle, &x, &y);
    }
    return Vector2(x, y);
}

/// Get window scale DPI factor
Vector2 GetWindowScaleDPI()
{
    Vector2 scale = Vector2( 1.0f, 1.0f );

    version(all) { // #if defined(PLATFORM_DESKTOP)
        float xdpi = 1.0;
        float ydpi = 1.0;
        Vector2 windowPos = GetWindowPosition();

        int monitorCount = 0;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        // Check window monitor
        for (int i = 0; i < monitorCount; i++)
        {
            glfwGetMonitorContentScale(monitors[i], &xdpi, &ydpi);

            int xpos, ypos, width, height;
            glfwGetMonitorWorkarea(monitors[i], &xpos, &ypos, &width, &height);

            if ((windowPos.x >= xpos) && (windowPos.x < xpos + width) &&
                (windowPos.y >= ypos) && (windowPos.y < ypos + height))
            {
                scale.x = xdpi;
                scale.y = ydpi;
                break;
            }
        }
    }

    return scale;
}

/// Get the human-readable, UTF-8 encoded name of the primary monitor
const(char) *GetMonitorName(int monitor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        int monitorCount;
        GLFWmonitor **monitors = glfwGetMonitors(&monitorCount);

        if ((monitor >= 0) && (monitor < monitorCount))
        {
            return glfwGetMonitorName(monitors[monitor]);
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Failed to find selected monitor");
    }
    return "";
}

/// Get clipboard text content
/// NOTE: returned string is allocated and freed by GLFW
const(char) *GetClipboardText()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        return glfwGetClipboardString(CORE.Window.handle);
    }

    else {
        return null;
    }
}

/// Set clipboard text content
void SetClipboardText(const char *text)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwSetClipboardString(CORE.Window.handle, text);
    }
}

/// Show mouse cursor
void ShowCursor()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwSetInputMode(CORE.Window.handle, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }

    CORE.Input.Mouse.cursorHidden = false;
}

/// Hides mouse cursor
void HideCursor()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwSetInputMode(CORE.Window.handle, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    }

    CORE.Input.Mouse.cursorHidden = true;
}

/// Check if cursor is not visible
bool IsCursorHidden()
{
    return CORE.Input.Mouse.cursorHidden;
}

// Enables cursor (unlock cursor)
void EnableCursor()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwSetInputMode(CORE.Window.handle, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }

    version(none) { // #if defined(PLATFORM_WEB)
        emscripten_exit_pointerlock();
    }

    CORE.Input.Mouse.cursorHidden = false;
}

/// Disables cursor (lock cursor)
void DisableCursor()
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        glfwSetInputMode(CORE.Window.handle, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    }
    version(none) { // #if defined(PLATFORM_WEB)
        emscripten_request_pointerlock("#canvas", 1);
    }

    CORE.Input.Mouse.cursorHidden = true;
}

/// Check if cursor is on the current screen.
bool IsCursorOnScreen()
{
    return CORE.Input.Mouse.cursorOnScreen;
}

/// Set background color (framebuffer clear color)
void ClearBackground(Color color)
{
    rlClearColor(color.r, color.g, color.b, color.a);   // Set clear color
    rlClearScreenBuffers();                             // Clear current framebuffers
}

/// Setup canvas (framebuffer) to start drawing
void BeginDrawing()
{
    // WARNING: Previously to BeginDrawing() other render textures drawing could happen,
    // consequently the measure for update vs draw is not accurate (only the total frame time is accurate)

    CORE.Time.current = GetTime();      // Number of elapsed seconds since InitTimer()
    CORE.Time.update = CORE.Time.current - CORE.Time.previous;
    CORE.Time.previous = CORE.Time.current;

    rlLoadIdentity();                   // Reset current matrix (modelview)
    rlMultMatrixf(MatrixToFloat(CORE.Window.screenScale)); // Apply screen scaling

    //rlTranslatef(0.375, 0.375, 0);    // HACK to have 2D pixel-perfect drawing on OpenGL 1.1
                                        // NOTE: Not required with OpenGL 3.3+
}

/// End canvas drawing and swap buffers (double buffering)
void EndDrawing()
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    version(none) { // #if defined(SUPPORT_MOUSE_CURSOR_POINT)
                    // Draw a small rectangle on mouse position for user reference
        if (!CORE.Input.Mouse.cursorHidden)
        {
            DrawRectangle(CORE.Input.Mouse.currentPosition.x, CORE.Input.Mouse.currentPosition.y, 3, 3, MAROON);
            rlDrawRenderBatchActive();  // Update and draw internal render batch
        }
    }

    version(all) { // #if defined(SUPPORT_GIF_RECORDING)
        // Draw record indicator
        if (gifRecording)
        {
            enum GIF_RECORD_FRAMERATE = 10;
            gifFrameCounter++;

            // NOTE: We record one gif frame every 10 game frames
            if ((gifFrameCounter%GIF_RECORD_FRAMERATE) == 0)
            {
                // Get image data for the current frame (from backbuffer)
                // NOTE: This process is quite slow... :(
                ubyte *screenData = rlReadScreenPixels(CORE.Window.screen.width, CORE.Window.screen.height);
                msf_gif_frame(&gifState, screenData, 10, 16, CORE.Window.screen.width*4);

                RL_FREE(screenData);    // Free image data
            }

            if (((gifFrameCounter/15)%2) == 1)
            {
                DrawCircle(30, CORE.Window.screen.height - 20, 10, MAROON);
                DrawText("GIF RECORDING", 50, CORE.Window.screen.height - 25, 10, RED);
            }

            rlDrawRenderBatchActive();  // Update and draw internal render batch
        }
    }

    version(none) { //  #if defined(SUPPORT_EVENTS_AUTOMATION)
                    // Draw record/play indicator
        if (eventsRecording)
        {
            gifFrameCounter++;

            if (((gifFrameCounter/15)%2) == 1)
            {
                DrawCircle(30, CORE.Window.screen.height - 20, 10, MAROON);
                DrawText("EVENTS RECORDING", 50, CORE.Window.screen.height - 25, 10, RED);
            }

            rlDrawRenderBatchActive();  // Update and draw internal render batch
        }
        else if (eventsPlaying)
        {
            gifFrameCounter++;

            if (((gifFrameCounter/15)%2) == 1)
            {
                DrawCircle(30, CORE.Window.screen.height - 20, 10, LIME);
                DrawText("EVENTS PLAYING", 50, CORE.Window.screen.height - 25, 10, GREEN);
            }

            rlDrawRenderBatchActive();  // Update and draw internal render batch
        }
    }

    version(all) { // #if !defined(SUPPORT_CUSTOM_FRAME_CONTROL)
        SwapScreenBuffer();                  // Copy back buffer to front buffer (screen)

        // Frame time control system
        CORE.Time.current = GetTime();
        CORE.Time.draw = CORE.Time.current - CORE.Time.previous;
        CORE.Time.previous = CORE.Time.current;

        CORE.Time.frame = CORE.Time.update + CORE.Time.draw;

        // Wait for some milliseconds...
        if (CORE.Time.frame < CORE.Time.target)
        {
            WaitTime((CORE.Time.target - CORE.Time.frame)*1000.0f);

            CORE.Time.current = GetTime();
            double waitTime = CORE.Time.current - CORE.Time.previous;
            CORE.Time.previous = CORE.Time.current;

            CORE.Time.frame += waitTime;    // Total frame time: update + draw + wait
        }

        PollInputEvents();      // Poll user events (before next frame update)
    }

    version(none) { // #if defined(SUPPORT_EVENTS_AUTOMATION)
                    // Events recording and playing logic
        if (eventsRecording) RecordAutomationEvent(CORE.Time.frameCounter);
        else if (eventsPlaying)
        {
            // TODO: When should we play? After/before/replace PollInputEvents()?
            if (CORE.Time.frameCounter >= eventCount) eventsPlaying = false;
            PlayAutomationEvent(CORE.Time.frameCounter);
        }
    }

    CORE.Time.frameCounter++;
}

/// Initialize 2D mode with custom camera (2D)
void BeginMode2D(Camera2D camera)
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    rlLoadIdentity();               // Reset current matrix (modelview)

    // Apply 2d camera transformation to modelview
    rlMultMatrixf(MatrixToFloat(GetCameraMatrix2D(camera)));

    // Apply screen scaling if required
    rlMultMatrixf(MatrixToFloat(CORE.Window.screenScale));
}

/// Ends 2D mode with custom camera
void EndMode2D()
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    rlLoadIdentity();               // Reset current matrix (modelview)
    rlMultMatrixf(MatrixToFloat(CORE.Window.screenScale)); // Apply screen scaling if required
}

// Initializes 3D mode with custom camera (3D)
void BeginMode3D(Camera3D camera)
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    rlMatrixMode(RL_PROJECTION);    // Switch to projection matrix
    rlPushMatrix();                 // Save previous matrix, which contains the settings for the 2d ortho projection
    rlLoadIdentity();               // Reset current matrix (projection)

    float aspect = CORE.Window.currentFbo.width/cast(float)CORE.Window.currentFbo.height;

    // NOTE: zNear and zFar values are important when computing depth buffer values
    if (camera.projection == CameraProjection.CAMERA_PERSPECTIVE)
    {
        // Setup perspective projection
        double top = RL_CULL_DISTANCE_NEAR*tan(camera.fovy*0.5*DEG2RAD);
        double right = top*aspect;

        rlFrustum(-right, right, -top, top, RL_CULL_DISTANCE_NEAR, RL_CULL_DISTANCE_FAR);
    }
    else if (camera.projection == CameraProjection.CAMERA_ORTHOGRAPHIC)
    {
        // Setup orthographic projection
        double top = camera.fovy/2.0;
        double right = top*aspect;

        rlOrtho(-right, right, -top,top, RL_CULL_DISTANCE_NEAR, RL_CULL_DISTANCE_FAR);
    }

    rlMatrixMode(RL_MODELVIEW);     // Switch back to modelview matrix
    rlLoadIdentity();               // Reset current matrix (modelview)

    // Setup Camera view
    Matrix matView = MatrixLookAt(camera.position, camera.target, camera.up);
    rlMultMatrixf(MatrixToFloat(matView));      // Multiply modelview matrix by view matrix (camera)

    rlEnableDepthTest();            // Enable DEPTH_TEST for 3D
}

/// Ends 3D mode and returns to default 2D orthographic mode
void EndMode3D()
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    rlMatrixMode(RL_PROJECTION);    // Switch to projection matrix
    rlPopMatrix();                  // Restore previous matrix (projection) from matrix stack

    rlMatrixMode(RL_MODELVIEW);     // Switch back to modelview matrix
    rlLoadIdentity();               // Reset current matrix (modelview)

    rlMultMatrixf(MatrixToFloat(CORE.Window.screenScale)); // Apply screen scaling if required

    rlDisableDepthTest();           // Disable DEPTH_TEST for 2D
}

/// Initializes render texture for drawing
void BeginTextureMode(RenderTexture2D target)
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    rlEnableFramebuffer(target.id); // Enable render target

    // Set viewport to framebuffer size
    rlViewport(0, 0, target.texture.width, target.texture.height);

    rlMatrixMode(RL_PROJECTION);    // Switch to projection matrix
    rlLoadIdentity();               // Reset current matrix (projection)

    // Set orthographic projection to current framebuffer size
    // NOTE: Configured top-left corner as (0, 0)
    rlOrtho(0, target.texture.width, target.texture.height, 0, 0.0f, 1.0f);

    rlMatrixMode(RL_MODELVIEW);     // Switch back to modelview matrix
    rlLoadIdentity();               // Reset current matrix (modelview)

    //rlScalef(0.0f, -1.0f, 0.0f);  // Flip Y-drawing (?)

    // Setup current width/height for proper aspect ratio
    // calculation when using BeginMode3D()
    CORE.Window.currentFbo.width = target.texture.width;
    CORE.Window.currentFbo.height = target.texture.height;
}

/// Ends drawing to render texture
void EndTextureMode()
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    rlDisableFramebuffer();         // Disable render target (fbo)

    // Set viewport to default framebuffer size
    SetupViewport(CORE.Window.render.width, CORE.Window.render.height);

    // Reset current fbo to screen size
    CORE.Window.currentFbo.width = CORE.Window.render.width;
    CORE.Window.currentFbo.height = CORE.Window.render.height;
}

/// Begin custom shader mode
void BeginShaderMode(Shader shader)
{
    rlSetShader(shader.id, shader.locs);
}

/// End custom shader mode (returns to default shader)
void EndShaderMode()
{
    rlSetShader(rlGetShaderIdDefault(), rlGetShaderLocsDefault());
}

/// Begin blending mode (alpha, additive, multiplied, subtract, custom)
/// NOTE: Blend modes supported are enumerated in BlendMode enum
void BeginBlendMode(int mode)
{
    rlSetBlendMode(mode);
}

/// End blending mode (reset to default: alpha blending)
void EndBlendMode()
{
    rlSetBlendMode(BlendMode.BLEND_ALPHA);
}

/// Begin scissor mode (define screen area for following drawing)
/// NOTE: Scissor rec refers to bottom-left corner, we change it to upper-left
void BeginScissorMode(int x, int y, int width, int height)
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch

    rlEnableScissorTest();

    if ((CORE.Window.flags & ConfigFlags.FLAG_WINDOW_HIGHDPI) > 0)
    {
        Vector2 scale = GetWindowScaleDPI();

        rlScissor(cast(int)(x*scale.x), cast(int)(CORE.Window.currentFbo.height - (y + height)*scale.y), cast(int)(width*scale.x), cast(int)(height*scale.y));
    }
    else
    {
        rlScissor(x, CORE.Window.currentFbo.height - (y + height), width, height);
    }
}

/// End scissor mode
void EndScissorMode()
{
    rlDrawRenderBatchActive();      // Update and draw internal render batch
    rlDisableScissorTest();
}

/// Begin VR drawing configuration
void BeginVrStereoMode(VrStereoConfig config)
{
    rlEnableStereoRender();

    // Set stereo render matrices
    rlSetMatrixProjectionStereo(config.projection[0], config.projection[1]);
    rlSetMatrixViewOffsetStereo(config.viewOffset[0], config.viewOffset[1]);
}

/// End VR drawing process (and desktop mirror)
void EndVrStereoMode()
{
    rlDisableStereoRender();
}

/// Load VR stereo config for VR simulator device parameters
VrStereoConfig LoadVrStereoConfig(VrDeviceInfo device)
{
    VrStereoConfig config;

    if ((rlGetVersion() == rlGlVersion.OPENGL_33) || (rlGetVersion() == rlGlVersion.OPENGL_ES_20))
    {
        // Compute aspect ratio
        float aspect = (device.hResolution*0.5f)/device.vResolution;

        // Compute lens parameters
        float lensShift = (device.hScreenSize*0.25f - device.lensSeparationDistance*0.5f)/device.hScreenSize;
        config.leftLensCenter[0] = 0.25f + lensShift;
        config.leftLensCenter[1] = 0.5f;
        config.rightLensCenter[0] = 0.75f - lensShift;
        config.rightLensCenter[1] = 0.5f;
        config.leftScreenCenter[0] = 0.25f;
        config.leftScreenCenter[1] = 0.5f;
        config.rightScreenCenter[0] = 0.75f;
        config.rightScreenCenter[1] = 0.5f;

        // Compute distortion scale parameters
        // NOTE: To get lens max radius, lensShift must be normalized to [-1..1]
        float lensRadius = fabsf(-1.0f - 4.0f*lensShift);
        float lensRadiusSq = lensRadius*lensRadius;
        float distortionScale = device.lensDistortionValues[0] +
                                device.lensDistortionValues[1]*lensRadiusSq +
                                device.lensDistortionValues[2]*lensRadiusSq*lensRadiusSq +
                                device.lensDistortionValues[3]*lensRadiusSq*lensRadiusSq*lensRadiusSq;

        float normScreenWidth = 0.5f;
        float normScreenHeight = 1.0f;
        config.scaleIn[0] = 2.0f/normScreenWidth;
        config.scaleIn[1] = 2.0f/normScreenHeight/aspect;
        config.scale[0] = normScreenWidth*0.5f/distortionScale;
        config.scale[1] = normScreenHeight*0.5f*aspect/distortionScale;

        // Fovy is normally computed with: 2*atan2f(device.vScreenSize, 2*device.eyeToScreenDistance)
        // ...but with lens distortion it is increased (see Oculus SDK Documentation)
        //float fovy = 2.0f*atan2f(device.vScreenSize*0.5f*distortionScale, device.eyeToScreenDistance);     // Really need distortionScale?
        float fovy = 2.0f*atan2f(device.vScreenSize*0.5f, device.eyeToScreenDistance);

        // Compute camera projection matrices
        float projOffset = 4.0f*lensShift;      // Scaled to projection space coordinates [-1..1]
        Matrix proj = MatrixPerspective(fovy, aspect, RL_CULL_DISTANCE_NEAR, RL_CULL_DISTANCE_FAR);

        config.projection[0] = MatrixMultiply(proj, MatrixTranslate(projOffset, 0.0f, 0.0f));
        config.projection[1] = MatrixMultiply(proj, MatrixTranslate(-projOffset, 0.0f, 0.0f));

        // Compute camera transformation matrices
        // NOTE: Camera movement might seem more natural if we model the head.
        // Our axis of rotation is the base of our head, so we might want to add
        // some y (base of head to eye level) and -z (center of head to eye protrusion) to the camera positions.
        config.viewOffset[0] = MatrixTranslate(-device.interpupillaryDistance*0.5f, 0.075f, 0.045f);
        config.viewOffset[1] = MatrixTranslate(device.interpupillaryDistance*0.5f, 0.075f, 0.045f);

        // Compute eyes Viewports
        /*
        config.eyeViewportRight[0] = 0;
        config.eyeViewportRight[1] = 0;
        config.eyeViewportRight[2] = device.hResolution/2;
        config.eyeViewportRight[3] = device.vResolution;

        config.eyeViewportLeft[0] = device.hResolution/2;
        config.eyeViewportLeft[1] = 0;
        config.eyeViewportLeft[2] = device.hResolution/2;
        config.eyeViewportLeft[3] = device.vResolution;
        */
    }
    else TraceLog(TraceLogLevel.LOG_WARNING, "RLGL: VR Simulator not supported on OpenGL 1.1");

    return config;
}

/// Unload VR stereo config properties
void UnloadVrStereoConfig(VrStereoConfig config)
{
    //...
}

/// Load shader from files and bind default locations
/// NOTE: If shader string is null, using default vertex/fragment shaders
Shader LoadShader(const char *vsFileName, const char *fsFileName)
{
    Shader shader;

    char *vShaderStr = null;
    char *fShaderStr = null;

    if (vsFileName != null) vShaderStr = LoadFileText(vsFileName);
    if (fsFileName != null) fShaderStr = LoadFileText(fsFileName);

    shader = LoadShaderFromMemory(vShaderStr, fShaderStr);

    UnloadFileText(vShaderStr);
    UnloadFileText(fShaderStr);

    return shader;
}

/// Load shader from code strings and bind default locations
Shader LoadShaderFromMemory(const char *vsCode, const char *fsCode)
{
    Shader shader;
    shader.locs = cast(int *)RL_CALLOC(RL_MAX_SHADER_LOCATIONS, int.sizeof);

    // NOTE: All locations must be reseted to -1 (no location)
    for (int i = 0; i < RL_MAX_SHADER_LOCATIONS; i++) shader.locs[i] = -1;

    shader.id = rlLoadShaderCode(vsCode, fsCode);

    // After shader loading, we TRY to set default location names
    if (shader.id > 0)
    {
        // Default shader attribute locations have been binded before linking:
        //          vertex position location    = 0
        //          vertex texcoord location    = 1
        //          vertex normal location      = 2
        //          vertex color location       = 3
        //          vertex tangent location     = 4
        //          vertex texcoord2 location   = 5

        // NOTE: If any location is not found, loc point becomes -1

        // Get handles to GLSL input attibute locations
        shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_POSITION] = rlGetLocationAttrib(shader.id, RL_DEFAULT_SHADER_ATTRIB_NAME_POSITION);
        shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD01] = rlGetLocationAttrib(shader.id, RL_DEFAULT_SHADER_ATTRIB_NAME_TEXCOORD);
        shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD02] = rlGetLocationAttrib(shader.id, RL_DEFAULT_SHADER_ATTRIB_NAME_TEXCOORD2);
        shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_NORMAL] = rlGetLocationAttrib(shader.id, RL_DEFAULT_SHADER_ATTRIB_NAME_NORMAL);
        shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT] = rlGetLocationAttrib(shader.id, RL_DEFAULT_SHADER_ATTRIB_NAME_TANGENT);
        shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR] = rlGetLocationAttrib(shader.id, RL_DEFAULT_SHADER_ATTRIB_NAME_COLOR);

        // Get handles to GLSL uniform locations (vertex shader)
        shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MVP] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_UNIFORM_NAME_MVP);
        shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_VIEW] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_UNIFORM_NAME_VIEW);
        shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_PROJECTION] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_UNIFORM_NAME_PROJECTION);
        shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_UNIFORM_NAME_MODEL);
        shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_NORMAL] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_UNIFORM_NAME_NORMAL);

        // Get handles to GLSL uniform locations (fragment shader)
        shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_DIFFUSE] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_UNIFORM_NAME_COLOR);
        shader.locs[ShaderLocationIndex.SHADER_LOC_MAP_DIFFUSE] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_SAMPLER2D_NAME_TEXTURE0);  // SHADER_LOC_MAP_ALBEDO
        shader.locs[ShaderLocationIndex.SHADER_LOC_MAP_SPECULAR] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_SAMPLER2D_NAME_TEXTURE1); // SHADER_LOC_MAP_METALNESS
        shader.locs[ShaderLocationIndex.SHADER_LOC_MAP_NORMAL] = rlGetLocationUniform(shader.id, RL_DEFAULT_SHADER_SAMPLER2D_NAME_TEXTURE2);
    }

    return shader;
}

/// Unload shader from GPU memory (VRAM)
void UnloadShader(Shader shader)
{
    if (shader.id != rlGetShaderIdDefault())
    {
        rlUnloadShaderProgram(shader.id);
        RL_FREE(shader.locs);
    }
}

/// Get shader uniform location
int GetShaderLocation(Shader shader, const char *uniformName)
{
    return rlGetLocationUniform(shader.id, uniformName);
}

/// Get shader attribute location
int GetShaderLocationAttrib(Shader shader, const char *attribName)
{
    return rlGetLocationAttrib(shader.id, attribName);
}

/// Set shader uniform value
void SetShaderValue(Shader shader, int locIndex, const void *value, int uniformType)
{
    SetShaderValueV(shader, locIndex, value, uniformType, 1);
}

/// Set shader uniform value vector
void SetShaderValueV(Shader shader, int locIndex, const void *value, int uniformType, int count)
{
    rlEnableShader(shader.id);
    rlSetUniform(locIndex, value, uniformType, count);
    //rlDisableShader();      // Avoid reseting current shader program, in case other uniforms are set
}

/// Set shader uniform value (matrix 4x4)
void SetShaderValueMatrix(Shader shader, int locIndex, Matrix mat)
{
    rlEnableShader(shader.id);
    rlSetUniformMatrix(locIndex, mat);
    //rlDisableShader();
}

/// Set shader uniform value for texture
void SetShaderValueTexture(Shader shader, int locIndex, Texture2D texture)
{
    rlEnableShader(shader.id);
    rlSetUniformSampler(locIndex, texture.id);
    //rlDisableShader();
}

/// Get a ray trace from mouse position
Ray GetMouseRay(Vector2 mouse, Camera camera)
{
    Ray ray;

    // Calculate normalized device coordinates
    // NOTE: y value is negative
    float x = (2.0f*mouse.x)/GetScreenWidth() - 1.0f;
    float y = 1.0f - (2.0f*mouse.y)/GetScreenHeight();
    float z = 1.0f;

    // Store values in a vector
    Vector3 deviceCoords = Vector3( x, y, z );

    // Calculate view matrix from camera look at
    Matrix matView = MatrixLookAt(camera.position, camera.target, camera.up);

    Matrix matProj = MatrixIdentity();

    if (camera.projection == CameraProjection.CAMERA_PERSPECTIVE)
    {
        // Calculate projection matrix from perspective
        matProj = MatrixPerspective(camera.fovy*DEG2RAD, (GetScreenWidth()/cast(double)GetScreenHeight()), RL_CULL_DISTANCE_NEAR, RL_CULL_DISTANCE_FAR);
    }
    else if (camera.projection == CameraProjection.CAMERA_ORTHOGRAPHIC)
    {
        float aspect = CORE.Window.screen.width/cast(float)CORE.Window.screen.height;
        double top = camera.fovy/2.0;
        double right = top*aspect;

        // Calculate projection matrix from orthographic
        matProj = MatrixOrtho(-right, right, -top, top, 0.01, 1000.0);
    }

    // Unproject far/near points
    Vector3 nearPoint = Vector3Unproject(Vector3( deviceCoords.x, deviceCoords.y, 0.0f ), matProj, matView);
    Vector3 farPoint = Vector3Unproject(Vector3( deviceCoords.x, deviceCoords.y, 1.0f ), matProj, matView);

    // Unproject the mouse cursor in the near plane.
    // We need this as the source position because orthographic projects, compared to perspect doesn't have a
    // convergence point, meaning that the "eye" of the camera is more like a plane than a point.
    Vector3 cameraPlanePointerPos = Vector3Unproject(Vector3( deviceCoords.x, deviceCoords.y, -1.0f ), matProj, matView);

    // Calculate normalized direction vector
    Vector3 direction = Vector3Normalize(Vector3Subtract(farPoint, nearPoint));

    if (camera.projection == CameraProjection.CAMERA_PERSPECTIVE) ray.position = camera.position;
    else if (camera.projection == CameraProjection.CAMERA_ORTHOGRAPHIC) ray.position = cameraPlanePointerPos;

    // Apply calculated vectors to ray
    ray.direction = direction;

    return ray;
}

/// Get transform matrix for camera
Matrix GetCameraMatrix(Camera camera)
{
    return MatrixLookAt(camera.position, camera.target, camera.up);
}

/// Get camera 2d transform matrix
Matrix GetCameraMatrix2D(Camera2D camera)
{
    Matrix matTransform;
    // The camera in world-space is set by
    //   1. Move it to target
    //   2. Rotate by -rotation and scale by (1/zoom)
    //      When setting higher scale, it's more intuitive for the world to become bigger (= camera become smaller),
    //      not for the camera getting bigger, hence the invert. Same deal with rotation.
    //   3. Move it by (-offset);
    //      Offset defines target transform relative to screen, but since we're effectively "moving" screen (camera)
    //      we need to do it into opposite direction (inverse transform)

    // Having camera transform in world-space, inverse of it gives the modelview transform.
    // Since (A*B*C)' = C'*B'*A', the modelview is
    //   1. Move to offset
    //   2. Rotate and Scale
    //   3. Move by -target
    Matrix matOrigin = MatrixTranslate(-camera.target.x, -camera.target.y, 0.0f);
    Matrix matRotation = MatrixRotate(Vector3( 0.0f, 0.0f, 1.0f ), camera.rotation*DEG2RAD);
    Matrix matScale = MatrixScale(camera.zoom, camera.zoom, 1.0f);
    Matrix matTranslation = MatrixTranslate(camera.offset.x, camera.offset.y, 0.0f);

    matTransform = MatrixMultiply(MatrixMultiply(matOrigin, MatrixMultiply(matScale, matRotation)), matTranslation);

    return matTransform;
}

/// Get the screen space position from a 3d world space position
Vector2 GetWorldToScreen(Vector3 position, Camera camera)
{
    Vector2 screenPosition = GetWorldToScreenEx(position, camera, GetScreenWidth(), GetScreenHeight());

    return screenPosition;
}

/// Get size position for a 3d world space position (useful for texture drawing)
Vector2 GetWorldToScreenEx(Vector3 position, Camera camera, int width, int height)
{
    // Calculate projection matrix (from perspective instead of frustum
    Matrix matProj = MatrixIdentity();

    if (camera.projection == CameraProjection.CAMERA_PERSPECTIVE)
    {
        // Calculate projection matrix from perspective
        matProj = MatrixPerspective(camera.fovy*DEG2RAD, (width/cast(double)height), RL_CULL_DISTANCE_NEAR, RL_CULL_DISTANCE_FAR);
    }
    else if (camera.projection == CameraProjection.CAMERA_ORTHOGRAPHIC)
    {
        float aspect = CORE.Window.screen.width/cast(float)CORE.Window.screen.height;
        double top = camera.fovy/2.0;
        double right = top*aspect;

        // Calculate projection matrix from orthographic
        matProj = MatrixOrtho(-right, right, -top, top, RL_CULL_DISTANCE_NEAR, RL_CULL_DISTANCE_FAR);
    }

    // Calculate view matrix from camera look at (and transpose it)
    Matrix matView = MatrixLookAt(camera.position, camera.target, camera.up);

    // TODO: Why not use Vector3Transform(Vector3 v, Matrix mat)?

    // Convert world position vector to quaternion
    Quaternion worldPos = Quaternion( position.x, position.y, position.z, 1.0f );

    // Transform world position to view
    worldPos = QuaternionTransform(worldPos, matView);

    // Transform result to projection (clip space position)
    worldPos = QuaternionTransform(worldPos, matProj);

    // Calculate normalized device coordinates (inverted y)
    Vector3 ndcPos = Vector3( worldPos.x/worldPos.w, -worldPos.y/worldPos.w, worldPos.z/worldPos.w );

    // Calculate 2d screen position vector
    Vector2 screenPosition = Vector2( (ndcPos.x + 1.0f)/2.0f*width, (ndcPos.y + 1.0f)/2.0f*height );

    return screenPosition;
}

/// Get the screen space position for a 2d camera world space position
Vector2 GetWorldToScreen2D(Vector2 position, Camera2D camera)
{
    Matrix matCamera = GetCameraMatrix2D(camera);
    Vector3 transform = Vector3Transform(Vector3( position.x, position.y, 0 ), matCamera);

    return Vector2( transform.x, transform.y );
}

/// Get the world space position for a 2d camera screen space position
Vector2 GetScreenToWorld2D(Vector2 position, Camera2D camera)
{
    Matrix invMatCamera = MatrixInvert(GetCameraMatrix2D(camera));
    Vector3 transform = Vector3Transform(Vector3( position.x, position.y, 0 ), invMatCamera);

    return Vector2( transform.x, transform.y );
}

/// Set target FPS (maximum)
void SetTargetFPS(int fps)
{
    if (fps < 1) CORE.Time.target = 0.0;
    else CORE.Time.target = 1.0/fps;

    TraceLog(TraceLogLevel.LOG_INFO, "TIMER: Target time per frame: %02.03f milliseconds", cast(float)CORE.Time.target*1000);
}

/// Get current FPS
/// NOTE: We calculate an average framerate
int GetFPS()
{
    int fps = 0;

    version(all) { // #if !defined(SUPPORT_CUSTOM_FRAME_CONTROL)
        enum FPS_CAPTURE_FRAMES_COUNT = 30;     // 30 captures
        enum FPS_AVERAGE_TIME_SECONDS = 0.5f;    // 500 millisecondes
        enum FPS_STEP = (FPS_AVERAGE_TIME_SECONDS/FPS_CAPTURE_FRAMES_COUNT);

        static int index = 0;
        static float[FPS_CAPTURE_FRAMES_COUNT] history = 0;
        static float average = 0, last = 0;
        float fpsFrame = GetFrameTime();

        if (fpsFrame == 0) return 0;

        if ((GetTime() - last) > FPS_STEP)
        {
            last = GetTime();
            index = (index + 1)%FPS_CAPTURE_FRAMES_COUNT;
            average -= history[index];
            history[index] = fpsFrame/FPS_CAPTURE_FRAMES_COUNT;
            average += history[index];
        }

        fps = cast(int)roundf(1.0f/average);
    }

    return fps;
}

/// Get time in seconds for last frame drawn (delta time)
float GetFrameTime()
{
    return CORE.Time.frame;
}

/// Get elapsed time measure in seconds since InitTimer()
/// NOTE: On PLATFORM_DESKTOP InitTimer() is called on InitWindow()
/// NOTE: On PLATFORM_DESKTOP, timer is initialized on glfwInit()
double GetTime()
{
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        return glfwGetTime();   // Elapsed time since glfwInit()
    }

    version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        timespec ts;
        clock_gettime(CLOCK_MONOTONIC, &ts);
        cpp_ulonglong time = ts.tv_sec*1000000000UL + ts.tv_nsec;

        return (time - CORE.Time.base)*1e-9;  // Elapsed time since InitTimer()
    }
}

/// Setup window configuration flags (view FLAGS)
/// NOTE: This function is expected to be called before window creation,
/// because it setups some flags for the window creation process.
/// To configure window states after creation, just use SetWindowState()
void SetConfigFlags(uint flags)
{
    // Selected flags are set but not evaluated at this point,
    // flag evaluation happens at InitWindow() or SetWindowState()
    CORE.Window.flags |= flags;
}

/// Takes a screenshot of current screen (saved a .png)
void TakeScreenshot(const char *fileName)
{
    ubyte *imgData = rlReadScreenPixels(CORE.Window.render.width, CORE.Window.render.height);
    Image image = Image( imgData, CORE.Window.render.width, CORE.Window.render.height, 1, PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 );

    char[512] path = 0;
    strcpy(path.ptr, TextFormat("%s/%s", CORE.Storage.basePath, fileName));

    ExportImage(image, path.ptr);
    RL_FREE(imgData);

    version(none) { // #if defined(PLATFORM_WEB)
        // Download file from MEMFS (emscripten memory filesystem)
        // saveFileFromMEMFSToDisk() function is defined in raylib/src/shell.html
        emscripten_run_script(TextFormat("saveFileFromMEMFSToDisk('%s','%s')", GetFileName(path), GetFileName(path)));
    }

    TraceLog(TraceLogLevel.LOG_INFO, "SYSTEM: [%s] Screenshot taken successfully", path.ptr);
}

/// Get a random value between min and max (both included)
deprecated("Use std.random.uniform instead.") int GetRandomValue(int min, int max)
{
    if (min > max)
    {
        int tmp = max;
        max = min;
        min = tmp;
    }

    return (rand()%(abs(max - min) + 1) + min);
}

/// Set the seed for the random number generator
void SetRandomSeed(uint seed)
{
    srand(seed);
}

/// Check if the file exists
bool FileExists(const char *fileName)
{
    bool result = false;

    version(Windows) { //#if defined(_WIN32)
        if (_access(fileName, 0) != -1) result = true;
    } else {
        if (access(fileName, F_OK) != -1) result = true;
    }

    return result;
}

/// Check file extension
/// NOTE: Extensions checking is not case-sensitive
bool IsFileExtension(const char *fileName, const char *ext)
{
    bool result = false;
    const char *fileExt = GetFileExtension(fileName);

    if (fileExt != null)
    {
        version(all) { // #if defined(SUPPORT_TEXT_MANIPULATION)
            int extCount = 0;
            const char **checkExts = TextSplit(ext, ';', &extCount);

            char[16] fileExtLower = 0;
            strcpy(fileExtLower.ptr, TextToLower(fileExt));

            for (int i = 0; i < extCount; i++)
            {
                if (TextIsEqual(fileExtLower.ptr, TextToLower(checkExts[i])))
                {
                    result = true;
                    break;
                }
            }
        } else {
            if (strcmp(fileExt, ext) == 0) result = true;
        }
    }

    return result;
}

/// Check if a directory path exists
bool DirectoryExists(const char *dirPath)
{
    bool result = false;
    DIR *dir = opendir(dirPath);

    if (dir != null)
    {
        result = true;
        closedir(dir);
    }

    return result;
}

/// Get pointer to extension for a filename string (includes the dot: .png)
const(char) *GetFileExtension(const char *fileName)
{
    const char *dot = strrchr(fileName, '.');

    if (!dot || dot == fileName) return null;

    return dot;
}

/// String pointer reverse break: returns right-most occurrence of charset in s
private const(char) *strprbrk(const(char)* s, const char *charset)
{
    const(char)*latestMatch = null;
    for (; (s = strpbrk(s, charset)) != null; latestMatch = s++) { }
    return latestMatch;
}

/// Get pointer to filename for a path string
const(char) *GetFileName(const(char)* filePath)
{
    const(char)* fileName = null;
    if (filePath != null) fileName = strprbrk(filePath, "\\/");

    if (!fileName) return filePath;

    return fileName + 1;
}

/// Get filename string without extension (uses static string)
const(char) *GetFileNameWithoutExt(const char *filePath)
{
    enum MAX_FILENAMEWITHOUTEXT_LENGTH = 128;

    static char[MAX_FILENAMEWITHOUTEXT_LENGTH] fileName = 0;
    memset(fileName.ptr, 0, MAX_FILENAMEWITHOUTEXT_LENGTH);

    if (filePath != null) strcpy(fileName.ptr, GetFileName(filePath));   // Get filename with extension

    int size = cast(int)strlen(fileName.ptr);   // Get size in bytes

    for (int i = 0; (i < size) && (i < MAX_FILENAMEWITHOUTEXT_LENGTH); i++)
    {
        if (fileName[i] == '.')
        {
            // NOTE: We break on first '.' found
            fileName[i] = '\0';
            break;
        }
    }

    return fileName.ptr;
}

/// Get directory for a given filePath
const(char)*GetDirectoryPath(const char *filePath)
{
/*
    // NOTE: Directory separator is different in Windows and other platforms,
    // fortunately, Windows also support the '/' separator, that's the one should be used
    #if defined(_WIN32)
        char separator = '\\';
    #else
        char separator = '/';
    #endif
*/
    const(char) *lastSlash = null;
    static char[MAX_FILEPATH_LENGTH] dirPath = 0;
    memset(dirPath.ptr, 0, MAX_FILEPATH_LENGTH);

    // In case provided path does not contain a root drive letter (C:\, D:\) nor leading path separator (\, /),
    // we add the current directory path to dirPath
    if (filePath[1] != ':' && filePath[0] != '\\' && filePath[0] != '/')
    {
        // For security, we set starting path to current directory,
        // obtained path will be concated to this
        dirPath[0] = '.';
        dirPath[1] = '/';
    }

    lastSlash = strprbrk(filePath, "\\/");
    if (lastSlash)
    {
        if (lastSlash == filePath)
        {
            // The last and only slash is the leading one: path is in a root directory
            dirPath[0] = filePath[0];
            dirPath[1] = '\0';
        }
        else
        {
            // NOTE: Be careful, strncpy() is not safe, it does not care about '\0'
            memcpy(dirPath.ptr + (filePath[1] != ':' && filePath[0] != '\\' && filePath[0] != '/' ? 2 : 0), filePath, strlen(filePath) - (strlen(lastSlash) - 1));
            dirPath[strlen(filePath) - strlen(lastSlash) + (filePath[1] != ':' && filePath[0] != '\\' && filePath[0] != '/' ? 2 : 0)] = '\0';  // Add '\0' manually
        }
    }

    return dirPath.ptr;
}

/// Get previous directory path for a given path
const(char) *GetPrevDirectoryPath(const char *dirPath)
{
    static char[MAX_FILEPATH_LENGTH] prevDirPath = 0;
    memset(prevDirPath.ptr, 0, MAX_FILEPATH_LENGTH);
    int pathLen = cast(int)strlen(dirPath);

    if (pathLen <= 3) strcpy(prevDirPath.ptr, dirPath);

    for (int i = (pathLen - 1); (i >= 0) && (pathLen > 3); i--)
    {
        if ((dirPath[i] == '\\') || (dirPath[i] == '/'))
        {
            // Check for root: "C:\" or "/"
            if (((i == 2) && (dirPath[1] ==':')) || (i == 0)) i++;

            strncpy(prevDirPath.ptr, dirPath, i);
            break;
        }
    }

    return prevDirPath.ptr;
}

//// Get current working directory
const(char) *GetWorkingDirectory()
{
    static char[MAX_FILEPATH_LENGTH] currentDir = 0;
    memset(currentDir.ptr, 0, MAX_FILEPATH_LENGTH);

    char *path = GETCWD(currentDir.ptr, MAX_FILEPATH_LENGTH - 1);

    return path;
}


/// Get filenames in a directory path (max 512 files)
/// NOTE: Files count is returned by parameters pointer
char **GetDirectoryFiles(const char *dirPath, int *fileCount)
{

    ClearDirectoryFiles();

    // Memory allocation for MAX_DIRECTORY_FILES
    dirFilesPath = cast(char **)malloc(MAX_DIRECTORY_FILES * (char *).sizeof);
    for (int i = 0; i < MAX_DIRECTORY_FILES; i++) dirFilesPath[i] = cast(char *)malloc(MAX_FILEPATH_LENGTH * char.sizeof);

    int counter = 0;
    dirent *entity;
    DIR *dir = opendir(dirPath);

    if (dir != null)  // It's a directory
    {
        // TODO: Reading could be done in two passes,
        // first one to count files and second one to read names
        // That way we can allocate required memory, instead of a limited pool

        while ((entity = readdir(dir)) != null)
        {
            strcpy(dirFilesPath[counter], entity.d_name.ptr);
            counter++;
        }

        closedir(dir);
    }
    else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: Failed to open requested directory");  // Maybe it's a file...

    dirFileCount = counter;
    *fileCount = dirFileCount;

    return dirFilesPath;
}

/// Clear directory files paths buffers
void ClearDirectoryFiles()
{
    if (dirFileCount > 0)
    {
        for (int i = 0; i < MAX_DIRECTORY_FILES; i++) free(dirFilesPath[i]);

        free(dirFilesPath);
    }

    dirFileCount = 0;
}

/// Change working directory, returns true on success
bool ChangeDirectory(const char *dir)
{
    int result = CHDIR(dir);

    if (result != 0) TraceLog(TraceLogLevel.LOG_WARNING, "SYSTEM: Failed to change to directory: %s", dir);

    return (result == 0);
}

/// Check if a file has been dropped into window
bool IsFileDropped()
{
    if (CORE.Window.dropFileCount > 0) return true;
    else return false;
}

/// Get dropped files names
char **GetDroppedFiles(int *count)
{
    *count = CORE.Window.dropFileCount;
    return CORE.Window.dropFilesPath;
}

/// Clear dropped files paths buffer
void ClearDroppedFiles()
{
    if (CORE.Window.dropFileCount > 0)
    {
        for (int i = 0; i < CORE.Window.dropFileCount; i++) free(CORE.Window.dropFilesPath[i]);

        free(CORE.Window.dropFilesPath);

        CORE.Window.dropFileCount = 0;
    }
}

/// Get file modification time (last write time)
c_long GetFileModTime(const char *fileName)
{
    stat_t result;

    if (stat(fileName, &result) == 0)
    {
        time_t mod = result.st_mtime;

        return cast(c_long)mod;
    }

    return 0;
}

/// Compress data (DEFLATE algorythm)
ubyte *CompressData(ubyte *data, int dataLength, int *compDataLength)
{
    enum COMPRESSION_QUALITY_DEFLATE = 8;

    ubyte *compData = null;

    version(all) { // #if defined(SUPPORT_COMPRESSION_API)
                   // Compress data and generate a valid DEFLATE stream
        sdefl sdeflThing;
        int bounds = sdefl_bound(dataLength);
        compData = cast(ubyte *)RL_CALLOC(bounds, 1);
        *compDataLength = sdeflate(&sdeflThing, compData, data, dataLength, COMPRESSION_QUALITY_DEFLATE);   // Compression level 8, same as stbwi

        TraceLog(TraceLogLevel.LOG_INFO, "SYSTEM: Compress data: Original size: %i -> Comp. size: %i", dataLength, *compDataLength);
    }

    return compData;
}

/// Decompress data (DEFLATE algorythm)
ubyte *DecompressData(ubyte *compData, int compDataLength, int *dataLength)
{
    ubyte *data = null;

    version(all) { // #if defined(SUPPORT_COMPRESSION_API)
        // Decompress data from a valid DEFLATE stream
        data = cast(ubyte *)RL_CALLOC(MAX_DECOMPRESSION_SIZE*1024*1024, 1);
        int length = sinflate(data, MAX_DECOMPRESSION_SIZE, compData, compDataLength);
        ubyte *temp = cast(ubyte *)RL_REALLOC(data, length);

        if (temp != null) data = temp;
        else TraceLog(TraceLogLevel.LOG_WARNING, "SYSTEM: Failed to re-allocate required decompression memory");

        *dataLength = length;

        TraceLog(TraceLogLevel.LOG_INFO, "SYSTEM: Decompress data: Comp. size: %i -> Original size: %i", compDataLength, *dataLength);
    }

    return data;
}

/// Encode data to Base64 string
char *EncodeDataBase64(const ubyte *data, int dataLength, int *outputLength)
{
    static const ubyte[] base64encodeTable = [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
        'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
        'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
    ];

    static const int[] modTable = [ 0, 2, 1 ];

    *outputLength = 4*((dataLength + 2)/3);

    char *encodedData = cast(char *)RL_MALLOC(*outputLength);

    if (encodedData == null) return null;

    for (int i = 0, j = 0; i < dataLength;)
    {
        uint octetA = (i < dataLength)? data[i++] : 0;
        uint octetB = (i < dataLength)? data[i++] : 0;
        uint octetC = (i < dataLength)? data[i++] : 0;

        uint triple = (octetA << 0x10) + (octetB << 0x08) + octetC;

        encodedData[j++] = base64encodeTable[(triple >> 3*6) & 0x3F];
        encodedData[j++] = base64encodeTable[(triple >> 2*6) & 0x3F];
        encodedData[j++] = base64encodeTable[(triple >> 1*6) & 0x3F];
        encodedData[j++] = base64encodeTable[(triple >> 0*6) & 0x3F];
    }

    for (int i = 0; i < modTable[dataLength%3]; i++) encodedData[*outputLength - 1 - i] = '=';

    return encodedData;
}

/// Decode Base64 string data
ubyte *DecodeDataBase64(ubyte *data, int *outputLength)
{
    static const ubyte[] base64decodeTable = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 62, 0, 0, 0, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 0, 0, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36,
        37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
    ];

    // Get output size of Base64 input data
    int outLength = 0;
    for (int i = 0; data[4*i] != 0; i++)
    {
        if (data[4*i + 3] == '=')
        {
            if (data[4*i + 2] == '=') outLength += 1;
            else outLength += 2;
        }
        else outLength += 3;
    }

    // Allocate memory to store decoded Base64 data
    ubyte *decodedData = cast(ubyte *)RL_MALLOC(outLength);

    for (int i = 0; i < outLength/3; i++)
    {
        ubyte a = base64decodeTable[data[4*i]];
        ubyte b = base64decodeTable[data[4*i + 1]];
        ubyte c = base64decodeTable[data[4*i + 2]];
        ubyte d = base64decodeTable[data[4*i + 3]];

        decodedData[3*i] = cast(ubyte)((a << 2) | (b >> 4));
        decodedData[3*i + 1] = cast(ubyte)((b << 4) | (c >> 2));
        decodedData[3*i + 2] = cast(ubyte)((c << 6) | d);
    }

    if (outLength%3 == 1)
    {
        int n = outLength/3;
        ubyte a = base64decodeTable[data[4*n]];
        ubyte b = base64decodeTable[data[4*n + 1]];
        decodedData[outLength - 1] = cast(ubyte)((a << 2) | (b >> 4));
    }
    else if (outLength%3 == 2)
    {
        int n = outLength/3;
        ubyte a = base64decodeTable[data[4*n]];
        ubyte b = base64decodeTable[data[4*n + 1]];
        ubyte c = base64decodeTable[data[4*n + 2]];
        decodedData[outLength - 2] = cast(ubyte)((a << 2) | (b >> 4));
        decodedData[outLength - 1] = cast(ubyte)((b << 4) | (c >> 2));
    }

    *outputLength = outLength;
    return decodedData;
}

/// Save integer value to storage file (to defined position)
/// NOTE: Storage positions is directly related to file memory layout (4 bytes each integer)
bool SaveStorageValue(uint position, int value)
{
    bool success = false;

    version(all) { // #if defined(SUPPORT_DATA_STORAGE)
        char[512] path = 0;
        strcpy(path.ptr, TextFormat("%s/%s", CORE.Storage.basePath, STORAGE_DATA_FILE.ptr));

        uint dataSize = 0;
        uint newDataSize = 0;
        ubyte *fileData = LoadFileData(path.ptr, &dataSize);
        ubyte *newFileData = null;

        if (fileData != null)
        {
            if (dataSize <= (position*int.sizeof))
            {
                // Increase data size up to position and store value
                newDataSize = (position + 1)*int(int.sizeof);
                newFileData = cast(ubyte *)RL_REALLOC(fileData, newDataSize);

                if (newFileData != null)
                {
                    // RL_REALLOC succeded
                    int *dataPtr = cast(int *)newFileData;
                    dataPtr[position] = value;
                }
                else
                {
                    // RL_REALLOC failed
                    TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to realloc data (%u), position in bytes (%u) bigger than actual file size", path.ptr, dataSize, position*int(int.sizeof));

                    // We store the old size of the file
                    newFileData = fileData;
                    newDataSize = dataSize;
                }
            }
            else
            {
                // Store the old size of the file
                newFileData = fileData;
                newDataSize = dataSize;

                // Replace value on selected position
                int *dataPtr = cast(int *)newFileData;
                dataPtr[position] = value;
            }

            success = SaveFileData(path.ptr, newFileData, newDataSize);
            RL_FREE(newFileData);

            TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] Saved storage value: %i", path.ptr, value);
        }
        else
        {
            TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] File created successfully", path.ptr);

            dataSize = (position + 1)*int(int.sizeof);
            fileData = cast(ubyte *)RL_MALLOC(dataSize);
            int *dataPtr = cast(int *)fileData;
            dataPtr[position] = value;

            success = SaveFileData(path.ptr, fileData, dataSize);
            UnloadFileData(fileData);

            TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] Saved storage value: %i", path.ptr, value);
        }
    }

    return success;
}

/// Load integer value from storage file (from defined position)
/// NOTE: If requested position could not be found, value 0 is returned
int LoadStorageValue(uint position)
{
    int value = 0;

    version(all) { // #if defined(SUPPORT_DATA_STORAGE)
        char[512] path = 0;
        strcpy(path.ptr, TextFormat("%s/%s", CORE.Storage.basePath, STORAGE_DATA_FILE.ptr));

        uint dataSize = 0;
        ubyte *fileData = LoadFileData(path.ptr, &dataSize);

        if (fileData != null)
        {
            if (dataSize < (position*4)) TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to find storage position: %i", path.ptr, position);
            else
            {
                int *dataPtr = cast(int *)fileData;
                value = dataPtr[position];
            }

            UnloadFileData(fileData);

            TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] Loaded storage value: %i", path.ptr, value);
        }
    }
    return value;
}

/// Open URL with default system browser (if available)
/// NOTE: This function is only safe to use if you control the URL given.
/// A user could craft a malicious string performing another action.
/// Only call this function yourself not with user input or make sure to check the string yourself.
/// Ref: https://github.com/raysan5/raylib/issues/686
void OpenURL(const char *url)
{
    // Small security check trying to avoid (partially) malicious code...
    // sorry for the inconvenience when you hit this point...
    if (strchr(url, '\'') != null)
    {
        TraceLog(TraceLogLevel.LOG_WARNING, "SYSTEM: Provided URL is not valid");
    }
    else
    {
        version(all) { // #if defined(PLATFORM_DESKTOP)
            char *cmd = cast(char *)RL_CALLOC(strlen(url) + 10, char.sizeof);
            version(Windows) {
                sprintf(cmd, "explorer %s", url);
            }
            version(linux) {
                sprintf(cmd, "xdg-open '%s'", url); // Alternatives: firefox, x-www-browser
            }
            version(FreeBSD) {
                sprintf(cmd, "xdg-open '%s'", url); // Alternatives: firefox, x-www-browser
            }
            version(OSX) {
                sprintf(cmd, "open '%s'", url);
            }
            system(cmd);
            RL_FREE(cmd);
        }
        version(none) { // #if defined(PLATFORM_WEB)
            emscripten_run_script(TextFormat("window.open('%s', '_blank')", url));
        }
    }
}

//----------------------------------------------------------------------------------
// Module Functions Definition - Input (Keyboard, Mouse, Gamepad) Functions
//----------------------------------------------------------------------------------
/// Check if a key has been pressed once
bool IsKeyPressed(int key)
{
    bool pressed = false;

    if ((CORE.Input.Keyboard.previousKeyState[key] == 0) && (CORE.Input.Keyboard.currentKeyState[key] == 1)) pressed = true;

    return pressed;
}

/// Check if a key is being pressed (key held down)
bool IsKeyDown(int key)
{
    if (CORE.Input.Keyboard.currentKeyState[key] == 1) return true;
    else return false;
}

/// Check if a key has been released once
bool IsKeyReleased(int key)
{
    bool released = false;

    if ((CORE.Input.Keyboard.previousKeyState[key] == 1) && (CORE.Input.Keyboard.currentKeyState[key] == 0)) released = true;

    return released;
}

/// Check if a key is NOT being pressed (key not held down)
bool IsKeyUp(int key)
{
    if (CORE.Input.Keyboard.currentKeyState[key] == 0) return true;
    else return false;
}

/// Get the last key pressed
int GetKeyPressed()
{
    int value = 0;

    if (CORE.Input.Keyboard.keyPressedQueueCount > 0)
    {
        // Get character from the queue head
        value = CORE.Input.Keyboard.keyPressedQueue[0];

        // Shift elements 1 step toward the head.
        for (int i = 0; i < (CORE.Input.Keyboard.keyPressedQueueCount - 1); i++)
            CORE.Input.Keyboard.keyPressedQueue[i] = CORE.Input.Keyboard.keyPressedQueue[i + 1];

        // Reset last character in the queue
        CORE.Input.Keyboard.keyPressedQueue[CORE.Input.Keyboard.keyPressedQueueCount] = 0;
        CORE.Input.Keyboard.keyPressedQueueCount--;
    }

    return value;
}

/// Get the last char pressed
int GetCharPressed()
{
    int value = 0;

    if (CORE.Input.Keyboard.charPressedQueueCount > 0)
    {
        // Get character from the queue head
        value = CORE.Input.Keyboard.charPressedQueue[0];

        // Shift elements 1 step toward the head.
        for (int i = 0; i < (CORE.Input.Keyboard.charPressedQueueCount - 1); i++)
            CORE.Input.Keyboard.charPressedQueue[i] = CORE.Input.Keyboard.charPressedQueue[i + 1];

        // Reset last character in the queue
        CORE.Input.Keyboard.charPressedQueue[CORE.Input.Keyboard.charPressedQueueCount] = 0;
        CORE.Input.Keyboard.charPressedQueueCount--;
    }

    return value;
}

/// Set a custom key to exit program
/// NOTE: default exitKey is ESCAPE
void SetExitKey(int key)
{
    version(all) { // #if !defined(PLATFORM_ANDROID)
        CORE.Input.Keyboard.exitKey = key;
    }
}

// NOTE: Gamepad support not implemented in emscripten GLFW3 (PLATFORM_WEB)

/// Check if a gamepad is available
bool IsGamepadAvailable(int gamepad)
{
    bool result = false;

    if ((gamepad < MAX_GAMEPADS) && CORE.Input.Gamepad.ready[gamepad]) result = true;

    return result;
}

/// Get gamepad internal name id
const(char)* GetGamepadName(int gamepad)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        if (CORE.Input.Gamepad.ready[gamepad]) return glfwGetJoystickName(gamepad);
        else return null;
    }
    else version(none) { // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        if (CORE.Input.Gamepad.ready[gamepad]) ioctl(CORE.Input.Gamepad.streamId[gamepad], JSIOCGNAME(64), &CORE.Input.Gamepad.name[gamepad]);
        return CORE.Input.Gamepad.name[gamepad];
    }
    else version(none) { // #if defined(PLATFORM_WEB)
        return CORE.Input.Gamepad.name[gamepad];
    }
    else return null;
}

/// Get gamepad axis count
int GetGamepadAxisCount(int gamepad)
{
    version(none) { // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        int axisCount = 0;
        if (CORE.Input.Gamepad.ready[gamepad]) ioctl(CORE.Input.Gamepad.streamId[gamepad], JSIOCGAXES, &axisCount);
        CORE.Input.Gamepad.axisCount = axisCount;
    }

    return CORE.Input.Gamepad.axisCount;
}

/// Get axis movement vector for a gamepad
float GetGamepadAxisMovement(int gamepad, int axis)
{
    float value = 0;

    if ((gamepad < MAX_GAMEPADS) && CORE.Input.Gamepad.ready[gamepad] && (axis < MAX_GAMEPAD_AXIS) &&
        (fabsf(CORE.Input.Gamepad.axisState[gamepad][axis]) > 0.1f)) value = CORE.Input.Gamepad.axisState[gamepad][axis];      // 0.1f = GAMEPAD_AXIS_MINIMUM_DRIFT/DELTA

    return value;
}

/// Check if a gamepad button has been pressed once
bool IsGamepadButtonPressed(int gamepad, int button)
{
    bool pressed = false;

    if ((gamepad < MAX_GAMEPADS) && CORE.Input.Gamepad.ready[gamepad] && (button < MAX_GAMEPAD_BUTTONS) &&
        (CORE.Input.Gamepad.previousButtonState[gamepad][button] == 0) && (CORE.Input.Gamepad.currentButtonState[gamepad][button] == 1)) pressed = true;

    return pressed;
}

/// Check if a gamepad button is being pressed
bool IsGamepadButtonDown(int gamepad, int button)
{
    bool result = false;

    if ((gamepad < MAX_GAMEPADS) && CORE.Input.Gamepad.ready[gamepad] && (button < MAX_GAMEPAD_BUTTONS) &&
        (CORE.Input.Gamepad.currentButtonState[gamepad][button] == 1)) result = true;

    return result;
}

/// Check if a gamepad button has NOT been pressed once
bool IsGamepadButtonReleased(int gamepad, int button)
{
    bool released = false;

    if ((gamepad < MAX_GAMEPADS) && CORE.Input.Gamepad.ready[gamepad] && (button < MAX_GAMEPAD_BUTTONS) &&
        (CORE.Input.Gamepad.previousButtonState[gamepad][button] == 1) && (CORE.Input.Gamepad.currentButtonState[gamepad][button] == 0)) released = true;

    return released;
}

/// Check if a gamepad button is NOT being pressed
bool IsGamepadButtonUp(int gamepad, int button)
{
    bool result = false;

    if ((gamepad < MAX_GAMEPADS) && CORE.Input.Gamepad.ready[gamepad] && (button < MAX_GAMEPAD_BUTTONS) &&
        (CORE.Input.Gamepad.currentButtonState[gamepad][button] == 0)) result = true;

    return result;
}

/// Get the last gamepad button pressed
int GetGamepadButtonPressed()
{
    return CORE.Input.Gamepad.lastButtonPressed;
}

/// Set internal gamepad mappings
int SetGamepadMappings(const char *mappings)
{
    int result = 0;

    version(all) { // #if defined(PLATFORM_DESKTOP)
        result = glfwUpdateGamepadMappings(mappings);
    }

    return result;
}

/// Check if a mouse button has been pressed once
bool IsMouseButtonPressed(int button)
{
    bool pressed = false;

    if ((CORE.Input.Mouse.currentButtonState[button] == 1) && (CORE.Input.Mouse.previousButtonState[button] == 0)) pressed = true;

    // Map touches to mouse buttons checking
    if ((CORE.Input.Touch.currentTouchState[button] == 1) && (CORE.Input.Touch.previousTouchState[button] == 0)) pressed = true;

    return pressed;
}

/// Check if a mouse button is being pressed
bool IsMouseButtonDown(int button)
{
    bool down = false;

    if (CORE.Input.Mouse.currentButtonState[button] == 1) down = true;

    // Map touches to mouse buttons checking
    if (CORE.Input.Touch.currentTouchState[button] == 1) down = true;

    return down;
}

/// Check if a mouse button has been released once
bool IsMouseButtonReleased(int button)
{
    bool released = false;

    if ((CORE.Input.Mouse.currentButtonState[button] == 0) && (CORE.Input.Mouse.previousButtonState[button] == 1)) released = true;

    // Map touches to mouse buttons checking
    if ((CORE.Input.Touch.currentTouchState[button] == 0) && (CORE.Input.Touch.previousTouchState[button] == 1)) released = true;

    return released;
}

/// Check if a mouse button is NOT being pressed
bool IsMouseButtonUp(int button)
{
    return !IsMouseButtonDown(button);
}

/// Get mouse position X
int GetMouseX()
{
    version(none) { // #if defined(PLATFORM_ANDROID)
        return cast(int)CORE.Input.Touch.position[0].x;
    } else {
        return cast(int)((CORE.Input.Mouse.currentPosition.x + CORE.Input.Mouse.offset.x)*CORE.Input.Mouse.scale.x);
    }
}

/// Get mouse position Y
int GetMouseY()
{
    version(none) { // #if defined(PLATFORM_ANDROID)
        return cast(int)CORE.Input.Touch.position[0].y;
    } else {
        return cast(int)((CORE.Input.Mouse.currentPosition.y + CORE.Input.Mouse.offset.y)*CORE.Input.Mouse.scale.y);
    }
}

/// Get mouse position XY
Vector2 GetMousePosition()
{
    Vector2 position;

    version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_WEB)
        position = GetTouchPosition(0);
    } else {
        position.x = (CORE.Input.Mouse.currentPosition.x + CORE.Input.Mouse.offset.x)*CORE.Input.Mouse.scale.x;
        position.y = (CORE.Input.Mouse.currentPosition.y + CORE.Input.Mouse.offset.y)*CORE.Input.Mouse.scale.y;
    }

    return position;
}

/// Get mouse delta between frames
Vector2 GetMouseDelta()
{
    Vector2 delta;

    delta.x = CORE.Input.Mouse.currentPosition.x - CORE.Input.Mouse.previousPosition.x;
    delta.y = CORE.Input.Mouse.currentPosition.y - CORE.Input.Mouse.previousPosition.y;

    return delta;
}

/// Set mouse position XY
void SetMousePosition(int x, int y)
{
    CORE.Input.Mouse.currentPosition = Vector2(x, y);
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
                   // NOTE: emscripten not implemented
        glfwSetCursorPos(CORE.Window.handle, CORE.Input.Mouse.currentPosition.x, CORE.Input.Mouse.currentPosition.y);
    }
}

/// Set mouse offset
/// NOTE: Useful when rendering to different size targets
void SetMouseOffset(int offsetX, int offsetY)
{
    CORE.Input.Mouse.offset = Vector2(offsetX, offsetY);
}

/// Set mouse scaling
/// NOTE: Useful when rendering to different size targets
void SetMouseScale(float scaleX, float scaleY)
{
    CORE.Input.Mouse.scale = Vector2(scaleX, scaleY);
}

/// Get mouse wheel movement Y
float GetMouseWheelMove()
{
    version(none) { // #if defined(PLATFORM_ANDROID)
        return 0.0f;
    } else version(none) { // #if defined(PLATFORM_WEB)
        return CORE.Input.Mouse.previousWheelMove/100.0f;
    } else {
        return CORE.Input.Mouse.previousWheelMove;
    }
}

/// Set mouse cursor
/// NOTE: This is a no-op on platforms other than PLATFORM_DESKTOP
void SetMouseCursor(int cursor)
{
    version(all) { // #if defined(PLATFORM_DESKTOP)
        CORE.Input.Mouse.cursor = cursor;
        if (cursor == MouseCursor.MOUSE_CURSOR_DEFAULT) glfwSetCursor(CORE.Window.handle, null);
        else
        {
            // NOTE: We are relating internal GLFW enum values to our MouseCursor enum values
            glfwSetCursor(CORE.Window.handle, glfwCreateStandardCursor(0x00036000 + cursor));
        }
    }
}

/// Get touch position X for touch point 0 (relative to screen size)
int GetTouchX()
{
    version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_WEB)
        return cast(int)CORE.Input.Touch.position[0].x;
    } else {   // PLATFORM_DESKTOP, PLATFORM_RPI, PLATFORM_DRM
        return GetMouseX();
    }
}

/// Get touch position Y for touch point 0 (relative to screen size)
int GetTouchY()
{
    version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_WEB)
        return cast(int)CORE.Input.Touch.position[0].y;
    } else { // PLATFORM_DESKTOP, PLATFORM_RPI, PLATFORM_DRM
        return GetMouseY();
    }
}

/// Get touch position XY for a touch point index (relative to screen size)
/// TODO: Touch position should be scaled depending on display size and render size
Vector2 GetTouchPosition(int index)
{
    Vector2 position = Vector2(-1.0f, -1.0f);

    version(all) { // #if defined(PLATFORM_DESKTOP)
        // TODO: GLFW does not support multi-touch input just yet
        // https://www.codeproject.com/Articles/668404/Programming-for-Multi-Touch
        // https://docs.microsoft.com/en-us/windows/win32/wintouch/getting-started-with-multi-touch-messages
        if (index == 0) position = GetMousePosition();
    }
    version(none) { // #if defined(PLATFORM_ANDROID)
        if (index < MAX_TOUCH_POINTS) position = CORE.Input.Touch.position[index];
        else TraceLog(TraceLogLevel.LOG_WARNING, "INPUT: Required touch point out of range (Max touch points: %i)", MAX_TOUCH_POINTS);

        if ((CORE.Window.screen.width > CORE.Window.display.width) || (CORE.Window.screen.height > CORE.Window.display.height))
        {
            position.x = position.x*(cast(float)CORE.Window.screen.width/cast(float)(CORE.Window.display.width - CORE.Window.renderOffset.x)) - CORE.Window.renderOffset.x/2;
            position.y = position.y*(cast(float)CORE.Window.screen.height/cast(float)(CORE.Window.display.height - CORE.Window.renderOffset.y)) - CORE.Window.renderOffset.y/2;
        }
        else
        {
            position.x = position.x*(cast(float)CORE.Window.render.width/cast(float)CORE.Window.display.width) - CORE.Window.renderOffset.x/2;
            position.y = position.y*(cast(float)CORE.Window.render.height/cast(float)CORE.Window.display.height) - CORE.Window.renderOffset.y/2;
        }
    }
    version(none) { // #if defined(PLATFORM_WEB) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        if (index < MAX_TOUCH_POINTS) position = CORE.Input.Touch.position[index];
        else TraceLog(TraceLogLevel.LOG_WARNING, "INPUT: Required touch point out of range (Max touch points: %i)", MAX_TOUCH_POINTS);
    }

    return position;
}

/// Get touch point identifier for given index
int GetTouchPointId(int index)
{
    int id = -1;

    if (index < MAX_TOUCH_POINTS) id = CORE.Input.Touch.pointId[index];

    return id;
}

/// Get number of touch points
int GetTouchPointCount()
{
    return CORE.Input.Touch.pointCount;
}

/// Wait for some milliseconds (stop program execution)
/// NOTE: Sleep() granularity could be around 10 ms, it means, Sleep() could
/// take longer than expected... for that reason we use the busy wait loop
/// Ref: http://stackoverflow.com/questions/43057578/c-programming-win32-games-sleep-taking-longer-than-expected
/// Ref: http://www.geisswerks.com/ryan/FAQS/timing.html --> All about timming on Win32!
void WaitTime(float ms)
{
    version(none) { // #if defined(SUPPORT_BUSY_WAIT_LOOP)
        double previousTime = GetTime();
        double currentTime = 0.0;

        // Busy wait loop
        while ((currentTime - previousTime) < ms/1000.0f) currentTime = GetTime();
    } else {
        version(all) { //  #if defined(SUPPORT_PARTIALBUSY_WAIT_LOOP)
            double busyWait = ms*0.05;     // NOTE: We are using a busy wait of 5% of the time
            ms -= busyWait;
        }

        // System halt functions
        version(Windows){
            Sleep(cast(uint)ms);
        } else version(OSX) {
            usleep(cast(int)(ms*1000.0f));
        } else version(Posix) { // #if defined(__linux__) || defined(__FreeBSD__) || defined(__EMSCRIPTEN__)
            timespec req;
            time_t sec = cast(int)(ms/1000.0f);
            ms -= (sec*1000);
            req.tv_sec = sec;
            req.tv_nsec = cast(int)(ms*1000000L);

            // NOTE: Use nanosleep() on Unix platforms... usleep() it's deprecated.
            while (nanosleep(&req, &req) == -1) continue;
        }

        version(all) { // #if defined(SUPPORT_PARTIALBUSY_WAIT_LOOP)
            double previousTime = GetTime();
            double currentTime = 0.0;

            // Partial busy wait loop (only a fraction of the total wait time)
            while ((currentTime - previousTime) < busyWait/1000.0f) currentTime = GetTime();
        }
    }
}

/// Swap back buffer with front buffer (screen drawing)
void SwapScreenBuffer()
{
    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        glfwSwapBuffers(CORE.Window.handle);
    }

    version(none) { // #if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
        eglSwapBuffers(CORE.Window.device, CORE.Window.surface);

        version(none) { // #if defined(PLATFORM_DRM)
            if (!CORE.Window.gbmSurface || (-1 == CORE.Window.fd) || !CORE.Window.connector || !CORE.Window.crtc)
            {
                TraceLog(TraceLogLevel.TraceLogLevel.LOG_ERROR, "DISPLAY: DRM initialization failed to swap");
                abort();
            }

            gbm_bo *bo = gbm_surface_lock_front_buffer(CORE.Window.gbmSurface);
            if (!bo)
            {
                TraceLog(TraceLogLevel.LOG_ERROR, "DISPLAY: Failed GBM to lock front buffer");
                abort();
            }

            uint fb = 0;
            int result = drmModeAddFB(CORE.Window.fd, CORE.Window.connector.modes[CORE.Window.modeIndex].hdisplay,
                                      CORE.Window.connector.modes[CORE.Window.modeIndex].vdisplay, 24, 32, gbm_bo_get_stride(bo), gbm_bo_get_handle(bo).u32, &fb);
            if (0 != result)
            {
                TraceLog(TraceLogLevel.LOG_ERROR, "DISPLAY: drmModeAddFB() failed with result: %d", result);
                abort();
            }

            result = drmModeSetCrtc(CORE.Window.fd, CORE.Window.crtc.crtc_id, fb, 0, 0,
                                    &CORE.Window.connector.connector_id, 1, &CORE.Window.connector.modes[CORE.Window.modeIndex]);
            if (0 != result)
            {
                TraceLog(TraceLogLevel.LOG_ERROR, "DISPLAY: drmModeSetCrtc() failed with result: %d", result);
                abort();
            }

            if (CORE.Window.prevFB)
            {
                result = drmModeRmFB(CORE.Window.fd, CORE.Window.prevFB);
                if (0 != result)
                {
                    TraceLog(TraceLogLevel.LOG_ERROR, "DISPLAY: drmModeRmFB() failed with result: %d", result);
                    abort();
                }
            }
            CORE.Window.prevFB = fb;

            if (CORE.Window.prevBO)
            {
                gbm_surface_release_buffer(CORE.Window.gbmSurface, CORE.Window.prevBO);
            }

            CORE.Window.prevBO = bo;
        } // PLATFORM_DRM
    } // PLATFORM_ANDROID || PLATFORM_RPI || PLATFORM_DRM
}

/// Register all input events
void PollInputEvents()
{
    version(all) { // #if defined(SUPPORT_GESTURES_SYSTEM)
        // NOTE: Gestures update must be called every frame to reset gestures correctly
        // because ProcessGestureEvent() is just called on an event, not every frame
        UpdateGestures();
    }

    // Reset keys/chars pressed registered
    CORE.Input.Keyboard.keyPressedQueueCount = 0;
    CORE.Input.Keyboard.charPressedQueueCount = 0;

    version(all) { // #if !(defined(PLATFORM_RPI) || defined(PLATFORM_DRM))
                    // Reset last gamepad button/axis registered state
        CORE.Input.Gamepad.lastButtonPressed = -1;
        CORE.Input.Gamepad.axisCount = 0;
    }

    version(none) { // #if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
                    // Register previous keys states
        for (int i = 0; i < MAX_KEYBOARD_KEYS; i++) CORE.Input.Keyboard.previousKeyState[i] = CORE.Input.Keyboard.currentKeyState[i];

        PollKeyboardEvents();

        // Register previous mouse states
        CORE.Input.Mouse.previousWheelMove = CORE.Input.Mouse.currentWheelMove;
        CORE.Input.Mouse.currentWheelMove = 0.0f;
        for (int i = 0; i < MAX_MOUSE_BUTTONS; i++)
        {
            CORE.Input.Mouse.previousButtonState[i] = CORE.Input.Mouse.currentButtonState[i];
            CORE.Input.Mouse.currentButtonState[i] = CORE.Input.Mouse.currentButtonStateEvdev[i];
        }

        // Register gamepads buttons events
        for (int i = 0; i < MAX_GAMEPADS; i++)
        {
            if (CORE.Input.Gamepad.ready[i])
            {
                // Register previous gamepad states
                for (int k = 0; k < MAX_GAMEPAD_BUTTONS; k++) CORE.Input.Gamepad.previousButtonState[i][k] = CORE.Input.Gamepad.currentButtonState[i][k];
            }
        }
    }

    version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
        // Keyboard/Mouse input polling (automatically managed by GLFW3 through callback)

        // Register previous keys states
        for (int i = 0; i < MAX_KEYBOARD_KEYS; i++) CORE.Input.Keyboard.previousKeyState[i] = CORE.Input.Keyboard.currentKeyState[i];

        // Register previous mouse states
        for (int i = 0; i < MAX_MOUSE_BUTTONS; i++) CORE.Input.Mouse.previousButtonState[i] = CORE.Input.Mouse.currentButtonState[i];

        // Register previous mouse wheel state
        CORE.Input.Mouse.previousWheelMove = CORE.Input.Mouse.currentWheelMove;
        CORE.Input.Mouse.currentWheelMove = 0.0f;

        // Register previous mouse position
        CORE.Input.Mouse.previousPosition = CORE.Input.Mouse.currentPosition;
    }

    // Register previous touch states
    for (int i = 0; i < MAX_TOUCH_POINTS; i++) CORE.Input.Touch.previousTouchState[i] = CORE.Input.Touch.currentTouchState[i];
    
    // Reset touch positions
    // TODO: It resets on PLATFORM_WEB the mouse position and not filled again until a move-event,
    // so, if mouse is not moved it returns a (0, 0) position... this behaviour should be reviewed!
    //for (int i = 0; i < MAX_TOUCH_POINTS; i++) CORE.Input.Touch.position[i] = (Vector2){ 0, 0 };

    version(all) { // #if defined(PLATFORM_DESKTOP)
        // Check if gamepads are ready
        // NOTE: We do it here in case of disconnection
        for (int i = 0; i < MAX_GAMEPADS; i++)
        {
            if (glfwJoystickPresent(i)) CORE.Input.Gamepad.ready[i] = true;
            else CORE.Input.Gamepad.ready[i] = false;
        }

        // Register gamepads buttons events
        for (int i = 0; i < MAX_GAMEPADS; i++)
        {
            if (CORE.Input.Gamepad.ready[i])     // Check if gamepad is available
            {
                // Register previous gamepad states
                for (int k = 0; k < MAX_GAMEPAD_BUTTONS; k++) CORE.Input.Gamepad.previousButtonState[i][k] = CORE.Input.Gamepad.currentButtonState[i][k];

                // Get current gamepad state
                // NOTE: There is no callback available, so we get it manually
                // Get remapped buttons
                GLFWgamepadstate state = { 0 };
                glfwGetGamepadState(i, &state); // This remapps all gamepads so they have their buttons mapped like an xbox controller

                const ubyte *buttons = state.buttons.ptr;

                for (int k = 0; (buttons != null) && (k < GLFW_GAMEPAD_BUTTON_DPAD_LEFT + 1) && (k < MAX_GAMEPAD_BUTTONS); k++)
                {
                    GamepadButton button = cast(GamepadButton)-1;

                    with(GamepadButton) switch (k)
                    {
                    case GLFW_GAMEPAD_BUTTON_Y: button = GAMEPAD_BUTTON_RIGHT_FACE_UP; break;
                    case GLFW_GAMEPAD_BUTTON_B: button = GAMEPAD_BUTTON_RIGHT_FACE_RIGHT; break;
                    case GLFW_GAMEPAD_BUTTON_A: button = GAMEPAD_BUTTON_RIGHT_FACE_DOWN; break;
                    case GLFW_GAMEPAD_BUTTON_X: button = GAMEPAD_BUTTON_RIGHT_FACE_LEFT; break;

                    case GLFW_GAMEPAD_BUTTON_LEFT_BUMPER: button = GAMEPAD_BUTTON_LEFT_TRIGGER_1; break;
                    case GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER: button = GAMEPAD_BUTTON_RIGHT_TRIGGER_1; break;

                    case GLFW_GAMEPAD_BUTTON_BACK: button = GAMEPAD_BUTTON_MIDDLE_LEFT; break;
                    case GLFW_GAMEPAD_BUTTON_GUIDE: button = GAMEPAD_BUTTON_MIDDLE; break;
                    case GLFW_GAMEPAD_BUTTON_START: button = GAMEPAD_BUTTON_MIDDLE_RIGHT; break;

                    case GLFW_GAMEPAD_BUTTON_DPAD_UP: button = GAMEPAD_BUTTON_LEFT_FACE_UP; break;
                    case GLFW_GAMEPAD_BUTTON_DPAD_RIGHT: button = GAMEPAD_BUTTON_LEFT_FACE_RIGHT; break;
                    case GLFW_GAMEPAD_BUTTON_DPAD_DOWN: button = GAMEPAD_BUTTON_LEFT_FACE_DOWN; break;
                    case GLFW_GAMEPAD_BUTTON_DPAD_LEFT: button = GAMEPAD_BUTTON_LEFT_FACE_LEFT; break;

                    case GLFW_GAMEPAD_BUTTON_LEFT_THUMB: button = GAMEPAD_BUTTON_LEFT_THUMB; break;
                    case GLFW_GAMEPAD_BUTTON_RIGHT_THUMB: button = GAMEPAD_BUTTON_RIGHT_THUMB; break;
                    default: break;
                    }

                    if (button != -1)   // Check for valid button
                    {
                        if (buttons[k] == GLFW_PRESS)
                        {
                            CORE.Input.Gamepad.currentButtonState[i][button] = 1;
                            CORE.Input.Gamepad.lastButtonPressed = button;
                        }
                        else CORE.Input.Gamepad.currentButtonState[i][button] = 0;
                    }
                }

                // Get current axis state
                const float *axes = state.axes.ptr;

                for (int k = 0; (axes != null) && (k < GLFW_GAMEPAD_AXIS_LAST + 1) && (k < MAX_GAMEPAD_AXIS); k++)
                {
                    CORE.Input.Gamepad.axisState[i][k] = axes[k];
                }

                // Register buttons for 2nd triggers (because GLFW doesn't count these as buttons but rather axis)
                CORE.Input.Gamepad.currentButtonState[i][GamepadButton.GAMEPAD_BUTTON_LEFT_TRIGGER_2] = cast(char)(CORE.Input.Gamepad.axisState[i][GamepadAxis.GAMEPAD_AXIS_LEFT_TRIGGER] > 0.1);
                CORE.Input.Gamepad.currentButtonState[i][GamepadButton.GAMEPAD_BUTTON_RIGHT_TRIGGER_2] = cast(char)(CORE.Input.Gamepad.axisState[i][GamepadAxis.GAMEPAD_AXIS_RIGHT_TRIGGER] > 0.1);

                CORE.Input.Gamepad.axisCount = GLFW_GAMEPAD_AXIS_LAST + 1;
            }
        }

        CORE.Window.resizedLastFrame = false;

        version(none) { // #if defined(SUPPORT_EVENTS_WAITING)
            glfwWaitEvents();
        } else {
            glfwPollEvents();       // Register keyboard/mouse events (callbacks)... and window events!
        }
    }  // PLATFORM_DESKTOP

    version(none) { // #if defined(PLATFORM_WEB)
        CORE.Window.resizedLastFrame = false;
    }  // PLATFORM_WEB

    // Gamepad support using emscripten API
    // NOTE: GLFW3 joystick functionality not available in web
    version(none) { // #if defined(PLATFORM_WEB)
        // Get number of gamepads connected
        int numGamepads = 0;
        if (emscripten_sample_gamepad_data() == EMSCRIPTEN_RESULT_SUCCESS) numGamepads = emscripten_get_num_gamepads();

        for (int i = 0; (i < numGamepads) && (i < MAX_GAMEPADS); i++)
        {
            // Register previous gamepad button states
            for (int k = 0; k < MAX_GAMEPAD_BUTTONS; k++) CORE.Input.Gamepad.previousButtonState[i][k] = CORE.Input.Gamepad.currentButtonState[i][k];

            EmscriptenGamepadEvent gamepadState;

            int result = emscripten_get_gamepad_status(i, &gamepadState);

            if (result == EMSCRIPTEN_RESULT_SUCCESS)
            {
                // Register buttons data for every connected gamepad
                for (int j = 0; (j < gamepadState.numButtons) && (j < MAX_GAMEPAD_BUTTONS); j++)
                {
                    GamepadButton button = -1;

                    // Gamepad Buttons reference: https://www.w3.org/TR/gamepad/#gamepad-interface
                    with(GamepadButton) switch (j)
                    {
                    case 0: button = GAMEPAD_BUTTON_RIGHT_FACE_DOWN; break;
                    case 1: button = GAMEPAD_BUTTON_RIGHT_FACE_RIGHT; break;
                    case 2: button = GAMEPAD_BUTTON_RIGHT_FACE_LEFT; break;
                    case 3: button = GAMEPAD_BUTTON_RIGHT_FACE_UP; break;
                    case 4: button = GAMEPAD_BUTTON_LEFT_TRIGGER_1; break;
                    case 5: button = GAMEPAD_BUTTON_RIGHT_TRIGGER_1; break;
                    case 6: button = GAMEPAD_BUTTON_LEFT_TRIGGER_2; break;
                    case 7: button = GAMEPAD_BUTTON_RIGHT_TRIGGER_2; break;
                    case 8: button = GAMEPAD_BUTTON_MIDDLE_LEFT; break;
                    case 9: button = GAMEPAD_BUTTON_MIDDLE_RIGHT; break;
                    case 10: button = GAMEPAD_BUTTON_LEFT_THUMB; break;
                    case 11: button = GAMEPAD_BUTTON_RIGHT_THUMB; break;
                    case 12: button = GAMEPAD_BUTTON_LEFT_FACE_UP; break;
                    case 13: button = GAMEPAD_BUTTON_LEFT_FACE_DOWN; break;
                    case 14: button = GAMEPAD_BUTTON_LEFT_FACE_LEFT; break;
                    case 15: button = GAMEPAD_BUTTON_LEFT_FACE_RIGHT; break;
                    default: break;
                    }

                    if (button != -1)   // Check for valid button
                    {
                        if (gamepadState.digitalButton[j] == 1)
                        {
                            CORE.Input.Gamepad.currentButtonState[i][button] = 1;
                            CORE.Input.Gamepad.lastButtonPressed = button;
                        }
                        else CORE.Input.Gamepad.currentButtonState[i][button] = 0;
                    }

                    //TRACELOGD("INPUT: Gamepad %d, button %d: Digital: %d, Analog: %g", gamepadState.index, j, gamepadState.digitalButton[j], gamepadState.analogButton[j]);
                }

                // Register axis data for every connected gamepad
                for (int j = 0; (j < gamepadState.numAxes) && (j < MAX_GAMEPAD_AXIS); j++)
                {
                    CORE.Input.Gamepad.axisState[i][j] = gamepadState.axis[j];
                }

                CORE.Input.Gamepad.axisCount = gamepadState.numAxes;
            }
        }
    }

    version(none) { // #if defined(PLATFORM_ANDROID)
        // Register previous keys states
        // NOTE: Android supports up to 260 keys
        for (int i = 0; i < 260; i++) CORE.Input.Keyboard.previousKeyState[i] = CORE.Input.Keyboard.currentKeyState[i];

        // Android ALooper_pollAll() variables
        int pollResult = 0;
        int pollEvents = 0;

        // Poll Events (registered events)
        // NOTE: Activity is paused if not enabled (CORE.Android.appEnabled)
        while ((pollResult = ALooper_pollAll(CORE.Android.appEnabled? 0 : -1, null, &pollEvents, cast(void**)&CORE.Android.source)) >= 0)
        {
            // Process this event
            if (CORE.Android.source != null) CORE.Android.source.process(CORE.Android.app, CORE.Android.source);

            // NOTE: Never close window, native activity is controlled by the system!
            if (CORE.Android.app.destroyRequested != 0)
            {
                //CORE.Window.shouldClose = true;
                //ANativeActivity_finish(CORE.Android.app.activity);
            }
        }
    }

    version(none) {  // #if (defined(PLATFORM_RPI) || defined(PLATFORM_DRM)) && defined(SUPPORT_SSH_KEYBOARD_RPI)
        // NOTE: Keyboard reading could be done using input_event(s) or just read from stdin, both methods are used here.
        // stdin reading is still used for legacy purposes, it allows keyboard input trough SSH console

        if (!CORE.Input.Keyboard.evtMode) ProcessKeyboard();

        // NOTE: Mouse input events polling is done asynchronously in another pthread - EventThread()
        // NOTE: Gamepad (Joystick) input events polling is done asynchonously in another pthread - GamepadThread()
    }
}
