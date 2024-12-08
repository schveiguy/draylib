//@nogc nothrow:
extern(C): __gshared:

private template HasVersion(string versionId) {
	mixin("version("~versionId~") {enum HasVersion = true;} else {enum HasVersion = false;}");
}
/**********************************************************************************************
*
*   rmodels - Basic functions to draw 3d shapes and load and draw 3d models
*
*   CONFIGURATION:
*
*   #define SUPPORT_FILEFORMAT_OBJ
*   #define SUPPORT_FILEFORMAT_MTL
*   #define SUPPORT_FILEFORMAT_IQM
*   #define SUPPORT_FILEFORMAT_GLTF
*   #define SUPPORT_FILEFORMAT_VOX
*
*       Selected desired fileformats to be supported for model data loading.
*
*   #define SUPPORT_MESH_GENERATION
*       Support procedural mesh generation functions, uses external par_shapes.h library
*       NOTE: Some generated meshes DO NOT include generated texture coordinates
*
*
*   LICENSE: zlib/libpng
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

import raylib;         // Declares module functions

import raylib.config;     // Defines module configuration flags

import raylib.utils : TRACELOG;          // Required for: TRACELOG(), LoadFileData(), LoadFileText(), SaveFileText()
import raylib.rlgl;           // OpenGL abstraction layer to OpenGL 1.1, 2.1, 3.3+ or ES2
import raylib.raymath;        // Required for: Vector3, Quaternion and Matrix functionality

import core.stdc.stdio;          // Required for: sprintf()
import core.stdc.stdlib;         // Required for: malloc(), free()
import core.stdc.string;         // Required for: memcmp(), strlen()
import core.stdc.math;           // Required for: sinf(), cosf(), sqrtf(), fabsf()

import modelfiles_import;

version (Windows) {
    import direct : CHDIR = _chdir;     // Required for: _chdir() [Used in LoadOBJ()]
} else {
    import core.sys.posix.unistd : CHDIR = chdir;     // Required for: chdir() (POSIX) [Used in LoadOBJ()]
}

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
enum MAX_MATERIAL_MAPS =       12;    // Maximum number of maps supported

enum MAX_MESH_VERTEX_BUFFERS =  7;    // Maximum vertex buffers (VBO) per mesh

alias RL_MALLOC = core.stdc.stdlib.malloc;
alias RL_FREE = core.stdc.stdlib.free;
alias RL_CALLOC = core.stdc.stdlib.calloc;
enum string PAR_MALLOC(string T, string N) = `(cast(` ~ T ~ `*)RL_MALLOC(` ~ N ~ `*` ~ T ~ `.sizeof))`;
enum string PAR_CALLOC(string T, string N) = `(cast(` ~ T ~ `*)RL_CALLOC(` ~ N ~ `*` ~ T ~ `.sizeof, 1))`;
enum string PAR_REALLOC(string T, string BUF, string N) = `(cast(` ~ T ~ `*)RL_REALLOC(` ~ BUF ~ `, sizeof(` ~ T ~ `)*(` ~ N ~ `)))`;


//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
// ...

// helper to do a float[3] array
struct Float3 {
    float[3] arr;
    this(float x, float y, float z) @nogc{
        this.arr = [x, y, z];
    }

    float* getArr() => arr.ptr;

    alias this = getArr;
}

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
// ...

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------

// Draw a line in 3D world space
void DrawLine3D(Vector3 startPos, Vector3 endPos, Color color)
{
    // WARNING: Be careful with internal buffer vertex alignment
    // when using RL_LINES or RL_TRIANGLES, data is aligned to fit
    // lines-triangles-quads in the same indexed buffers!!!
    rlCheckRenderBatchLimit(8);

    rlBegin(RL_LINES);
        rlColor4ub(color.r, color.g, color.b, color.a);
        rlVertex3f(startPos.x, startPos.y, startPos.z);
        rlVertex3f(endPos.x, endPos.y, endPos.z);
    rlEnd();
}

// Draw a point in 3D space, actually a small line
void DrawPoint3D(Vector3 position, Color color)
{
    rlCheckRenderBatchLimit(8);

    rlPushMatrix();
        rlTranslatef(position.x, position.y, position.z);
        rlBegin(RL_LINES);
            rlColor4ub(color.r, color.g, color.b, color.a);
            rlVertex3f(0.0f, 0.0f, 0.0f);
            rlVertex3f(0.0f, 0.0f, 0.1f);
        rlEnd();
    rlPopMatrix();
}

// Draw a circle in 3D world space
void DrawCircle3D(Vector3 center, float radius, Vector3 rotationAxis, float rotationAngle, Color color)
{
    rlCheckRenderBatchLimit(2*36);

    rlPushMatrix();
        rlTranslatef(center.x, center.y, center.z);
        rlRotatef(rotationAngle, rotationAxis.x, rotationAxis.y, rotationAxis.z);

        rlBegin(RL_LINES);
            for (int i = 0; i < 360; i += 10)
            {
                rlColor4ub(color.r, color.g, color.b, color.a);

                rlVertex3f(sinf(DEG2RAD*i)*radius, cosf(DEG2RAD*i)*radius, 0.0f);
                rlVertex3f(sinf(DEG2RAD*(i + 10))*radius, cosf(DEG2RAD*(i + 10))*radius, 0.0f);
            }
        rlEnd();
    rlPopMatrix();
}

// Draw a color-filled triangle (vertex in counter-clockwise order!)
void DrawTriangle3D(Vector3 v1, Vector3 v2, Vector3 v3, Color color)
{
    rlCheckRenderBatchLimit(3);

    rlBegin(RL_TRIANGLES);
        rlColor4ub(color.r, color.g, color.b, color.a);
        rlVertex3f(v1.x, v1.y, v1.z);
        rlVertex3f(v2.x, v2.y, v2.z);
        rlVertex3f(v3.x, v3.y, v3.z);
    rlEnd();
}

// Draw a triangle strip defined by points
void DrawTriangleStrip3D(Vector3* points, int pointCount, Color color)
{
    if (pointCount >= 3)
    {
        rlCheckRenderBatchLimit(3*(pointCount - 2));

        rlBegin(RL_TRIANGLES);
            rlColor4ub(color.r, color.g, color.b, color.a);

            for (int i = 2; i < pointCount; i++)
            {
                if ((i%2) == 0)
                {
                    rlVertex3f(points[i].x, points[i].y, points[i].z);
                    rlVertex3f(points[i - 2].x, points[i - 2].y, points[i - 2].z);
                    rlVertex3f(points[i - 1].x, points[i - 1].y, points[i - 1].z);
                }
                else
                {
                    rlVertex3f(points[i].x, points[i].y, points[i].z);
                    rlVertex3f(points[i - 1].x, points[i - 1].y, points[i - 1].z);
                    rlVertex3f(points[i - 2].x, points[i - 2].y, points[i - 2].z);
                }
            }
        rlEnd();
    }
}

// Draw cube
// NOTE: Cube position is the center position
void DrawCube(Vector3 position, float width, float height, float length, Color color)
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    rlCheckRenderBatchLimit(36);

    rlPushMatrix();
        // NOTE: Transformation is applied in inverse order (scale -> rotate -> translate)
        rlTranslatef(position.x, position.y, position.z);
        //rlRotatef(45, 0, 1, 0);
        //rlScalef(1.0f, 1.0f, 1.0f);   // NOTE: Vertices are directly scaled on definition

        rlBegin(RL_TRIANGLES);
            rlColor4ub(color.r, color.g, color.b, color.a);

            // Front face
            rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Left
            rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Right
            rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Left

            rlVertex3f(x + width/2, y + height/2, z + length/2);  // Top Right
            rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Left
            rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Right

            // Back face
            rlVertex3f(x - width/2, y - height/2, z - length/2);  // Bottom Left
            rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left
            rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Right

            rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Right
            rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Right
            rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left

            // Top face
            rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left
            rlVertex3f(x - width/2, y + height/2, z + length/2);  // Bottom Left
            rlVertex3f(x + width/2, y + height/2, z + length/2);  // Bottom Right

            rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Right
            rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left
            rlVertex3f(x + width/2, y + height/2, z + length/2);  // Bottom Right

            // Bottom face
            rlVertex3f(x - width/2, y - height/2, z - length/2);  // Top Left
            rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Right
            rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Left

            rlVertex3f(x + width/2, y - height/2, z - length/2);  // Top Right
            rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Right
            rlVertex3f(x - width/2, y - height/2, z - length/2);  // Top Left

            // Right face
            rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Right
            rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Right
            rlVertex3f(x + width/2, y + height/2, z + length/2);  // Top Left

            rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Left
            rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Right
            rlVertex3f(x + width/2, y + height/2, z + length/2);  // Top Left

            // Left face
            rlVertex3f(x - width/2, y - height/2, z - length/2);  // Bottom Right
            rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Left
            rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Right

            rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Left
            rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Left
            rlVertex3f(x - width/2, y - height/2, z - length/2);  // Bottom Right
        rlEnd();
    rlPopMatrix();
}

// Draw cube (Vector version)
void DrawCubeV(Vector3 position, Vector3 size, Color color)
{
    DrawCube(position, size.x, size.y, size.z, color);
}

// Draw cube wires
void DrawCubeWires(Vector3 position, float width, float height, float length, Color color)
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    rlCheckRenderBatchLimit(36);

    rlPushMatrix();
        rlTranslatef(position.x, position.y, position.z);

        rlBegin(RL_LINES);
            rlColor4ub(color.r, color.g, color.b, color.a);

            // Front face -----------------------------------------------------
            // Bottom line
            rlVertex3f(x-width/2, y-height/2, z+length/2);  // Bottom left
            rlVertex3f(x+width/2, y-height/2, z+length/2);  // Bottom right

            // Left line
            rlVertex3f(x+width/2, y-height/2, z+length/2);  // Bottom right
            rlVertex3f(x+width/2, y+height/2, z+length/2);  // Top right

            // Top line
            rlVertex3f(x+width/2, y+height/2, z+length/2);  // Top right
            rlVertex3f(x-width/2, y+height/2, z+length/2);  // Top left

            // Right line
            rlVertex3f(x-width/2, y+height/2, z+length/2);  // Top left
            rlVertex3f(x-width/2, y-height/2, z+length/2);  // Bottom left

            // Back face ------------------------------------------------------
            // Bottom line
            rlVertex3f(x-width/2, y-height/2, z-length/2);  // Bottom left
            rlVertex3f(x+width/2, y-height/2, z-length/2);  // Bottom right

            // Left line
            rlVertex3f(x+width/2, y-height/2, z-length/2);  // Bottom right
            rlVertex3f(x+width/2, y+height/2, z-length/2);  // Top right

            // Top line
            rlVertex3f(x+width/2, y+height/2, z-length/2);  // Top right
            rlVertex3f(x-width/2, y+height/2, z-length/2);  // Top left

            // Right line
            rlVertex3f(x-width/2, y+height/2, z-length/2);  // Top left
            rlVertex3f(x-width/2, y-height/2, z-length/2);  // Bottom left

            // Top face -------------------------------------------------------
            // Left line
            rlVertex3f(x-width/2, y+height/2, z+length/2);  // Top left front
            rlVertex3f(x-width/2, y+height/2, z-length/2);  // Top left back

            // Right line
            rlVertex3f(x+width/2, y+height/2, z+length/2);  // Top right front
            rlVertex3f(x+width/2, y+height/2, z-length/2);  // Top right back

            // Bottom face  ---------------------------------------------------
            // Left line
            rlVertex3f(x-width/2, y-height/2, z+length/2);  // Top left front
            rlVertex3f(x-width/2, y-height/2, z-length/2);  // Top left back

            // Right line
            rlVertex3f(x+width/2, y-height/2, z+length/2);  // Top right front
            rlVertex3f(x+width/2, y-height/2, z-length/2);  // Top right back
        rlEnd();
    rlPopMatrix();
}

// Draw cube wires (vector version)
void DrawCubeWiresV(Vector3 position, Vector3 size, Color color)
{
    DrawCubeWires(position, size.x, size.y, size.z, color);
}

// Draw cube
// NOTE: Cube position is the center position
void DrawCubeTexture(Texture2D texture, Vector3 position, float width, float height, float length, Color color)
{
    float x = position.x;
    float y = position.y;
    float z = position.z;

    rlCheckRenderBatchLimit(36);

    rlSetTexture(texture.id);

    //rlPushMatrix();
        // NOTE: Transformation is applied in inverse order (scale -> rotate -> translate)
        //rlTranslatef(2.0f, 0.0f, 0.0f);
        //rlRotatef(45, 0, 1, 0);
        //rlScalef(2.0f, 2.0f, 2.0f);

        rlBegin(RL_QUADS);
            rlColor4ub(color.r, color.g, color.b, color.a);
            // Front Face
            rlNormal3f(0.0f, 0.0f, 1.0f);                  // Normal Pointing Towards Viewer
            rlTexCoord2f(0.0f, 0.0f); rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            rlTexCoord2f(1.0f, 0.0f); rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            rlTexCoord2f(1.0f, 1.0f); rlVertex3f(x + width/2, y + height/2, z + length/2);  // Top Right Of The Texture and Quad
            rlTexCoord2f(0.0f, 1.0f); rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Left Of The Texture and Quad
            // Back Face
            rlNormal3f(0.0f, 0.0f, - 1.0f);                  // Normal Pointing Away From Viewer
            rlTexCoord2f(1.0f, 0.0f); rlVertex3f(x - width/2, y - height/2, z - length/2);  // Bottom Right Of The Texture and Quad
            rlTexCoord2f(1.0f, 1.0f); rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Right Of The Texture and Quad
            rlTexCoord2f(0.0f, 1.0f); rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Left Of The Texture and Quad
            rlTexCoord2f(0.0f, 0.0f); rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Left Of The Texture and Quad
            // Top Face
            rlNormal3f(0.0f, 1.0f, 0.0f);                  // Normal Pointing Up
            rlTexCoord2f(0.0f, 1.0f); rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left Of The Texture and Quad
            rlTexCoord2f(0.0f, 0.0f); rlVertex3f(x - width/2, y + height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            rlTexCoord2f(1.0f, 0.0f); rlVertex3f(x + width/2, y + height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            rlTexCoord2f(1.0f, 1.0f); rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Right Of The Texture and Quad
            // Bottom Face
            rlNormal3f(0.0f, - 1.0f, 0.0f);                  // Normal Pointing Down
            rlTexCoord2f(1.0f, 1.0f); rlVertex3f(x - width/2, y - height/2, z - length/2);  // Top Right Of The Texture and Quad
            rlTexCoord2f(0.0f, 1.0f); rlVertex3f(x + width/2, y - height/2, z - length/2);  // Top Left Of The Texture and Quad
            rlTexCoord2f(0.0f, 0.0f); rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            rlTexCoord2f(1.0f, 0.0f); rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            // Right face
            rlNormal3f(1.0f, 0.0f, 0.0f);                  // Normal Pointing Right
            rlTexCoord2f(1.0f, 0.0f); rlVertex3f(x + width/2, y - height/2, z - length/2);  // Bottom Right Of The Texture and Quad
            rlTexCoord2f(1.0f, 1.0f); rlVertex3f(x + width/2, y + height/2, z - length/2);  // Top Right Of The Texture and Quad
            rlTexCoord2f(0.0f, 1.0f); rlVertex3f(x + width/2, y + height/2, z + length/2);  // Top Left Of The Texture and Quad
            rlTexCoord2f(0.0f, 0.0f); rlVertex3f(x + width/2, y - height/2, z + length/2);  // Bottom Left Of The Texture and Quad
            // Left Face
            rlNormal3f( - 1.0f, 0.0f, 0.0f);                  // Normal Pointing Left
            rlTexCoord2f(0.0f, 0.0f); rlVertex3f(x - width/2, y - height/2, z - length/2);  // Bottom Left Of The Texture and Quad
            rlTexCoord2f(1.0f, 0.0f); rlVertex3f(x - width/2, y - height/2, z + length/2);  // Bottom Right Of The Texture and Quad
            rlTexCoord2f(1.0f, 1.0f); rlVertex3f(x - width/2, y + height/2, z + length/2);  // Top Right Of The Texture and Quad
            rlTexCoord2f(0.0f, 1.0f); rlVertex3f(x - width/2, y + height/2, z - length/2);  // Top Left Of The Texture and Quad
        rlEnd();
    //rlPopMatrix();

    rlSetTexture(0);
}

// Draw cube with texture piece applied to all faces
void DrawCubeTextureRec(Texture2D texture, Rectangle source, Vector3 position, float width, float height, float length, Color color)
{
    float x = position.x;
    float y = position.y;
    float z = position.z;
    float texWidth = cast(float)texture.width;
    float texHeight = cast(float)texture.height;

    rlCheckRenderBatchLimit(36);

    rlSetTexture(texture.id);

    rlBegin(RL_QUADS);
        rlColor4ub(color.r, color.g, color.b, color.a);

        // Front face
        rlNormal3f(0.0f, 0.0f, 1.0f);
        rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x - width/2, y - height/2, z + length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x + width/2, y - height/2, z + length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
        rlVertex3f(x + width/2, y + height/2, z + length/2);
        rlTexCoord2f(source.x/texWidth, source.y/texHeight);
        rlVertex3f(x - width/2, y + height/2, z + length/2);

        // Back face
        rlNormal3f(0.0f, 0.0f, - 1.0f);
        rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x - width/2, y - height/2, z - length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
        rlVertex3f(x - width/2, y + height/2, z - length/2);
        rlTexCoord2f(source.x/texWidth, source.y/texHeight);
        rlVertex3f(x + width/2, y + height/2, z - length/2);
        rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x + width/2, y - height/2, z - length/2);

        // Top face
        rlNormal3f(0.0f, 1.0f, 0.0f);
        rlTexCoord2f(source.x/texWidth, source.y/texHeight);
        rlVertex3f(x - width/2, y + height/2, z - length/2);
        rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x - width/2, y + height/2, z + length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x + width/2, y + height/2, z + length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
        rlVertex3f(x + width/2, y + height/2, z - length/2);

        // Bottom face
        rlNormal3f(0.0f, - 1.0f, 0.0f);
        rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
        rlVertex3f(x - width/2, y - height/2, z - length/2);
        rlTexCoord2f(source.x/texWidth, source.y/texHeight);
        rlVertex3f(x + width/2, y - height/2, z - length/2);
        rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x + width/2, y - height/2, z + length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x - width/2, y - height/2, z + length/2);

        // Right face
        rlNormal3f(1.0f, 0.0f, 0.0f);
        rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x + width/2, y - height/2, z - length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
        rlVertex3f(x + width/2, y + height/2, z - length/2);
        rlTexCoord2f(source.x/texWidth, source.y/texHeight);
        rlVertex3f(x + width/2, y + height/2, z + length/2);
        rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x + width/2, y - height/2, z + length/2);

        // Left face
        rlNormal3f( - 1.0f, 0.0f, 0.0f);
        rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x - width/2, y - height/2, z - length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight);
        rlVertex3f(x - width/2, y - height/2, z + length/2);
        rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight);
        rlVertex3f(x - width/2, y + height/2, z + length/2);
        rlTexCoord2f(source.x/texWidth, source.y/texHeight);
        rlVertex3f(x - width/2, y + height/2, z - length/2);

    rlEnd();

    rlSetTexture(0);
}

// Draw sphere
void DrawSphere(Vector3 centerPos, float radius, Color color)
{
    DrawSphereEx(centerPos, radius, 16, 16, color);
}

// Draw sphere with extended parameters
void DrawSphereEx(Vector3 centerPos, float radius, int rings, int slices, Color color)
{
    int numVertex = (rings + 2)*slices*6;
    rlCheckRenderBatchLimit(numVertex);

    rlPushMatrix();
        // NOTE: Transformation is applied in inverse order (scale -> translate)
        rlTranslatef(centerPos.x, centerPos.y, centerPos.z);
        rlScalef(radius, radius, radius);

        rlBegin(RL_TRIANGLES);
            rlColor4ub(color.r, color.g, color.b, color.a);

            for (int i = 0; i < (rings + 2); i++)
            {
                for (int j = 0; j < slices; j++)
                {
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*sinf(DEG2RAD*(360.0f*j/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*i)),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*cosf(DEG2RAD*(360.0f*j/slices)));
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*sinf(DEG2RAD*(360.0f*(j + 1)/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*cosf(DEG2RAD*(360.0f*(j + 1)/slices)));
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*sinf(DEG2RAD*(360.0f*j/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*cosf(DEG2RAD*(360.0f*j/slices)));

                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*sinf(DEG2RAD*(360.0f*j/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*i)),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*cosf(DEG2RAD*(360.0f*j/slices)));
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i)))*sinf(DEG2RAD*(360.0f*(j + 1)/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i)))*cosf(DEG2RAD*(360.0f*(j + 1)/slices)));
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*sinf(DEG2RAD*(360.0f*(j + 1)/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*cosf(DEG2RAD*(360.0f*(j + 1)/slices)));
                }
            }
        rlEnd();
    rlPopMatrix();
}

// Draw sphere wires
void DrawSphereWires(Vector3 centerPos, float radius, int rings, int slices, Color color)
{
    int numVertex = (rings + 2)*slices*6;
    rlCheckRenderBatchLimit(numVertex);

    rlPushMatrix();
        // NOTE: Transformation is applied in inverse order (scale -> translate)
        rlTranslatef(centerPos.x, centerPos.y, centerPos.z);
        rlScalef(radius, radius, radius);

        rlBegin(RL_LINES);
            rlColor4ub(color.r, color.g, color.b, color.a);

            for (int i = 0; i < (rings + 2); i++)
            {
                for (int j = 0; j < slices; j++)
                {
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*sinf(DEG2RAD*(360.0f*j/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*i)),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*cosf(DEG2RAD*(360.0f*j/slices)));
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*sinf(DEG2RAD*(360.0f*(j + 1)/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*cosf(DEG2RAD*(360.0f*(j + 1)/slices)));

                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*sinf(DEG2RAD*(360.0f*(j + 1)/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*cosf(DEG2RAD*(360.0f*(j + 1)/slices)));
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*sinf(DEG2RAD*(360.0f*j/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*cosf(DEG2RAD*(360.0f*j/slices)));

                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*sinf(DEG2RAD*(360.0f*j/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1))),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*(i + 1)))*cosf(DEG2RAD*(360.0f*j/slices)));
                    rlVertex3f(cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*sinf(DEG2RAD*(360.0f*j/slices)),
                               sinf(DEG2RAD*(270 + (180.0f/(rings + 1))*i)),
                               cosf(DEG2RAD*(270 + (180.0f/(rings + 1))*i))*cosf(DEG2RAD*(360.0f*j/slices)));
                }
            }
        rlEnd();
    rlPopMatrix();
}

// Draw a cylinder
// NOTE: It could be also used for pyramid and cone
void DrawCylinder(Vector3 position, float radiusTop, float radiusBottom, float height, int sides, Color color)
{
    if (sides < 3) sides = 3;

    int numVertex = sides*6;
    rlCheckRenderBatchLimit(numVertex);

    rlPushMatrix();
        rlTranslatef(position.x, position.y, position.z);

        rlBegin(RL_TRIANGLES);
            rlColor4ub(color.r, color.g, color.b, color.a);

            if (radiusTop > 0)
            {
                // Draw Body -------------------------------------------------------------------------------------
                for (int i = 0; i < 360; i += 360/sides)
                {
                    rlVertex3f(sinf(DEG2RAD*i)*radiusBottom, 0, cosf(DEG2RAD*i)*radiusBottom); //Bottom Left
                    rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusBottom, 0, cosf(DEG2RAD*(i + 360.0f/sides))*radiusBottom); //Bottom Right
                    rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusTop, height, cosf(DEG2RAD*(i + 360.0f/sides))*radiusTop); //Top Right

                    rlVertex3f(sinf(DEG2RAD*i)*radiusTop, height, cosf(DEG2RAD*i)*radiusTop); //Top Left
                    rlVertex3f(sinf(DEG2RAD*i)*radiusBottom, 0, cosf(DEG2RAD*i)*radiusBottom); //Bottom Left
                    rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusTop, height, cosf(DEG2RAD*(i + 360.0f/sides))*radiusTop); //Top Right
                }

                // Draw Cap --------------------------------------------------------------------------------------
                for (int i = 0; i < 360; i += 360/sides)
                {
                    rlVertex3f(0, height, 0);
                    rlVertex3f(sinf(DEG2RAD*i)*radiusTop, height, cosf(DEG2RAD*i)*radiusTop);
                    rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusTop, height, cosf(DEG2RAD*(i + 360.0f/sides))*radiusTop);
                }
            }
            else
            {
                // Draw Cone -------------------------------------------------------------------------------------
                for (int i = 0; i < 360; i += 360/sides)
                {
                    rlVertex3f(0, height, 0);
                    rlVertex3f(sinf(DEG2RAD*i)*radiusBottom, 0, cosf(DEG2RAD*i)*radiusBottom);
                    rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusBottom, 0, cosf(DEG2RAD*(i + 360.0f/sides))*radiusBottom);
                }
            }

            // Draw Base -----------------------------------------------------------------------------------------
            for (int i = 0; i < 360; i += 360/sides)
            {
                rlVertex3f(0, 0, 0);
                rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusBottom, 0, cosf(DEG2RAD*(i + 360.0f/sides))*radiusBottom);
                rlVertex3f(sinf(DEG2RAD*i)*radiusBottom, 0, cosf(DEG2RAD*i)*radiusBottom);
            }
        rlEnd();
    rlPopMatrix();
}

// Draw a cylinder with base at startPos and top at endPos
// NOTE: It could be also used for pyramid and cone
void DrawCylinderEx(Vector3 startPos, Vector3 endPos, float startRadius, float endRadius, int sides, Color color)
{
    if (sides < 3) sides = 3;

    int numVertex = sides*6;
    rlCheckRenderBatchLimit(numVertex);

    Vector3 direction = { endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z };
    if ((direction.x == 0) && (direction.y == 0) && (direction.z == 0)) return;

    // Construct a basis of the base and the top face:
    Vector3 b1 = Vector3Normalize(Vector3Perpendicular(direction));
    Vector3 b2 = Vector3Normalize(Vector3CrossProduct(b1, direction));

    float baseAngle = (2.0f*PI)/sides;

    rlBegin(RL_TRIANGLES);
        rlColor4ub(color.r, color.g, color.b, color.a);

        for (int i = 0; i < sides; i++) {
            // compute the four vertices
            float s1 = sinf(baseAngle*(i + 0))*startRadius;
            float c1 = cosf(baseAngle*(i + 0))*startRadius;
            Vector3 w1 = { startPos.x + s1*b1.x + c1*b2.x, startPos.y + s1*b1.y + c1*b2.y, startPos.z + s1*b1.z + c1*b2.z };
            float s2 = sinf(baseAngle*(i + 1))*startRadius;
            float c2 = cosf(baseAngle*(i + 1))*startRadius;
            Vector3 w2 = { startPos.x + s2*b1.x + c2*b2.x, startPos.y + s2*b1.y + c2*b2.y, startPos.z + s2*b1.z + c2*b2.z };
            float s3 = sinf(baseAngle*(i + 0))*endRadius;
            float c3 = cosf(baseAngle*(i + 0))*endRadius;
            Vector3 w3 = { endPos.x + s3*b1.x + c3*b2.x, endPos.y + s3*b1.y + c3*b2.y, endPos.z + s3*b1.z + c3*b2.z };
            float s4 = sinf(baseAngle*(i + 1))*endRadius;
            float c4 = cosf(baseAngle*(i + 1))*endRadius;
            Vector3 w4 = { endPos.x + s4*b1.x + c4*b2.x, endPos.y + s4*b1.y + c4*b2.y, endPos.z + s4*b1.z + c4*b2.z };

            if (startRadius > 0) {                              //
                rlVertex3f(startPos.x, startPos.y, startPos.z); // |
                rlVertex3f(w2.x, w2.y, w2.z);                   // T0
                rlVertex3f(w1.x, w1.y, w1.z);                   // |
            }                                                   //
                                                                //          w2 x.-----------x startPos
            rlVertex3f(w1.x, w1.y, w1.z);                       // |           |\'.  T0    /
            rlVertex3f(w2.x, w2.y, w2.z);                       // T1          | \ '.     /
            rlVertex3f(w3.x, w3.y, w3.z);                       // |           |T \  '.  /
                                                                //             | 2 \ T 'x w1
            rlVertex3f(w2.x, w2.y, w2.z);                       // |        w4 x.---\-1-|---x endPos
            rlVertex3f(w4.x, w4.y, w4.z);                       // T2            '.  \  |T3/
            rlVertex3f(w3.x, w3.y, w3.z);                       // |               '. \ | /
                                                                //                   '.\|/
            if (endRadius > 0) {                                //                     'x w3
                rlVertex3f(endPos.x, endPos.y, endPos.z);       // |
                rlVertex3f(w3.x, w3.y, w3.z);                   // T3
                rlVertex3f(w4.x, w4.y, w4.z);                   // |
            }                                                   //
        }
    rlEnd();
}

// Draw a wired cylinder
// NOTE: It could be also used for pyramid and cone
void DrawCylinderWires(Vector3 position, float radiusTop, float radiusBottom, float height, int sides, Color color)
{
    if (sides < 3) sides = 3;

    int numVertex = sides*8;
    rlCheckRenderBatchLimit(numVertex);

    rlPushMatrix();
        rlTranslatef(position.x, position.y, position.z);

        rlBegin(RL_LINES);
            rlColor4ub(color.r, color.g, color.b, color.a);

            for (int i = 0; i < 360; i += 360/sides)
            {
                rlVertex3f(sinf(DEG2RAD*i)*radiusBottom, 0, cosf(DEG2RAD*i)*radiusBottom);
                rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusBottom, 0, cosf(DEG2RAD*(i + 360.0f/sides))*radiusBottom);

                rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusBottom, 0, cosf(DEG2RAD*(i + 360.0f/sides))*radiusBottom);
                rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusTop, height, cosf(DEG2RAD*(i + 360.0f/sides))*radiusTop);

                rlVertex3f(sinf(DEG2RAD*(i + 360.0f/sides))*radiusTop, height, cosf(DEG2RAD*(i + 360.0f/sides))*radiusTop);
                rlVertex3f(sinf(DEG2RAD*i)*radiusTop, height, cosf(DEG2RAD*i)*radiusTop);

                rlVertex3f(sinf(DEG2RAD*i)*radiusTop, height, cosf(DEG2RAD*i)*radiusTop);
                rlVertex3f(sinf(DEG2RAD*i)*radiusBottom, 0, cosf(DEG2RAD*i)*radiusBottom);
            }
        rlEnd();
    rlPopMatrix();
}


// Draw a wired cylinder with base at startPos and top at endPos
// NOTE: It could be also used for pyramid and cone
void DrawCylinderWiresEx(Vector3 startPos, Vector3 endPos, float startRadius, float endRadius, int sides, Color color)
{
    if (sides < 3) sides = 3;

    int numVertex = sides*6;
    rlCheckRenderBatchLimit(numVertex);

    Vector3 direction = { endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z };
    if ((direction.x == 0) && (direction.y == 0) && (direction.z == 0))return;

    // Construct a basis of the base and the top face:
    Vector3 b1 = Vector3Normalize(Vector3Perpendicular(direction));
    Vector3 b2 = Vector3Normalize(Vector3CrossProduct(b1, direction));

    float baseAngle = (2.0f*PI)/sides;

    rlBegin(RL_LINES);
        rlColor4ub(color.r, color.g, color.b, color.a);

        for (int i = 0; i < sides; i++) {
            // compute the four vertices
            float s1 = sinf(baseAngle*(i + 0))*startRadius;
            float c1 = cosf(baseAngle*(i + 0))*startRadius;
            Vector3 w1 = { startPos.x + s1*b1.x + c1*b2.x, startPos.y + s1*b1.y + c1*b2.y, startPos.z + s1*b1.z + c1*b2.z };
            float s2 = sinf(baseAngle*(i + 1))*startRadius;
            float c2 = cosf(baseAngle*(i + 1))*startRadius;
            Vector3 w2 = { startPos.x + s2*b1.x + c2*b2.x, startPos.y + s2*b1.y + c2*b2.y, startPos.z + s2*b1.z + c2*b2.z };
            float s3 = sinf(baseAngle*(i + 0))*endRadius;
            float c3 = cosf(baseAngle*(i + 0))*endRadius;
            Vector3 w3 = { endPos.x + s3*b1.x + c3*b2.x, endPos.y + s3*b1.y + c3*b2.y, endPos.z + s3*b1.z + c3*b2.z };
            float s4 = sinf(baseAngle*(i + 1))*endRadius;
            float c4 = cosf(baseAngle*(i + 1))*endRadius;
            Vector3 w4 = { endPos.x + s4*b1.x + c4*b2.x, endPos.y + s4*b1.y + c4*b2.y, endPos.z + s4*b1.z + c4*b2.z };

            rlVertex3f(w1.x, w1.y, w1.z);
            rlVertex3f(w2.x, w2.y, w2.z);

            rlVertex3f(w1.x, w1.y, w1.z);
            rlVertex3f(w3.x, w3.y, w3.z);

            rlVertex3f(w3.x, w3.y, w3.z);
            rlVertex3f(w4.x, w4.y, w4.z);
        }
    rlEnd();
}


// Draw a plane
void DrawPlane(Vector3 centerPos, Vector2 size, Color color)
{
    rlCheckRenderBatchLimit(4);

    // NOTE: Plane is always created on XZ ground
    rlPushMatrix();
        rlTranslatef(centerPos.x, centerPos.y, centerPos.z);
        rlScalef(size.x, 1.0f, size.y);

        rlBegin(RL_QUADS);
            rlColor4ub(color.r, color.g, color.b, color.a);
            rlNormal3f(0.0f, 1.0f, 0.0f);

            rlVertex3f(-0.5f, 0.0f, -0.5f);
            rlVertex3f(-0.5f, 0.0f, 0.5f);
            rlVertex3f(0.5f, 0.0f, 0.5f);
            rlVertex3f(0.5f, 0.0f, -0.5f);
        rlEnd();
    rlPopMatrix();
}

// Draw a ray line
void DrawRay(Ray ray, Color color)
{
    float scale = 10000;

    rlBegin(RL_LINES);
        rlColor4ub(color.r, color.g, color.b, color.a);
        rlColor4ub(color.r, color.g, color.b, color.a);

        rlVertex3f(ray.position.x, ray.position.y, ray.position.z);
        rlVertex3f(ray.position.x + ray.direction.x*scale, ray.position.y + ray.direction.y*scale, ray.position.z + ray.direction.z*scale);
    rlEnd();
}

// Draw a grid centered at (0, 0, 0)
void DrawGrid(int slices, float spacing)
{
    int halfSlices = slices/2;

    rlCheckRenderBatchLimit((slices + 2)*4);

    rlBegin(RL_LINES);
        for (int i = -halfSlices; i <= halfSlices; i++)
        {
            if (i == 0)
            {
                rlColor3f(0.5f, 0.5f, 0.5f);
                rlColor3f(0.5f, 0.5f, 0.5f);
                rlColor3f(0.5f, 0.5f, 0.5f);
                rlColor3f(0.5f, 0.5f, 0.5f);
            }
            else
            {
                rlColor3f(0.75f, 0.75f, 0.75f);
                rlColor3f(0.75f, 0.75f, 0.75f);
                rlColor3f(0.75f, 0.75f, 0.75f);
                rlColor3f(0.75f, 0.75f, 0.75f);
            }

            rlVertex3f(cast(float)i*spacing, 0.0f, cast(float)-halfSlices*spacing);
            rlVertex3f(cast(float)i*spacing, 0.0f, cast(float)halfSlices*spacing);

            rlVertex3f(cast(float)-halfSlices*spacing, 0.0f, cast(float)i*spacing);
            rlVertex3f(cast(float)halfSlices*spacing, 0.0f, cast(float)i*spacing);
        }
    rlEnd();
}

// Load model from files (mesh and material)
Model LoadModel(const(char)* fileName)
{
    Model model = Model.init; // { 0 };

static if (SUPPORT_FILEFORMAT_OBJ) {
    if (IsFileExtension(fileName, ".obj")) model = LoadOBJ(fileName);
}
static if (SUPPORT_FILEFORMAT_IQM) {
    if (IsFileExtension(fileName, ".iqm")) model = LoadIQM(fileName);
}
static if (SUPPORT_FILEFORMAT_GLTF) {
    if (IsFileExtension(fileName, ".gltf;.glb")) model = LoadGLTF(fileName);
}
static if (SUPPORT_FILEFORMAT_VOX) {
    if (IsFileExtension(fileName, ".vox")) model = LoadVOX(fileName);
}

    // Make sure model transform is set to identity matrix!
    model.transform = MatrixIdentity();

    if (model.meshCount == 0)
    {
        model.meshCount = 1;
        model.meshes = cast(Mesh*)RL_CALLOC(model.meshCount, Mesh.sizeof);
version (SUPPORT_MESH_GENERATION) {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: [%s] Failed to load mesh data, default to cube mesh", fileName);
        model.meshes[0] = GenMeshCube(1.0f, 1.0f, 1.0f);
} else {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: [%s] Failed to load mesh data", fileName);
}
    }
    else
    {
        // Upload vertex data to GPU (static mesh)
        for (int i = 0; i < model.meshCount; i++) UploadMesh(&model.meshes[i], false);
    }

    if (model.materialCount == 0)
    {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MATERIAL: [%s] Failed to load material data, default to white material", fileName);

        model.materialCount = 1;
        model.materials = cast(Material*)RL_CALLOC(model.materialCount, Material.sizeof);
        model.materials[0] = LoadMaterialDefault();

        if (model.meshMaterial == null) model.meshMaterial = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);
    }

    return model;
}

// Load model from generated mesh
// WARNING: A shallow copy of mesh is generated, passed by value,
// as long as struct contains pointers to data and some values, we get a copy
// of mesh pointing to same data as original version... be careful!
Model LoadModelFromMesh(Mesh mesh)
{
    Model model = Model.init; // { 0 };

    model.transform = MatrixIdentity();

    model.meshCount = 1;
    model.meshes = cast(Mesh*)RL_CALLOC(model.meshCount, Mesh.sizeof);
    model.meshes[0] = mesh;

    model.materialCount = 1;
    model.materials = cast(Material*)RL_CALLOC(model.materialCount, Material.sizeof);
    model.materials[0] = LoadMaterialDefault();

    model.meshMaterial = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);
    model.meshMaterial[0] = 0;  // First material index

    return model;
}

// Unload model (meshes/materials) from memory (RAM and/or VRAM)
// NOTE: This function takes care of all model elements, for a detailed control
// over them, use UnloadMesh() and UnloadMaterial()
void UnloadModel(Model model)
{
    // Unload meshes
    for (int i = 0; i < model.meshCount; i++) UnloadMesh(model.meshes[i]);

    // Unload materials maps
    // NOTE: As the user could be sharing shaders and textures between models,
    // we don't unload the material but just free it's maps,
    // the user is responsible for freeing models shaders and textures
    for (int i = 0; i < model.materialCount; i++) RL_FREE(model.materials[i].maps);

    // Unload arrays
    RL_FREE(model.meshes);
    RL_FREE(model.materials);
    RL_FREE(model.meshMaterial);

    // Unload animation data
    RL_FREE(model.bones);
    RL_FREE(model.bindPose);

    TRACELOG(TraceLogLevel.LOG_INFO, "MODEL: Unloaded model (and meshes) from RAM and VRAM");
}

// Unload model (but not meshes) from memory (RAM and/or VRAM)
void UnloadModelKeepMeshes(Model model)
{
    // Unload materials maps
    // NOTE: As the user could be sharing shaders and textures between models,
    // we don't unload the material but just free it's maps,
    // the user is responsible for freeing models shaders and textures
    for (int i = 0; i < model.materialCount; i++) RL_FREE(model.materials[i].maps);

    // Unload arrays
    RL_FREE(model.meshes);
    RL_FREE(model.materials);
    RL_FREE(model.meshMaterial);

    // Unload animation data
    RL_FREE(model.bones);
    RL_FREE(model.bindPose);

    TRACELOG(TraceLogLevel.LOG_INFO, "MODEL: Unloaded model (but not meshes) from RAM and VRAM");
}

// Compute model bounding box limits (considers all meshes)
BoundingBox GetModelBoundingBox(Model model)
{
    BoundingBox bounds = BoundingBox.init; // { 0 };

    if (model.meshCount > 0)
    {
        Vector3 temp = Vector3.init; // { 0 };
        bounds = GetMeshBoundingBox(model.meshes[0]);

        for (int i = 1; i < model.meshCount; i++)
        {
            BoundingBox tempBounds = GetMeshBoundingBox(model.meshes[i]);

            temp.x = (bounds.min.x < tempBounds.min.x)? bounds.min.x : tempBounds.min.x;
            temp.y = (bounds.min.y < tempBounds.min.y)? bounds.min.y : tempBounds.min.y;
            temp.z = (bounds.min.z < tempBounds.min.z)? bounds.min.z : tempBounds.min.z;
            bounds.min = temp;

            temp.x = (bounds.max.x > tempBounds.max.x)? bounds.max.x : tempBounds.max.x;
            temp.y = (bounds.max.y > tempBounds.max.y)? bounds.max.y : tempBounds.max.y;
            temp.z = (bounds.max.z > tempBounds.max.z)? bounds.max.z : tempBounds.max.z;
            bounds.max = temp;
        }
    }

    return bounds;
}

// Upload vertex data into a VAO (if supported) and VBO
void UploadMesh(Mesh* mesh, bool dynamic)
{
    if (mesh.vaoId > 0)
    {
        // Check if mesh has already been loaded in GPU
        TRACELOG(TraceLogLevel.LOG_WARNING, "VAO: [ID %i] Trying to re-load an already loaded mesh", mesh.vaoId);
        return;
    }

    mesh.vboId = cast(uint*)RL_CALLOC(MAX_MESH_VERTEX_BUFFERS, uint.sizeof);

    mesh.vaoId = 0;        // Vertex Array Object
    mesh.vboId[0] = 0;     // Vertex buffer: positions
    mesh.vboId[1] = 0;     // Vertex buffer: texcoords
    mesh.vboId[2] = 0;     // Vertex buffer: normals
    mesh.vboId[3] = 0;     // Vertex buffer: colors
    mesh.vboId[4] = 0;     // Vertex buffer: tangents
    mesh.vboId[5] = 0;     // Vertex buffer: texcoords2
    mesh.vboId[6] = 0;     // Vertex buffer: indices

static if (HasVersion!"GRAPHICS_API_OPENGL_33" || HasVersion!"GRAPHICS_API_OPENGL_ES2") {
    mesh.vaoId = rlLoadVertexArray();
    rlEnableVertexArray(mesh.vaoId);

    // NOTE: Attributes must be uploaded considering default locations points

    // Enable vertex attributes: position (shader-location = 0)
    void* vertices = mesh.animVertices != null ? mesh.animVertices : mesh.vertices;
    mesh.vboId[0] = rlLoadVertexBuffer(vertices, mesh.vertexCount*3*int(float.sizeof), dynamic);
    rlSetVertexAttribute(0, 3, RL_FLOAT, 0, 0, null);
    rlEnableVertexAttribute(0);

    // Enable vertex attributes: texcoords (shader-location = 1)
    mesh.vboId[1] = rlLoadVertexBuffer(mesh.texcoords, mesh.vertexCount*2*int(float.sizeof), dynamic);
    rlSetVertexAttribute(1, 2, RL_FLOAT, 0, 0, null);
    rlEnableVertexAttribute(1);

    if (mesh.normals != null)
    {
        // Enable vertex attributes: normals (shader-location = 2)
        void* normals = mesh.animNormals != null ? mesh.animNormals : mesh.normals;
        mesh.vboId[2] = rlLoadVertexBuffer(normals, mesh.vertexCount*3*int(float.sizeof), dynamic);
        rlSetVertexAttribute(2, 3, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(2);
    }
    else
    {
        // Default color vertex attribute set to WHITE
        float[3] value = [ 1.0f, 1.0f, 1.0f ];
        rlSetVertexAttributeDefault(2, value.ptr, ShaderAttributeDataType.SHADER_ATTRIB_VEC3, 3);
        rlDisableVertexAttribute(2);
    }

    if (mesh.colors != null)
    {
        // Enable vertex attribute: color (shader-location = 3)
        mesh.vboId[3] = rlLoadVertexBuffer(mesh.colors, mesh.vertexCount*4*int(ubyte.sizeof), dynamic);
        rlSetVertexAttribute(3, 4, RL_UNSIGNED_BYTE, 1, 0, null);
        rlEnableVertexAttribute(3);
    }
    else
    {
        // Default color vertex attribute set to WHITE
        float[4] value = [ 1.0f, 1.0f, 1.0f, 1.0f ];
        rlSetVertexAttributeDefault(3, value.ptr, ShaderAttributeDataType.SHADER_ATTRIB_VEC4, 4);
        rlDisableVertexAttribute(3);
    }

    if (mesh.tangents != null)
    {
        // Enable vertex attribute: tangent (shader-location = 4)
        mesh.vboId[4] = rlLoadVertexBuffer(mesh.tangents, mesh.vertexCount*4*int(float.sizeof), dynamic);
        rlSetVertexAttribute(4, 4, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(4);
    }
    else
    {
        // Default tangents vertex attribute
        float[4] value = [ 0.0f, 0.0f, 0.0f, 0.0f ];
        rlSetVertexAttributeDefault(4, value.ptr, ShaderAttributeDataType.SHADER_ATTRIB_VEC4, 4);
        rlDisableVertexAttribute(4);
    }

    if (mesh.texcoords2 != null)
    {
        // Enable vertex attribute: texcoord2 (shader-location = 5)
        mesh.vboId[5] = rlLoadVertexBuffer(mesh.texcoords2, mesh.vertexCount*2*int(float.sizeof), dynamic);
        rlSetVertexAttribute(5, 2, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(5);
    }
    else
    {
        // Default texcoord2 vertex attribute
        float[2] value = [ 0.0f, 0.0f ];
        rlSetVertexAttributeDefault(5, value.ptr, ShaderAttributeDataType.SHADER_ATTRIB_VEC2, 2);
        rlDisableVertexAttribute(5);
    }

    if (mesh.indices != null)
    {
        mesh.vboId[6] = rlLoadVertexBufferElement(mesh.indices, mesh.triangleCount*3*int(ushort.sizeof), dynamic);
    }

    if (mesh.vaoId > 0) TRACELOG(TraceLogLevel.LOG_INFO, "VAO: [ID %i] Mesh uploaded successfully to VRAM (GPU)", mesh.vaoId);
    else TRACELOG(TraceLogLevel.LOG_INFO, "VBO: Mesh uploaded successfully to VRAM (GPU)");

    rlDisableVertexArray();
}
}

// Update mesh vertex data in GPU for a specific buffer index
void UpdateMeshBuffer(Mesh mesh, int index, void* data, int dataSize, int offset)
{
    rlUpdateVertexBuffer(mesh.vboId[index], data, dataSize, offset);
}

// Draw a 3d mesh with material and transform
void DrawMesh(Mesh mesh, Material material, Matrix transform)
{
version (GRAPHICS_API_OPENGL_11) {
    enum GL_VERTEX_ARRAY =         0x8074;
    enum GL_NORMAL_ARRAY =         0x8075;
    enum GL_COLOR_ARRAY =          0x8076;
    enum GL_TEXTURE_COORD_ARRAY =  0x8078;

    rlEnableTexture(material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].texture.id);

    rlEnableStatePointer(GL_VERTEX_ARRAY, mesh.vertices);
    rlEnableStatePointer(GL_TEXTURE_COORD_ARRAY, mesh.texcoords);
    rlEnableStatePointer(GL_NORMAL_ARRAY, mesh.normals);
    rlEnableStatePointer(GL_COLOR_ARRAY, mesh.colors);

    rlPushMatrix();
        rlMultMatrixf(MatrixToFloat(transform));
        rlColor4ub(material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.r,
                   material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.g,
                   material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.b,
                   material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.a);

        if (mesh.indices != null) rlDrawVertexArrayElements(0, mesh.triangleCount*3, mesh.indices);
        else rlDrawVertexArray(0, mesh.vertexCount);
    rlPopMatrix();

    rlDisableStatePointer(GL_VERTEX_ARRAY);
    rlDisableStatePointer(GL_TEXTURE_COORD_ARRAY);
    rlDisableStatePointer(GL_NORMAL_ARRAY);
    rlDisableStatePointer(GL_COLOR_ARRAY);

    rlDisableTexture();
}

static if (HasVersion!"GRAPHICS_API_OPENGL_33" || HasVersion!"GRAPHICS_API_OPENGL_ES2") {
    // Bind shader program
    rlEnableShader(material.shader.id);

    // Send required data to shader (matrices, values)
    //-----------------------------------------------------
    // Upload to shader material.colDiffuse
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_DIFFUSE] != -1)
    {
        float[4] values = [
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.r/255.0f,
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.g/255.0f,
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.b/255.0f,
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.a/255.0f
        ];

        rlSetUniform(material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_DIFFUSE], values.ptr, ShaderUniformDataType.SHADER_UNIFORM_VEC4, 1);
    }

    // Upload to shader material.colSpecular (if location available)
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR] != -1)
    {
        float[4] values = [
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.r/255.0f,
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.g/255.0f,
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.b/255.0f,
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.a/255.0f
        ];

        rlSetUniform(material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR], values.ptr, ShaderUniformDataType.SHADER_UNIFORM_VEC4, 1);
    }

    // Get a copy of current matrices to work with,
    // just in case stereo render is required and we need to modify them
    // NOTE: At this point the modelview matrix just contains the view matrix (camera)
    // That's because BeginMode3D() sets it and there is no model-drawing function
    // that modifies it, all use rlPushMatrix() and rlPopMatrix()
    Matrix matModel = MatrixIdentity();
    Matrix matView = rlGetMatrixModelview();
    Matrix matModelView = MatrixIdentity();
    Matrix matProjection = rlGetMatrixProjection();

    // Upload view and projection matrices (if locations available)
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_VIEW] != -1) rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_VIEW], matView);
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_PROJECTION] != -1) rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_PROJECTION], matProjection);

    // Model transformation matrix is send to shader uniform location: ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL] != -1) rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL], transform);

    // Accumulate several model transformations:
    //    transform: model transformation provided (includes DrawModel() params combined with model.transform)
    //    rlGetMatrixTransform(): rlgl internal transform matrix due to push/pop matrix stack
    matModel = MatrixMultiply(transform, rlGetMatrixTransform());

    // Get model-view matrix
    matModelView = MatrixMultiply(matModel, matView);

    // Upload model normal matrix (if locations available)
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_NORMAL] != -1) rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_NORMAL], MatrixTranspose(MatrixInvert(matModel)));
    //-----------------------------------------------------

    // Bind active texture maps (if available)
    for (int i = 0; i < MAX_MATERIAL_MAPS; i++)
    {
        if (material.maps[i].texture.id > 0)
        {
            // Select current shader texture slot
            rlActiveTextureSlot(i);

            // Enable texture for active slot
            if ((i == MaterialMapIndex.MATERIAL_MAP_IRRADIANCE) ||
                (i == MaterialMapIndex.MATERIAL_MAP_PREFILTER) ||
                (i == MaterialMapIndex.MATERIAL_MAP_CUBEMAP)) rlEnableTextureCubemap(material.maps[i].texture.id);
            else rlEnableTexture(material.maps[i].texture.id);

            rlSetUniform(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MAP_DIFFUSE + i], &i, ShaderUniformDataType.SHADER_UNIFORM_INT, 1);
        }
    }

    // Try binding vertex array objects (VAO)
    // or use VBOs if not possible
    if (!rlEnableVertexArray(mesh.vaoId))
    {
        // Bind mesh VBO data: vertex position (shader-location = 0)
        rlEnableVertexBuffer(mesh.vboId[0]);
        rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_POSITION], 3, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_POSITION]);

        // Bind mesh VBO data: vertex texcoords (shader-location = 1)
        rlEnableVertexBuffer(mesh.vboId[1]);
        rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD01], 2, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD01]);

        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_NORMAL] != -1)
        {
            // Bind mesh VBO data: vertex normals (shader-location = 2)
            rlEnableVertexBuffer(mesh.vboId[2]);
            rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_NORMAL], 3, RL_FLOAT, 0, 0, null);
            rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_NORMAL]);
        }

        // Bind mesh VBO data: vertex colors (shader-location = 3, if available)
        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR] != -1)
        {
            if (mesh.vboId[3] != 0)
            {
                rlEnableVertexBuffer(mesh.vboId[3]);
                rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR], 4, RL_UNSIGNED_BYTE, 1, 0, null);
                rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR]);
            }
            else
            {
                // Set default value for unused attribute
                // NOTE: Required when using default shader and no VAO support
                float[4] value = [ 1.0f, 1.0f, 1.0f, 1.0f ];
                rlSetVertexAttributeDefault(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR], value.ptr, ShaderAttributeDataType.SHADER_ATTRIB_VEC2, 4);
                rlDisableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR]);
            }
        }

        // Bind mesh VBO data: vertex tangents (shader-location = 4, if available)
        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT] != -1)
        {
            rlEnableVertexBuffer(mesh.vboId[4]);
            rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT], 4, RL_FLOAT, 0, 0, null);
            rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT]);
        }

        // Bind mesh VBO data: vertex texcoords2 (shader-location = 5, if available)
        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD02] != -1)
        {
            rlEnableVertexBuffer(mesh.vboId[5]);
            rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD02], 2, RL_FLOAT, 0, 0, null);
            rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD02]);
        }

        if (mesh.indices != null) rlEnableVertexBufferElement(mesh.vboId[6]);
    }

    int eyeCount = 1;
    if (rlIsStereoRenderEnabled()) eyeCount = 2;

    for (int eye = 0; eye < eyeCount; eye++)
    {
        // Calculate model-view-projection matrix (MVP)
        Matrix matModelViewProjection = MatrixIdentity();
        if (eyeCount == 1) matModelViewProjection = MatrixMultiply(matModelView, matProjection);
        else
        {
            // Setup current eye viewport (half screen width)
            rlViewport(eye*rlGetFramebufferWidth()/2, 0, rlGetFramebufferWidth()/2, rlGetFramebufferHeight());
            matModelViewProjection = MatrixMultiply(MatrixMultiply(matModelView, rlGetMatrixViewOffsetStereo(eye)), rlGetMatrixProjectionStereo(eye));
        }

        // Send combined model-view-projection matrix to shader
        rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MVP], matModelViewProjection);

        // Draw mesh
        if (mesh.indices != null) rlDrawVertexArrayElements(0, mesh.triangleCount*3, null);
        else rlDrawVertexArray(0, mesh.vertexCount);
    }

    // Unbind all binded texture maps
    for (int i = 0; i < MAX_MATERIAL_MAPS; i++)
    {
        // Select current shader texture slot
        rlActiveTextureSlot(i);

        // Disable texture for active slot
        if ((i == MaterialMapIndex.MATERIAL_MAP_IRRADIANCE) ||
            (i == MaterialMapIndex.MATERIAL_MAP_PREFILTER) ||
            (i == MaterialMapIndex.MATERIAL_MAP_CUBEMAP)) rlDisableTextureCubemap();
        else rlDisableTexture();
    }

    // Disable all possible vertex array objects (or VBOs)
    rlDisableVertexArray();
    rlDisableVertexBuffer();
    rlDisableVertexBufferElement();

    // Disable shader program
    rlDisableShader();

    // Restore rlgl internal modelview and projection matrices
    rlSetMatrixModelview(matView);
    rlSetMatrixProjection(matProjection);
}
}

// Draw multiple mesh instances with material and different transforms
void DrawMeshInstanced(Mesh mesh, Material material, Matrix* transforms, int instances)
{
static if (HasVersion!"GRAPHICS_API_OPENGL_33" || HasVersion!"GRAPHICS_API_OPENGL_ES2") {
    // Instancing required variables
    float16* instanceTransforms = null;
    uint instancesVboId = 0;

    // Bind shader program
    rlEnableShader(material.shader.id);

    // Send required data to shader (matrices, values)
    //-----------------------------------------------------
    // Upload to shader material.colDiffuse
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_DIFFUSE] != -1)
    {
        float[4] values = [
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.r/255.0f,
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.g/255.0f,
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.b/255.0f,
            cast(float)material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color.a/255.0f
        ];

        rlSetUniform(material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_DIFFUSE], values.ptr, ShaderUniformDataType.SHADER_UNIFORM_VEC4, 1);
    }

    // Upload to shader material.colSpecular (if location available)
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR] != -1)
    {
        float[4] values = [
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.r/255.0f,
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.g/255.0f,
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.b/255.0f,
            cast(float)material.maps[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR].color.a/255.0f
        ];

        rlSetUniform(material.shader.locs[ShaderLocationIndex.SHADER_LOC_COLOR_SPECULAR], values.ptr, ShaderUniformDataType.SHADER_UNIFORM_VEC4, 1);
    }

    // Get a copy of current matrices to work with,
    // just in case stereo render is required and we need to modify them
    // NOTE: At this point the modelview matrix just contains the view matrix (camera)
    // That's because BeginMode3D() sets it and there is no model-drawing function
    // that modifies it, all use rlPushMatrix() and rlPopMatrix()
    Matrix matModel = MatrixIdentity();
    Matrix matView = rlGetMatrixModelview();
    Matrix matModelView = MatrixIdentity();
    Matrix matProjection = rlGetMatrixProjection();

    // Upload view and projection matrices (if locations available)
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_VIEW] != -1) rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_VIEW], matView);
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_PROJECTION] != -1) rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_PROJECTION], matProjection);

    // Create instances buffer
    instanceTransforms = cast(float16*)RL_MALLOC(instances*float16.sizeof);

    // Fill buffer with instances transformations as float16 arrays
    for (int i = 0; i < instances; i++) instanceTransforms[i] = MatrixToFloatV(transforms[i]);

    // Enable mesh VAO to attach new buffer
    rlEnableVertexArray(mesh.vaoId);

    // This could alternatively use a static VBO and either glMapBuffer() or glBufferSubData().
    // It isn't clear which would be reliably faster in all cases and on all platforms,
    // anecdotally glMapBuffer() seems very slow (syncs) while glBufferSubData() seems
    // no faster, since we're transferring all the transform matrices anyway
    instancesVboId = rlLoadVertexBuffer(instanceTransforms, instances*int(float16.sizeof), false);

    // Instances transformation matrices are send to shader attribute location: ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL
    for (uint i = 0; i < 4; i++)
    {
        rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL] + i);
        rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL] + i, 4, RL_FLOAT, 0, Matrix.sizeof, cast(void*)(i*Vector4.sizeof));
        rlSetVertexAttributeDivisor(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MODEL] + i, 1);
    }

    rlDisableVertexBuffer();
    rlDisableVertexArray();

    // Accumulate internal matrix transform (push/pop) and view matrix
    // NOTE: In this case, model instance transformation must be computed in the shader
    matModelView = MatrixMultiply(rlGetMatrixTransform(), matView);

    // Upload model normal matrix (if locations available)
    if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_NORMAL] != -1) rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_NORMAL], MatrixTranspose(MatrixInvert(matModel)));
    //-----------------------------------------------------

    // Bind active texture maps (if available)
    for (int i = 0; i < MAX_MATERIAL_MAPS; i++)
    {
        if (material.maps[i].texture.id > 0)
        {
            // Select current shader texture slot
            rlActiveTextureSlot(i);

            // Enable texture for active slot
            if ((i == MaterialMapIndex.MATERIAL_MAP_IRRADIANCE) ||
                (i == MaterialMapIndex.MATERIAL_MAP_PREFILTER) ||
                (i == MaterialMapIndex.MATERIAL_MAP_CUBEMAP)) rlEnableTextureCubemap(material.maps[i].texture.id);
            else rlEnableTexture(material.maps[i].texture.id);

            rlSetUniform(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MAP_DIFFUSE + i], &i, ShaderUniformDataType.SHADER_UNIFORM_INT, 1);
        }
    }

    // Try binding vertex array objects (VAO)
    // or use VBOs if not possible
    if (!rlEnableVertexArray(mesh.vaoId))
    {
        // Bind mesh VBO data: vertex position (shader-location = 0)
        rlEnableVertexBuffer(mesh.vboId[0]);
        rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_POSITION], 3, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_POSITION]);

        // Bind mesh VBO data: vertex texcoords (shader-location = 1)
        rlEnableVertexBuffer(mesh.vboId[1]);
        rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD01], 2, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD01]);

        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_NORMAL] != -1)
        {
            // Bind mesh VBO data: vertex normals (shader-location = 2)
            rlEnableVertexBuffer(mesh.vboId[2]);
            rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_NORMAL], 3, RL_FLOAT, 0, 0, null);
            rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_NORMAL]);
        }

        // Bind mesh VBO data: vertex colors (shader-location = 3, if available)
        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR] != -1)
        {
            if (mesh.vboId[3] != 0)
            {
                rlEnableVertexBuffer(mesh.vboId[3]);
                rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR], 4, RL_UNSIGNED_BYTE, 1, 0, null);
                rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR]);
            }
            else
            {
                // Set default value for unused attribute
                // NOTE: Required when using default shader and no VAO support
                float[4] value = [ 1.0f, 1.0f, 1.0f, 1.0f ];
                rlSetVertexAttributeDefault(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR], value.ptr, ShaderAttributeDataType.SHADER_ATTRIB_VEC2, 4);
                rlDisableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_COLOR]);
            }
        }

        // Bind mesh VBO data: vertex tangents (shader-location = 4, if available)
        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT] != -1)
        {
            rlEnableVertexBuffer(mesh.vboId[4]);
            rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT], 4, RL_FLOAT, 0, 0, null);
            rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT]);
        }

        // Bind mesh VBO data: vertex texcoords2 (shader-location = 5, if available)
        if (material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD02] != -1)
        {
            rlEnableVertexBuffer(mesh.vboId[5]);
            rlSetVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD02], 2, RL_FLOAT, 0, 0, null);
            rlEnableVertexAttribute(material.shader.locs[ShaderLocationIndex.SHADER_LOC_VERTEX_TEXCOORD02]);
        }

        if (mesh.indices != null) rlEnableVertexBufferElement(mesh.vboId[6]);
    }

    int eyeCount = 1;
    if (rlIsStereoRenderEnabled()) eyeCount = 2;

    for (int eye = 0; eye < eyeCount; eye++)
    {
        // Calculate model-view-projection matrix (MVP)
        Matrix matModelViewProjection = MatrixIdentity();
        if (eyeCount == 1) matModelViewProjection = MatrixMultiply(matModelView, matProjection);
        else
        {
            // Setup current eye viewport (half screen width)
            rlViewport(eye*rlGetFramebufferWidth()/2, 0, rlGetFramebufferWidth()/2, rlGetFramebufferHeight());
            matModelViewProjection = MatrixMultiply(MatrixMultiply(matModelView, rlGetMatrixViewOffsetStereo(eye)), rlGetMatrixProjectionStereo(eye));
        }

        // Send combined model-view-projection matrix to shader
        rlSetUniformMatrix(material.shader.locs[ShaderLocationIndex.SHADER_LOC_MATRIX_MVP], matModelViewProjection);

        // Draw mesh instanced
        if (mesh.indices != null) rlDrawVertexArrayElementsInstanced(0, mesh.triangleCount*3, null, instances);
        else rlDrawVertexArrayInstanced(0, mesh.vertexCount, instances);
    }

    // Unbind all binded texture maps
    for (int i = 0; i < MAX_MATERIAL_MAPS; i++)
    {
        // Select current shader texture slot
        rlActiveTextureSlot(i);

        // Disable texture for active slot
        if ((i == MaterialMapIndex.MATERIAL_MAP_IRRADIANCE) ||
            (i == MaterialMapIndex.MATERIAL_MAP_PREFILTER) ||
            (i == MaterialMapIndex.MATERIAL_MAP_CUBEMAP)) rlDisableTextureCubemap();
        else rlDisableTexture();
    }

    // Disable all possible vertex array objects (or VBOs)
    rlDisableVertexArray();
    rlDisableVertexBuffer();
    rlDisableVertexBufferElement();

    // Disable shader program
    rlDisableShader();

    // Remove instance transforms buffer
    rlUnloadVertexBuffer(instancesVboId);
    RL_FREE(instanceTransforms);
}
}

// Unload mesh from memory (RAM and VRAM)
void UnloadMesh(Mesh mesh)
{
    // Unload rlgl mesh vboId data
    rlUnloadVertexArray(mesh.vaoId);

    for (int i = 0; i < MAX_MESH_VERTEX_BUFFERS; i++) rlUnloadVertexBuffer(mesh.vboId[i]);
    RL_FREE(mesh.vboId);

    RL_FREE(mesh.vertices);
    RL_FREE(mesh.texcoords);
    RL_FREE(mesh.normals);
    RL_FREE(mesh.colors);
    RL_FREE(mesh.tangents);
    RL_FREE(mesh.texcoords2);
    RL_FREE(mesh.indices);

    RL_FREE(mesh.animVertices);
    RL_FREE(mesh.animNormals);
    RL_FREE(mesh.boneWeights);
    RL_FREE(mesh.boneIds);
}

// Export mesh data to file
bool ExportMesh(Mesh mesh, const(char)* fileName)
{
    bool success = false;

    if (IsFileExtension(fileName, ".obj"))
    {
        // Estimated data size, it should be enough...
        int dataSize = mesh.vertexCount/3* cast(int)strlen("v 0000.00f 0000.00f 0000.00f") +
                       mesh.vertexCount/2* cast(int)strlen("vt 0.000f 0.00f") +
                       mesh.vertexCount/3* cast(int)strlen("vn 0.000f 0.00f 0.00f") +
                       mesh.triangleCount/3* cast(int)strlen("f 00000/00000/00000 00000/00000/00000 00000/00000/00000");

        // NOTE: Text data buffer size is estimated considering mesh data size
        char* txtData = cast(char*)RL_CALLOC(dataSize + 2000, char.sizeof);

        int byteCount = 0;
        byteCount += sprintf(txtData + byteCount, "# //////////////////////////////////////////////////////////////////////////////////\n");
        byteCount += sprintf(txtData + byteCount, "# //                                                                              //\n");
        byteCount += sprintf(txtData + byteCount, "# // rMeshOBJ exporter v1.0 - Mesh exported as triangle faces and not optimized   //\n");
        byteCount += sprintf(txtData + byteCount, "# //                                                                              //\n");
        byteCount += sprintf(txtData + byteCount, "# // more info and bugs-report:  github.com/raysan5/raylib                        //\n");
        byteCount += sprintf(txtData + byteCount, "# // feedback and support:       ray[at]raylib.com                                //\n");
        byteCount += sprintf(txtData + byteCount, "# //                                                                              //\n");
        byteCount += sprintf(txtData + byteCount, "# // Copyright (c) 2018 Ramon Santamaria (@raysan5)                               //\n");
        byteCount += sprintf(txtData + byteCount, "# //                                                                              //\n");
        byteCount += sprintf(txtData + byteCount, "# //////////////////////////////////////////////////////////////////////////////////\n\n");
        byteCount += sprintf(txtData + byteCount, "# Vertex Count:     %i\n", mesh.vertexCount);
        byteCount += sprintf(txtData + byteCount, "# Triangle Count:   %i\n\n", mesh.triangleCount);

        byteCount += sprintf(txtData + byteCount, "g mesh\n");

        for (int i = 0, v = 0; i < mesh.vertexCount; i++, v += 3)
        {
            byteCount += sprintf(txtData + byteCount, "v %.2f %.2f %.2f\n", mesh.vertices[v], mesh.vertices[v + 1], mesh.vertices[v + 2]);
        }

        for (int i = 0, v = 0; i < mesh.vertexCount; i++, v += 2)
        {
            byteCount += sprintf(txtData + byteCount, "vt %.3f %.3f\n", mesh.texcoords[v], mesh.texcoords[v + 1]);
        }

        for (int i = 0, v = 0; i < mesh.vertexCount; i++, v += 3)
        {
            byteCount += sprintf(txtData + byteCount, "vn %.3f %.3f %.3f\n", mesh.normals[v], mesh.normals[v + 1], mesh.normals[v + 2]);
        }

        for (int i = 0; i < mesh.triangleCount; i += 3)
        {
            byteCount += sprintf(txtData + byteCount, "f %i/%i/%i %i/%i/%i %i/%i/%i\n", i, i, i, i + 1, i + 1, i + 1, i + 2, i + 2, i + 2);
        }

        byteCount += sprintf(txtData + byteCount, "\n");

        // NOTE: Text data length exported is determined by '\0' (NULL) character
        success = SaveFileText(fileName, txtData);

        RL_FREE(txtData);
    }
    else if (IsFileExtension(fileName, ".raw"))
    {
        // TODO: Support additional file formats to export mesh vertex data
    }

    return success;
}


// Load materials from model file
Material* LoadMaterials(const(char)* fileName, int* materialCount)
{
    Material* materials = null;
    uint count = 0;

    // TODO: Support IQM and GLTF for materials parsing

static if (SUPPORT_FILEFORMAT_MTL) {
    if (IsFileExtension(fileName, ".mtl"))
    {
        tinyobj_material_t* mats = null;

        int result = tinyobj_parse_mtl_file(&mats, &count, fileName);
        if (result != TINYOBJ_SUCCESS) TRACELOG(TraceLogLevel.LOG_WARNING, "MATERIAL: [%s] Failed to parse materials file", fileName);

        // TODO: Process materials to return

        tinyobj_materials_free(mats, count);
    }
} else {
    TRACELOG(TraceLogLevel.LOG_WARNING, "FILEIO: [%s] Failed to load material file", fileName);
}

    // Set materials shader to default (DIFFUSE, SPECULAR, NORMAL)
    if (materials != null)
    {
        for (uint i = 0; i < count; i++)
        {
            materials[i].shader.id = rlGetShaderIdDefault();
            materials[i].shader.locs = rlGetShaderLocsDefault();
        }
    }

    *materialCount = count;
    return materials;
}

// Load default material (Supports: DIFFUSE, SPECULAR, NORMAL maps)
Material LoadMaterialDefault()
{
    Material material = Material.init; // { 0 };
    material.maps = cast(MaterialMap*)RL_CALLOC(MAX_MATERIAL_MAPS, MaterialMap.sizeof);

    // Using rlgl default shader
    material.shader.id = rlGetShaderIdDefault();
    material.shader.locs = rlGetShaderLocsDefault();

    // Using rlgl default texture (1x1 pixel, UNCOMPRESSED_R8G8B8A8, 1 mipmap)
    material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].texture = Texture2D( rlGetTextureIdDefault(), 1, 1, 1, PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 );
    //material.maps[MaterialMapIndex.MATERIAL_MAP_NORMAL].texture;         // NOTE: By default, not set
    //material.maps[MaterialMapIndex.MATERIAL_MAP_SPECULAR].texture;       // NOTE: By default, not set

    material.maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color = WHITE;    // Diffuse color
    material.maps[MaterialMapIndex.MATERIAL_MAP_SPECULAR].color = WHITE;   // Specular color

    return material;
}

// Unload material from memory
void UnloadMaterial(Material material)
{
    // Unload material shader (avoid unloading default shader, managed by raylib)
    if (material.shader.id != rlGetShaderIdDefault()) UnloadShader(material.shader);

    // Unload loaded texture maps (avoid unloading default texture, managed by raylib)
    for (int i = 0; i < MAX_MATERIAL_MAPS; i++)
    {
        if (material.maps[i].texture.id != rlGetTextureIdDefault()) rlUnloadTexture(material.maps[i].texture.id);
    }

    RL_FREE(material.maps);
}

// Set texture for a material map type (MaterialMapIndex.MATERIAL_MAP_DIFFUSE, MaterialMapIndex.MATERIAL_MAP_SPECULAR...)
// NOTE: Previous texture should be manually unloaded
void SetMaterialTexture(Material* material, int mapType, Texture2D texture)
{
    material.maps[mapType].texture = texture;
}

// Set the material for a mesh
void SetModelMeshMaterial(Model* model, int meshId, int materialId)
{
    if (meshId >= model.meshCount) TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: Id greater than mesh count");
    else if (materialId >= model.materialCount) TRACELOG(TraceLogLevel.LOG_WARNING, "MATERIAL: Id greater than material count");
    else  model.meshMaterial[meshId] = materialId;
}

// Load model animations from file
ModelAnimation* LoadModelAnimations(const(char)* fileName, uint* animCount)
{
    ModelAnimation* animations = null;

static if (SUPPORT_FILEFORMAT_IQM) {
    if (IsFileExtension(fileName, ".iqm")) animations = LoadModelAnimationsIQM(fileName, animCount);
}
static if (SUPPORT_FILEFORMAT_GLTF) {
    //if (IsFileExtension(fileName, ".gltf;.glb")) animations = LoadModelAnimationGLTF(fileName, animCount);
}

    return animations;
}

// Update model animated vertex data (positions and normals) for a given frame
// NOTE: Updated data is uploaded to GPU
void UpdateModelAnimation(Model model, ModelAnimation anim, int frame)
{
    if ((anim.frameCount > 0) && (anim.bones != null) && (anim.framePoses != null))
    {
        if (frame >= anim.frameCount) frame = frame%anim.frameCount;

        for (int m = 0; m < model.meshCount; m++)
        {
            Mesh mesh = model.meshes[m];
            if (mesh.boneIds == null || mesh.boneWeights == null)
            {
                TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: UpdateModelAnimation Mesh %i has no connection to bones",m);
                continue;
            }

            bool updated = false; // set to true when anim vertex information is updated
            Vector3 animVertex = { 0 };
            Vector3 animNormal = { 0 };

            Vector3 inTranslation = { 0 };
            Quaternion inRotation = { 0 };
            // Vector3 inScale = { 0 };

            Vector3 outTranslation = { 0 };
            Quaternion outRotation = { 0 };
            Vector3 outScale = { 0 };

            int boneId = 0;
            int boneCounter = 0;
            float boneWeight = 0.0;

            const(int) vValues = mesh.vertexCount*3;
            for (int vCounter = 0; vCounter < vValues; vCounter+=3)
            {
                mesh.animVertices[vCounter] = 0;
                mesh.animVertices[vCounter + 1] = 0;
                mesh.animVertices[vCounter + 2] = 0;

                if (mesh.animNormals!=null)
                {
                    mesh.animNormals[vCounter] = 0;
                    mesh.animNormals[vCounter + 1] = 0;
                    mesh.animNormals[vCounter + 2] = 0;
                }

                // Iterates over 4 bones per vertex
                for (int j = 0; j < 4; j++, boneCounter++)
                {
                    boneWeight = mesh.boneWeights[boneCounter];
                    // early stop when no transformation will be applied
                    if (boneWeight == 0.0f)
                    {
                        continue;
                    }
                    boneId = mesh.boneIds[boneCounter];
                    //int boneIdParent = model.bones[boneId].parent;
                    inTranslation = model.bindPose[boneId].translation;
                    inRotation = model.bindPose[boneId].rotation;
                    // inScale = model.bindPose[boneId].scale;
                    outTranslation = anim.framePoses[frame][boneId].translation;
                    outRotation = anim.framePoses[frame][boneId].rotation;
                    outScale = anim.framePoses[frame][boneId].scale;

                    // Vertices processing
                    // NOTE: We use meshes.vertices (default vertex position) to calculate meshes.animVertices (animated vertex position)
                    animVertex = Vector3( mesh.vertices[vCounter], mesh.vertices[vCounter + 1], mesh.vertices[vCounter + 2] );
                    animVertex = Vector3Multiply(animVertex, outScale);
                    animVertex = Vector3Subtract(animVertex, inTranslation);
                    animVertex = Vector3RotateByQuaternion(animVertex, QuaternionMultiply(outRotation, QuaternionInvert(inRotation)));
                    animVertex = Vector3Add(animVertex, outTranslation);
//                     animVertex = Vector3Transform(animVertex, model.transform);
                    mesh.animVertices[vCounter] += animVertex.x*boneWeight;
                    mesh.animVertices[vCounter + 1] += animVertex.y*boneWeight;
                    mesh.animVertices[vCounter + 2] += animVertex.z*boneWeight;
                    updated = true;

                    // Normals processing
                    // NOTE: We use meshes.baseNormals (default normal) to calculate meshes.normals (animated normals)
                    if (mesh.normals != null)
                    {
                        animNormal = Vector3( mesh.normals[vCounter], mesh.normals[vCounter + 1], mesh.normals[vCounter + 2] );
                        animNormal = Vector3RotateByQuaternion(animNormal, QuaternionMultiply(outRotation, QuaternionInvert(inRotation)));
                        mesh.animNormals[vCounter] += animNormal.x*boneWeight;
                        mesh.animNormals[vCounter + 1] += animNormal.y*boneWeight;
                        mesh.animNormals[vCounter + 2] += animNormal.z*boneWeight;
                    }
                }
            }

            // Upload new vertex data to GPU for model drawing
            // Only update data when values changed.
            if (updated){
                rlUpdateVertexBuffer(mesh.vboId[0], mesh.animVertices, mesh.vertexCount*3*int(float.sizeof), 0);    // Update vertex position
                rlUpdateVertexBuffer(mesh.vboId[2], mesh.animNormals, mesh.vertexCount*3*int(float.sizeof), 0);     // Update vertex normals
            }
        }
    }
}

// Unload animation array data
void UnloadModelAnimations(ModelAnimation* animations, uint count)
{
    for (uint i = 0; i < count; i++) UnloadModelAnimation(animations[i]);
    RL_FREE(animations);
}

// Unload animation data
void UnloadModelAnimation(ModelAnimation anim)
{
    for (int i = 0; i < anim.frameCount; i++) RL_FREE(anim.framePoses[i]);

    RL_FREE(anim.bones);
    RL_FREE(anim.framePoses);
}

// Check model animation skeleton match
// NOTE: Only number of bones and parent connections are checked
bool IsModelAnimationValid(Model model, ModelAnimation anim)
{
    bool result = true;

    if (model.boneCount != anim.boneCount) result = false;
    else
    {
        for (int i = 0; i < model.boneCount; i++)
        {
            if (model.bones[i].parent != anim.bones[i].parent) { result = false; break; }
        }
    }

    return result;
}

static if (SUPPORT_MESH_GENERATION) {
// Generate polygonal mesh
Mesh GenMeshPoly(int sides, float radius)
{
    Mesh mesh = { 0 };

    if (sides < 3) return mesh;

    int vertexCount = sides*3;

    // Vertices definition
    Vector3* vertices = cast(Vector3*)RL_MALLOC(vertexCount*Vector3.sizeof);

    float d = 0.0f, dStep = 360.0f/sides;
    for (int v = 0; v < vertexCount; v += 3)
    {
        vertices[v] = Vector3( 0.0f, 0.0f, 0.0f );
        vertices[v + 1] = Vector3( sinf(DEG2RAD*d)*radius, 0.0f, cosf(DEG2RAD*d)*radius );
        vertices[v + 2] = Vector3(sinf(DEG2RAD*(d+dStep))*radius, 0.0f, cosf(DEG2RAD*(d+dStep))*radius );
        d += dStep;
    }

    // Normals definition
    Vector3* normals = cast(Vector3*)RL_MALLOC(vertexCount*Vector3.sizeof);
    for (int n = 0; n < vertexCount; n++) normals[n] = Vector3( 0.0f, 1.0f, 0.0f );   // Vector3.up;

    // TexCoords definition
    Vector2* texcoords = cast(Vector2*)RL_MALLOC(vertexCount*Vector2.sizeof);
    for (int n = 0; n < vertexCount; n++) texcoords[n] = Vector2( 0.0f, 0.0f );

    mesh.vertexCount = vertexCount;
    mesh.triangleCount = sides;
    mesh.vertices = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));
    mesh.texcoords = cast(float*)RL_MALLOC(mesh.vertexCount*2*int(float.sizeof));
    mesh.normals = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));

    // Mesh vertices position array
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        mesh.vertices[3*i] = vertices[i].x;
        mesh.vertices[3*i + 1] = vertices[i].y;
        mesh.vertices[3*i + 2] = vertices[i].z;
    }

    // Mesh texcoords array
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        mesh.texcoords[2*i] = texcoords[i].x;
        mesh.texcoords[2*i + 1] = texcoords[i].y;
    }

    // Mesh normals array
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        mesh.normals[3*i] = normals[i].x;
        mesh.normals[3*i + 1] = normals[i].y;
        mesh.normals[3*i + 2] = normals[i].z;
    }

    RL_FREE(vertices);
    RL_FREE(normals);
    RL_FREE(texcoords);

    // Upload vertex data to GPU (static mesh)
    // NOTE: mesh.vboId array is allocated inside UploadMesh()
    UploadMesh(&mesh, false);

    return mesh;
}

version = CUSTOM_MESH_GEN_PLANE;

// Generate plane mesh (with subdivisions)
Mesh GenMeshPlane(float width, float length, int resX, int resZ)
{
    Mesh mesh = { 0 };

version (CUSTOM_MESH_GEN_PLANE) {
    resX++;
    resZ++;

    // Vertices definition
    int vertexCount = resX*resZ; // vertices get reused for the faces

    Vector3* vertices = cast(Vector3*)RL_MALLOC(vertexCount*Vector3.sizeof);
    for (int z = 0; z < resZ; z++)
    {
        // [-length/2, length/2]
        float zPos = (cast(float)z/(resZ - 1) - 0.5f)*length;
        for (int x = 0; x < resX; x++)
        {
            // [-width/2, width/2]
            float xPos = (cast(float)x/(resX - 1) - 0.5f)*width;
            vertices[x + z*resX] = Vector3( xPos, 0.0f, zPos );
        }
    }

    // Normals definition
    Vector3* normals = cast(Vector3*)RL_MALLOC(vertexCount*Vector3.sizeof);
    for (int n = 0; n < vertexCount; n++) normals[n] = Vector3( 0.0f, 1.0f, 0.0f );   // Vector3.up;

    // TexCoords definition
    Vector2* texcoords = cast(Vector2*)RL_MALLOC(vertexCount*Vector2.sizeof);
    for (int v = 0; v < resZ; v++)
    {
        for (int u = 0; u < resX; u++)
        {
            texcoords[u + v*resX] = Vector2( cast(float)u/(resX - 1), cast(float)v/(resZ - 1) );
        }
    }

    // Triangles definition (indices)
    int numFaces = (resX - 1)*(resZ - 1);
    int* triangles = cast(int*)RL_MALLOC(numFaces*6*int.sizeof);
    int t = 0;
    for (int face = 0; face < numFaces; face++)
    {
        // Retrieve lower left corner from face ind
        int i = face % (resX - 1) + (face/(resZ - 1)*resX);

        triangles[t++] = i + resX;
        triangles[t++] = i + 1;
        triangles[t++] = i;

        triangles[t++] = i + resX;
        triangles[t++] = i + resX + 1;
        triangles[t++] = i + 1;
    }

    mesh.vertexCount = vertexCount;
    mesh.triangleCount = numFaces*2;
    mesh.vertices = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));
    mesh.texcoords = cast(float*)RL_MALLOC(mesh.vertexCount*2*int(float.sizeof));
    mesh.normals = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));
    mesh.indices = cast(ushort*)RL_MALLOC(mesh.triangleCount*3*int(ushort.sizeof));

    // Mesh vertices position array
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        mesh.vertices[3*i] = vertices[i].x;
        mesh.vertices[3*i + 1] = vertices[i].y;
        mesh.vertices[3*i + 2] = vertices[i].z;
    }

    // Mesh texcoords array
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        mesh.texcoords[2*i] = texcoords[i].x;
        mesh.texcoords[2*i + 1] = texcoords[i].y;
    }

    // Mesh normals array
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        mesh.normals[3*i] = normals[i].x;
        mesh.normals[3*i + 1] = normals[i].y;
        mesh.normals[3*i + 2] = normals[i].z;
    }

    // Mesh indices array initialization
    for (int i = 0; i < mesh.triangleCount*3; i++) mesh.indices[i] = cast(ushort)triangles[i];

    RL_FREE(vertices);
    RL_FREE(normals);
    RL_FREE(texcoords);
    RL_FREE(triangles);

} else {       // Use par_shapes library to generate plane mesh

    par_shapes_mesh* plane = par_shapes_create_plane(resX, resZ);   // No normals/texcoords generated!!!
    par_shapes_scale(plane, width, length, 1.0f);
    float[3] rotate_floats = [1, 0, 0];
    par_shapes_rotate(plane, -PI/2.0f, args);
    par_shapes_translate(plane, -width/2, 0.0f, length/2);

    mesh.vertices = cast(float*)RL_MALLOC(plane.ntriangles*3*3*int(float.sizeof));
    mesh.texcoords = cast(float*)RL_MALLOC(plane.ntriangles*3*2*int(float.sizeof));
    mesh.normals = cast(float*)RL_MALLOC(plane.ntriangles*3*3*int(float.sizeof));

    mesh.vertexCount = plane.ntriangles*3;
    mesh.triangleCount = plane.ntriangles;

    for (int k = 0; k < mesh.vertexCount; k++)
    {
        mesh.vertices[k*3] = plane.points[plane.triangles[k]*3];
        mesh.vertices[k*3 + 1] = plane.points[plane.triangles[k]*3 + 1];
        mesh.vertices[k*3 + 2] = plane.points[plane.triangles[k]*3 + 2];

        mesh.normals[k*3] = plane.normals[plane.triangles[k]*3];
        mesh.normals[k*3 + 1] = plane.normals[plane.triangles[k]*3 + 1];
        mesh.normals[k*3 + 2] = plane.normals[plane.triangles[k]*3 + 2];

        mesh.texcoords[k*2] = plane.tcoords[plane.triangles[k]*2];
        mesh.texcoords[k*2 + 1] = plane.tcoords[plane.triangles[k]*2 + 1];
    }

    par_shapes_free_mesh(plane);
}

    // Upload vertex data to GPU (static mesh)
    UploadMesh(&mesh, false);

    return mesh;
}

version = CUSTOM_MESH_GEN_CUBE;
// Generated cuboid mesh
Mesh GenMeshCube(float width, float height, float length)
{
    Mesh mesh = { 0 };

version (CUSTOM_MESH_GEN_CUBE) {
    float[72] vertices = [
        -width/2, -height/2, length/2,
        width/2, -height/2, length/2,
        width/2, height/2, length/2,
        -width/2, height/2, length/2,
        -width/2, -height/2, -length/2,
        -width/2, height/2, -length/2,
        width/2, height/2, -length/2,
        width/2, -height/2, -length/2,
        -width/2, height/2, -length/2,
        -width/2, height/2, length/2,
        width/2, height/2, length/2,
        width/2, height/2, -length/2,
        -width/2, -height/2, -length/2,
        width/2, -height/2, -length/2,
        width/2, -height/2, length/2,
        -width/2, -height/2, length/2,
        width/2, -height/2, -length/2,
        width/2, height/2, -length/2,
        width/2, height/2, length/2,
        width/2, -height/2, length/2,
        -width/2, -height/2, -length/2,
        -width/2, -height/2, length/2,
        -width/2, height/2, length/2,
        -width/2, height/2, -length/2
    ];

    float[48] texcoords = [
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f
    ];

    float[72] normals = [
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f,-1.0f,
        0.0f, 0.0f,-1.0f,
        0.0f, 0.0f,-1.0f,
        0.0f, 0.0f,-1.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f,-1.0f, 0.0f,
        0.0f,-1.0f, 0.0f,
        0.0f,-1.0f, 0.0f,
        0.0f,-1.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f
    ];

    mesh.vertices = cast(float*)RL_MALLOC(24*3*int(float.sizeof));
    memcpy(mesh.vertices, vertices.ptr, 24*3*int(float.sizeof));

    mesh.texcoords = cast(float*)RL_MALLOC(24*2*int(float.sizeof));
    memcpy(mesh.texcoords, texcoords.ptr, 24*2*int(float.sizeof));

    mesh.normals = cast(float*)RL_MALLOC(24*3*int(float.sizeof));
    memcpy(mesh.normals, normals.ptr, 24*3*int(float.sizeof));

    mesh.indices = cast(ushort*)RL_MALLOC(36*int(ushort.sizeof));

    ubyte k = 0;

    // Indices can be initialized right now
    for (int i = 0; i < 36; i+=6)
    {
        mesh.indices[i] = 4*k;
        mesh.indices[i+1] = 4*k+1;
        mesh.indices[i+2] = 4*k+2;
        mesh.indices[i+3] = 4*k;
        mesh.indices[i+4] = 4*k+2;
        mesh.indices[i+5] = 4*k+3;

        k++;
    }

    mesh.vertexCount = 24;
    mesh.triangleCount = 12;

} else {               // Use par_shapes library to generate cube mesh
/*
// Platonic solids:
par_shapes_mesh* par_shapes_create_tetrahedron();       // 4 sides polyhedron (pyramid)
par_shapes_mesh* par_shapes_create_cube();              // 6 sides polyhedron (cube)
par_shapes_mesh* par_shapes_create_octahedron();        // 8 sides polyhedron (dyamond)
par_shapes_mesh* par_shapes_create_dodecahedron();      // 12 sides polyhedron
par_shapes_mesh* par_shapes_create_icosahedron();       // 20 sides polyhedron
*/
    // Platonic solid generation: cube (6 sides)
    // NOTE: No normals/texcoords generated by default
    par_shapes_mesh* cube = par_shapes_create_cube();
    cube.tcoords = mixin(PAR_MALLOC!(`float`, `2*cube.npoints`));
    for (int i = 0; i < 2*cube.npoints; i++) cube.tcoords[i] = 0.0f;
    par_shapes_scale(cube, width, height, length);
    par_shapes_translate(cube, -width/2, 0.0f, -length/2);
    par_shapes_compute_normals(cube);

    mesh.vertices = cast(float*)RL_MALLOC(cube.ntriangles*3*3*int(float.sizeof));
    mesh.texcoords = cast(float*)RL_MALLOC(cube.ntriangles*3*2*int(float.sizeof));
    mesh.normals = cast(float*)RL_MALLOC(cube.ntriangles*3*3*int(float.sizeof));

    mesh.vertexCount = cube.ntriangles*3;
    mesh.triangleCount = cube.ntriangles;

    for (int k = 0; k < mesh.vertexCount; k++)
    {
        mesh.vertices[k*3] = cube.points[cube.triangles[k]*3];
        mesh.vertices[k*3 + 1] = cube.points[cube.triangles[k]*3 + 1];
        mesh.vertices[k*3 + 2] = cube.points[cube.triangles[k]*3 + 2];

        mesh.normals[k*3] = cube.normals[cube.triangles[k]*3];
        mesh.normals[k*3 + 1] = cube.normals[cube.triangles[k]*3 + 1];
        mesh.normals[k*3 + 2] = cube.normals[cube.triangles[k]*3 + 2];

        mesh.texcoords[k*2] = cube.tcoords[cube.triangles[k]*2];
        mesh.texcoords[k*2 + 1] = cube.tcoords[cube.triangles[k]*2 + 1];
    }

    par_shapes_free_mesh(cube);
}

    // Upload vertex data to GPU (static mesh)
    UploadMesh(&mesh, false);

    return mesh;
}

