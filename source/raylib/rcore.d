module raylib.rcore;
import bindbc.glfw;
import raylib;
import raylib.config;
import raylib.raymath;
import raylib.rlgl;
import core.stdc.stdlib;

// port of rcore.c
//
enum MAX_KEYBOARD_KEYS = 512;        // Maximum number of keyboard keys supported
enum MAX_MOUSE_BUTTONS = 8;          // Maximum number of mouse buttons supported
enum MAX_GAMEPADS = 4;               // Maximum number of gamepads supported
enum MAX_GAMEPAD_AXIS = 8;           // Maximum number of axis supported (per gamepad)
enum MAX_GAMEPAD_BUTTONS = 32;       // Maximum number of buttons supported (per gamepad)
enum MAX_TOUCH_POINTS = 8;           // Maximum number of touch points supported
enum MAX_KEY_PRESSED_QUEUE = 16;     // Maximum number of keys in the key input queue
enum MAX_CHAR_PRESSED_QUEUE = 16;    // Maximum number of characters in the char input queue

version(all) { // #if defined(SUPPORT_DEFAULT_FONT)
    extern(C) void LoadFontDefault() nothrow @nogc;          // [Module: text] Loads default font on InitWindow()
    extern(C) void UnloadFontDefault() nothrow @nogc;        // [Module: text] Unloads default font from GPU memory
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
            char[MAX_KEYBOARD_KEYS] currentKeyState = 0;        // Registers current frame key state
            char[MAX_KEYBOARD_KEYS] previousKeyState = 0;       // Registers previous frame key state

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

            char[MAX_MOUSE_BUTTONS] currentButtonState = 0;     // Registers current mouse button state
            char[MAX_MOUSE_BUTTONS] previousButtonState = 0;    // Registers previous mouse button state
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
            char[MAX_GAMEPAD_BUTTONS][MAX_GAMEPADS] currentButtonState = [0];     // Current gamepad buttons state
            char[MAX_GAMEPAD_BUTTONS][MAX_GAMEPADS] previousButtonState = [0];    // Previous gamepad buttons state
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

// provide API to 
private __gshared CoreData CORE;
private extern(C) CoreData *_getCoreData() {
    return &CORE;
}

extern(C) void InitWindow(int width, int height, const(char)*title) nothrow @nogc
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

extern(C) private bool InitGraphicsDevice(int width, int height) nothrow @nogc
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

// GLFW3 Error Callback, runs on GLFW3 error
version(all) { // #if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
    private extern(C) void ErrorCallback(int error, const char *description) nothrow @nogc
    {
        TraceLog(TraceLogLevel.LOG_WARNING, "GLFW: Error: %i Description: %s", error, description);
    }
}
// GLFW3 WindowSize Callback, runs when window is resizedLastFrame
// NOTE: Window resizing not allowed by default
private extern(C) void WindowSizeCallback(GLFWwindow *window, int width, int height) nothrow @nogc
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
    private extern(C) void WindowMaximizeCallback(GLFWwindow *window, int maximized) nothrow @nogc
    {
        if (maximized) CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_MAXIMIZED;  // The window was maximized
        else CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MAXIMIZED;           // The window was restored
    }
}

// GLFW3 WindowIconify Callback, runs when window is minimized/restored
private extern(C) void WindowIconifyCallback(GLFWwindow *window, int iconified) @nogc nothrow
{
    if (iconified) CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_MINIMIZED;  // The window was iconified
    else CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_MINIMIZED;           // The window was restored
}

// GLFW3 WindowFocus Callback, runs when window get/lose focus
private extern(C) void WindowFocusCallback(GLFWwindow *window, int focused) @nogc nothrow
{
    if (focused) CORE.Window.flags &= ~ConfigFlags.FLAG_WINDOW_UNFOCUSED;   // The window was focused
    else CORE.Window.flags |= ConfigFlags.FLAG_WINDOW_UNFOCUSED;            // The window lost focus
}

