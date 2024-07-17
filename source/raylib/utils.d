module raylib.utils;
@nogc nothrow:
extern(C): __gshared:

private template HasVersion(string versionId) {
	mixin("version("~versionId~") {enum HasVersion = true;} else {enum HasVersion = false;}");
}
/**********************************************************************************************
*
*   raylib.utils - Some common utility functions
*
*   CONFIGURATION:
*
*   #define SUPPORT_TRACELOG
*       Show TraceLog() output messages
*       NOTE: By default LOG_DEBUG traces not shown
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

import raylib;                     // WARNING: Required for: LogType enum

alias TRACELOG=TraceLog;


// Check if config flags have been externally provided on compilation line
import raylib.config;                 // Defines module configuration flags

version (none) { // PLATFORM_ANDROID
    public import core.stdc.errno;                  // Required for: Android error types
    public import android.log;            // Required for: Android log system: __android_log_vprint()
    public import android.asset_manager;  // Required for: Android assets manager: AAsset, AAssetManager_open(), ...
}

import core.stdc.stdlib;                     // Required for: exit()
import core.stdc.stdio;                      // Required for: FILE, fopen(), fseek(), ftell(), fread(), fwrite(), fprintf(), vprintf(), fclose()
import core.stdc.stdarg;                     // Required for: va_list, va_start(), va_end()
import core.stdc.string;                     // Required for: strcpy(), strcat()

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
enum MAX_TRACELOG_MSG_LENGTH =     128;     // Max length of one trace-log message


//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
private int logTypeLevel = TraceLogLevel.LOG_INFO;                 // Minimum log type level

private TraceLogCallback traceLog = null;            // TraceLog callback function pointer
private LoadFileDataCallback loadFileData = null;    // LoadFileData callback funtion pointer
private SaveFileDataCallback saveFileData = null;    // SaveFileText callback funtion pointer
private LoadFileTextCallback loadFileText = null;    // LoadFileText callback funtion pointer
private SaveFileTextCallback saveFileText = null;    // SaveFileText callback funtion pointer

//----------------------------------------------------------------------------------
// Functions to set internal callbacks
//----------------------------------------------------------------------------------
void SetTraceLogCallback(TraceLogCallback callback) { traceLog = callback; }              // Set custom trace log
void SetLoadFileDataCallback(LoadFileDataCallback callback) { loadFileData = callback; }  // Set custom file data loader
void SetSaveFileDataCallback(SaveFileDataCallback callback) { saveFileData = callback; }  // Set custom file data saver
void SetLoadFileTextCallback(LoadFileTextCallback callback) { loadFileText = callback; }  // Set custom file text loader
void SetSaveFileTextCallback(SaveFileTextCallback callback) { saveFileText = callback; }  // Set custom file text saver


version (none) { // PLATFORM_ANDROID
private AAssetManager* assetManager = null;              // Android assets manager pointer
private const(char)* internalDataPath = null;             // Android internal data path
}

//----------------------------------------------------------------------------------
// Module specific Functions Declaration
//----------------------------------------------------------------------------------
version (none) { // PLATFORM_ANDROID
FILE* funopen(const(void)* cookie, int function(void*, char*, int) readfn, int function(void*, const(char)*, int) writefn, fpos_t function(void*, fpos_t, int) seekfn, int function(void*) closefn);





}

//----------------------------------------------------------------------------------
// Module Functions Definition - Utilities
//----------------------------------------------------------------------------------

// Set the current threshold (minimum) log level
void SetTraceLogLevel(int logType) { logTypeLevel = logType; }

// Show trace log messages (LOG_INFO, LOG_WARNING, LOG_ERROR, LOG_DEBUG)
void TraceLog(int logType, const(char)* text, ...)
{
version (all) { // SUPPORT_TRACELOG
    // Message has level below current threshold, don't emit
    if (logType < logTypeLevel) return;

    va_list args = void;
    va_start(args, text);

    if (traceLog)
    {
        traceLog(logType, text, args);
        va_end(args);
        return;
    }

version (none) { // PLATFORM_ANDROID
    with(TraceLogLevel) switch (logType)
    {
        case LOG_TRACE: __android_log_vprint(ANDROID_LOG_VERBOSE, "raylib", text, args); break;
        case LOG_DEBUG: __android_log_vprint(ANDROID_LOG_DEBUG, "raylib", text, args); break;
        case LOG_INFO: __android_log_vprint(ANDROID_LOG_INFO, "raylib", text, args); break;
        case LOG_WARNING: __android_log_vprint(ANDROID_LOG_WARN, "raylib", text, args); break;
        case LOG_ERROR: __android_log_vprint(ANDROID_LOG_ERROR, "raylib", text, args); break;
        case LOG_FATAL: __android_log_vprint(ANDROID_LOG_FATAL, "raylib", text, args); break;
        default: break;
    }
} else {
    char[MAX_TRACELOG_MSG_LENGTH] buffer = 0;

    with(TraceLogLevel) switch (logType)
    {
        case LOG_TRACE: strcpy(buffer.ptr, "TRACE: "); break;
        case LOG_DEBUG: strcpy(buffer.ptr, "DEBUG: "); break;
        case LOG_INFO: strcpy(buffer.ptr, "INFO: "); break;
        case LOG_WARNING: strcpy(buffer.ptr, "WARNING: "); break;
        case LOG_ERROR: strcpy(buffer.ptr, "ERROR: "); break;
        case LOG_FATAL: strcpy(buffer.ptr, "FATAL: "); break;
        default: break;
    }

    strcat(buffer.ptr, text);
    strcat(buffer.ptr, "\n");
    vprintf(buffer.ptr, args);
}

    va_end(args);

    if (logType == TraceLogLevel.LOG_FATAL) exit(EXIT_FAILURE);  // If fatal logging, exit program

}  // SUPPORT_TRACELOG
}

void TRACELOGD(const(char)* text, ...) {
    debug {
        va_list args = void;
        va_start(args, text);
        TraceLog(TraceLogLevel.LOG_DEBUG, text, args);
        va_end(args);
    }
}


// Internal memory allocator
// NOTE: Initializes to zero by default
void* MemAlloc(int size)
{
    void* ptr = calloc(size, 1);
    return ptr;
}

// Internal memory reallocator
void* MemRealloc(void* ptr, int size)
{
    void* ret = realloc(ptr, size);
    return ret;
}

// Internal memory free
void MemFree(void* ptr)
{
    free(ptr);
}

// Load data from file into a buffer
ubyte* LoadFileData(const(char)* fileName, uint* bytesRead)
{
    ubyte* data = null;
    *bytesRead = 0;

    if (fileName != null)
    {
        if (loadFileData)
        {
            data = loadFileData(fileName, bytesRead);
            return data;
        }
version (all) { // SUPPORT_STANDARD_FILEIO)
        FILE* file = fopen(fileName, "rb");

        if (file != null)
        {
            // WARNING: On binary streams SEEK_END could not be found,
            // using fseek() and ftell() could not work in some (rare) cases
            fseek(file, 0, SEEK_END);
            int size = cast(int)ftell(file);
            fseek(file, 0, SEEK_SET);

            if (size > 0)
            {
                data = cast(ubyte*)malloc(size*ubyte.sizeof);

                // NOTE: fread() returns number of read elements instead of bytes, so we read [1 byte, size elements]
                uint count = cast(uint)fread(data, ubyte.sizeof, size, file);
                *bytesRead = count;

                if (count != size) TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] File partially loaded", fileName);
                else TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] File loaded successfully", fileName);
            }
            else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to read file", fileName);

            fclose(file);
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to open file", fileName);
} else {
    TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: Standard file io not supported, use custom file callback");
}
    }
    else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: File name provided is not valid");

    return data;
}

// Unload file data allocated by LoadFileData()
void UnloadFileData(ubyte* data)
{
    free(data);
}

// Save data to file from buffer
bool SaveFileData(const(char)* fileName, void* data, uint bytesToWrite)
{
    bool success = false;

    if (fileName != null)
    {
        if (saveFileData)
        {
            return saveFileData(fileName, data, bytesToWrite);
        }
version (all) { // SUPPORT_STANDARD_FILEIO) {
        FILE* file = fopen(fileName, "wb");

        if (file != null)
        {
            uint count = cast(uint)fwrite(data, ubyte.sizeof, bytesToWrite, file);

            if (count == 0) TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to write file", fileName);
            else if (count != bytesToWrite) TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] File partially written", fileName);
            else TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] File saved successfully", fileName);

            int result = fclose(file);
            if (result == 0) success = true;
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to open file", fileName);
} else {
    TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: Standard file io not supported, use custom file callback");
}
    }
    else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: File name provided is not valid");

    return success;
}

// Load text data from file, returns a '\0' terminated string
// NOTE: text chars array should be freed manually
char* LoadFileText(const(char)* fileName)
{
    char* text = null;

    if (fileName != null)
    {
        if (loadFileText)
        {
            text = loadFileText(fileName);
            return text;
        }
version (all) { // SUPPORT_STANDARD_FILEIO
        FILE* file = fopen(fileName, "rt");

        if (file != null)
        {
            // WARNING: When reading a file as 'text' file,
            // text mode causes carriage return-linefeed translation...
            // ...but using fseek() should return correct byte-offset
            fseek(file, 0, SEEK_END);
            uint size = cast(uint)ftell(file);
            fseek(file, 0, SEEK_SET);

            if (size > 0)
            {
                text = cast(char*)malloc((size + 1)*char.sizeof);
                uint count = cast(uint)fread(text, char.sizeof, size, file);

                // WARNING: \r\n is converted to \n on reading, so,
                // read bytes count gets reduced by the number of lines
                if (count < size) text = cast(char *)realloc(text, count + 1);

                // Zero-terminate the string
                text[count] = '\0';

                TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] Text file loaded successfully", fileName);
            }
            else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to read text file", fileName);

            fclose(file);
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to open text file", fileName);
} else {
    TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: Standard file io not supported, use custom file callback");
}
    }
    else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: File name provided is not valid");

    return text;
}

// Unload file text data allocated by LoadFileText()
void UnloadFileText(char* text)
{
    free(text);
}

// Save text data to file (write), string must be '\0' terminated
bool SaveFileText(const(char)* fileName, char* text)
{
    bool success = false;

    if (fileName != null)
    {
        if (saveFileText)
        {
            return saveFileText(fileName, text);
        }
version (all) { // SUPPORT_STANDARD_FILEIO
        FILE* file = fopen(fileName, "wt");

        if (file != null)
        {
            int count = fprintf(file, "%s", text);

            if (count < 0) TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to write text file", fileName);
            else TraceLog(TraceLogLevel.LOG_INFO, "FILEIO: [%s] Text file saved successfully", fileName);

            int result = fclose(file);
            if (result == 0) success = true;
        }
        else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to open text file", fileName);
} else {
    TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: Standard file io not supported, use custom file callback");
}
    }
    else TraceLog(TraceLogLevel.LOG_WARNING, "FILEIO: File name provided is not valid");

    return success;
}

version (none) { // PLATFORM_ANDROID
// Initialize asset manager from android app
void InitAssetManager(AAssetManager* manager, const(char)* dataPath)
{
    assetManager = manager;
    internalDataPath = dataPath;
}

// Replacement for fopen()
// Ref: https://developer.android.com/ndk/reference/group/asset
FILE* android_fopen(const(char)* fileName, const(char)* mode)
{
    if (mode[0] == 'w')
    {
        // fopen() is mapped to android_fopen() that only grants read access to
        // assets directory through AAssetManager but we want to also be able to
        // write data when required using the standard stdio FILE access functions
        // Ref: https://stackoverflow.com/questions/11294487/android-writing-saving-files-from-native-code-only
                return fopen(TextFormat("%s/%s", internalDataPath, fileName), mode);
        enum string fopen(string name, string mode) = `android_fopen(` ~ name ~ `, ` ~ mode ~ `)`;
    }
    else
    {
        // NOTE: AAsset provides access to read-only asset
        AAsset* asset = AAssetManager_open(assetManager, fileName, AASSET_MODE_UNKNOWN);

        if (asset != null)
        {
            // Get pointer to file in the assets
            return funopen(asset, android_read, android_write, android_seek, android_close);
        }
        else
        {
                        // Just do a regular open if file is not found in the assets
            return mixin(fopen!(`TextFormat("%s/%s", internalDataPath, fileName)`, `mode`));
            enum string fopen(string name, string mode) = `android_fopen(` ~ name ~ `, ` ~ mode ~ `)`;
        }
    }
}
}  // PLATFORM_ANDROID

//----------------------------------------------------------------------------------
// Module specific Functions Definition
//----------------------------------------------------------------------------------
version (none) { // PLATFORM_ANDROID
private int android_read(void* cookie, char* buf, int size)
{
    return AAsset_read(cast(AAsset*)cookie, buf, size);
}

private int android_write(void* cookie, const(char)* buf, int size)
{
    TraceLog(TraceLogLevel.LOG_WARNING, "ANDROID: Failed to provide write access to APK");

    return EACCES;
}

private fpos_t android_seek(void* cookie, fpos_t offset, int whence)
{
    return AAsset_seek(cast(AAsset*)cookie, offset, whence);
}

private int android_close(void* cookie)
{
    AAsset_close(cast(AAsset*)cookie);
    return 0;
}
}  // PLATFORM_ANDROID