// Generate sphere mesh (standard sphere)
Mesh GenMeshSphere(float radius, int rings, int slices)
{
    Mesh mesh = { 0 };

    if ((rings >= 3) && (slices >= 3))
    {
        par_shapes_mesh* sphere = par_shapes_create_parametric_sphere(slices, rings);
        par_shapes_scale(sphere, radius, radius, radius);
        // NOTE: Soft normals are computed internally

        mesh.vertices = cast(float*)RL_MALLOC(sphere.ntriangles*3*3*int(float.sizeof));
        mesh.texcoords = cast(float*)RL_MALLOC(sphere.ntriangles*3*2*int(float.sizeof));
        mesh.normals = cast(float*)RL_MALLOC(sphere.ntriangles*3*3*int(float.sizeof));

        mesh.vertexCount = sphere.ntriangles*3;
        mesh.triangleCount = sphere.ntriangles;

        for (int k = 0; k < mesh.vertexCount; k++)
        {
            mesh.vertices[k*3] = sphere.points[sphere.triangles[k]*3];
            mesh.vertices[k*3 + 1] = sphere.points[sphere.triangles[k]*3 + 1];
            mesh.vertices[k*3 + 2] = sphere.points[sphere.triangles[k]*3 + 2];

            mesh.normals[k*3] = sphere.normals[sphere.triangles[k]*3];
            mesh.normals[k*3 + 1] = sphere.normals[sphere.triangles[k]*3 + 1];
            mesh.normals[k*3 + 2] = sphere.normals[sphere.triangles[k]*3 + 2];

            mesh.texcoords[k*2] = sphere.tcoords[sphere.triangles[k]*2];
            mesh.texcoords[k*2 + 1] = sphere.tcoords[sphere.triangles[k]*2 + 1];
        }

        par_shapes_free_mesh(sphere);

        // Upload vertex data to GPU (static mesh)
        UploadMesh(&mesh, false);
    }
    else TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: Failed to generate mesh: sphere");

    return mesh;
}

