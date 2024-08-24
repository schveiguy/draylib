module raylib.rgestures;
@nogc nothrow:
extern(C): __gshared:

private template HasVersion(string versionId) {
	mixin("version("~versionId~") {enum HasVersion = true;} else {enum HasVersion = false;}");
}
/**********************************************************************************************
*
*   rgestures - Gestures system, gestures processing based on input events (touch/mouse)
*
*   NOTE: Memory footprint of this library is aproximately 128 bytes (global variables)
*
*   CONFIGURATION:
*
*   #define GESTURES_IMPLEMENTATION
*       Generates the implementation of the library into the included file.
*       If not defined, the library is in header only mode and can be included in other headers
*       or source files without problems. But only ONE file should hold the implementation.
*
*   #define GESTURES_STANDALONE
*       If defined, the library can be used as standalone to process gesture events with
*       no external dependencies.
*
*   CONTRIBUTORS:
*       Marc Palau:         Initial implementation (2014)
*       Albert Martos:      Complete redesign and testing (2015)
*       Ian Eito:           Complete redesign and testing (2015)
*       Ramon Santamaria:   Supervision, review, update and maintenance
*
*
*   LICENSE: zlib/libpng
*
*   Copyright (c) 2014-2021 Ramon Santamaria (@raysan5)
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

import raylib;

enum PI = 3.14159265358979323846;


//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
enum MAX_TOUCH_POINTS =        8;        // Maximum number of touch points supported

enum TouchAction {
    TOUCH_ACTION_UP = 0,
    TOUCH_ACTION_DOWN,
    TOUCH_ACTION_MOVE,
    TOUCH_ACTION_CANCEL
}
alias TOUCH_ACTION_UP = TouchAction.TOUCH_ACTION_UP;
alias TOUCH_ACTION_DOWN = TouchAction.TOUCH_ACTION_DOWN;
alias TOUCH_ACTION_MOVE = TouchAction.TOUCH_ACTION_MOVE;
alias TOUCH_ACTION_CANCEL = TouchAction.TOUCH_ACTION_CANCEL;


// Gesture event
struct GestureEvent {
    int touchAction;
    int pointCount;
    int[MAX_TOUCH_POINTS] pointId;
    Vector2[MAX_TOUCH_POINTS] position;
}

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
//...

/***********************************************************************************
*
*   GESTURES IMPLEMENTATION
*
************************************************************************************/

version(Windows) {
    // Functions required to query time on Windows
    extern(Windows):
        int QueryPerformanceCounter(ulong *lpPerformanceCount);
        int QueryPerformanceFrequency(uint* lpFrequency);
} else version(linux) {
    import core.sys.posix.sys.time;               // Required for: timespec
    import core.stdc.time;                   // Required for: clock_gettime()

    import core.stdc.math;                   // Required for: sqrtf(), atan2f()
} else version (OSX) {                  // macOS also defines __MACH__
    import mach_import;
}

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
enum FORCE_TO_SWIPE =      0.0005f;     // Swipe force, measured in normalized screen units/time
enum MINIMUM_DRAG =        0.015f;      // Drag minimum force, measured in normalized screen units (0.0f to 1.0f)
enum MINIMUM_PINCH =       0.005f;      // Pinch minimum force, measured in normalized screen units (0.0f to 1.0f)
enum TAP_TIMEOUT =         300;         // Tap minimum time, measured in milliseconds
enum PINCH_TIMEOUT =       300;         // Pinch minimum time, measured in milliseconds
enum DOUBLETAP_RANGE =     0.03f;       // DoubleTap range, measured in normalized screen units (0.0f to 1.0f)

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------

