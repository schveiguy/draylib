module raylib.rcore;
import bindbc.glfw;
import raylib;
import raylib.config;

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
    extern(C) void LoadFontDefault();          // [Module: text] Loads default font on InitWindow()
    extern(C) void UnloadFontDefault();        // [Module: text] Unloads default font from GPU memory
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

extern(C) void InitWindow(int width, int height, const(char)*title)
{
    TraceLog(TraceLogLevel.LOG_INFO, "Initializing raylib %s", RAYLIB_VERSION.ptr);

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

// TODO: move impl to D
extern(C) bool InitGraphicsDevice(int width, int height);
extern(C) void InitTimer();