// Generate hemi-sphere mesh (half sphere, no bottom cap)
Mesh GenMeshHemiSphere(float radius, int rings, int slices)
{
    Mesh mesh = { 0 };

    if ((rings >= 3) && (slices >= 3))
    {
        if (radius < 0.0f) radius = 0.0f;

        par_shapes_mesh* sphere = par_shapes_create_hemisphere(slices, rings);
        par_shapes_scale(sphere, radius, radius, radius);
        // NOTE: Soft normals are computed internally

        mesh.vertices = cast(float*)RL_MALLOC(sphere.ntriangles*3*3*int(float.sizeof));
        mesh.texcoords = cast(float*)RL_MALLOC(sphere.ntriangles*3*2*int(float.sizeof));
        mesh.normals = cast(float*)RL_MALLOC(sphere.ntriangles*3*3*int(float.sizeof));

        mesh.vertexCount = sphere.ntriangles*3;
        mesh.triangleCount = sphere.ntriangles;

        for (int k = 0; k < mesh.vertexCount; k++)
        {
            mesh.vertices[k*3] = sphere.points[sphere.triangles[k]*3];
            mesh.vertices[k*3 + 1] = sphere.points[sphere.triangles[k]*3 + 1];
            mesh.vertices[k*3 + 2] = sphere.points[sphere.triangles[k]*3 + 2];

            mesh.normals[k*3] = sphere.normals[sphere.triangles[k]*3];
            mesh.normals[k*3 + 1] = sphere.normals[sphere.triangles[k]*3 + 1];
            mesh.normals[k*3 + 2] = sphere.normals[sphere.triangles[k]*3 + 2];

            mesh.texcoords[k*2] = sphere.tcoords[sphere.triangles[k]*2];
            mesh.texcoords[k*2 + 1] = sphere.tcoords[sphere.triangles[k]*2 + 1];
        }

        par_shapes_free_mesh(sphere);

        // Upload vertex data to GPU (static mesh)
        UploadMesh(&mesh, false);
    }
    else TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: Failed to generate mesh: hemisphere");

    return mesh;
}