// Gestures module state context [136 bytes]
struct GesturesData {
    uint current;               // Current detected gesture
    uint enabledFlags;          // Enabled gestures flags
    struct _Touch {
        int firstId;                    // Touch id for first touch point
        int pointCount;                 // Touch points counter
        double eventTime = 0;               // Time stamp when an event happened
        Vector2 upPosition;             // Touch up position
        Vector2 downPositionA;          // First touch down position
        Vector2 downPositionB;          // Second touch down position
        Vector2 downDragPosition;       // Touch drag position
        Vector2 moveDownPositionA;      // First touch down position on move
        Vector2 moveDownPositionB;      // Second touch down position on move
        int tapCounter;                 // TAP counter (one tap implies TOUCH_ACTION_DOWN and TOUCH_ACTION_UP actions)
    }_Touch Touch;
    struct _Hold {
        bool resetRequired;             // HOLD reset to get first touch point again
        double timeDuration = 0;            // HOLD duration in milliseconds
    }_Hold Hold;
    struct _Drag {
        Vector2 vector;                 // DRAG vector (between initial and current position)
        float angle = 0;                    // DRAG angle (relative to x-axis)
        float distance = 0;                 // DRAG distance (from initial touch point to final) (normalized [0..1])
        float intensity = 0;                // DRAG intensity, how far why did the DRAG (pixels per frame)
    }_Drag Drag;
    struct _Swipe {
        bool start;                     // SWIPE used to define when start measuring GESTURES.Swipe.timeDuration
        double timeDuration = 0;            // SWIPE time to calculate drag intensity
    }_Swipe Swipe;
    struct _Pinch {
        Vector2 vector;                 // PINCH vector (between first and second touch points)
        float angle = 0;                    // PINCH angle (relative to x-axis)
        float distance = 0;                 // PINCH displacement distance (normalized [0..1])
    }_Pinch Pinch;
}

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
private GesturesData GESTURES = {
    Touch:  {firstId: -1},
    current: GESTURE_NONE,        // No current gesture detected
    enabledFlags: 0b0000001111111111  // All gestures supported by default
};

//----------------------------------------------------------------------------------
// Module specific Functions Declaration
//----------------------------------------------------------------------------------




//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------

// Enable only desired getures to be detected
void SetGesturesEnabled(uint flags)
{
    GESTURES.enabledFlags = flags;
}

// Check if a gesture have been detected
bool IsGestureDetected(int gesture)
{
    if ((GESTURES.enabledFlags & GESTURES.current) == gesture) return true;
    else return false;
}

