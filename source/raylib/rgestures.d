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
module raylib.rgestures;

extern (C) @nogc nothrow:

enum PI = 3.14159265358979323846;

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------

enum MAX_TOUCH_POINTS = 8; // Maximum number of touch points supported

//----------------------------------------------------------------------------------
// Types and Structures Definition
// NOTE: Below types are required for GESTURES_STANDALONE usage
//----------------------------------------------------------------------------------
// Boolean type

// Vector2 type
public import raylib : Vector2;

// Gestures type
// NOTE: It could be used as flags to enable only some gestures

enum TouchAction
{
    TOUCH_ACTION_UP = 0,
    TOUCH_ACTION_DOWN = 1,
    TOUCH_ACTION_MOVE = 2,
    TOUCH_ACTION_CANCEL = 3
}

// Gesture event
struct GestureEvent
{
    int touchAction;
    int pointCount;
    int[MAX_TOUCH_POINTS] pointId;
    Vector2[MAX_TOUCH_POINTS] position;
}

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
//...

//----------------------------------------------------------------------------------
// Module Functions Declaration
//----------------------------------------------------------------------------------

// Prevents name mangling of functions

void ProcessGestureEvent (GestureEvent event); // Process gesture event and translate it into gestures
void UpdateGestures (); // Update gestures detected (must be called every frame)

// Enable a set of gestures using flags
// Check if a gesture have been detected
// Get latest detected gesture

// Get gesture hold time in milliseconds
// Get gesture drag vector
// Get gesture drag angle
// Get gesture pinch delta
// Get gesture pinch angle

// GESTURES_H

/***********************************************************************************
*
*   GESTURES IMPLEMENTATION
*
************************************************************************************/

// Prevents name mangling of functions

// Functions required to query time on Windows

// Required for CLOCK_MONOTONIC if compiled with c99 without gnu ext.

// Required for: timespec
// Required for: clock_gettime()

// Required for: sqrtf(), atan2f()

// macOS also defines __MACH__
// Required for: clock_get_time()
// Required for: mach_timespec_t

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
// Swipe force, measured in normalized screen units/time
// Drag minimum force, measured in normalized screen units (0.0f to 1.0f)
// Pinch minimum force, measured in normalized screen units (0.0f to 1.0f)
// Tap minimum time, measured in milliseconds
// Pinch minimum time, measured in milliseconds
// DoubleTap range, measured in normalized screen units (0.0f to 1.0f)

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------

// Gestures module state context [136 bytes]

// Current detected gesture
// Enabled gestures flags

// Touch id for first touch point
// Touch points counter
// Time stamp when an event happened
// Touch up position
// First touch down position
// Second touch down position
// Touch drag position
// First touch down position on move
// Second touch down position on move
// TAP counter (one tap implies TOUCH_ACTION_DOWN and TOUCH_ACTION_UP actions)

// HOLD reset to get first touch point again
// HOLD duration in milliseconds

// DRAG vector (between initial and current position)
// DRAG angle (relative to x-axis)
// DRAG distance (from initial touch point to final) (normalized [0..1])
// DRAG intensity, how far why did the DRAG (pixels per frame)

// SWIPE used to define when start measuring GESTURES.Swipe.timeDuration
// SWIPE time to calculate drag intensity

// PINCH vector (between first and second touch points)
// PINCH angle (relative to x-axis)
// PINCH displacement distance (normalized [0..1])

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------

// No current gesture detected
// All gestures supported by default

//----------------------------------------------------------------------------------
// Module specific Functions Declaration
//----------------------------------------------------------------------------------

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------

// Enable only desired getures to be detected

// Check if a gesture have been detected

// Process gesture event and translate it into gestures

// Reset required variables
// Required on UpdateGestures()

// One touch point

// Tap counter

// Detect GESTURE_DOUBLE_TAP

// Detect GESTURE_TAP

// NOTE: GESTURES.Drag.intensity dependend on the resolution of the screen

// Detect GESTURE_SWIPE

// NOTE: Angle should be inverted in Y

// Right
// Up
// Left
// Down

// Detect GESTURE_DRAG

// Two touch points

//GESTURES.Pinch.distance = rgVector2Distance(GESTURES.Touch.downPositionA, GESTURES.Touch.downPositionB);

// NOTE: Angle should be inverted in Y

// More than two touch points

// TODO: Process gesture events for more than two points

// Update gestures detected (must be called every frame)

// NOTE: Gestures are processed through system callbacks on touch events

// Detect GESTURE_HOLD

// Detect GESTURE_NONE

// Get latest detected gesture

// Get current gesture only if enabled

// Hold time measured in ms

// NOTE: time is calculated on current gesture HOLD

// Get drag vector (between initial touch point to current)

// NOTE: drag vector is calculated on one touch points TOUCH_ACTION_MOVE

// Get drag angle
// NOTE: Angle in degrees, horizontal-right is 0, counterclock-wise

// NOTE: drag angle is calculated on one touch points TOUCH_ACTION_UP

// Get distance between two pinch points

// NOTE: Pinch distance is calculated on two touch points TOUCH_ACTION_MOVE

// Get angle beween two pinch points
// NOTE: Angle in degrees, horizontal-right is 0, counterclock-wise

// NOTE: pinch angle is calculated on two touch points TOUCH_ACTION_MOVE

//----------------------------------------------------------------------------------
// Module specific Functions Definition
//----------------------------------------------------------------------------------
// Get angle from two-points vector with X-axis

// Calculate distance between two Vector2

// Time measure returned are milliseconds

// BE CAREFUL: Costly operation!

// Time in miliseconds

// NOTE: Only for Linux-based systems

// Time in nanoseconds

// Time in miliseconds

//#define CLOCK_REALTIME  CALENDAR_CLOCK    // returns UTC time since 1970-01-01
//#define CLOCK_MONOTONIC SYSTEM_CLOCK      // returns the time since boot time

// NOTE: OS X does not have clock_gettime(), using clock_get_time()

// Time in nanoseconds

// Time in miliseconds

// GESTURES_IMPLEMENTATION