// Generate cylinder mesh
Mesh GenMeshCylinder(float radius, float height, int slices)
{
    Mesh mesh = { 0 };

    if (slices >= 3)
    {
        // Instance a cylinder that sits on the Z=0 plane using the given tessellation
        // levels across the UV domain.  Think of "slices" like a number of pizza
        // slices, and "stacks" like a number of stacked rings.
        // Height and radius are both 1.0, but they can easily be changed with par_shapes_scale
        par_shapes_mesh* cylinder = par_shapes_create_cylinder(slices, 8);
        par_shapes_scale(cylinder, radius, radius, height);
        par_shapes_rotate(cylinder, -PI/2.0f, Float3( 1, 0, 0 ));
        par_shapes_rotate(cylinder, PI/2.0f, Float3( 0, 1, 0 ));

        // Generate an orientable disk shape (top cap)
        par_shapes_mesh* capTop = par_shapes_create_disk(radius, slices, Float3( 0, 0, 0 ), Float3( 0, 0, 1 ));
        capTop.tcoords = mixin(PAR_MALLOC!(`float`, `2*capTop.npoints`));
        for (int i = 0; i < 2*capTop.npoints; i++) capTop.tcoords[i] = 0.0f;
        par_shapes_rotate(capTop, -PI/2.0f, Float3( 1, 0, 0 ));
        par_shapes_translate(capTop, 0, height, 0);

        // Generate an orientable disk shape (bottom cap)
        par_shapes_mesh* capBottom = par_shapes_create_disk(radius, slices, Float3( 0, 0, 0 ), Float3( 0, 0, -1 ));
        capBottom.tcoords = mixin(PAR_MALLOC!(`float`, `2*capBottom.npoints`));
        for (int i = 0; i < 2*capBottom.npoints; i++) capBottom.tcoords[i] = 0.95f;
        par_shapes_rotate(capBottom, PI/2.0f, Float3( 1, 0, 0 ));

        par_shapes_merge_and_free(cylinder, capTop);
        par_shapes_merge_and_free(cylinder, capBottom);

        mesh.vertices = cast(float*)RL_MALLOC(cylinder.ntriangles*3*3*int(float.sizeof));
        mesh.texcoords = cast(float*)RL_MALLOC(cylinder.ntriangles*3*2*int(float.sizeof));
        mesh.normals = cast(float*)RL_MALLOC(cylinder.ntriangles*3*3*int(float.sizeof));

        mesh.vertexCount = cylinder.ntriangles*3;
        mesh.triangleCount = cylinder.ntriangles;

        for (int k = 0; k < mesh.vertexCount; k++)
        {
            mesh.vertices[k*3] = cylinder.points[cylinder.triangles[k]*3];
            mesh.vertices[k*3 + 1] = cylinder.points[cylinder.triangles[k]*3 + 1];
            mesh.vertices[k*3 + 2] = cylinder.points[cylinder.triangles[k]*3 + 2];

            mesh.normals[k*3] = cylinder.normals[cylinder.triangles[k]*3];
            mesh.normals[k*3 + 1] = cylinder.normals[cylinder.triangles[k]*3 + 1];
            mesh.normals[k*3 + 2] = cylinder.normals[cylinder.triangles[k]*3 + 2];

            mesh.texcoords[k*2] = cylinder.tcoords[cylinder.triangles[k]*2];
            mesh.texcoords[k*2 + 1] = cylinder.tcoords[cylinder.triangles[k]*2 + 1];
        }

        par_shapes_free_mesh(cylinder);

        // Upload vertex data to GPU (static mesh)
        UploadMesh(&mesh, false);
    }
    else TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: Failed to generate mesh: cylinder");

    return mesh;
}

// Generate cone/pyramid mesh
Mesh GenMeshCone(float radius, float height, int slices)
{
    Mesh mesh = { 0 };

    if (slices >= 3)
    {
        // Instance a cone that sits on the Z=0 plane using the given tessellation
        // levels across the UV domain.  Think of "slices" like a number of pizza
        // slices, and "stacks" like a number of stacked rings.
        // Height and radius are both 1.0, but they can easily be changed with par_shapes_scale
        par_shapes_mesh* cone = par_shapes_create_cone(slices, 8);
        par_shapes_scale(cone, radius, radius, height);
        par_shapes_rotate(cone, -PI/2.0f, Float3( 1, 0, 0 ));
        par_shapes_rotate(cone, PI/2.0f, Float3( 0, 1, 0 ));

        // Generate an orientable disk shape (bottom cap)
        par_shapes_mesh* capBottom = par_shapes_create_disk(radius, slices, Float3( 0, 0, 0 ), Float3( 0, 0, -1 ));
        capBottom.tcoords = mixin(PAR_MALLOC!(`float`, `2*capBottom.npoints`));
        for (int i = 0; i < 2*capBottom.npoints; i++) capBottom.tcoords[i] = 0.95f;
        par_shapes_rotate(capBottom, PI/2.0f, Float3( 1, 0, 0 ));

        par_shapes_merge_and_free(cone, capBottom);

        mesh.vertices = cast(float*)RL_MALLOC(cone.ntriangles*3*3*int(float.sizeof));
        mesh.texcoords = cast(float*)RL_MALLOC(cone.ntriangles*3*2*int(float.sizeof));
        mesh.normals = cast(float*)RL_MALLOC(cone.ntriangles*3*3*int(float.sizeof));

        mesh.vertexCount = cone.ntriangles*3;
        mesh.triangleCount = cone.ntriangles;

        for (int k = 0; k < mesh.vertexCount; k++)
        {
            mesh.vertices[k*3] = cone.points[cone.triangles[k]*3];
            mesh.vertices[k*3 + 1] = cone.points[cone.triangles[k]*3 + 1];
            mesh.vertices[k*3 + 2] = cone.points[cone.triangles[k]*3 + 2];

            mesh.normals[k*3] = cone.normals[cone.triangles[k]*3];
            mesh.normals[k*3 + 1] = cone.normals[cone.triangles[k]*3 + 1];
            mesh.normals[k*3 + 2] = cone.normals[cone.triangles[k]*3 + 2];

            mesh.texcoords[k*2] = cone.tcoords[cone.triangles[k]*2];
            mesh.texcoords[k*2 + 1] = cone.tcoords[cone.triangles[k]*2 + 1];
        }

        par_shapes_free_mesh(cone);

        // Upload vertex data to GPU (static mesh)
        UploadMesh(&mesh, false);
    }
    else TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: Failed to generate mesh: cone");

    return mesh;
}

// Generate torus mesh
Mesh GenMeshTorus(float radius, float size, int radSeg, int sides)
{
    Mesh mesh = { 0 };

    if ((sides >= 3) && (radSeg >= 3))
    {
        if (radius > 1.0f) radius = 1.0f;
        else if (radius < 0.1f) radius = 0.1f;

        // Create a donut that sits on the Z=0 plane with the specified inner radius
        // The outer radius can be controlled with par_shapes_scale
        par_shapes_mesh* torus = par_shapes_create_torus(radSeg, sides, radius);
        par_shapes_scale(torus, size/2, size/2, size/2);

        mesh.vertices = cast(float*)RL_MALLOC(torus.ntriangles*3*3*int(float.sizeof));
        mesh.texcoords = cast(float*)RL_MALLOC(torus.ntriangles*3*2*int(float.sizeof));
        mesh.normals = cast(float*)RL_MALLOC(torus.ntriangles*3*3*int(float.sizeof));

        mesh.vertexCount = torus.ntriangles*3;
        mesh.triangleCount = torus.ntriangles;

        for (int k = 0; k < mesh.vertexCount; k++)
        {
            mesh.vertices[k*3] = torus.points[torus.triangles[k]*3];
            mesh.vertices[k*3 + 1] = torus.points[torus.triangles[k]*3 + 1];
            mesh.vertices[k*3 + 2] = torus.points[torus.triangles[k]*3 + 2];

            mesh.normals[k*3] = torus.normals[torus.triangles[k]*3];
            mesh.normals[k*3 + 1] = torus.normals[torus.triangles[k]*3 + 1];
            mesh.normals[k*3 + 2] = torus.normals[torus.triangles[k]*3 + 2];

            mesh.texcoords[k*2] = torus.tcoords[torus.triangles[k]*2];
            mesh.texcoords[k*2 + 1] = torus.tcoords[torus.triangles[k]*2 + 1];
        }

        par_shapes_free_mesh(torus);

        // Upload vertex data to GPU (static mesh)
        UploadMesh(&mesh, false);
    }
    else TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: Failed to generate mesh: torus");

    return mesh;
}

// Generate trefoil knot mesh
Mesh GenMeshKnot(float radius, float size, int radSeg, int sides)
{
    Mesh mesh = { 0 };

    if ((sides >= 3) && (radSeg >= 3))
    {
        if (radius > 3.0f) radius = 3.0f;
        else if (radius < 0.5f) radius = 0.5f;

        par_shapes_mesh* knot = par_shapes_create_trefoil_knot(radSeg, sides, radius);
        par_shapes_scale(knot, size, size, size);

        mesh.vertices = cast(float*)RL_MALLOC(knot.ntriangles*3*3*int(float.sizeof));
        mesh.texcoords = cast(float*)RL_MALLOC(knot.ntriangles*3*2*int(float.sizeof));
        mesh.normals = cast(float*)RL_MALLOC(knot.ntriangles*3*3*int(float.sizeof));

        mesh.vertexCount = knot.ntriangles*3;
        mesh.triangleCount = knot.ntriangles;

        for (int k = 0; k < mesh.vertexCount; k++)
        {
            mesh.vertices[k*3] = knot.points[knot.triangles[k]*3];
            mesh.vertices[k*3 + 1] = knot.points[knot.triangles[k]*3 + 1];
            mesh.vertices[k*3 + 2] = knot.points[knot.triangles[k]*3 + 2];

            mesh.normals[k*3] = knot.normals[knot.triangles[k]*3];
            mesh.normals[k*3 + 1] = knot.normals[knot.triangles[k]*3 + 1];
            mesh.normals[k*3 + 2] = knot.normals[knot.triangles[k]*3 + 2];

            mesh.texcoords[k*2] = knot.tcoords[knot.triangles[k]*2];
            mesh.texcoords[k*2 + 1] = knot.tcoords[knot.triangles[k]*2 + 1];
        }

        par_shapes_free_mesh(knot);

        // Upload vertex data to GPU (static mesh)
        UploadMesh(&mesh, false);
    }
    else TRACELOG(TraceLogLevel.LOG_WARNING, "MESH: Failed to generate mesh: knot");

    return mesh;
}

// Generate a mesh from heightmap
// NOTE: Vertex data is uploaded to GPU
Mesh GenMeshHeightmap(Image heightmap, Vector3 size)
{
    enum string GRAY_VALUE(string c) = `((` ~ c ~ `.r+` ~ c ~ `.g+` ~ c ~ `.b)/3)`;

    Mesh mesh = { 0 };

    int mapX = heightmap.width;
    int mapZ = heightmap.height;

    Color* pixels = LoadImageColors(heightmap);

    // NOTE: One vertex per pixel
    mesh.triangleCount = (mapX-1)*(mapZ-1)*2;    // One quad every four pixels

    mesh.vertexCount = mesh.triangleCount*3;

    mesh.vertices = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));
    mesh.normals = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));
    mesh.texcoords = cast(float*)RL_MALLOC(mesh.vertexCount*2*int(float.sizeof));
    mesh.colors = null;

    int vCounter = 0;       // Used to count vertices float by float
    int tcCounter = 0;      // Used to count texcoords float by float
    int nCounter = 0;       // Used to count normals float by float

    int trisCounter = 0;

    Vector3 scaleFactor = { size.x/mapX, size.y/255.0f, size.z/mapZ };

    Vector3 vA = { 0 };
    Vector3 vB = { 0 };
    Vector3 vC = { 0 };
    Vector3 vN = { 0 };

    for (int z = 0; z < mapZ-1; z++)
    {
        for (int x = 0; x < mapX-1; x++)
        {
            // Fill vertices array with data
            //----------------------------------------------------------

            // one triangle - 3 vertex
            mesh.vertices[vCounter] = cast(float)x*scaleFactor.x;
            mesh.vertices[vCounter + 1] = cast(float)mixin(GRAY_VALUE!(`pixels[x + z*mapX]`))*scaleFactor.y;
            mesh.vertices[vCounter + 2] = cast(float)z*scaleFactor.z;

            mesh.vertices[vCounter + 3] = cast(float)x*scaleFactor.x;
            mesh.vertices[vCounter + 4] = cast(float)mixin(GRAY_VALUE!(`pixels[x + (z + 1)*mapX]`))*scaleFactor.y;
            mesh.vertices[vCounter + 5] = cast(float)(z + 1)*scaleFactor.z;

            mesh.vertices[vCounter + 6] = cast(float)(x + 1)*scaleFactor.x;
            mesh.vertices[vCounter + 7] = cast(float)mixin(GRAY_VALUE!(`pixels[(x + 1) + z*mapX]`))*scaleFactor.y;
            mesh.vertices[vCounter + 8] = cast(float)z*scaleFactor.z;

            // another triangle - 3 vertex
            mesh.vertices[vCounter + 9] = mesh.vertices[vCounter + 6];
            mesh.vertices[vCounter + 10] = mesh.vertices[vCounter + 7];
            mesh.vertices[vCounter + 11] = mesh.vertices[vCounter + 8];

            mesh.vertices[vCounter + 12] = mesh.vertices[vCounter + 3];
            mesh.vertices[vCounter + 13] = mesh.vertices[vCounter + 4];
            mesh.vertices[vCounter + 14] = mesh.vertices[vCounter + 5];

            mesh.vertices[vCounter + 15] = cast(float)(x + 1)*scaleFactor.x;
            mesh.vertices[vCounter + 16] = cast(float)mixin(GRAY_VALUE!(`pixels[(x + 1) + (z + 1)*mapX]`))*scaleFactor.y;
            mesh.vertices[vCounter + 17] = cast(float)(z + 1)*scaleFactor.z;
            vCounter += 18;     // 6 vertex, 18 floats

            // Fill texcoords array with data
            //--------------------------------------------------------------
            mesh.texcoords[tcCounter] = cast(float)x/(mapX - 1);
            mesh.texcoords[tcCounter + 1] = cast(float)z/(mapZ - 1);

            mesh.texcoords[tcCounter + 2] = cast(float)x/(mapX - 1);
            mesh.texcoords[tcCounter + 3] = cast(float)(z + 1)/(mapZ - 1);

            mesh.texcoords[tcCounter + 4] = cast(float)(x + 1)/(mapX - 1);
            mesh.texcoords[tcCounter + 5] = cast(float)z/(mapZ - 1);

            mesh.texcoords[tcCounter + 6] = mesh.texcoords[tcCounter + 4];
            mesh.texcoords[tcCounter + 7] = mesh.texcoords[tcCounter + 5];

            mesh.texcoords[tcCounter + 8] = mesh.texcoords[tcCounter + 2];
            mesh.texcoords[tcCounter + 9] = mesh.texcoords[tcCounter + 3];

            mesh.texcoords[tcCounter + 10] = cast(float)(x + 1)/(mapX - 1);
            mesh.texcoords[tcCounter + 11] = cast(float)(z + 1)/(mapZ - 1);
            tcCounter += 12;    // 6 texcoords, 12 floats

            // Fill normals array with data
            //--------------------------------------------------------------
            for (int i = 0; i < 18; i += 9)
            {
                vA.x = mesh.vertices[nCounter + i];
                vA.y = mesh.vertices[nCounter + i + 1];
                vA.z = mesh.vertices[nCounter + i + 2];

                vB.x = mesh.vertices[nCounter + i + 3];
                vB.y = mesh.vertices[nCounter + i + 4];
                vB.z = mesh.vertices[nCounter + i + 5];

                vC.x = mesh.vertices[nCounter + i + 6];
                vC.y = mesh.vertices[nCounter + i + 7];
                vC.z = mesh.vertices[nCounter + i + 8];

                vN = Vector3Normalize(Vector3CrossProduct(Vector3Subtract(vB, vA), Vector3Subtract(vC, vA)));

                mesh.normals[nCounter + i] = vN.x;
                mesh.normals[nCounter + i + 1] = vN.y;
                mesh.normals[nCounter + i + 2] = vN.z;

                mesh.normals[nCounter + i + 3] = vN.x;
                mesh.normals[nCounter + i + 4] = vN.y;
                mesh.normals[nCounter + i + 5] = vN.z;

                mesh.normals[nCounter + i + 6] = vN.x;
                mesh.normals[nCounter + i + 7] = vN.y;
                mesh.normals[nCounter + i + 8] = vN.z;
            }

            nCounter += 18;     // 6 vertex, 18 floats
            trisCounter += 2;
        }
    }

    UnloadImageColors(pixels);  // Unload pixels color data

    // Upload vertex data to GPU (static mesh)
    UploadMesh(&mesh, false);

    return mesh;
}