// Process gesture event and translate it into gestures
void ProcessGestureEvent(GestureEvent event)
{
    // Reset required variables
    GESTURES.Touch.pointCount = event.pointCount;      // Required on UpdateGestures()

    if (GESTURES.Touch.pointCount == 1)     // One touch point
    {
        if (event.touchAction == TOUCH_ACTION_DOWN)
        {
            GESTURES.Touch.tapCounter++;    // Tap counter

            // Detect GESTURE_DOUBLE_TAP
            if ((GESTURES.current == GESTURE_NONE) && (GESTURES.Touch.tapCounter >= 2) && ((rgGetCurrentTime() - GESTURES.Touch.eventTime) < TAP_TIMEOUT) && (rgVector2Distance(GESTURES.Touch.downPositionA, event.position[0]) < DOUBLETAP_RANGE))
            {
                GESTURES.current = GESTURE_DOUBLETAP;
                GESTURES.Touch.tapCounter = 0;
            }
            else    // Detect GESTURE_TAP
            {
                GESTURES.Touch.tapCounter = 1;
                GESTURES.current = GESTURE_TAP;
            }

            GESTURES.Touch.downPositionA = event.position[0];
            GESTURES.Touch.downDragPosition = event.position[0];

            GESTURES.Touch.upPosition = GESTURES.Touch.downPositionA;
            GESTURES.Touch.eventTime = rgGetCurrentTime();

            GESTURES.Touch.firstId = event.pointId[0];

            GESTURES.Drag.vector = Vector2( 0.0f, 0.0f );
        }
        else if (event.touchAction == TOUCH_ACTION_UP)
        {
            if (GESTURES.current == GESTURE_DRAG) GESTURES.Touch.upPosition = event.position[0];

            // NOTE: GESTURES.Drag.intensity dependend on the resolution of the screen
            GESTURES.Drag.distance = rgVector2Distance(GESTURES.Touch.downPositionA, GESTURES.Touch.upPosition);
            GESTURES.Drag.intensity = GESTURES.Drag.distance/cast(float)((rgGetCurrentTime() - GESTURES.Swipe.timeDuration));

            GESTURES.Swipe.start = false;

            // Detect GESTURE_SWIPE
            if ((GESTURES.Drag.intensity > FORCE_TO_SWIPE) && (GESTURES.Touch.firstId == event.pointId[0]))
            {
                // NOTE: Angle should be inverted in Y
                GESTURES.Drag.angle = 360.0f - rgVector2Angle(GESTURES.Touch.downPositionA, GESTURES.Touch.upPosition);

                if ((GESTURES.Drag.angle < 30) || (GESTURES.Drag.angle > 330)) GESTURES.current = GESTURE_SWIPE_RIGHT;        // Right
                else if ((GESTURES.Drag.angle > 30) && (GESTURES.Drag.angle < 120)) GESTURES.current = GESTURE_SWIPE_UP;      // Up
                else if ((GESTURES.Drag.angle > 120) && (GESTURES.Drag.angle < 210)) GESTURES.current = GESTURE_SWIPE_LEFT;   // Left
                else if ((GESTURES.Drag.angle > 210) && (GESTURES.Drag.angle < 300)) GESTURES.current = GESTURE_SWIPE_DOWN;   // Down
                else GESTURES.current = GESTURE_NONE;
            }
            else
            {
                GESTURES.Drag.distance = 0.0f;
                GESTURES.Drag.intensity = 0.0f;
                GESTURES.Drag.angle = 0.0f;

                GESTURES.current = GESTURE_NONE;
            }

            GESTURES.Touch.downDragPosition = Vector2( 0.0f, 0.0f );
            GESTURES.Touch.pointCount = 0;
        }
        else if (event.touchAction == TOUCH_ACTION_MOVE)
        {
            if (GESTURES.current == GESTURE_DRAG) GESTURES.Touch.eventTime = rgGetCurrentTime();

            if (!GESTURES.Swipe.start)
            {
                GESTURES.Swipe.timeDuration = rgGetCurrentTime();
                GESTURES.Swipe.start = true;
            }

            GESTURES.Touch.moveDownPositionA = event.position[0];

            if (GESTURES.current == GESTURE_HOLD)
            {
                if (GESTURES.Hold.resetRequired) GESTURES.Touch.downPositionA = event.position[0];

                GESTURES.Hold.resetRequired = false;

                // Detect GESTURE_DRAG
                if (rgVector2Distance(GESTURES.Touch.downPositionA, GESTURES.Touch.moveDownPositionA) >= MINIMUM_DRAG)
                {
                    GESTURES.Touch.eventTime = rgGetCurrentTime();
                    GESTURES.current = GESTURE_DRAG;
                }
            }

            GESTURES.Drag.vector.x = GESTURES.Touch.moveDownPositionA.x - GESTURES.Touch.downDragPosition.x;
            GESTURES.Drag.vector.y = GESTURES.Touch.moveDownPositionA.y - GESTURES.Touch.downDragPosition.y;
        }
    }
    else if (GESTURES.Touch.pointCount == 2)    // Two touch points
    {
        if (event.touchAction == TOUCH_ACTION_DOWN)
        {
            GESTURES.Touch.downPositionA = event.position[0];
            GESTURES.Touch.downPositionB = event.position[1];

            //GESTURES.Pinch.distance = rgVector2Distance(GESTURES.Touch.downPositionA, GESTURES.Touch.downPositionB);

            GESTURES.Pinch.vector.x = GESTURES.Touch.downPositionB.x - GESTURES.Touch.downPositionA.x;
            GESTURES.Pinch.vector.y = GESTURES.Touch.downPositionB.y - GESTURES.Touch.downPositionA.y;

            GESTURES.current = GESTURE_HOLD;
            GESTURES.Hold.timeDuration = rgGetCurrentTime();
        }
        else if (event.touchAction == TOUCH_ACTION_MOVE)
        {
            GESTURES.Pinch.distance = rgVector2Distance(GESTURES.Touch.moveDownPositionA, GESTURES.Touch.moveDownPositionB);

            GESTURES.Touch.downPositionA = GESTURES.Touch.moveDownPositionA;
            GESTURES.Touch.downPositionB = GESTURES.Touch.moveDownPositionB;

            GESTURES.Touch.moveDownPositionA = event.position[0];
            GESTURES.Touch.moveDownPositionB = event.position[1];

            GESTURES.Pinch.vector.x = GESTURES.Touch.moveDownPositionB.x - GESTURES.Touch.moveDownPositionA.x;
            GESTURES.Pinch.vector.y = GESTURES.Touch.moveDownPositionB.y - GESTURES.Touch.moveDownPositionA.y;

            if ((rgVector2Distance(GESTURES.Touch.downPositionA, GESTURES.Touch.moveDownPositionA) >= MINIMUM_PINCH) || (rgVector2Distance(GESTURES.Touch.downPositionB, GESTURES.Touch.moveDownPositionB) >= MINIMUM_PINCH))
            {
                if ((rgVector2Distance(GESTURES.Touch.moveDownPositionA, GESTURES.Touch.moveDownPositionB) - GESTURES.Pinch.distance) < 0) GESTURES.current = GESTURE_PINCH_IN;
                else GESTURES.current = GESTURE_PINCH_OUT;
            }
            else
            {
                GESTURES.current = GESTURE_HOLD;
                GESTURES.Hold.timeDuration = rgGetCurrentTime();
            }

            // NOTE: Angle should be inverted in Y
            GESTURES.Pinch.angle = 360.0f - rgVector2Angle(GESTURES.Touch.moveDownPositionA, GESTURES.Touch.moveDownPositionB);
        }
        else if (event.touchAction == TOUCH_ACTION_UP)
        {
            GESTURES.Pinch.distance = 0.0f;
            GESTURES.Pinch.angle = 0.0f;
            GESTURES.Pinch.vector = Vector2( 0.0f, 0.0f );
            GESTURES.Touch.pointCount = 0;

            GESTURES.current = GESTURE_NONE;
        }
    }
    else if (GESTURES.Touch.pointCount > 2)     // More than two touch points
    {
        // TODO: Process gesture events for more than two points
    }
}