// GLFW3 Window Drop Callback, runs when drop files into window
// NOTE: Paths are stored in dynamic memory for further retrieval
// Everytime new files are dropped, old ones are discarded
private extern(C) void WindowDropCallback(GLFWwindow *window, int count, const(char *)*paths) nothrow @nogc
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
private extern(C) void CharCallback(GLFWwindow *window, uint key) nothrow @nogc
{
    //TRACELOG(LOG_DEBUG, "Char Callback: KEY:%i(%c)", key, key);

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

// GLFW3 Srolling Callback, runs on mouse wheel
private extern(C) void MouseScrollCallback(GLFWwindow *window, double xoffset, double yoffset) nothrow @nogc
{
    if (xoffset != 0.0) CORE.Input.Mouse.currentWheelMove = xoffset;
    else CORE.Input.Mouse.currentWheelMove = yoffset;
}

// GLFW3 CursorEnter Callback, when cursor enters the window
private extern(C) void CursorEnterCallback(GLFWwindow *window, int enter) nothrow @nogc
{
    if (enter == true) CORE.Input.Mouse.cursorOnScreen = true;
    else CORE.Input.Mouse.cursorOnScreen = false;
}


// TODO: move impl to D
private extern(C) void InitTimer() nothrow @nogc;
private extern(C) void SetupFramebuffer(int width, int height) nothrow @nogc;
private extern(C) void KeyCallback(GLFWwindow *window, int key, int scancode, int action, int mods) nothrow @nogc;
private extern(C) void MouseButtonCallback(GLFWwindow *window, int button, int action, int mods) nothrow @nogc;
private extern(C) void MouseCursorPosCallback(GLFWwindow *window, double x, double y) nothrow @nogc;
private extern(C) void SetupViewport(int width, int height) nothrow @nogc;

extern(C) void CloseWindow()
{
//#if defined(SUPPORT_GIF_RECORDING)
version(all)
    if (gifRecording)
    {
        MsfGifResult result = msf_gif_end(&gifState);
        msf_gif_free(result);
        gifRecording = false;
    }
//#endif

//#if defined(SUPPORT_DEFAULT_FONT)
version(all)
    UnloadFontDefault();
//endif

    rlglClose();                // De-init rlgl

//#if defined(PLATFORM_DESKTOP) || defined(PLATFORM_WEB)
version(all)
{
    glfwDestroyWindow(CORE.Window.handle);
    glfwTerminate();
}
//#endif

//#if defined(_WIN32) && defined(SUPPORT_WINMM_HIGHRES_TIMER) && !defined(SUPPORT_BUSY_WAIT_LOOP)
version(Win32)
    timeEndPeriod(1);           // Restore time period
//#endif

//#if defined(PLATFORM_ANDROID) || defined(PLATFORM_RPI)
    // Close surface, context and display
version(none)
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
//#endif

//#if defined(PLATFORM_DRM)
version(none)
{
    if (CORE.Window.prevFB)
    {
        drmModeRmFB(CORE.Window.fd, CORE.Window.prevFB);
        CORE.Window.prevFB = 0;
    }

    if (CORE.Window.prevBO)
    {
        gbm_surface_release_buffer(CORE.Window.gbmSurface, CORE.Window.prevBO);
        CORE.Window.prevBO = NULL;
    }

    if (CORE.Window.gbmSurface)
    {
        gbm_surface_destroy(CORE.Window.gbmSurface);
        CORE.Window.gbmSurface = NULL;
    }

    if (CORE.Window.gbmDevice)
    {
        gbm_device_destroy(CORE.Window.gbmDevice);
        CORE.Window.gbmDevice = NULL;
    }

    if (CORE.Window.crtc)
    {
        if (CORE.Window.connector)
        {
            drmModeSetCrtc(CORE.Window.fd, CORE.Window.crtc.crtc_id, CORE.Window.crtc.buffer_id,
                CORE.Window.crtc.x, CORE.Window.crtc.y, &CORE.Window.connector.connector_id, 1, &CORE.Window.crtc.mode);
            drmModeFreeConnector(CORE.Window.connector);
            CORE.Window.connector = NULL;
        }

        drmModeFreeCrtc(CORE.Window.crtc);
        CORE.Window.crtc = NULL;
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
//#endif

//#if defined(PLATFORM_RPI) || defined(PLATFORM_DRM)
    // Wait for mouse and gamepad threads to finish before closing
    // NOTE: Those threads should already have finished at this point
    // because they are controlled by CORE.Window.shouldClose variable
version(none)
{
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
            pthread_join(CORE.Input.eventWorker[i].threadId, NULL);
        }
    }

    if (CORE.Input.Gamepad.threadId) pthread_join(CORE.Input.Gamepad.threadId, NULL);
}
//#endif

//#if defined(SUPPORT_EVENTS_AUTOMATION)
version(all)
    free(events);
//#endif

    CORE.Window.ready = false;
    TraceLog(TraceLogLevel.LOG_INFO, "Window closed successfully".ptr);
}
// TODO: this one is actually from rlgl.c / rlgl.h and will need to be moved once ported over
extern(C) void rlglClose();