// Generate a cubes mesh from pixel data
// NOTE: Vertex data is uploaded to GPU
Mesh GenMeshCubicmap(Image cubicmap, Vector3 cubeSize)
{
    enum string COLOR_EQUAL(string col1, string col2) = `((` ~ col1 ~ `.r == ` ~ col2 ~ `.r)&&(` ~ col1 ~ `.g == ` ~ col2 ~ `.g)&&(` ~ col1 ~ `.b == ` ~ col2 ~ `.b)&&(` ~ col1 ~ `.a == ` ~ col2 ~ `.a))`;

    Mesh mesh = { 0 };

    Color* pixels = LoadImageColors(cubicmap);

    int mapWidth = cubicmap.width;
    int mapHeight = cubicmap.height;

    // NOTE: Max possible number of triangles numCubes*(12 triangles by cube)
    int maxTriangles = cubicmap.width*cubicmap.height*12;

    int vCounter = 0;       // Used to count vertices
    int tcCounter = 0;      // Used to count texcoords
    int nCounter = 0;       // Used to count normals

    float w = cubeSize.x;
    float h = cubeSize.z;
    float h2 = cubeSize.y;

    Vector3* mapVertices = cast(Vector3*)RL_MALLOC(maxTriangles*3*Vector3.sizeof);
    Vector2* mapTexcoords = cast(Vector2*)RL_MALLOC(maxTriangles*3*Vector2.sizeof);
    Vector3* mapNormals = cast(Vector3*)RL_MALLOC(maxTriangles*3*Vector3.sizeof);

    // Define the 6 normals of the cube, we will combine them accordingly later...
    Vector3 n1 = { 1.0f, 0.0f, 0.0f };
    Vector3 n2 = { -1.0f, 0.0f, 0.0f };
    Vector3 n3 = { 0.0f, 1.0f, 0.0f };
    Vector3 n4 = { 0.0f, -1.0f, 0.0f };
    Vector3 n5 = { 0.0f, 0.0f, -1.0f };
    Vector3 n6 = { 0.0f, 0.0f, 1.0f };

    // NOTE: We use texture rectangles to define different textures for top-bottom-front-back-right-left (6)
    struct RectangleF {
        float x = 0;
        float y = 0;
        float width = 0;
        float height = 0;
    }

    RectangleF rightTexUV = { 0.0f, 0.0f, 0.5f, 0.5f };
    RectangleF leftTexUV = { 0.5f, 0.0f, 0.5f, 0.5f };
    RectangleF frontTexUV = { 0.0f, 0.0f, 0.5f, 0.5f };
    RectangleF backTexUV = { 0.5f, 0.0f, 0.5f, 0.5f };
    RectangleF topTexUV = { 0.0f, 0.5f, 0.5f, 0.5f };
    RectangleF bottomTexUV = { 0.5f, 0.5f, 0.5f, 0.5f };

    for (int z = 0; z < mapHeight; ++z)
    {
        for (int x = 0; x < mapWidth; ++x)
        {
            // Define the 8 vertex of the cube, we will combine them accordingly later...
            Vector3 v1 = { w*(x - 0.5f), h2, h*(z - 0.5f) };
            Vector3 v2 = { w*(x - 0.5f), h2, h*(z + 0.5f) };
            Vector3 v3 = { w*(x + 0.5f), h2, h*(z + 0.5f) };
            Vector3 v4 = { w*(x + 0.5f), h2, h*(z - 0.5f) };
            Vector3 v5 = { w*(x + 0.5f), 0, h*(z - 0.5f) };
            Vector3 v6 = { w*(x - 0.5f), 0, h*(z - 0.5f) };
            Vector3 v7 = { w*(x - 0.5f), 0, h*(z + 0.5f) };
            Vector3 v8 = { w*(x + 0.5f), 0, h*(z + 0.5f) };

            // We check pixel color to be WHITE -> draw full cube
            if (mixin(COLOR_EQUAL!(`pixels[z*cubicmap.width + x]`, `WHITE`)))
            {
                // Define triangles and checking collateral cubes
                //------------------------------------------------

                // Define top triangles (2 tris, 6 vertex --> v1-v2-v3, v1-v3-v4)
                // WARNING: Not required for a WHITE cubes, created to allow seeing the map from outside
                mapVertices[vCounter] = v1;
                mapVertices[vCounter + 1] = v2;
                mapVertices[vCounter + 2] = v3;
                mapVertices[vCounter + 3] = v1;
                mapVertices[vCounter + 4] = v3;
                mapVertices[vCounter + 5] = v4;
                vCounter += 6;

                mapNormals[nCounter] = n3;
                mapNormals[nCounter + 1] = n3;
                mapNormals[nCounter + 2] = n3;
                mapNormals[nCounter + 3] = n3;
                mapNormals[nCounter + 4] = n3;
                mapNormals[nCounter + 5] = n3;
                nCounter += 6;

                mapTexcoords[tcCounter] = Vector2( topTexUV.x, topTexUV.y );
                mapTexcoords[tcCounter + 1] = Vector2( topTexUV.x, topTexUV.y + topTexUV.height );
                mapTexcoords[tcCounter + 2] = Vector2( topTexUV.x + topTexUV.width, topTexUV.y + topTexUV.height );
                mapTexcoords[tcCounter + 3] = Vector2( topTexUV.x, topTexUV.y );
                mapTexcoords[tcCounter + 4] = Vector2( topTexUV.x + topTexUV.width, topTexUV.y + topTexUV.height );
                mapTexcoords[tcCounter + 5] = Vector2( topTexUV.x + topTexUV.width, topTexUV.y );
                tcCounter += 6;

                // Define bottom triangles (2 tris, 6 vertex --> v6-v8-v7, v6-v5-v8)
                mapVertices[vCounter] = v6;
                mapVertices[vCounter + 1] = v8;
                mapVertices[vCounter + 2] = v7;
                mapVertices[vCounter + 3] = v6;
                mapVertices[vCounter + 4] = v5;
                mapVertices[vCounter + 5] = v8;
                vCounter += 6;

                mapNormals[nCounter] = n4;
                mapNormals[nCounter + 1] = n4;
                mapNormals[nCounter + 2] = n4;
                mapNormals[nCounter + 3] = n4;
                mapNormals[nCounter + 4] = n4;
                mapNormals[nCounter + 5] = n4;
                nCounter += 6;

                mapTexcoords[tcCounter] = Vector2( bottomTexUV.x + bottomTexUV.width, bottomTexUV.y );
                mapTexcoords[tcCounter + 1] = Vector2( bottomTexUV.x, bottomTexUV.y + bottomTexUV.height );
                mapTexcoords[tcCounter + 2] = Vector2( bottomTexUV.x + bottomTexUV.width, bottomTexUV.y + bottomTexUV.height );
                mapTexcoords[tcCounter + 3] = Vector2( bottomTexUV.x + bottomTexUV.width, bottomTexUV.y );
                mapTexcoords[tcCounter + 4] = Vector2( bottomTexUV.x, bottomTexUV.y );
                mapTexcoords[tcCounter + 5] = Vector2( bottomTexUV.x, bottomTexUV.y + bottomTexUV.height );
                tcCounter += 6;

                // Checking cube on bottom of current cube
                if (((z < cubicmap.height - 1) && mixin(COLOR_EQUAL!(`pixels[(z + 1)*cubicmap.width + x]`, `BLACK`))) || (z == cubicmap.height - 1))
                {
                    // Define front triangles (2 tris, 6 vertex) --> v2 v7 v3, v3 v7 v8
                    // NOTE: Collateral occluded faces are not generated
                    mapVertices[vCounter] = v2;
                    mapVertices[vCounter + 1] = v7;
                    mapVertices[vCounter + 2] = v3;
                    mapVertices[vCounter + 3] = v3;
                    mapVertices[vCounter + 4] = v7;
                    mapVertices[vCounter + 5] = v8;
                    vCounter += 6;

                    mapNormals[nCounter] = n6;
                    mapNormals[nCounter + 1] = n6;
                    mapNormals[nCounter + 2] = n6;
                    mapNormals[nCounter + 3] = n6;
                    mapNormals[nCounter + 4] = n6;
                    mapNormals[nCounter + 5] = n6;
                    nCounter += 6;

                    mapTexcoords[tcCounter] = Vector2( frontTexUV.x, frontTexUV.y );
                    mapTexcoords[tcCounter + 1] = Vector2( frontTexUV.x, frontTexUV.y + frontTexUV.height );
                    mapTexcoords[tcCounter + 2] = Vector2( frontTexUV.x + frontTexUV.width, frontTexUV.y );
                    mapTexcoords[tcCounter + 3] = Vector2( frontTexUV.x + frontTexUV.width, frontTexUV.y );
                    mapTexcoords[tcCounter + 4] = Vector2( frontTexUV.x, frontTexUV.y + frontTexUV.height );
                    mapTexcoords[tcCounter + 5] = Vector2( frontTexUV.x + frontTexUV.width, frontTexUV.y + frontTexUV.height );
                    tcCounter += 6;
                }

                // Checking cube on top of current cube
                if (((z > 0) && mixin(COLOR_EQUAL!(`pixels[(z - 1)*cubicmap.width + x]`, `BLACK`))) || (z == 0))
                {
                    // Define back triangles (2 tris, 6 vertex) --> v1 v5 v6, v1 v4 v5
                    // NOTE: Collateral occluded faces are not generated
                    mapVertices[vCounter] = v1;
                    mapVertices[vCounter + 1] = v5;
                    mapVertices[vCounter + 2] = v6;
                    mapVertices[vCounter + 3] = v1;
                    mapVertices[vCounter + 4] = v4;
                    mapVertices[vCounter + 5] = v5;
                    vCounter += 6;

                    mapNormals[nCounter] = n5;
                    mapNormals[nCounter + 1] = n5;
                    mapNormals[nCounter + 2] = n5;
                    mapNormals[nCounter + 3] = n5;
                    mapNormals[nCounter + 4] = n5;
                    mapNormals[nCounter + 5] = n5;
                    nCounter += 6;

                    mapTexcoords[tcCounter] = Vector2( backTexUV.x + backTexUV.width, backTexUV.y );
                    mapTexcoords[tcCounter + 1] = Vector2( backTexUV.x, backTexUV.y + backTexUV.height );
                    mapTexcoords[tcCounter + 2] = Vector2( backTexUV.x + backTexUV.width, backTexUV.y + backTexUV.height );
                    mapTexcoords[tcCounter + 3] = Vector2( backTexUV.x + backTexUV.width, backTexUV.y );
                    mapTexcoords[tcCounter + 4] = Vector2( backTexUV.x, backTexUV.y );
                    mapTexcoords[tcCounter + 5] = Vector2( backTexUV.x, backTexUV.y + backTexUV.height );
                    tcCounter += 6;
                }

                // Checking cube on right of current cube
                if (((x < cubicmap.width - 1) && mixin(COLOR_EQUAL!(`pixels[z*cubicmap.width + (x + 1)]`, `BLACK`))) || (x == cubicmap.width - 1))
                {
                    // Define right triangles (2 tris, 6 vertex) --> v3 v8 v4, v4 v8 v5
                    // NOTE: Collateral occluded faces are not generated
                    mapVertices[vCounter] = v3;
                    mapVertices[vCounter + 1] = v8;
                    mapVertices[vCounter + 2] = v4;
                    mapVertices[vCounter + 3] = v4;
                    mapVertices[vCounter + 4] = v8;
                    mapVertices[vCounter + 5] = v5;
                    vCounter += 6;

                    mapNormals[nCounter] = n1;
                    mapNormals[nCounter + 1] = n1;
                    mapNormals[nCounter + 2] = n1;
                    mapNormals[nCounter + 3] = n1;
                    mapNormals[nCounter + 4] = n1;
                    mapNormals[nCounter + 5] = n1;
                    nCounter += 6;

                    mapTexcoords[tcCounter] = Vector2( rightTexUV.x, rightTexUV.y );
                    mapTexcoords[tcCounter + 1] = Vector2( rightTexUV.x, rightTexUV.y + rightTexUV.height );
                    mapTexcoords[tcCounter + 2] = Vector2( rightTexUV.x + rightTexUV.width, rightTexUV.y );
                    mapTexcoords[tcCounter + 3] = Vector2( rightTexUV.x + rightTexUV.width, rightTexUV.y );
                    mapTexcoords[tcCounter + 4] = Vector2( rightTexUV.x, rightTexUV.y + rightTexUV.height );
                    mapTexcoords[tcCounter + 5] = Vector2( rightTexUV.x + rightTexUV.width, rightTexUV.y + rightTexUV.height );
                    tcCounter += 6;
                }

                // Checking cube on left of current cube
                if (((x > 0) && mixin(COLOR_EQUAL!(`pixels[z*cubicmap.width + (x - 1)]`, `BLACK`))) || (x == 0))
                {
                    // Define left triangles (2 tris, 6 vertex) --> v1 v7 v2, v1 v6 v7
                    // NOTE: Collateral occluded faces are not generated
                    mapVertices[vCounter] = v1;
                    mapVertices[vCounter + 1] = v7;
                    mapVertices[vCounter + 2] = v2;
                    mapVertices[vCounter + 3] = v1;
                    mapVertices[vCounter + 4] = v6;
                    mapVertices[vCounter + 5] = v7;
                    vCounter += 6;

                    mapNormals[nCounter] = n2;
                    mapNormals[nCounter + 1] = n2;
                    mapNormals[nCounter + 2] = n2;
                    mapNormals[nCounter + 3] = n2;
                    mapNormals[nCounter + 4] = n2;
                    mapNormals[nCounter + 5] = n2;
                    nCounter += 6;

                    mapTexcoords[tcCounter] = Vector2( leftTexUV.x, leftTexUV.y );
                    mapTexcoords[tcCounter + 1] = Vector2( leftTexUV.x + leftTexUV.width, leftTexUV.y + leftTexUV.height );
                    mapTexcoords[tcCounter + 2] = Vector2( leftTexUV.x + leftTexUV.width, leftTexUV.y );
                    mapTexcoords[tcCounter + 3] = Vector2( leftTexUV.x, leftTexUV.y );
                    mapTexcoords[tcCounter + 4] = Vector2( leftTexUV.x, leftTexUV.y + leftTexUV.height );
                    mapTexcoords[tcCounter + 5] = Vector2( leftTexUV.x + leftTexUV.width, leftTexUV.y + leftTexUV.height );
                    tcCounter += 6;
                }
            }
            // We check pixel color to be BLACK, we will only draw floor and roof
            else if (mixin(COLOR_EQUAL!(`pixels[z*cubicmap.width + x]`, `BLACK`)))
            {
                // Define top triangles (2 tris, 6 vertex --> v1-v2-v3, v1-v3-v4)
                mapVertices[vCounter] = v1;
                mapVertices[vCounter + 1] = v3;
                mapVertices[vCounter + 2] = v2;
                mapVertices[vCounter + 3] = v1;
                mapVertices[vCounter + 4] = v4;
                mapVertices[vCounter + 5] = v3;
                vCounter += 6;

                mapNormals[nCounter] = n4;
                mapNormals[nCounter + 1] = n4;
                mapNormals[nCounter + 2] = n4;
                mapNormals[nCounter + 3] = n4;
                mapNormals[nCounter + 4] = n4;
                mapNormals[nCounter + 5] = n4;
                nCounter += 6;

                mapTexcoords[tcCounter] = Vector2( topTexUV.x, topTexUV.y );
                mapTexcoords[tcCounter + 1] = Vector2( topTexUV.x + topTexUV.width, topTexUV.y + topTexUV.height );
                mapTexcoords[tcCounter + 2] = Vector2( topTexUV.x, topTexUV.y + topTexUV.height );
                mapTexcoords[tcCounter + 3] = Vector2( topTexUV.x, topTexUV.y );
                mapTexcoords[tcCounter + 4] = Vector2( topTexUV.x + topTexUV.width, topTexUV.y );
                mapTexcoords[tcCounter + 5] = Vector2( topTexUV.x + topTexUV.width, topTexUV.y + topTexUV.height );
                tcCounter += 6;

                // Define bottom triangles (2 tris, 6 vertex --> v6-v8-v7, v6-v5-v8)
                mapVertices[vCounter] = v6;
                mapVertices[vCounter + 1] = v7;
                mapVertices[vCounter + 2] = v8;
                mapVertices[vCounter + 3] = v6;
                mapVertices[vCounter + 4] = v8;
                mapVertices[vCounter + 5] = v5;
                vCounter += 6;

                mapNormals[nCounter] = n3;
                mapNormals[nCounter + 1] = n3;
                mapNormals[nCounter + 2] = n3;
                mapNormals[nCounter + 3] = n3;
                mapNormals[nCounter + 4] = n3;
                mapNormals[nCounter + 5] = n3;
                nCounter += 6;

                mapTexcoords[tcCounter] = Vector2( bottomTexUV.x + bottomTexUV.width, bottomTexUV.y );
                mapTexcoords[tcCounter + 1] = Vector2( bottomTexUV.x + bottomTexUV.width, bottomTexUV.y + bottomTexUV.height );
                mapTexcoords[tcCounter + 2] = Vector2( bottomTexUV.x, bottomTexUV.y + bottomTexUV.height );
                mapTexcoords[tcCounter + 3] = Vector2( bottomTexUV.x + bottomTexUV.width, bottomTexUV.y );
                mapTexcoords[tcCounter + 4] = Vector2( bottomTexUV.x, bottomTexUV.y + bottomTexUV.height );
                mapTexcoords[tcCounter + 5] = Vector2( bottomTexUV.x, bottomTexUV.y );
                tcCounter += 6;
            }
        }
    }

    // Move data from mapVertices temp arays to vertices float array
    mesh.vertexCount = vCounter;
    mesh.triangleCount = vCounter/3;

    mesh.vertices = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));
    mesh.normals = cast(float*)RL_MALLOC(mesh.vertexCount*3*int(float.sizeof));
    mesh.texcoords = cast(float*)RL_MALLOC(mesh.vertexCount*2*int(float.sizeof));
    mesh.colors = null;

    int fCounter = 0;

    // Move vertices data
    for (int i = 0; i < vCounter; i++)
    {
        mesh.vertices[fCounter] = mapVertices[i].x;
        mesh.vertices[fCounter + 1] = mapVertices[i].y;
        mesh.vertices[fCounter + 2] = mapVertices[i].z;
        fCounter += 3;
    }

    fCounter = 0;

    // Move normals data
    for (int i = 0; i < nCounter; i++)
    {
        mesh.normals[fCounter] = mapNormals[i].x;
        mesh.normals[fCounter + 1] = mapNormals[i].y;
        mesh.normals[fCounter + 2] = mapNormals[i].z;
        fCounter += 3;
    }

    fCounter = 0;

    // Move texcoords data
    for (int i = 0; i < tcCounter; i++)
    {
        mesh.texcoords[fCounter] = mapTexcoords[i].x;
        mesh.texcoords[fCounter + 1] = mapTexcoords[i].y;
        fCounter += 2;
    }

    RL_FREE(mapVertices);
    RL_FREE(mapNormals);
    RL_FREE(mapTexcoords);

    UnloadImageColors(pixels);   // Unload pixels color data

    // Upload vertex data to GPU (static mesh)
    UploadMesh(&mesh, false);

    return mesh;
}
}      // SUPPORT_MESH_GENERATION

// Compute mesh bounding box limits
// NOTE: minVertex and maxVertex should be transformed by model transform matrix
BoundingBox GetMeshBoundingBox(Mesh mesh)
{
    // Get min and max vertex to construct bounds (AABB)
    Vector3 minVertex = { 0 };
    Vector3 maxVertex = { 0 };

    if (mesh.vertices != null)
    {
        minVertex = Vector3( mesh.vertices[0], mesh.vertices[1], mesh.vertices[2] );
        maxVertex = Vector3( mesh.vertices[0], mesh.vertices[1], mesh.vertices[2] );

        for (int i = 1; i < mesh.vertexCount; i++)
        {
            minVertex = Vector3Min(minVertex, Vector3( mesh.vertices[i*3], mesh.vertices[i*3 + 1], mesh.vertices[i*3 + 2] ));
            maxVertex = Vector3Max(maxVertex, Vector3( mesh.vertices[i*3], mesh.vertices[i*3 + 1], mesh.vertices[i*3 + 2] ));
        }
    }

    // Create the bounding box
    BoundingBox box = BoundingBox.init; // { 0 };
    box.min = minVertex;
    box.max = maxVertex;

    return box;
}

// Compute mesh tangents
// NOTE: To calculate mesh tangents and binormals we need mesh vertex positions and texture coordinates
// Implementation base don: https://answers.unity.com/questions/7789/calculating-tangents-vector4.html
void GenMeshTangents(Mesh* mesh)
{
    if (mesh.tangents == null) mesh.tangents = cast(float*)RL_MALLOC(mesh.vertexCount*4*int(float.sizeof));
    else
    {
        RL_FREE(mesh.tangents);
        mesh.tangents = cast(float*)RL_MALLOC(mesh.vertexCount*4*int(float.sizeof));
    }

    Vector3* tan1 = cast(Vector3*)RL_MALLOC(mesh.vertexCount*Vector3.sizeof);
    Vector3* tan2 = cast(Vector3*)RL_MALLOC(mesh.vertexCount*Vector3.sizeof);

    for (int i = 0; i < mesh.vertexCount; i += 3)
    {
        // Get triangle vertices
        Vector3 v1 = { mesh.vertices[(i + 0)*3 + 0], mesh.vertices[(i + 0)*3 + 1], mesh.vertices[(i + 0)*3 + 2] };
        Vector3 v2 = { mesh.vertices[(i + 1)*3 + 0], mesh.vertices[(i + 1)*3 + 1], mesh.vertices[(i + 1)*3 + 2] };
        Vector3 v3 = { mesh.vertices[(i + 2)*3 + 0], mesh.vertices[(i + 2)*3 + 1], mesh.vertices[(i + 2)*3 + 2] };

        // Get triangle texcoords
        Vector2 uv1 = { mesh.texcoords[(i + 0)*2 + 0], mesh.texcoords[(i + 0)*2 + 1] };
        Vector2 uv2 = { mesh.texcoords[(i + 1)*2 + 0], mesh.texcoords[(i + 1)*2 + 1] };
        Vector2 uv3 = { mesh.texcoords[(i + 2)*2 + 0], mesh.texcoords[(i + 2)*2 + 1] };

        float x1 = v2.x - v1.x;
        float y1 = v2.y - v1.y;
        float z1 = v2.z - v1.z;
        float x2 = v3.x - v1.x;
        float y2 = v3.y - v1.y;
        float z2 = v3.z - v1.z;

        float s1 = uv2.x - uv1.x;
        float t1 = uv2.y - uv1.y;
        float s2 = uv3.x - uv1.x;
        float t2 = uv3.y - uv1.y;

        float div = s1*t2 - s2*t1;
        float r = (div == 0.0f)? 0.0f : 1.0f/div;

        Vector3 sdir = { (t2*x1 - t1*x2)*r, (t2*y1 - t1*y2)*r, (t2*z1 - t1*z2)*r };
        Vector3 tdir = { (s1*x2 - s2*x1)*r, (s1*y2 - s2*y1)*r, (s1*z2 - s2*z1)*r };

        tan1[i + 0] = sdir;
        tan1[i + 1] = sdir;
        tan1[i + 2] = sdir;

        tan2[i + 0] = tdir;
        tan2[i + 1] = tdir;
        tan2[i + 2] = tdir;
    }

    // Compute tangents considering normals
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        Vector3 normal = { mesh.normals[i*3 + 0], mesh.normals[i*3 + 1], mesh.normals[i*3 + 2] };
        Vector3 tangent = tan1[i];

        // TODO: Review, not sure if tangent computation is right, just used reference proposed maths...
version (COMPUTE_TANGENTS_METHOD_01) {
        Vector3 tmp = Vector3Subtract(tangent, Vector3Scale(normal, Vector3DotProduct(normal, tangent)));
        tmp = Vector3Normalize(tmp);
        mesh.tangents[i*4 + 0] = tmp.x;
        mesh.tangents[i*4 + 1] = tmp.y;
        mesh.tangents[i*4 + 2] = tmp.z;
        mesh.tangents[i*4 + 3] = 1.0f;
} else {
        Vector3OrthoNormalize(&normal, &tangent);
        mesh.tangents[i*4 + 0] = tangent.x;
        mesh.tangents[i*4 + 1] = tangent.y;
        mesh.tangents[i*4 + 2] = tangent.z;
        mesh.tangents[i*4 + 3] = (Vector3DotProduct(Vector3CrossProduct(normal, tangent), tan2[i]) < 0.0f)? -1.0f : 1.0f;
}
    }

    RL_FREE(tan1);
    RL_FREE(tan2);

    if (mesh.vboId != null)
    {
        if (mesh.vboId[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT] != 0)
        {
            // Upate existing vertex buffer
            rlUpdateVertexBuffer(mesh.vboId[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT], mesh.tangents, mesh.vertexCount*4*int(float.sizeof), 0);
        }
        else
        {
            // Load a new tangent attributes buffer
            mesh.vboId[ShaderLocationIndex.SHADER_LOC_VERTEX_TANGENT] = rlLoadVertexBuffer(mesh.tangents, mesh.vertexCount*4*int(float.sizeof), false);
        }

        rlEnableVertexArray(mesh.vaoId);
        rlSetVertexAttribute(4, 4, RL_FLOAT, 0, 0, null);
        rlEnableVertexAttribute(4);
        rlDisableVertexArray();
    }

    TRACELOG(TraceLogLevel.LOG_INFO, "MESH: Tangents data computed and uploaded for provided mesh");
}