// Update gestures detected (must be called every frame)
void UpdateGestures()
{
    // NOTE: Gestures are processed through system callbacks on touch events

    // Detect GESTURE_HOLD
    if (((GESTURES.current == GESTURE_TAP) || (GESTURES.current == GESTURE_DOUBLETAP)) && (GESTURES.Touch.pointCount < 2))
    {
        GESTURES.current = GESTURE_HOLD;
        GESTURES.Hold.timeDuration = rgGetCurrentTime();
    }

    if (((rgGetCurrentTime() - GESTURES.Touch.eventTime) > TAP_TIMEOUT) && (GESTURES.current == GESTURE_DRAG) && (GESTURES.Touch.pointCount < 2))
    {
        GESTURES.current = GESTURE_HOLD;
        GESTURES.Hold.timeDuration = rgGetCurrentTime();
        GESTURES.Hold.resetRequired = true;
    }

    // Detect GESTURE_NONE
    if ((GESTURES.current == GESTURE_SWIPE_RIGHT) || (GESTURES.current == GESTURE_SWIPE_UP) || (GESTURES.current == GESTURE_SWIPE_LEFT) || (GESTURES.current == GESTURE_SWIPE_DOWN))
    {
        GESTURES.current = GESTURE_NONE;
    }
}

// Get latest detected gesture
int GetGestureDetected()
{
    // Get current gesture only if enabled
    return (GESTURES.enabledFlags & GESTURES.current);
}