// Compute mesh binormals (aka bitangent)
void GenMeshBinormals(Mesh* mesh)
{
    for (int i = 0; i < mesh.vertexCount; i++)
    {
        //Vector3 normal = { mesh->normals[i*3 + 0], mesh->normals[i*3 + 1], mesh->normals[i*3 + 2] };
        //Vector3 tangent = { mesh->tangents[i*4 + 0], mesh->tangents[i*4 + 1], mesh->tangents[i*4 + 2] };
        //Vector3 binormal = Vector3Scale(Vector3CrossProduct(normal, tangent), mesh->tangents[i*4 + 3]);

        // TODO: Register computed binormal in mesh->binormal?
    }
}

// Draw a model (with texture if set)
void DrawModel(Model model, Vector3 position, float scale, Color tint)
{
    Vector3 vScale = { scale, scale, scale };
    Vector3 rotationAxis = { 0.0f, 1.0f, 0.0f };

    DrawModelEx(model, position, rotationAxis, 0.0f, vScale, tint);
}

// Draw a model with extended parameters
void DrawModelEx(Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint)
{
    // Calculate transformation matrix from function parameters
    // Get transform matrix (rotation -> scale -> translation)
    Matrix matScale = MatrixScale(scale.x, scale.y, scale.z);
    Matrix matRotation = MatrixRotate(rotationAxis, rotationAngle*DEG2RAD);
    Matrix matTranslation = MatrixTranslate(position.x, position.y, position.z);

    Matrix matTransform = MatrixMultiply(MatrixMultiply(matScale, matRotation), matTranslation);

    // Combine model transformation matrix (model.transform) with matrix generated by function parameters (matTransform)
    model.transform = MatrixMultiply(model.transform, matTransform);

    for (int i = 0; i < model.meshCount; i++)
    {
        Color color = model.materials[model.meshMaterial[i]].maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color;

        Color colorTint = WHITE;
        colorTint.r = cast(ubyte)(((cast(float)color.r/255.0)*(cast(float)tint.r/255.0))*255.0f);
        colorTint.g = cast(ubyte)(((cast(float)color.g/255.0)*(cast(float)tint.g/255.0))*255.0f);
        colorTint.b = cast(ubyte)(((cast(float)color.b/255.0)*(cast(float)tint.b/255.0))*255.0f);
        colorTint.a = cast(ubyte)(((cast(float)color.a/255.0)*(cast(float)tint.a/255.0))*255.0f);

        model.materials[model.meshMaterial[i]].maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color = colorTint;
        DrawMesh(model.meshes[i], model.materials[model.meshMaterial[i]], model.transform);
        model.materials[model.meshMaterial[i]].maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color = color;
    }
}

// Draw a model wires (with texture if set)
void DrawModelWires(Model model, Vector3 position, float scale, Color tint)
{
    rlEnableWireMode();

    DrawModel(model, position, scale, tint);

    rlDisableWireMode();
}

// Draw a model wires (with texture if set) with extended parameters
void DrawModelWiresEx(Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint)
{
    rlEnableWireMode();

    DrawModelEx(model, position, rotationAxis, rotationAngle, scale, tint);

    rlDisableWireMode();
}

// Draw a billboard
void DrawBillboard(Camera camera, Texture2D texture, Vector3 position, float size, Color tint)
{
    Rectangle source = { 0.0f, 0.0f, cast(float)texture.width, cast(float)texture.height };

    DrawBillboardRec(camera, texture, source, position, Vector2( size, size ), tint);
}

// Draw a billboard (part of a texture defined by a rectangle)
void DrawBillboardRec(Camera camera, Texture2D texture, Rectangle source, Vector3 position, Vector2 size, Color tint)
{
    // NOTE: Billboard locked on axis-Y
    Vector3 up = { 0.0f, 1.0f, 0.0f };

    DrawBillboardPro(camera, texture, source, position, up, size, Vector2Zero(), 0.0f, tint);
}

void DrawBillboardPro(Camera camera, Texture2D texture, Rectangle source, Vector3 position, Vector3 up, Vector2 size, Vector2 origin, float rotation, Color tint)
{
    // NOTE: Billboard size will maintain source rectangle aspect ratio, size will represent billboard width
    Vector2 sizeRatio = { size.y, size.x*cast(float)source.height/source.width };

    Matrix matView = MatrixLookAt(camera.position, camera.target, camera.up);

    Vector3 right = { matView.m0, matView.m4, matView.m8 };
    //Vector3 up = { matView.m1, matView.m5, matView.m9 };

    Vector3 rightScaled = Vector3Scale(right, sizeRatio.x/2);
    Vector3 upScaled = Vector3Scale(up, sizeRatio.y/2);

    Vector3 p1 = Vector3Add(rightScaled, upScaled);
    Vector3 p2 = Vector3Subtract(rightScaled, upScaled);

    Vector3 topLeft = Vector3Scale(p2, -1);
    Vector3 topRight = p1;
    Vector3 bottomRight = p2;
    Vector3 bottomLeft = Vector3Scale(p1, -1);

    if (rotation != 0.0f)
    {
        float sinRotation = sinf(rotation*DEG2RAD);
        float cosRotation = cosf(rotation*DEG2RAD);

        // NOTE: (-1, 1) is the range where origin.x, origin.y is inside the texture
        float rotateAboutX = sizeRatio.x*origin.x/2;
        float rotateAboutY = sizeRatio.y*origin.y/2;

        float xtvalue = void, ytvalue = void;
        float rotatedX = void, rotatedY = void;

        xtvalue = Vector3DotProduct(right, topLeft) - rotateAboutX; // Project points to x and y coordinates on the billboard plane
        ytvalue = Vector3DotProduct(up, topLeft) - rotateAboutY;
        rotatedX = xtvalue*cosRotation - ytvalue*sinRotation + rotateAboutX; // Rotate about the point origin
        rotatedY = xtvalue*sinRotation + ytvalue*cosRotation + rotateAboutY;
        topLeft = Vector3Add(Vector3Scale(up, rotatedY), Vector3Scale(right, rotatedX)); // Translate back to cartesian coordinates

        xtvalue = Vector3DotProduct(right, topRight) - rotateAboutX;
        ytvalue = Vector3DotProduct(up, topRight) - rotateAboutY;
        rotatedX = xtvalue*cosRotation - ytvalue*sinRotation + rotateAboutX;
        rotatedY = xtvalue*sinRotation + ytvalue*cosRotation + rotateAboutY;
        topRight = Vector3Add(Vector3Scale(up, rotatedY), Vector3Scale(right, rotatedX));

        xtvalue = Vector3DotProduct(right, bottomRight) - rotateAboutX;
        ytvalue = Vector3DotProduct(up, bottomRight) - rotateAboutY;
        rotatedX = xtvalue*cosRotation - ytvalue*sinRotation + rotateAboutX;
        rotatedY = xtvalue*sinRotation + ytvalue*cosRotation + rotateAboutY;
        bottomRight = Vector3Add(Vector3Scale(up, rotatedY), Vector3Scale(right, rotatedX));

        xtvalue = Vector3DotProduct(right, bottomLeft)-rotateAboutX;
        ytvalue = Vector3DotProduct(up, bottomLeft)-rotateAboutY;
        rotatedX = xtvalue*cosRotation - ytvalue*sinRotation + rotateAboutX;
        rotatedY = xtvalue*sinRotation + ytvalue*cosRotation + rotateAboutY;
        bottomLeft = Vector3Add(Vector3Scale(up, rotatedY), Vector3Scale(right, rotatedX));
    }

    // Translate points to the draw center (position)
    topLeft = Vector3Add(topLeft, position);
    topRight = Vector3Add(topRight, position);
    bottomRight = Vector3Add(bottomRight, position);
    bottomLeft = Vector3Add(bottomLeft, position);

    rlCheckRenderBatchLimit(4);

    rlSetTexture(texture.id);

    rlBegin(RL_QUADS);
        rlColor4ub(tint.r, tint.g, tint.b, tint.a);

        // Bottom-left corner for texture and quad
        rlTexCoord2f(cast(float)source.x/texture.width, cast(float)source.y/texture.height);
        rlVertex3f(topLeft.x, topLeft.y, topLeft.z);

        // Top-left corner for texture and quad
        rlTexCoord2f(cast(float)source.x/texture.width, cast(float)(source.y + source.height)/texture.height);
        rlVertex3f(bottomLeft.x, bottomLeft.y, bottomLeft.z);

        // Top-right corner for texture and quad
        rlTexCoord2f(cast(float)(source.x + source.width)/texture.width, cast(float)(source.y + source.height)/texture.height);
        rlVertex3f(bottomRight.x, bottomRight.y, bottomRight.z);

        // Bottom-right corner for texture and quad
        rlTexCoord2f(cast(float)(source.x + source.width)/texture.width, cast(float)source.y/texture.height);
        rlVertex3f(topRight.x, topRight.y, topRight.z);
    rlEnd();

    rlSetTexture(0);
}

// Draw a bounding box with wires
void DrawBoundingBox(BoundingBox box, Color color)
{
    Vector3 size = { 0 };

    size.x = fabsf(box.max.x - box.min.x);
    size.y = fabsf(box.max.y - box.min.y);
    size.z = fabsf(box.max.z - box.min.z);

    Vector3 center = { box.min.x + size.x/2.0f, box.min.y + size.y/2.0f, box.min.z + size.z/2.0f };

    DrawCubeWires(center, size.x, size.y, size.z, color);
}

// Check collision between two spheres
bool CheckCollisionSpheres(Vector3 center1, float radius1, Vector3 center2, float radius2)
{
    bool collision = false;

    // Simple way to check for collision, just checking distance between two points
    // Unfortunately, sqrtf() is a costly operation, so we avoid it with following solution
    /*
    float dx = center1.x - center2.x;      // X distance between centers
    float dy = center1.y - center2.y;      // Y distance between centers
    float dz = center1.z - center2.z;      // Z distance between centers

    float distance = sqrtf(dx*dx + dy*dy + dz*dz);  // Distance between centers

    if (distance <= (radius1 + radius2)) collision = true;
    */

    // Check for distances squared to avoid sqrtf()
    if (Vector3DotProduct(Vector3Subtract(center2, center1), Vector3Subtract(center2, center1)) <= (radius1 + radius2)*(radius1 + radius2)) collision = true;

    return collision;
}

// Check collision between two boxes
// NOTE: Boxes are defined by two points minimum and maximum
bool CheckCollisionBoxes(BoundingBox box1, BoundingBox box2)
{
    bool collision = true;

    if ((box1.max.x >= box2.min.x) && (box1.min.x <= box2.max.x))
    {
        if ((box1.max.y < box2.min.y) || (box1.min.y > box2.max.y)) collision = false;
        if ((box1.max.z < box2.min.z) || (box1.min.z > box2.max.z)) collision = false;
    }
    else collision = false;

    return collision;
}

// Check collision between box and sphere
bool CheckCollisionBoxSphere(BoundingBox box, Vector3 center, float radius)
{
    bool collision = false;

    float dmin = 0;

    if (center.x < box.min.x) dmin += powf(center.x - box.min.x, 2);
    else if (center.x > box.max.x) dmin += powf(center.x - box.max.x, 2);

    if (center.y < box.min.y) dmin += powf(center.y - box.min.y, 2);
    else if (center.y > box.max.y) dmin += powf(center.y - box.max.y, 2);

    if (center.z < box.min.z) dmin += powf(center.z - box.min.z, 2);
    else if (center.z > box.max.z) dmin += powf(center.z - box.max.z, 2);

    if (dmin <= (radius*radius)) collision = true;

    return collision;
}

// Get collision info between ray and sphere
RayCollision GetRayCollisionSphere(Ray ray, Vector3 center, float radius)
{
    RayCollision collision = { 0 };

    Vector3 raySpherePos = Vector3Subtract(center, ray.position);
    float vector = Vector3DotProduct(raySpherePos, ray.direction);
    float distance = Vector3Length(raySpherePos);
    float d = radius*radius - (distance*distance - vector*vector);

    collision.hit = d >= 0.0f;

    // Check if ray origin is inside the sphere to calculate the correct collision point
    if (distance < radius)
    {
        collision.distance = vector + sqrtf(d);

        // Calculate collision point
        collision.point = Vector3Add(ray.position, Vector3Scale(ray.direction, collision.distance));

        // Calculate collision normal (pointing outwards)
        collision.normal = Vector3Negate(Vector3Normalize(Vector3Subtract(collision.point, center)));
    }
    else
    {
        collision.distance = vector - sqrtf(d);

        // Calculate collision point
        collision.point = Vector3Add(ray.position, Vector3Scale(ray.direction, collision.distance));

        // Calculate collision normal (pointing inwards)
        collision.normal = Vector3Normalize(Vector3Subtract(collision.point, center));
    }

    return collision;
}

// Get collision info between ray and box
RayCollision GetRayCollisionBox(Ray ray, BoundingBox box)
{
    RayCollision collision = { 0 };

    // Note: If ray.position is inside the box, the distance is negative (as if the ray was reversed)
    // Reversing ray.direction will give use the correct result.
    bool insideBox = (ray.position.x > box.min.x) && (ray.position.x < box.max.x) &&
                     (ray.position.y > box.min.y) && (ray.position.y < box.max.y) &&
                     (ray.position.z > box.min.z) && (ray.position.z < box.max.z);

    if (insideBox) ray.direction = Vector3Negate(ray.direction);

    float[11] t = 0;

    t[8] = 1.0f/ray.direction.x;
    t[9] = 1.0f/ray.direction.y;
    t[10] = 1.0f/ray.direction.z;

    t[0] = (box.min.x - ray.position.x)*t[8];
    t[1] = (box.max.x - ray.position.x)*t[8];
    t[2] = (box.min.y - ray.position.y)*t[9];
    t[3] = (box.max.y - ray.position.y)*t[9];
    t[4] = (box.min.z - ray.position.z)*t[10];
    t[5] = (box.max.z - ray.position.z)*t[10];
    t[6] = cast(float)fmax(fmax(fmin(t[0], t[1]), fmin(t[2], t[3])), fmin(t[4], t[5]));
    t[7] = cast(float)fmin(fmin(fmax(t[0], t[1]), fmax(t[2], t[3])), fmax(t[4], t[5]));

    collision.hit = !((t[7] < 0) || (t[6] > t[7]));
    collision.distance = t[6];
    collision.point = Vector3Add(ray.position, Vector3Scale(ray.direction, collision.distance));

    // Get box center point
    collision.normal = Vector3Lerp(box.min, box.max, 0.5f);
    // Get vector center point->hit point
    collision.normal = Vector3Subtract(collision.point, collision.normal);
    // Scale vector to unit cube
    // NOTE: We use an additional .01 to fix numerical errors
    collision.normal = Vector3Scale(collision.normal, 2.01f);
    collision.normal = Vector3Divide(collision.normal, Vector3Subtract(box.max, box.min));
    // The relevant elemets of the vector are now slightly larger than 1.0f (or smaller than -1.0f)
    // and the others are somewhere between -1.0 and 1.0 casting to int is exactly our wanted normal!
    collision.normal.x = cast(float)(cast(int)collision.normal.x);
    collision.normal.y = cast(float)(cast(int)collision.normal.y);
    collision.normal.z = cast(float)(cast(int)collision.normal.z);

    collision.normal = Vector3Normalize(collision.normal);

    if (insideBox)
    {
        // Reset ray.direction
        ray.direction = Vector3Negate(ray.direction);
        // Fix result
        collision.distance *= -1.0f;
        collision.normal = Vector3Negate(collision.normal);
    }

    return collision;
}

// Get collision info between ray and mesh
RayCollision GetRayCollisionMesh(Ray ray, Mesh mesh, Matrix transform)
{
    RayCollision collision = { 0 };

    // Check if mesh vertex data on CPU for testing
    if (mesh.vertices != null)
    {
        int triangleCount = mesh.triangleCount;

        // Test against all triangles in mesh
        for (int i = 0; i < triangleCount; i++)
        {
            Vector3 a = void, b = void, c = void;
            Vector3* vertdata = cast(Vector3*)mesh.vertices;

            if (mesh.indices)
            {
                a = vertdata[mesh.indices[i*3 + 0]];
                b = vertdata[mesh.indices[i*3 + 1]];
                c = vertdata[mesh.indices[i*3 + 2]];
            }
            else
            {
                a = vertdata[i*3 + 0];
                b = vertdata[i*3 + 1];
                c = vertdata[i*3 + 2];
            }

            a = Vector3Transform(a, transform);
            b = Vector3Transform(b, transform);
            c = Vector3Transform(c, transform);

            RayCollision triHitInfo = GetRayCollisionTriangle(ray, a, b, c);

            if (triHitInfo.hit)
            {
                // Save the closest hit triangle
                if ((!collision.hit) || (collision.distance > triHitInfo.distance)) collision = triHitInfo;
            }
        }
    }

    return collision;
}

// Get collision info between ray and model
RayCollision GetRayCollisionModel(Ray ray, Model model)
{
    RayCollision collision = { 0 };

    for (int m = 0; m < model.meshCount; m++)
    {
        RayCollision meshHitInfo = GetRayCollisionMesh(ray, model.meshes[m], model.transform);

        if (meshHitInfo.hit)
        {
            // Save the closest hit mesh
            if ((!collision.hit) || (collision.distance > meshHitInfo.distance)) collision = meshHitInfo;
        }
    }

    return collision;
}

// Get collision info between ray and triangle
// NOTE: The points are expected to be in counter-clockwise winding
// NOTE: Based on https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
RayCollision GetRayCollisionTriangle(Ray ray, Vector3 p1, Vector3 p2, Vector3 p3)
{
    enum EPSILON = 0.000001;        // A small number

    RayCollision collision = { 0 };
    Vector3 edge1 = { 0 };
    Vector3 edge2 = { 0 };
    Vector3 p = void, q = void, tv = void;
    float det = void, invDet = void, u = void, v = void, t = void;

    // Find vectors for two edges sharing V1
    edge1 = Vector3Subtract(p2, p1);
    edge2 = Vector3Subtract(p3, p1);

    // Begin calculating determinant - also used to calculate u parameter
    p = Vector3CrossProduct(ray.direction, edge2);

    // If determinant is near zero, ray lies in plane of triangle or ray is parallel to plane of triangle
    det = Vector3DotProduct(edge1, p);

    // Avoid culling!
    if ((det > -EPSILON) && (det < EPSILON)) return collision;

    invDet = 1.0f/det;

    // Calculate distance from V1 to ray origin
    tv = Vector3Subtract(ray.position, p1);

    // Calculate u parameter and test bound
    u = Vector3DotProduct(tv, p)*invDet;

    // The intersection lies outside of the triangle
    if ((u < 0.0f) || (u > 1.0f)) return collision;

    // Prepare to test v parameter
    q = Vector3CrossProduct(tv, edge1);

    // Calculate V parameter and test bound
    v = Vector3DotProduct(ray.direction, q)*invDet;

    // The intersection lies outside of the triangle
    if ((v < 0.0f) || ((u + v) > 1.0f)) return collision;

    t = Vector3DotProduct(edge2, q)*invDet;

    if (t > EPSILON)
    {
        // Ray hit, get hit point and normal
        collision.hit = true;
        collision.distance = t;
        collision.normal = Vector3Normalize(Vector3CrossProduct(edge1, edge2));
        collision.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
    }

    return collision;
}

// Get collision info between ray and quad
// NOTE: The points are expected to be in counter-clockwise winding
RayCollision GetRayCollisionQuad(Ray ray, Vector3 p1, Vector3 p2, Vector3 p3, Vector3 p4)
{
    RayCollision collision = { 0 };

    collision = GetRayCollisionTriangle(ray, p1, p2, p4);

    if (!collision.hit) collision = GetRayCollisionTriangle(ray, p2, p3, p4);

    return collision;
}

//----------------------------------------------------------------------------------
// Module specific Functions Definition
//----------------------------------------------------------------------------------
static if (SUPPORT_FILEFORMAT_OBJ) {
// Load OBJ mesh data
//
// Keep the following information in mind when reading this
//  - A mesh is created for every material present in the obj file
//  - the model.meshCount is therefore the materialCount returned from tinyobj
//  - the mesh is automatically triangulated by tinyobj
private Model LoadOBJ(const(char)* fileName)
{
    Model model = Model.init; // { 0 };

    tinyobj_attrib_t attrib = tinyobj_attrib_t.init; // { 0 };
    tinyobj_shape_t* meshes = null;
    uint meshCount = 0;

    tinyobj_material_t* materials = null;
    uint materialCount = 0;

    char* fileText = LoadFileText(fileName);

    if (fileText != null)
    {
        uint dataSize = cast(uint)strlen(fileText);
        char[1024] currentDir = 0;
        strcpy(currentDir.ptr, GetWorkingDirectory());
        const(char)* workingDir = GetDirectoryPath(fileName);
        if (CHDIR(workingDir) != 0)
        {
            TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Failed to change working directory", workingDir);
        }

        uint flags = TINYOBJ_FLAG_TRIANGULATE;
        int ret = tinyobj_parse_obj(&attrib, &meshes, &meshCount, &materials, &materialCount, fileText, dataSize, flags);

        if (ret != TINYOBJ_SUCCESS) TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Failed to load OBJ data", fileName);
        else TRACELOG(TraceLogLevel.LOG_INFO, "MODEL: [%s] OBJ data loaded successfully: %i meshes/%i materials", fileName, meshCount, materialCount);

        model.meshCount = materialCount;

        // Init model materials array
        if (materialCount > 0)
        {
            model.materialCount = materialCount;
            model.materials = cast(Material*)RL_CALLOC(model.materialCount, Material.sizeof);
            TraceLog(TraceLogLevel.LOG_INFO, "MODEL: model has %i material meshes", materialCount);
        }
        else
        {
            model.meshCount = 1;
            TraceLog(TraceLogLevel.LOG_INFO, "MODEL: No materials, putting all meshes in a default material");
        }

        model.meshes = cast(Mesh*)RL_CALLOC(model.meshCount, Mesh.sizeof);
        model.meshMaterial = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);

        // Count the faces for each material
        int* matFaces = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);

        // iff no materials are present use all faces on one mesh
        if (materialCount > 0)
        {
            for (uint fi = 0; fi < attrib.num_faces; fi++)
            {
                //tinyobj_vertex_index_t face = attrib.faces[fi];
                int idx = attrib.material_ids[fi];
                matFaces[idx]++;
            }

        }
        else
        {
            matFaces[0] = attrib.num_faces;
        }

        //--------------------------------------
        // Create the material meshes

        // Running counts/indexes for each material mesh as we are
        // building them at the same time
        int* vCount = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);
        int* vtCount = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);
        int* vnCount = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);
        int* faceCount = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);

        // Allocate space for each of the material meshes
        for (int mi = 0; mi < model.meshCount; mi++)
        {
            model.meshes[mi].vertexCount = matFaces[mi]*3;
            model.meshes[mi].triangleCount = matFaces[mi];
            model.meshes[mi].vertices = cast(float*)RL_CALLOC(model.meshes[mi].vertexCount*3, float.sizeof);
            model.meshes[mi].texcoords = cast(float*)RL_CALLOC(model.meshes[mi].vertexCount*2, float.sizeof);
            model.meshes[mi].normals = cast(float*)RL_CALLOC(model.meshes[mi].vertexCount*3, float.sizeof);
            model.meshMaterial[mi] = mi;
        }

        // Scan through the combined sub meshes and pick out each material mesh
        for (uint af = 0; af < attrib.num_faces; af++)
        {
            int mm = attrib.material_ids[af];   // mesh material for this face
            if (mm == -1) { mm = 0; }           // no material object..

            // Get indices for the face
            tinyobj_vertex_index_t idx0 = attrib.faces[3*af + 0];
            tinyobj_vertex_index_t idx1 = attrib.faces[3*af + 1];
            tinyobj_vertex_index_t idx2 = attrib.faces[3*af + 2];

            // Fill vertices buffer (float) using vertex index of the face
            for (int v = 0; v < 3; v++) { model.meshes[mm].vertices[vCount[mm] + v] = attrib.vertices[idx0.v_idx*3 + v]; } vCount[mm] +=3;
            for (int v = 0; v < 3; v++) { model.meshes[mm].vertices[vCount[mm] + v] = attrib.vertices[idx1.v_idx*3 + v]; } vCount[mm] +=3;
            for (int v = 0; v < 3; v++) { model.meshes[mm].vertices[vCount[mm] + v] = attrib.vertices[idx2.v_idx*3 + v]; } vCount[mm] +=3;

            if (attrib.num_texcoords > 0)
            {
                // Fill texcoords buffer (float) using vertex index of the face
                // NOTE: Y-coordinate must be flipped upside-down to account for
                // raylib's upside down textures...
                model.meshes[mm].texcoords[vtCount[mm] + 0] = attrib.texcoords[idx0.vt_idx*2 + 0];
                model.meshes[mm].texcoords[vtCount[mm] + 1] = 1.0f - attrib.texcoords[idx0.vt_idx*2 + 1]; vtCount[mm] += 2;
                model.meshes[mm].texcoords[vtCount[mm] + 0] = attrib.texcoords[idx1.vt_idx*2 + 0];
                model.meshes[mm].texcoords[vtCount[mm] + 1] = 1.0f - attrib.texcoords[idx1.vt_idx*2 + 1]; vtCount[mm] += 2;
                model.meshes[mm].texcoords[vtCount[mm] + 0] = attrib.texcoords[idx2.vt_idx*2 + 0];
                model.meshes[mm].texcoords[vtCount[mm] + 1] = 1.0f - attrib.texcoords[idx2.vt_idx*2 + 1]; vtCount[mm] += 2;
            }

            if (attrib.num_normals > 0)
            {
                // Fill normals buffer (float) using vertex index of the face
                for (int v = 0; v < 3; v++) { model.meshes[mm].normals[vnCount[mm] + v] = attrib.normals[idx0.vn_idx*3 + v]; } vnCount[mm] +=3;
                for (int v = 0; v < 3; v++) { model.meshes[mm].normals[vnCount[mm] + v] = attrib.normals[idx1.vn_idx*3 + v]; } vnCount[mm] +=3;
                for (int v = 0; v < 3; v++) { model.meshes[mm].normals[vnCount[mm] + v] = attrib.normals[idx2.vn_idx*3 + v]; } vnCount[mm] +=3;
            }
        }

        // Init model materials
        for (uint m = 0; m < materialCount; m++)
        {
            // Init material to default
            // NOTE: Uses default shader, which only supports MaterialMapIndex.MATERIAL_MAP_DIFFUSE
            model.materials[m] = LoadMaterialDefault();

            // Get default texture, in case no texture is defined
            // NOTE: rlgl default texture is a 1x1 pixel UNCOMPRESSED_R8G8B8A8
            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].texture = Texture2D( rlGetTextureIdDefault(), 1, 1, 1, PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 );

            if (materials[m].diffuse_texname != null) model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].texture = LoadTexture(materials[m].diffuse_texname);  //char *diffuse_texname; // map_Kd

            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].color = Color( cast(ubyte)(materials[m].diffuse[0]*255.0f), cast(ubyte)(materials[m].diffuse[1]*255.0f), cast(ubyte)(materials[m].diffuse[2]*255.0f), 255 ); //float diffuse[3];
            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_DIFFUSE].value = 0.0f;

            if (materials[m].specular_texname != null) model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_SPECULAR].texture = LoadTexture(materials[m].specular_texname);  //char *specular_texname; // map_Ks
            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_SPECULAR].color = Color( cast(ubyte)(materials[m].specular[0]*255.0f), cast(ubyte)(materials[m].specular[1]*255.0f), cast(ubyte)(materials[m].specular[2]*255.0f), 255 ); //float specular[3];
            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_SPECULAR].value = 0.0f;

            if (materials[m].bump_texname != null) model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_NORMAL].texture = LoadTexture(materials[m].bump_texname);  //char *bump_texname; // map_bump, bump
            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_NORMAL].color = WHITE;
            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_NORMAL].value = materials[m].shininess;

            model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_EMISSION].color = Color( cast(ubyte)(materials[m].emission[0]*255.0f), cast(ubyte)(materials[m].emission[1]*255.0f), cast(ubyte)(materials[m].emission[2]*255.0f), 255 ); //float emission[3];

            if (materials[m].displacement_texname != null) model.materials[m].maps[MaterialMapIndex.MATERIAL_MAP_HEIGHT].texture = LoadTexture(materials[m].displacement_texname);  //char *displacement_texname; // disp
        }

        tinyobj_attrib_free(&attrib);
        tinyobj_shapes_free(meshes, meshCount);
        tinyobj_materials_free(materials, materialCount);

        UnloadFileText(fileText);

        RL_FREE(matFaces);
        RL_FREE(vCount);
        RL_FREE(vtCount);
        RL_FREE(vnCount);
        RL_FREE(faceCount);

        if (CHDIR(currentDir.ptr) != 0)
        {
            TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Failed to change working directory", currentDir.ptr);
        }
    }

    return model;
}
}