// Hold time measured in ms
float GetGestureHoldDuration()
{
    // NOTE: time is calculated on current gesture HOLD

    double time = 0.0;

    if (GESTURES.current == GESTURE_HOLD) time = rgGetCurrentTime() - GESTURES.Hold.timeDuration;

    return cast(float)time;
}

// Get drag vector (between initial touch point to current)
Vector2 GetGestureDragVector()
{
    // NOTE: drag vector is calculated on one touch points TOUCH_ACTION_MOVE

    return GESTURES.Drag.vector;
}

// Get drag angle
// NOTE: Angle in degrees, horizontal-right is 0, counterclock-wise
float GetGestureDragAngle()
{
    // NOTE: drag angle is calculated on one touch points TOUCH_ACTION_UP

    return GESTURES.Drag.angle;
}

// Get distance between two pinch points
Vector2 GetGesturePinchVector()
{
    // NOTE: Pinch distance is calculated on two touch points TOUCH_ACTION_MOVE

    return GESTURES.Pinch.vector;
}

// Get angle beween two pinch points
// NOTE: Angle in degrees, horizontal-right is 0, counterclock-wise
float GetGesturePinchAngle()
{
    // NOTE: pinch angle is calculated on two touch points TOUCH_ACTION_MOVE

    return GESTURES.Pinch.angle;
}

//----------------------------------------------------------------------------------
// Module specific Functions Definition
//----------------------------------------------------------------------------------
// Get angle from two-points vector with X-axis
private float rgVector2Angle(Vector2 v1, Vector2 v2)
{
    float angle = atan2f(v2.y - v1.y, v2.x - v1.x)*(180.0f/PI);

    if (angle < 0) angle += 360.0f;

    return angle;
}

// Calculate distance between two Vector2
private float rgVector2Distance(Vector2 v1, Vector2 v2)
{
    float result = void;

    float dx = v2.x - v1.x;
    float dy = v2.y - v1.y;

    result = cast(float)sqrt(dx*dx + dy*dy);

    return result;
}

// Time measure returned are milliseconds
private double rgGetCurrentTime()
{
    double time = 0;

version (Windows) {
    uint clockFrequency = void, currentTime = void;

    QueryPerformanceFrequency(&clockFrequency);     // BE CAREFUL: Costly operation!
    QueryPerformanceCounter(&currentTime);

    time = cast(double)currentTime/clockFrequency*1000.0f;  // Time in miliseconds
}

version (linux) {
    // NOTE: Only for Linux-based systems
    timespec now = void;
    clock_gettime(CLOCK_MONOTONIC, &now);
    uint nowTime = cast(uint)now.tv_sec*1000000000LU + cast(uint)now.tv_nsec;     // Time in nanoseconds

    time = (cast(double)nowTime/1000000.0);     // Time in miliseconds
}

version (OSX) {
    //#define CLOCK_REALTIME  CALENDAR_CLOCK    // returns UTC time since 1970-01-01
    //#define CLOCK_MONOTONIC SYSTEM_CLOCK      // returns the time since boot time

    clock_serv_t cclock = void;
    mach_timespec_t now = void;
    host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);

    // NOTE: OS X does not have clock_gettime(), using clock_get_time()
    clock_get_time(cclock, &now);
    mach_port_deallocate(mach_task_self(), cclock);
    uint nowTime = cast(uint)now.tv_sec*1000000000LU + cast(uint)now.tv_nsec;     // Time in nanoseconds

    time = (cast(double)nowTime/1000000.0);     // Time in miliseconds
}

    return time;
}