static if (SUPPORT_FILEFORMAT_IQM) {
// Load IQM mesh data
private Model LoadIQM(const(char)* fileName)
{
    enum IQM_MAGIC =     "INTERQUAKEMODEL"; // IQM file magic number
    enum IQM_VERSION =          2;          // only IQM version 2 supported

    enum BONE_NAME_LENGTH =    32;          // BoneInfo name string length
    enum MESH_NAME_LENGTH =    32;          // Mesh name string length
    enum MATERIAL_NAME_LENGTH = 32;         // Material name string length

    uint fileSize = 0;
    ubyte* fileData = LoadFileData(fileName, &fileSize);
    ubyte* fileDataPtr = fileData;

    // IQM file structs
    //-----------------------------------------------------------------------------------
    struct IQMHeader {
        char[16] magic = void;
        uint version_ = void;
        uint filesize = void;
        uint flags = void;
        uint num_text = void, ofs_text = void;
        uint num_meshes = void, ofs_meshes = void;
        uint num_vertexarrays = void, num_vertexes = void, ofs_vertexarrays = void;
        uint num_triangles = void, ofs_triangles = void, ofs_adjacency = void;
        uint num_joints = void, ofs_joints = void;
        uint num_poses = void, ofs_poses = void;
        uint num_anims = void, ofs_anims = void;
        uint num_frames = void, num_framechannels = void, ofs_frames = void, ofs_bounds = void;
        uint num_comment = void, ofs_comment = void;
        uint num_extensions = void, ofs_extensions = void;
    }

    struct IQMMesh {
        uint name = void;
        uint material = void;
        uint first_vertex = void, num_vertexes = void;
        uint first_triangle = void, num_triangles = void;
    }

    struct IQMTriangle {
        uint[3] vertex = void;
    }

    struct IQMJoint {
        uint name = void;
        int parent = void;
        float[3] translate = void; float[4] rotate = void; float[3] scale = void;
    }

    struct IQMVertexArray {
        uint type = void;
        uint flags = void;
        uint format = void;
        uint size = void;
        uint offset = void;
    }

    // NOTE: Below IQM structures are not used but listed for reference
    /*
    typedef struct IQMAdjacency {
        unsigned int triangle[3];
    } IQMAdjacency;

    typedef struct IQMPose {
        int parent;
        unsigned int mask;
        float channeloffset[10];
        float channelscale[10];
    } IQMPose;

    typedef struct IQMAnim {
        unsigned int name;
        unsigned int first_frame, num_frames;
        float framerate;
        unsigned int flags;
    } IQMAnim;

    typedef struct IQMBounds {
        float bbmin[3], bbmax[3];
        float xyradius, radius;
    } IQMBounds;
    */
    //-----------------------------------------------------------------------------------

    // IQM vertex data types
    enum {
        IQM_POSITION     = 0,
        IQM_TEXCOORD     = 1,
        IQM_NORMAL       = 2,
        IQM_TANGENT      = 3,       // NOTE: Tangents unused by default
        IQM_BLENDINDEXES = 4,
        IQM_BLENDWEIGHTS = 5,
        IQM_COLOR        = 6,
        IQM_CUSTOM       = 0x10     // NOTE: Custom vertex values unused by default
    };

    Model model = Model.init; //{ 0 };

    IQMMesh* imesh = null;
    IQMTriangle* tri = null;
    IQMVertexArray* va = null;
    IQMJoint* ijoint = null;

    float* vertex = null;
    float* normal = null;
    float* text = null;
    char* blendi = null;
    ubyte* blendw = null;
    ubyte* color = null;

    // In case file can not be read, return an empty model
    if (fileDataPtr == null) return model;

    // Read IQM header
    IQMHeader* iqmHeader = cast(IQMHeader*)fileDataPtr;

    if (memcmp(iqmHeader.magic.ptr, IQM_MAGIC.ptr, IQM_MAGIC.length) != 0)
    {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] IQM file is not a valid model", fileName);
        return model;
    }

    if (iqmHeader.version_ != IQM_VERSION)
    {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] IQM file version not supported (%i)", fileName, iqmHeader.version_);
        return model;
    }

    //fileDataPtr += sizeof(IQMHeader);       // Move file data pointer

    // Meshes data processing
    imesh = cast(typeof(imesh))RL_MALLOC(iqmHeader.num_meshes*IQMMesh.sizeof);
    //fseek(iqmFile, iqmHeader->ofs_meshes, SEEK_SET);
    //fread(imesh, sizeof(IQMMesh)*iqmHeader->num_meshes, 1, iqmFile);
    memcpy(imesh, fileDataPtr + iqmHeader.ofs_meshes, iqmHeader.num_meshes*IQMMesh.sizeof);

    model.meshCount = iqmHeader.num_meshes;
    model.meshes = cast(typeof(model.meshes))RL_CALLOC(model.meshCount, Mesh.sizeof);

    model.materialCount = model.meshCount;
    model.materials = cast(Material*)RL_CALLOC(model.materialCount, Material.sizeof);
    model.meshMaterial = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);

    char[MESH_NAME_LENGTH] name = 0;
    char[MATERIAL_NAME_LENGTH] material = 0;

    for (int i = 0; i < model.meshCount; i++)
    {
        //fseek(iqmFile, iqmHeader->ofs_text + imesh[i].name, SEEK_SET);
        //fread(name, sizeof(char)*MESH_NAME_LENGTH, 1, iqmFile);
        memcpy(name.ptr, fileDataPtr + iqmHeader.ofs_text + imesh[i].name, MESH_NAME_LENGTH*char.sizeof);

        //fseek(iqmFile, iqmHeader->ofs_text + imesh[i].material, SEEK_SET);
        //fread(material, sizeof(char)*MATERIAL_NAME_LENGTH, 1, iqmFile);
        memcpy(material.ptr, fileDataPtr + iqmHeader.ofs_text + imesh[i].material, MATERIAL_NAME_LENGTH*char.sizeof);

        model.materials[i] = LoadMaterialDefault();

        TRACELOG(TraceLogLevel.LOG_DEBUG, "MODEL: [%s] mesh name (%s), material (%s)", fileName, name.ptr, material.ptr);

        model.meshes[i].vertexCount = imesh[i].num_vertexes;

        model.meshes[i].vertices = cast(typeof(model.meshes[i].vertices))RL_CALLOC(model.meshes[i].vertexCount*3, float.sizeof);       // Default vertex positions
        model.meshes[i].normals = cast(typeof(model.meshes[i].normals))RL_CALLOC(model.meshes[i].vertexCount*3, float.sizeof);        // Default vertex normals
        model.meshes[i].texcoords = cast(typeof(model.meshes[i].texcoords))RL_CALLOC(model.meshes[i].vertexCount*2, float.sizeof);      // Default vertex texcoords

        model.meshes[i].boneIds = cast(typeof(model.meshes[i].boneIds))RL_CALLOC(model.meshes[i].vertexCount*4, ubyte.sizeof);  // Up-to 4 bones supported!
        model.meshes[i].boneWeights = cast(typeof(model.meshes[i].boneWeights))RL_CALLOC(model.meshes[i].vertexCount*4, float.sizeof);      // Up-to 4 bones supported!

        model.meshes[i].triangleCount = imesh[i].num_triangles;
        model.meshes[i].indices = cast(typeof(model.meshes[i].indices))RL_CALLOC(model.meshes[i].triangleCount*3, ushort.sizeof);

        // Animated verted data, what we actually process for rendering
        // NOTE: Animated vertex should be re-uploaded to GPU (if not using GPU skinning)
        model.meshes[i].animVertices = cast(typeof(model.meshes[i].animVertices))RL_CALLOC(model.meshes[i].vertexCount*3, float.sizeof);
        model.meshes[i].animNormals = cast(typeof(model.meshes[i].animNormals))RL_CALLOC(model.meshes[i].vertexCount*3, float.sizeof);
    }

    // Triangles data processing
    tri = cast(typeof(tri))RL_MALLOC(iqmHeader.num_triangles*IQMTriangle.sizeof);
    //fseek(iqmFile, iqmHeader->ofs_triangles, SEEK_SET);
    //fread(tri, iqmHeader->num_triangles*sizeof(IQMTriangle), 1, iqmFile);
    memcpy(tri, fileDataPtr + iqmHeader.ofs_triangles, iqmHeader.num_triangles*IQMTriangle.sizeof);

    for (int m = 0; m < model.meshCount; m++)
    {
        int tcounter = 0;

        for (uint i = imesh[m].first_triangle; i < (imesh[m].first_triangle + imesh[m].num_triangles); i++)
        {
            // IQM triangles indexes are stored in counter-clockwise, but raylib processes the index in linear order,
            // expecting they point to the counter-clockwise vertex triangle, so we need to reverse triangle indexes
            // NOTE: raylib renders vertex data in counter-clockwise order (standard convention) by default
            model.meshes[m].indices[tcounter + 2] = cast(ushort)(tri[i].vertex[0] - imesh[m].first_vertex);
            model.meshes[m].indices[tcounter + 1] = cast(ushort)(tri[i].vertex[1] - imesh[m].first_vertex);
            model.meshes[m].indices[tcounter] = cast(ushort)(tri[i].vertex[2] - imesh[m].first_vertex);
            tcounter += 3;
        }
    }

    // Vertex arrays data processing
    va = cast(typeof(va))RL_MALLOC(iqmHeader.num_vertexarrays*IQMVertexArray.sizeof);
    //fseek(iqmFile, iqmHeader->ofs_vertexarrays, SEEK_SET);
    //fread(va, iqmHeader->num_vertexarrays*sizeof(IQMVertexArray), 1, iqmFile);
    memcpy(va, fileDataPtr + iqmHeader.ofs_vertexarrays, iqmHeader.num_vertexarrays*IQMVertexArray.sizeof);

    for (uint i = 0; i < iqmHeader.num_vertexarrays; i++)
    {
        switch (va[i].type)
        {
            case IQM_POSITION:
            {
                vertex = cast(typeof(vertex))RL_MALLOC(iqmHeader.num_vertexes*3*int(float.sizeof));
                //fseek(iqmFile, va[i].offset, SEEK_SET);
                //fread(vertex, iqmHeader->num_vertexes*3*sizeof(float), 1, iqmFile);
                memcpy(vertex, fileDataPtr + va[i].offset, iqmHeader.num_vertexes*3*int(float.sizeof));

                for (uint m = 0; m < iqmHeader.num_meshes; m++)
                {
                    int vCounter = 0;
                    for (uint j = imesh[m].first_vertex*3; j < (imesh[m].first_vertex + imesh[m].num_vertexes)*3; j++)
                    {
                        model.meshes[m].vertices[vCounter] = vertex[j];
                        model.meshes[m].animVertices[vCounter] = vertex[j];
                        vCounter++;
                    }
                }
            } break;
            case IQM_NORMAL:
            {
                normal = cast(typeof(normal))RL_MALLOC(iqmHeader.num_vertexes*3*int(float.sizeof));
                //fseek(iqmFile, va[i].offset, SEEK_SET);
                //fread(normal, iqmHeader->num_vertexes*3*sizeof(float), 1, iqmFile);
                memcpy(normal, fileDataPtr + va[i].offset, iqmHeader.num_vertexes*3*int(float.sizeof));

                for (uint m = 0; m < iqmHeader.num_meshes; m++)
                {
                    int vCounter = 0;
                    for (uint j = imesh[m].first_vertex*3; j < (imesh[m].first_vertex + imesh[m].num_vertexes)*3; j++)
                    {
                        model.meshes[m].normals[vCounter] = normal[j];
                        model.meshes[m].animNormals[vCounter] = normal[j];
                        vCounter++;
                    }
                }
            } break;
            case IQM_TEXCOORD:
            {
                text = cast(typeof(text))RL_MALLOC(iqmHeader.num_vertexes*2*int(float.sizeof));
                //fseek(iqmFile, va[i].offset, SEEK_SET);
                //fread(text, iqmHeader->num_vertexes*2*sizeof(float), 1, iqmFile);
                memcpy(text, fileDataPtr + va[i].offset, iqmHeader.num_vertexes*2*int(float.sizeof));

                for (uint m = 0; m < iqmHeader.num_meshes; m++)
                {
                    int vCounter = 0;
                    for (uint j = imesh[m].first_vertex*2; j < (imesh[m].first_vertex + imesh[m].num_vertexes)*2; j++)
                    {
                        model.meshes[m].texcoords[vCounter] = text[j];
                        vCounter++;
                    }
                }
            } break;
            case IQM_BLENDINDEXES:
            {
                blendi = cast(typeof(blendi))RL_MALLOC(iqmHeader.num_vertexes*4*char.sizeof);
                //fseek(iqmFile, va[i].offset, SEEK_SET);
                //fread(blendi, iqmHeader->num_vertexes*4*sizeof(char), 1, iqmFile);
                memcpy(blendi, fileDataPtr + va[i].offset, iqmHeader.num_vertexes*4*char.sizeof);

                for (uint m = 0; m < iqmHeader.num_meshes; m++)
                {
                    int boneCounter = 0;
                    for (uint j = imesh[m].first_vertex*4; j < (imesh[m].first_vertex + imesh[m].num_vertexes)*4; j++)
                    {
                        model.meshes[m].boneIds[boneCounter] = blendi[j];
                        boneCounter++;
                    }
                }
            } break;
            case IQM_BLENDWEIGHTS:
            {
                blendw = cast(typeof(blendw))RL_MALLOC(iqmHeader.num_vertexes*4*int(ubyte.sizeof));
                //fseek(iqmFile, va[i].offset, SEEK_SET);
                //fread(blendw, iqmHeader->num_vertexes*4*sizeof(unsigned char), 1, iqmFile);
                memcpy(blendw, fileDataPtr + va[i].offset, iqmHeader.num_vertexes*4*int(ubyte.sizeof));

                for (uint m = 0; m < iqmHeader.num_meshes; m++)
                {
                    int boneCounter = 0;
                    for (uint j = imesh[m].first_vertex*4; j < (imesh[m].first_vertex + imesh[m].num_vertexes)*4; j++)
                    {
                        model.meshes[m].boneWeights[boneCounter] = blendw[j]/255.0f;
                        boneCounter++;
                    }
                }
            } break;
            case IQM_COLOR:
            {
                color = cast(typeof(color))RL_MALLOC(iqmHeader.num_vertexes*4*int(ubyte.sizeof));
                //fseek(iqmFile, va[i].offset, SEEK_SET);
                //fread(blendw, iqmHeader->num_vertexes*4*sizeof(unsigned char), 1, iqmFile);
                memcpy(color, fileDataPtr + va[i].offset, iqmHeader.num_vertexes*4*int(ubyte.sizeof));

                for (uint m = 0; m < iqmHeader.num_meshes; m++)
                {
                    model.meshes[m].colors = cast(typeof(model.meshes[m].colors))RL_CALLOC(model.meshes[m].vertexCount*4, ubyte.sizeof);

                    int vCounter = 0;
                    for (uint j = imesh[m].first_vertex*4; j < (imesh[m].first_vertex + imesh[m].num_vertexes)*4; j++)
                    {
                        model.meshes[m].colors[vCounter] = color[j];
                        vCounter++;
                    }
                }
            } break;
        default: break;}
    }

    // Bones (joints) data processing
    ijoint = cast(typeof(ijoint))RL_MALLOC(iqmHeader.num_joints*IQMJoint.sizeof);
    //fseek(iqmFile, iqmHeader->ofs_joints, SEEK_SET);
    //fread(ijoint, iqmHeader->num_joints*sizeof(IQMJoint), 1, iqmFile);
    memcpy(ijoint, fileDataPtr + iqmHeader.ofs_joints, iqmHeader.num_joints*IQMJoint.sizeof);

    model.boneCount = iqmHeader.num_joints;
    model.bones = cast(typeof(model.bones))RL_MALLOC(iqmHeader.num_joints*BoneInfo.sizeof);
    model.bindPose = cast(typeof(model.bindPose))RL_MALLOC(iqmHeader.num_joints*Transform.sizeof);

    for (uint i = 0; i < iqmHeader.num_joints; i++)
    {
        // Bones
        model.bones[i].parent = ijoint[i].parent;
        //fseek(iqmFile, iqmHeader->ofs_text + ijoint[i].name, SEEK_SET);
        //fread(model.bones[i].name, BONE_NAME_LENGTH*sizeof(char), 1, iqmFile);
        memcpy(model.bones[i].name.ptr, fileDataPtr + iqmHeader.ofs_text + ijoint[i].name, BONE_NAME_LENGTH*char.sizeof);

        // Bind pose (base pose)
        model.bindPose[i].translation.x = ijoint[i].translate[0];
        model.bindPose[i].translation.y = ijoint[i].translate[1];
        model.bindPose[i].translation.z = ijoint[i].translate[2];

        model.bindPose[i].rotation.x = ijoint[i].rotate[0];
        model.bindPose[i].rotation.y = ijoint[i].rotate[1];
        model.bindPose[i].rotation.z = ijoint[i].rotate[2];
        model.bindPose[i].rotation.w = ijoint[i].rotate[3];

        model.bindPose[i].scale.x = ijoint[i].scale[0];
        model.bindPose[i].scale.y = ijoint[i].scale[1];
        model.bindPose[i].scale.z = ijoint[i].scale[2];
    }

    // Build bind pose from parent joints
    for (int i = 0; i < model.boneCount; i++)
    {
        if (model.bones[i].parent >= 0)
        {
            model.bindPose[i].rotation = QuaternionMultiply(model.bindPose[model.bones[i].parent].rotation, model.bindPose[i].rotation);
            model.bindPose[i].translation = Vector3RotateByQuaternion(model.bindPose[i].translation, model.bindPose[model.bones[i].parent].rotation);
            model.bindPose[i].translation = Vector3Add(model.bindPose[i].translation, model.bindPose[model.bones[i].parent].translation);
            model.bindPose[i].scale = Vector3Multiply(model.bindPose[i].scale, model.bindPose[model.bones[i].parent].scale);
        }
    }

    RL_FREE(fileData);

    RL_FREE(imesh);
    RL_FREE(tri);
    RL_FREE(va);
    RL_FREE(vertex);
    RL_FREE(normal);
    RL_FREE(text);
    RL_FREE(blendi);
    RL_FREE(blendw);
    RL_FREE(ijoint);

    return model;
}

// Load IQM animation data
private ModelAnimation* LoadModelAnimationsIQM(const(char)* fileName, uint* animCount)
{
    enum IQM_MAGIC =       "INTERQUAKEMODEL";   // IQM file magic number
    enum IQM_VERSION =     2;                   // only IQM version 2 supported

    uint fileSize = 0;
    ubyte* fileData = LoadFileData(fileName, &fileSize);
    ubyte* fileDataPtr = fileData;

    struct IQMHeader {
        char[16] magic = void;
        uint version_ = void;
        uint filesize = void;
        uint flags = void;
        uint num_text = void, ofs_text = void;
        uint num_meshes = void, ofs_meshes = void;
        uint num_vertexarrays = void, num_vertexes = void, ofs_vertexarrays = void;
        uint num_triangles = void, ofs_triangles = void, ofs_adjacency = void;
        uint num_joints = void, ofs_joints = void;
        uint num_poses = void, ofs_poses = void;
        uint num_anims = void, ofs_anims = void;
        uint num_frames = void, num_framechannels = void, ofs_frames = void, ofs_bounds = void;
        uint num_comment = void, ofs_comment = void;
        uint num_extensions = void, ofs_extensions = void;
    }

    struct IQMPose {
        int parent = void;
        uint mask = void;
        float[10] channeloffset = void;
        float[10] channelscale = void;
    }

    struct IQMAnim {
        uint name = void;
        uint first_frame = void, num_frames = void;
        float framerate = void;
        uint flags = void;
    }

    // In case file can not be read, return an empty model
    if (fileDataPtr == null) return null;

    // Read IQM header
    IQMHeader* iqmHeader = cast(IQMHeader*)fileDataPtr;

    if (memcmp(iqmHeader.magic.ptr, IQM_MAGIC.ptr, IQM_MAGIC.sizeof) != 0)
    {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] IQM file is not a valid model", fileName);
        return null;
    }

    if (iqmHeader.version_ != IQM_VERSION)
    {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] IQM file version not supported (%i)", fileName, iqmHeader.version_);
        return null;
    }

    // Get bones data
    IQMPose* poses = cast(IQMPose*)RL_MALLOC(iqmHeader.num_poses*IQMPose.sizeof);
    //fseek(iqmFile, iqmHeader->ofs_poses, SEEK_SET);
    //fread(poses, iqmHeader->num_poses*sizeof(IQMPose), 1, iqmFile);
    memcpy(poses, fileDataPtr + iqmHeader.ofs_poses, iqmHeader.num_poses*IQMPose.sizeof);

    // Get animations data
    *animCount = iqmHeader.num_anims;
    IQMAnim* anim = cast(IQMAnim*)RL_MALLOC(iqmHeader.num_anims*IQMAnim.sizeof);
    //fseek(iqmFile, iqmHeader->ofs_anims, SEEK_SET);
    //fread(anim, iqmHeader->num_anims*sizeof(IQMAnim), 1, iqmFile);
    memcpy(anim, fileDataPtr + iqmHeader.ofs_anims, iqmHeader.num_anims*IQMAnim.sizeof);

    ModelAnimation* animations = cast(ModelAnimation*)RL_MALLOC(iqmHeader.num_anims*ModelAnimation.sizeof);

    // frameposes
    ushort* framedata = cast(ushort*)RL_MALLOC(iqmHeader.num_frames*iqmHeader.num_framechannels*int(ushort.sizeof));
    //fseek(iqmFile, iqmHeader->ofs_frames, SEEK_SET);
    //fread(framedata, iqmHeader->num_frames*iqmHeader->num_framechannels*sizeof(unsigned short), 1, iqmFile);
    memcpy(framedata, fileDataPtr + iqmHeader.ofs_frames, iqmHeader.num_frames*iqmHeader.num_framechannels*int(ushort.sizeof));

    for (uint a = 0; a < iqmHeader.num_anims; a++)
    {
        animations[a].frameCount = anim[a].num_frames;
        animations[a].boneCount = iqmHeader.num_poses;
        animations[a].bones = cast(typeof(animations[a].bones))RL_MALLOC(iqmHeader.num_poses*BoneInfo.sizeof);
        animations[a].framePoses = cast(typeof(animations[a].framePoses))RL_MALLOC(anim[a].num_frames*(Transform*).sizeof);
        // animations[a].framerate = anim.framerate;     // TODO: Use framerate?

        for (uint j = 0; j < iqmHeader.num_poses; j++)
        {
            strcpy(animations[a].bones[j].name.ptr, "ANIMJOINTNAME");
            animations[a].bones[j].parent = poses[j].parent;
        }

        for (uint j = 0; j < anim[a].num_frames; j++) animations[a].framePoses[j] = cast(typeof(animations[a].framePoses[j]))RL_MALLOC(iqmHeader.num_poses*Transform.sizeof);

        int dcounter = anim[a].first_frame*iqmHeader.num_framechannels;

        for (uint frame = 0; frame < anim[a].num_frames; frame++)
        {
            for (uint i = 0; i < iqmHeader.num_poses; i++)
            {
                animations[a].framePoses[frame][i].translation.x = poses[i].channeloffset[0];

                if (poses[i].mask & 0x01)
                {
                    animations[a].framePoses[frame][i].translation.x += framedata[dcounter]*poses[i].channelscale[0];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].translation.y = poses[i].channeloffset[1];

                if (poses[i].mask & 0x02)
                {
                    animations[a].framePoses[frame][i].translation.y += framedata[dcounter]*poses[i].channelscale[1];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].translation.z = poses[i].channeloffset[2];

                if (poses[i].mask & 0x04)
                {
                    animations[a].framePoses[frame][i].translation.z += framedata[dcounter]*poses[i].channelscale[2];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].rotation.x = poses[i].channeloffset[3];

                if (poses[i].mask & 0x08)
                {
                    animations[a].framePoses[frame][i].rotation.x += framedata[dcounter]*poses[i].channelscale[3];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].rotation.y = poses[i].channeloffset[4];

                if (poses[i].mask & 0x10)
                {
                    animations[a].framePoses[frame][i].rotation.y += framedata[dcounter]*poses[i].channelscale[4];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].rotation.z = poses[i].channeloffset[5];

                if (poses[i].mask & 0x20)
                {
                    animations[a].framePoses[frame][i].rotation.z += framedata[dcounter]*poses[i].channelscale[5];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].rotation.w = poses[i].channeloffset[6];

                if (poses[i].mask & 0x40)
                {
                    animations[a].framePoses[frame][i].rotation.w += framedata[dcounter]*poses[i].channelscale[6];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].scale.x = poses[i].channeloffset[7];

                if (poses[i].mask & 0x80)
                {
                    animations[a].framePoses[frame][i].scale.x += framedata[dcounter]*poses[i].channelscale[7];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].scale.y = poses[i].channeloffset[8];

                if (poses[i].mask & 0x100)
                {
                    animations[a].framePoses[frame][i].scale.y += framedata[dcounter]*poses[i].channelscale[8];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].scale.z = poses[i].channeloffset[9];

                if (poses[i].mask & 0x200)
                {
                    animations[a].framePoses[frame][i].scale.z += framedata[dcounter]*poses[i].channelscale[9];
                    dcounter++;
                }

                animations[a].framePoses[frame][i].rotation = QuaternionNormalize(animations[a].framePoses[frame][i].rotation);
            }
        }

        // Build frameposes
        for (uint frame = 0; frame < anim[a].num_frames; frame++)
        {
            for (int i = 0; i < animations[a].boneCount; i++)
            {
                if (animations[a].bones[i].parent >= 0)
                {
                    animations[a].framePoses[frame][i].rotation = QuaternionMultiply(animations[a].framePoses[frame][animations[a].bones[i].parent].rotation, animations[a].framePoses[frame][i].rotation);
                    animations[a].framePoses[frame][i].translation = Vector3RotateByQuaternion(animations[a].framePoses[frame][i].translation, animations[a].framePoses[frame][animations[a].bones[i].parent].rotation);
                    animations[a].framePoses[frame][i].translation = Vector3Add(animations[a].framePoses[frame][i].translation, animations[a].framePoses[frame][animations[a].bones[i].parent].translation);
                    animations[a].framePoses[frame][i].scale = Vector3Multiply(animations[a].framePoses[frame][i].scale, animations[a].framePoses[frame][animations[a].bones[i].parent].scale);
                }
            }
        }
    }

    RL_FREE(fileData);

    RL_FREE(framedata);
    RL_FREE(poses);
    RL_FREE(anim);

    return animations;
}

}

static if (SUPPORT_FILEFORMAT_GLTF) {
// Load image from different glTF provided methods (uri, path, buffer_view)
private Image LoadImageFromCgltfImage(cgltf_image* cgltfImage, const(char)* texPath)
{
    Image image = Image.init; // { 0 };

    if (cgltfImage.uri != null)     // Check if image data is provided as a uri (base64 or path)
    {
        if ((strlen(cgltfImage.uri) > 5) &&
            (cgltfImage.uri[0] == 'd') &&
            (cgltfImage.uri[1] == 'a') &&
            (cgltfImage.uri[2] == 't') &&
            (cgltfImage.uri[3] == 'a') &&
            (cgltfImage.uri[4] == ':'))     // Check if image is provided as base64 text data
        {
            // Data URI Format: data:<mediatype>;base64,<data>

            // Find the comma
            int i = 0;
            while ((cgltfImage.uri[i] != ',') && (cgltfImage.uri[i] != 0)) i++;

            if (cgltfImage.uri[i] == 0) TRACELOG(TraceLogLevel.LOG_WARNING, "IMAGE: glTF data URI is not a valid image");
            else
            {
                int base64Size = cast(int)strlen(cgltfImage.uri + i + 1);
                int outSize = 3*(base64Size/4);         // TODO: Consider padding (-numberOfPaddingCharacters)
                void* data = null;

                cgltf_options options = cgltf_options.init; // { 0 };
                cgltf_result result = cgltf_load_buffer_base64(&options, outSize, cgltfImage.uri + i + 1, &data);

                if (result == cgltf_result_success)
                {
                    image = LoadImageFromMemory(".png", cast(ubyte*)data, outSize);
                    cgltf_free(cast(cgltf_data*)data);
                }
            }
        }
        else     // Check if image is provided as image path
        {
            image = LoadImage(TextFormat("%s/%s", texPath, cgltfImage.uri));
        }
    }
    else if (cgltfImage.buffer_view.buffer.data != null)    // Check if image is provided as data buffer
    {
        ubyte* data = cast(ubyte*)RL_MALLOC(cgltfImage.buffer_view.size);
        int offset = cast(int)cgltfImage.buffer_view.offset;
        int stride = cast(int)cgltfImage.buffer_view.stride? cast(int)cgltfImage.buffer_view.stride : 1;

        // Copy buffer data to memory for loading
        for (uint i = 0; i < cgltfImage.buffer_view.size; i++)
        {
            data[i] = (cast(ubyte*)cgltfImage.buffer_view.buffer.data)[offset];
            offset += stride;
        }

        // Check mime_type for image: (cgltfImage->mime_type == "image/png")
        // NOTE: Detected that some models define mime_type as "image\\/png"
        if ((strcmp(cgltfImage.mime_type, "image\\/png") == 0) ||
            (strcmp(cgltfImage.mime_type, "image/png") == 0)) image = LoadImageFromMemory(".png", data, cast(int)cgltfImage.buffer_view.size);
        else if ((strcmp(cgltfImage.mime_type, "image\\/jpeg") == 0) ||
                 (strcmp(cgltfImage.mime_type, "image/jpeg") == 0)) image = LoadImageFromMemory(".jpg", data, cast(int)cgltfImage.buffer_view.size);
        else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: glTF image data MIME type not recognized", TextFormat("%s/%s", texPath, cgltfImage.uri));

        RL_FREE(data);
    }

    return image;
}

// Load glTF file into model struct, .gltf and .glb supported
private Model LoadGLTF(const(char)* fileName)
{
    /*********************************************************************************************

        Function implemented by Wilhem Barbier(@wbrbr), with modifications by Tyler Bezera(@gamerfiend)
        Reviewed by Ramon Santamaria (@raysan5)

        FEATURES:
          - Supports .gltf and .glb files
          - Supports embedded (base64) or external textures
          - Supports PBR metallic/roughness flow, loads material textures, values and colors
                     PBR specular/glossiness flow and extended texture flows not supported
          - Supports multiple meshes per model (every primitives is loaded as a separate mesh)

        RESTRICTIONS:
          - Only triangle meshes supported
          - Vertex attibute types and formats supported:
              > Vertices (position): vec3: float
              > Normals: vec3: float
              > Texcoords: vec2: float
              > Colors: vec4: u8, u16, f32 (normalized)
              > Indices: u16, u32 (truncated to u16)
          - Node hierarchies or transforms not supported

    ***********************************************************************************************/

    // Macro to simplify attributes loading code
    enum string LOAD_ATTRIBUTE(string accesor, string numComp, string dataType, string dstPtr) = `
    {
        int n = 0;
        ` ~ dataType ~ `* buffer = cast(` ~ dataType ~ `*)` ~ accesor ~ `.buffer_view.buffer.data + ` ~ accesor ~ `.buffer_view.offset/(` ~ dataType ~ `).sizeof + ` ~ accesor ~ `.offset/` ~ dataType ~ `.sizeof;
        for (uint k = 0; k < ` ~ accesor ~ `.count; k++)
        {
            for (int l = 0; l < ` ~ numComp ~ `; l++)
            {
                ` ~ dstPtr ~ `[` ~ numComp ~ `*k + l] = buffer[n + l];
            }
            n += cast(int)(` ~ accesor ~ `.stride/` ~ dataType ~ `.sizeof);
        }
    }`;

    Model model = Model.init; // { 0 };

    // glTF file loading
    uint dataSize = 0;
    ubyte* fileData = LoadFileData(fileName, &dataSize);

    if (fileData == null) return model;

    // glTF data loading
    cgltf_options options = cgltf_options.init; // { 0 };
    cgltf_data* data = null;
    cgltf_result result = cgltf_parse(&options, fileData, dataSize, &data);

    if (result == cgltf_result_success)
    {
        if (data.file_type == cgltf_file_type_glb) TRACELOG(TraceLogLevel.LOG_INFO, "MODEL: [%s] Model basic data (glb) loaded successfully", fileName);
        else if (data.file_type == cgltf_file_type_gltf) TRACELOG(TraceLogLevel.LOG_INFO, "MODEL: [%s] Model basic data (glTF) loaded successfully", fileName);
        else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Model format not recognized", fileName);

        TRACELOG(TraceLogLevel.LOG_INFO, "    > Meshes count: %i", data.meshes_count);
        TRACELOG(TraceLogLevel.LOG_INFO, "    > Materials count: %i (+1 default)", data.materials_count);
        TRACELOG(TraceLogLevel.LOG_DEBUG, "    > Buffers count: %i", data.buffers_count);
        TRACELOG(TraceLogLevel.LOG_DEBUG, "    > Images count: %i", data.images_count);
        TRACELOG(TraceLogLevel.LOG_DEBUG, "    > Textures count: %i", data.textures_count);

        // Force reading data buffers (fills buffer_view->buffer->data)
        // NOTE: If an uri is defined to base64 data or external path, it's automatically loaded -> TODO: Verify this assumption
        result = cgltf_load_buffers(&options, data, fileName);
        if (result != cgltf_result_success) TRACELOG(TraceLogLevel.LOG_INFO, "MODEL: [%s] Failed to load mesh/material buffers", fileName);

        int primitivesCount = 0;
        // NOTE: We will load every primitive in the glTF as a separate raylib mesh
        for (uint i = 0; i < data.meshes_count; i++) primitivesCount += cast(int)data.meshes[i].primitives_count;

        // Load our model data: meshes and materials
        model.meshCount = primitivesCount;
        model.meshes = cast(typeof(model.meshes))RL_CALLOC(model.meshCount, Mesh.sizeof);
        for (int i = 0; i < model.meshCount; i++) model.meshes[i].vboId = cast(uint*)RL_CALLOC(MAX_MESH_VERTEX_BUFFERS, uint.sizeof);

        // NOTE: We keep an extra slot for default material, in case some mesh requires it
        model.materialCount = cast(int)data.materials_count + 1;
        model.materials = cast(typeof(model.materials))RL_CALLOC(model.materialCount, Material.sizeof);
        model.materials[0] = LoadMaterialDefault();     // Load default material (index: 0)

        // Load mesh-material indices, by default all meshes are mapped to material index: 0
        model.meshMaterial = cast(typeof(model.meshMaterial))RL_CALLOC(model.meshCount, int.sizeof);

        // Load materials data
        //----------------------------------------------------------------------------------------------------
        for (uint i = 0, j = 1; i < data.materials_count; i++, j++)
        {
            model.materials[j] = LoadMaterialDefault();
            const(char)* texPath = GetDirectoryPath(fileName);

            // Check glTF material flow: PBR metallic/roughness flow
            // NOTE: Alternatively, materials can follow PBR specular/glossiness flow
            if (data.materials[i].has_pbr_metallic_roughness)
            {
                // Load base color texture (albedo)
                if (data.materials[i].pbr_metallic_roughness.base_color_texture.texture)
                {
                    Image imAlbedo = LoadImageFromCgltfImage(data.materials[i].pbr_metallic_roughness.base_color_texture.texture.image, texPath);
                    if (imAlbedo.data != null)
                    {
                        model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_ALBEDO].texture = LoadTextureFromImage(imAlbedo);
                        UnloadImage(imAlbedo);
                    }

                    // Load base color factor (tint)
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_ALBEDO].color.r = cast(ubyte)(data.materials[i].pbr_metallic_roughness.base_color_factor[0]*255);
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_ALBEDO].color.g = cast(ubyte)(data.materials[i].pbr_metallic_roughness.base_color_factor[1]*255);
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_ALBEDO].color.b = cast(ubyte)(data.materials[i].pbr_metallic_roughness.base_color_factor[2]*255);
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_ALBEDO].color.a = cast(ubyte)(data.materials[i].pbr_metallic_roughness.base_color_factor[3]*255);
                }

                // Load metallic/roughness texture
                if (data.materials[i].pbr_metallic_roughness.metallic_roughness_texture.texture)
                {
                    Image imMetallicRoughness = LoadImageFromCgltfImage(data.materials[i].pbr_metallic_roughness.metallic_roughness_texture.texture.image, texPath);
                    if (imMetallicRoughness.data != null)
                    {
                        model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_ROUGHNESS].texture = LoadTextureFromImage(imMetallicRoughness);
                        UnloadImage(imMetallicRoughness);
                    }

                    // Load metallic/roughness material properties
                    float roughness = data.materials[i].pbr_metallic_roughness.roughness_factor;
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_ROUGHNESS].value = roughness;

                    float metallic = data.materials[i].pbr_metallic_roughness.metallic_factor;
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_METALNESS].value = metallic;
                }

                // Load normal texture
                if (data.materials[i].normal_texture.texture)
                {
                    Image imNormal = LoadImageFromCgltfImage(data.materials[i].normal_texture.texture.image, texPath);
                    if (imNormal.data != null)
                    {
                        model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_NORMAL].texture = LoadTextureFromImage(imNormal);
                        UnloadImage(imNormal);
                    }
                }

                // Load ambient occlusion texture
                if (data.materials[i].occlusion_texture.texture)
                {
                    Image imOcclusion = LoadImageFromCgltfImage(data.materials[i].occlusion_texture.texture.image, texPath);
                    if (imOcclusion.data != null)
                    {
                        model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_OCCLUSION].texture = LoadTextureFromImage(imOcclusion);
                        UnloadImage(imOcclusion);
                    }
                }

                // Load emissive texture
                if (data.materials[i].emissive_texture.texture)
                {
                    Image imEmissive = LoadImageFromCgltfImage(data.materials[i].emissive_texture.texture.image, texPath);
                    if (imEmissive.data != null)
                    {
                        model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_EMISSION].texture = LoadTextureFromImage(imEmissive);
                        UnloadImage(imEmissive);
                    }

                    // Load emissive color factor
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_EMISSION].color.r = cast(ubyte)(data.materials[i].emissive_factor[0]*255);
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_EMISSION].color.g = cast(ubyte)(data.materials[i].emissive_factor[1]*255);
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_EMISSION].color.b = cast(ubyte)(data.materials[i].emissive_factor[2]*255);
                    model.materials[j].maps[MaterialMapIndex.MATERIAL_MAP_EMISSION].color.a = 255;
                }
            }

            // Other possible materials not supported by raylib pipeline:
            // has_clearcoat, has_transmission, has_volume, has_ior, has specular, has_sheen
        }

        // Load meshes data
        //----------------------------------------------------------------------------------------------------
        for (uint i = 0, meshIndex = 0; i < data.meshes_count; i++)
        {
            // NOTE: meshIndex accumulates primitives

            for (uint p = 0; p < data.meshes[i].primitives_count; p++)
            {
                // NOTE: We only support primitives defined by triangles
                // Other alternatives: points, lines, line_strip, triangle_strip
                if (data.meshes[i].primitives[p].type != cgltf_primitive_type_triangles) continue;

                // NOTE: Attributes data could be provided in several data formats (8, 8u, 16u, 32...),
                // Only some formats for each attribute type are supported, read info at the top of this function!

                for (uint j = 0; j < data.meshes[i].primitives[p].attributes_count; j++)
                {
                    // Check the different attributes for every pimitive
                    if (data.meshes[i].primitives[p].attributes[j].type == cgltf_attribute_type_position)      // POSITION
                    {
                        cgltf_accessor* attribute = data.meshes[i].primitives[p].attributes[j].data;

                        // WARNING: SPECS: POSITION accessor MUST have its min and max properties defined.

                        if ((attribute.component_type == cgltf_component_type_r_32f) && (attribute.type == cgltf_type_vec3))
                        {
                            // Init raylib mesh vertices to copy glTF attribute data
                            model.meshes[meshIndex].vertexCount = cast(int)attribute.count;
                            model.meshes[meshIndex].vertices = cast(typeof(model.meshes[meshIndex].vertices))RL_MALLOC(attribute.count*3*int(float.sizeof));

                            // Load 3 components of float data type into mesh.vertices
                            mixin(LOAD_ATTRIBUTE!(`attribute`, `3`, `float`, `model.meshes[meshIndex].vertices`));
                        }
                        else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Vertices attribute data format not supported, use vec3 float", fileName);
                    }
                    else if (data.meshes[i].primitives[p].attributes[j].type == cgltf_attribute_type_normal)   // NORMAL
                    {
                        cgltf_accessor* attribute = data.meshes[i].primitives[p].attributes[j].data;

                        if ((attribute.component_type == cgltf_component_type_r_32f) && (attribute.type == cgltf_type_vec3))
                        {
                            // Init raylib mesh normals to copy glTF attribute data
                            model.meshes[meshIndex].normals = cast(typeof(model.meshes[meshIndex].normals))RL_MALLOC(attribute.count*3*int(float.sizeof));

                            // Load 3 components of float data type into mesh.normals
                            mixin(LOAD_ATTRIBUTE!(`attribute`, `3`, `float`, `model.meshes[meshIndex].normals`));
                        }
                        else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Normal attribute data format not supported, use vec3 float", fileName);
                    }
                    else if (data.meshes[i].primitives[p].attributes[j].type == cgltf_attribute_type_tangent)   // TANGENT
                    {
                        cgltf_accessor* attribute = data.meshes[i].primitives[p].attributes[j].data;

                        if ((attribute.component_type == cgltf_component_type_r_32f) && (attribute.type == cgltf_type_vec4))
                        {
                            // Init raylib mesh tangent to copy glTF attribute data
                            model.meshes[meshIndex].tangents = cast(typeof(model.meshes[meshIndex].tangents))RL_MALLOC(attribute.count*4*int(float.sizeof));

                            // Load 4 components of float data type into mesh.tangents
                            mixin(LOAD_ATTRIBUTE!(`attribute`, `4`, `float`, `model.meshes[meshIndex].tangents`));
                        }
                        else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Tangent attribute data format not supported, use vec4 float", fileName);
                    }
                    else if (data.meshes[i].primitives[p].attributes[j].type == cgltf_attribute_type_texcoord) // TEXCOORD_0
                    {
                        // TODO: Support additional texture coordinates: TEXCOORD_1 -> mesh.texcoords2

                        cgltf_accessor* attribute = data.meshes[i].primitives[p].attributes[j].data;

                        if ((attribute.component_type == cgltf_component_type_r_32f) && (attribute.type == cgltf_type_vec2))
                        {
                            // Init raylib mesh texcoords to copy glTF attribute data
                            model.meshes[meshIndex].texcoords = cast(typeof(model.meshes[meshIndex].texcoords))RL_MALLOC(attribute.count*2*int(float.sizeof));

                            // Load 3 components of float data type into mesh.texcoords
                            mixin(LOAD_ATTRIBUTE!(`attribute`, `2`, `float`, `model.meshes[meshIndex].texcoords`));
                        }
                        else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Texcoords attribute data format not supported, use vec2 float", fileName);
                    }
                    else if (data.meshes[i].primitives[p].attributes[j].type == cgltf_attribute_type_color)    // COLOR_0
                    {
                        cgltf_accessor* attribute = data.meshes[i].primitives[p].attributes[j].data;

                        // WARNING: SPECS: All components of each COLOR_n accessor element MUST be clamped to [0.0, 1.0] range.

                        if ((attribute.component_type == cgltf_component_type_r_8u) && (attribute.type == cgltf_type_vec4))
                        {
                            // Init raylib mesh color to copy glTF attribute data
                            model.meshes[meshIndex].colors = cast(typeof(model.meshes[meshIndex].colors))RL_MALLOC(attribute.count*4*int(ubyte.sizeof));

                            // Load 4 components of unsigned char data type into mesh.colors
                            mixin(LOAD_ATTRIBUTE!(`attribute`, `4`, `ubyte`, `model.meshes[meshIndex].colors`));
                        }
                        else if ((attribute.component_type == cgltf_component_type_r_16u) && (attribute.type == cgltf_type_vec4))
                        {
                            // Init raylib mesh color to copy glTF attribute data
                            model.meshes[meshIndex].colors = cast(typeof(model.meshes[meshIndex].colors))RL_MALLOC(attribute.count*4*int(ubyte.sizeof));

                            // Load data into a temp buffer to be converted to raylib data type
                            ushort* temp = cast(ushort*)RL_MALLOC(attribute.count*4*int(ushort.sizeof));
                            mixin(LOAD_ATTRIBUTE!(`attribute`, `4`, `ushort`, `temp`));;

                            // Convert data to raylib color data type (4 bytes)
                            for (int c = 0; c < attribute.count*4; c++) model.meshes[meshIndex].colors[c] = cast(ubyte)((cast(float)temp[c]/65535.0f)*255.0f);

                            RL_FREE(temp);
                        }
                        else if ((attribute.component_type == cgltf_component_type_r_32f) && (attribute.type == cgltf_type_vec4))
                        {
                            // Init raylib mesh color to copy glTF attribute data
                            model.meshes[meshIndex].colors = cast(typeof(model.meshes[meshIndex].colors))RL_MALLOC(attribute.count*4*int(ubyte.sizeof));

                            // Load data into a temp buffer to be converted to raylib data type
                            float* temp = cast(float*)RL_MALLOC(attribute.count*4*int(float.sizeof));
                            mixin(LOAD_ATTRIBUTE!(`attribute`, `4`, `float`, `temp`));

                            // Convert data to raylib color data type (4 bytes), we expect the color data normalized
                            for (int c = 0; c < attribute.count*4; c++) model.meshes[meshIndex].colors[c] = cast(ubyte)(temp[c]*255.0f);

                            RL_FREE(temp);
                        }
                        else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Color attribute data format not supported", fileName);
                    }

                    // NOTE: Attributes related to animations are processed separately
                }

                // Load primitive indices data (if provided)
                if (data.meshes[i].primitives[p].indices != null)
                {
                    cgltf_accessor* attribute = data.meshes[i].primitives[p].indices;

                    model.meshes[meshIndex].triangleCount = cast(int)attribute.count/3;

                    if (attribute.component_type == cgltf_component_type_r_16u)
                    {
                        // Init raylib mesh indices to copy glTF attribute data
                        model.meshes[meshIndex].indices = cast(typeof(model.meshes[meshIndex].indices))RL_MALLOC(attribute.count*int(ushort.sizeof));

                        // Load unsigned short data type into mesh.indices
                        mixin(LOAD_ATTRIBUTE!(`attribute`, `1`, `ushort`, `model.meshes[meshIndex].indices`));
                    }
                    else if (attribute.component_type == cgltf_component_type_r_32u)
                    {
                        // Init raylib mesh indices to copy glTF attribute data
                        model.meshes[meshIndex].indices = cast(typeof(model.meshes[meshIndex].indices))RL_MALLOC(attribute.count*int(ushort.sizeof));

                        // Load data into a temp buffer to be converted to raylib data type
                        uint* temp = cast(uint*)RL_MALLOC(attribute.count*uint.sizeof);
                        mixin(LOAD_ATTRIBUTE!(`attribute`, `1`, `uint`, `temp`));

                        // Convert data to raylib indices data type (unsigned short)
                        for (int d = 0; d < attribute.count; d++) model.meshes[meshIndex].indices[d] = cast(ushort)temp[d];

                        TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Indices data converted from u32 to u16, possible loss of data", fileName);

                        RL_FREE(temp);
                    }
                    else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Indices data format not supported, use u16", fileName);
                }
                else model.meshes[meshIndex].triangleCount = model.meshes[meshIndex].vertexCount/3;    // Unindexed mesh

                // Assign to the primitive mesh the corresponding material index
                // NOTE: If no material defined, mesh uses the already assigned default material (index: 0)
                for (int m = 0; m < data.materials_count; m++)
                {
                    // The primitive actually keeps the pointer to the corresponding material,
                    // raylib instead assigns to the mesh the by its index, as loaded in model.materials array
                    // To get the index, we check if material pointers match and we assign the corresponding index,
                    // skipping index 0, the default material
                    if (&data.materials[m] == data.meshes[i].primitives[p].material)
                    {
                        model.meshMaterial[meshIndex] = m + 1;
                        break;
                    }
                }

                meshIndex++;       // Move to next mesh
            }
        }

        // Free all cgltf loaded data
        cgltf_free(data);
    }
    else TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Failed to load glTF data", fileName);

    // WARNING: cgltf requires the file pointer available while reading data
    UnloadFileData(fileData);

    return model;
}
}

static if (SUPPORT_FILEFORMAT_VOX) {
// Load VOX (MagicaVoxel) mesh data
private Model LoadVOX(const(char)* fileName)
{
    Model model = Model.init; // { 0 };

    int nbvertices = 0;
    int meshescount = 0;
    uint fileSize = 0;
    ubyte* fileData = null;

    // Read vox file into buffer
    fileData = LoadFileData(fileName, &fileSize);
    if (fileData is null)
    {
        TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Failed to load VOX file", fileName);
        return model;
    }

    // Read and build voxarray description
    VoxArray3D voxarray = { 0 };
    int ret = Vox_LoadFromMemory(fileData, fileSize, &voxarray);

    if (ret != VOX_SUCCESS)
    {
        // Error
        UnloadFileData(fileData);

        TRACELOG(TraceLogLevel.LOG_WARNING, "MODEL: [%s] Failed to load VOX data", fileName);
        return model;
    }
    else
    {
        // Success: Compute meshes count
        nbvertices = voxarray.vertices.used;
        meshescount = 1 + (nbvertices/65536);

        TRACELOG(TraceLogLevel.LOG_INFO, "MODEL: [%s] VOX data loaded successfully : %i vertices/%i meshes", fileName, nbvertices, meshescount);
    }

    // Build models from meshes
    model.transform = MatrixIdentity();

    model.meshCount = meshescount;
    model.meshes = cast(Mesh*)RL_CALLOC(model.meshCount, Mesh.sizeof);

    model.meshMaterial = cast(int*)RL_CALLOC(model.meshCount, int.sizeof);

    model.materialCount = 1;
    model.materials = cast(Material*)RL_CALLOC(model.materialCount, Material.sizeof);
    model.materials[0] = LoadMaterialDefault();

    // Init model meshes
    int verticesRemain = voxarray.vertices.used;
    int verticesMax = 65532; // 5461 voxels x 12 vertices per voxel -> 65532 (must be inf 65536)

    // 6*4 = 12 vertices per voxel
    Vector3* pvertices = cast(Vector3*)voxarray.vertices.array;
    Color* pcolors = cast(Color*)voxarray.colors.array;

    ushort* pindices = voxarray.indices.array;    // 5461*6*6 = 196596 indices max per mesh

    int size = 0;

    for (int i = 0; i < meshescount; i++)
    {
        Mesh* pmesh = &model.meshes[i];
        memset(pmesh, 0, Mesh.sizeof);

        // Copy vertices
        pmesh.vertexCount = cast(int)fmin(verticesMax, verticesRemain);

        size = pmesh.vertexCount*int(float.sizeof) *3;
        pmesh.vertices = cast(typeof(pmesh.vertices))RL_MALLOC(size);
        memcpy(pmesh.vertices, pvertices, size);

        // Copy indices
        // TODO: Compute globals indices array
        size = voxarray.indices.used*int(ushort.sizeof);
        pmesh.indices = cast(typeof(pmesh.indices))RL_MALLOC(size);
        memcpy(pmesh.indices, pindices, size);

        pmesh.triangleCount = (pmesh.vertexCount/4)*2;

        // Copy colors
        size = pmesh.vertexCount*int(Color.sizeof);
        pmesh.colors = cast(typeof(pmesh.colors))RL_MALLOC(size);
        memcpy(pmesh.colors, pcolors, size);

        // First material index
        model.meshMaterial[i] = 0;

        verticesRemain -= verticesMax;
        pvertices += verticesMax;
        pcolors += verticesMax;
    }

    // Free buffers
    Vox_FreeArrays(&voxarray);
    UnloadFileData(fileData);

    return model;
}
}