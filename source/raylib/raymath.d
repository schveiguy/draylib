/**********************************************************************************************
*
*   raymath v1.5 - Math functions to work with Vector2, Vector3, Matrix and Quaternions
*
*   CONFIGURATION:
*
*   #define RAYMATH_IMPLEMENTATION
*       Generates the implementation of the library into the included file.
*       If not defined, the library is in header only mode and can be included in other headers
*       or source files without problems. But only ONE file should hold the implementation.
*
*   #define RAYMATH_STATIC_INLINE
*       Define static inline functions code, so #include header suffices for use.
*       This may use up lots of memory.
*
*   CONVENTIONS:
*
*     - Functions are always self-contained, no function use another raymath function inside,
*       required code is directly re-implemented inside
*     - Functions input parameters are always received by value (2 unavoidable exceptions)
*     - Functions use always a "result" anmed variable for return
*     - Functions are always defined inline
*     - Angles are always in radians (DEG2RAD/RAD2DEG macros provided for convenience)
*
*
*   LICENSE: zlib/libpng
*
*   Copyright (c) 2015-2021 Ramon Santamaria (@raysan5)
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
module raylib.raymath;

extern (C) @nogc nothrow:

// Function specifiers definition

// We are building raylib as a Win32 shared library (.dll).

// We are using raylib as a Win32 shared library (.dll)

// Provide external definition

// Functions may be inlined, no external out-of-line definition

// plain inline not supported by tinycc (See issue #435) // Functions may be inlined or external definition used

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------

public import raylib: PI, DEG2RAD, RAD2DEG, Vector2, Vector3, Vector4, Quaternion, Matrix;
import core.stdc.math;
/+enum PI = 3.14159265358979323846f;

enum DEG2RAD = PI / 180.0f;

enum RAD2DEG = 180.0f / PI;
+/

// Get float vector for Matrix

extern (D) auto _devolveFloatArray(T)(ref T item)
{
    // build a shim which devolves to a pointer to float when needed
    static struct FloatThing {
        T item;
        auto _get() return { return &item[0]; }
        alias _get this;
    }
    return FloatThing(item);
}

extern (D) auto MatrixToFloat(T)(auto ref T mat)
{
    return MatrixToFloatV(mat).v._devolveFloatArray;
}

// Get float vector for Vector3

extern (D) auto Vector3ToFloat(T)(auto ref T vec)
{
    return Vector3ToFloatV(vec).v._devolveFloatArray;
}

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------

// Vector2 type
/+struct Vector2
{
    float x;
    float y;
}

// Vector3 type
struct Vector3
{
    float x;
    float y;
    float z;
}

// Vector4 type
struct Vector4
{
    float x;
    float y;
    float z;
    float w;
}

// Quaternion type
alias Quaternion = Vector4;

// Matrix type (OpenGL style 4x4 - right handed, column major)
struct Matrix
{
    float m0;
    float m4;
    float m8;
    float m12; // Matrix first row (4 components)
    float m1;
    float m5;
    float m9;
    float m13; // Matrix second row (4 components)
    float m2;
    float m6;
    float m10;
    float m14; // Matrix third row (4 components)
    float m3;
    float m7;
    float m11;
    float m15; // Matrix fourth row (4 components)
}+/

// NOTE: Helper types to be used instead of array return types for *ToFloat functions
struct float3
{
    float[3] v;
}

struct float16
{
    float[16] v;
}

// Required for: sinf(), cosf(), tan(), atan2f(), sqrtf(), fminf(), fmaxf(), fabs()

//----------------------------------------------------------------------------------
// Module Functions Definition - Utils math
//----------------------------------------------------------------------------------

// Clamp float value
float Clamp(float value, float min, float max)
{
    float result = value < min ? min : value;

    if (result > max) result = max;

    return result;
}

// Calculate linear interpolation between two floats
float Lerp(float start, float end, float amount)
{
    float result = start + amount * (end - start);

    return result;
}

// Normalize input value within input range
float Normalize(float value, float start, float end)
{
    float result = (value - start) / (end - start);

    return result;
}

// Remap input value within input range to output range
float Remap(float value, float inputStart, float inputEnd, float outputStart, float outputEnd)
{
    float result = (value - inputStart) / (inputEnd - inputStart) * (outputEnd - outputStart) + outputStart;

    return result;
}

//----------------------------------------------------------------------------------
// Module Functions Definition - Vector2 math
//----------------------------------------------------------------------------------

// Vector with components value 0.0f
Vector2 Vector2Zero()
{
    return Vector2(0, 0);
}

// Vector with components value 1.0f
Vector2 Vector2One()
{
    return Vector2(1, 1);
}

// Add two vectors (v1 + v2)
Vector2 Vector2Add(Vector2 v1, Vector2 v2)
{
    Vector2 result = { v1.x + v2.x, v1.y + v2.y };

    return result;
}

// Add vector and float value
Vector2 Vector2AddValue(Vector2 v, float add)
{
    Vector2 result = { v.x + add, v.y + add };

    return result;
}

// Subtract two vectors (v1 - v2)
Vector2 Vector2Subtract(Vector2 v1, Vector2 v2)
{
    Vector2 result = { v1.x - v2.x, v1.y - v2.y };

    return result;
}

// Subtract vector by float value
Vector2 Vector2SubtractValue(Vector2 v, float sub)
{
    Vector2 result = { v.x - sub, v.y - sub };

    return result;
}

// Calculate vector length
float Vector2Length(Vector2 v)
{
    float result = sqrtf(v.x * v.x + v.y * v.y);

    return result;
}

// Calculate vector square length
float Vector2LengthSqr(Vector2 v)
{
    float result = v.x * v.x + v.y * v.y;

    return result;
}

// Calculate two vectors dot product
float Vector2DotProduct(Vector2 v1, Vector2 v2)
{
    float result = v1.x * v2.x + v1.y * v2.y;

    return result;
}

// Calculate distance between two vectors
float Vector2Distance(Vector2 v1, Vector2 v2)
{
    float result = sqrtf((v1.x - v2.x) * (v1.x - v2.x) + (v1.y - v2.y) * (v1.y - v2.y));

    return result;
}

// Calculate angle from two vectors in X-axis
float Vector2Angle(Vector2 v1, Vector2 v2)
{
    float result = atan2f(v2.y - v1.y, v2.x - v1.x) * (180.0f / PI);

    if (result < 0) result += 360.0f;

    return result;
}

// Scale vector (multiply by value)
Vector2 Vector2Scale(Vector2 v, float scale)
{
    Vector2 result = { v.x * scale, v.y * scale };

    return result;
}

// Multiply vector by vector
Vector2 Vector2Multiply(Vector2 v1, Vector2 v2)
{
    Vector2 result = { v1.x * v2.x, v1.y * v2.y };

    return result;
}

// Negate vector
Vector2 Vector2Negate(Vector2 v)
{
    Vector2 result = { -v.x, -v.y };

    return result;
}

// Divide vector by vector
Vector2 Vector2Divide(Vector2 v1, Vector2 v2)
{
    Vector2 result = { v1.x / v2.x, v1.y / v2.y };

    return result;
}

// Normalize provided vector
Vector2 Vector2Normalize(Vector2 v)
{
    auto result = Vector2(0, 0);
    float length = sqrtf(v.x * v.x + v.y * v.y);

    if (length > 0)
    {
        result.x = v.x * 1.0f / length;
        result.y = v.y * 1.0f / length;
    }

    return result;
}

// Calculate linear interpolation between two vectors
Vector2 Vector2Lerp(Vector2 v1, Vector2 v2, float amount)
{
    auto result = Vector2(0, 0);

    result.x = v1.x + amount * (v2.x - v1.x);
    result.y = v1.y + amount * (v2.y - v1.y);

    return result;
}

// Calculate reflected vector to normal

// Dot product
Vector2 Vector2Reflect(Vector2 v, Vector2 normal)
{
    auto result = Vector2(0, 0);

    float dotProduct = (v.x * normal.x + v.y * normal.y); // Dot product

    result.x = v.x - (2.0f * normal.x) * dotProduct;
    result.y = v.y - (2.0f * normal.y) * dotProduct;

    return result;
}

// Rotate vector by angle
Vector2 Vector2Rotate(Vector2 v, float angle)
{
    auto result = Vector2(0, 0);

    result.x = v.x * cosf(angle) - v.y * sinf(angle);
    result.y = v.x * sinf(angle) + v.y * cosf(angle);

    return result;
}

// Move Vector towards target
Vector2 Vector2MoveTowards(Vector2 v, Vector2 target, float maxDistance)
{
    auto result = Vector2(0, 0);

    float dx = target.x - v.x;
    float dy = target.y - v.y;
    float value = (dx * dx) + (dy * dy);

    if ((value == 0) || ((maxDistance >= 0) && (value <= maxDistance * maxDistance))) return target;

    float dist = sqrtf(value);

    result.x = v.x + dx / dist * maxDistance;
    result.y = v.y + dy / dist * maxDistance;

    return result;
}

//----------------------------------------------------------------------------------
// Module Functions Definition - Vector3 math
//----------------------------------------------------------------------------------

// Vector with components value 0.0f
Vector3 Vector3Zero()
{
    Vector3 result = { 0.0f, 0.0f, 0.0f };

    return result;
}

// Vector with components value 1.0f
Vector3 Vector3One()
{
    Vector3 result = { 1.0f, 1.0f, 1.0f };

    return result;
}

// Add two vectors
Vector3 Vector3Add(Vector3 v1, Vector3 v2)
{
    Vector3 result = { v1.x + v2.x, v1.y + v2.y, v1.z + v2.z };

    return result;
}

// Add vector and float value
Vector3 Vector3AddValue(Vector3 v, float add)
{
    Vector3 result = { v.x + add, v.y + add, v.z + add };

    return result;
}

// Subtract two vectors
Vector3 Vector3Subtract(Vector3 v1, Vector3 v2)
{
    Vector3 result = { v1.x - v2.x, v1.y - v2.y, v1.z - v2.z };

    return result;
}

// Subtract vector by float value
Vector3 Vector3SubtractValue(Vector3 v, float sub)
{
    Vector3 result = { v.x - sub, v.y - sub, v.z - sub };

    return result;
}

// Multiply vector by scalar
Vector3 Vector3Scale(Vector3 v, float scalar)
{
    Vector3 result = { v.x * scalar, v.y * scalar, v.z * scalar };

    return result;
}

// Multiply vector by vector
Vector3 Vector3Multiply(Vector3 v1, Vector3 v2)
{
    Vector3 result = { v1.x * v2.x, v1.y * v2.y, v1.z * v2.z };

    return result;
}

// Calculate two vectors cross product
Vector3 Vector3CrossProduct(Vector3 v1, Vector3 v2)
{
    Vector3 result = { v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x };

    return result;
}
// Calculate one vector perpendicular vector

// Cross product between vectors
Vector3 Vector3Perpendicular(Vector3 v)
{
    auto result = Vector3(0, 0, 0);

    float min = cast(float)fabs(v.x);
    Vector3 cardinalAxis = {1.0f, 0.0f, 0.0f};

    if (fabs(v.y) < min)
    {
        min = cast(float)fabs(v.y);
        Vector3 tmp = {0.0f, 1.0f, 0.0f};
        cardinalAxis = tmp;
    }

    if (fabs(v.z) < min)
    {
        Vector3 tmp = {0.0f, 0.0f, 1.0f};
        cardinalAxis = tmp;
    }

    // Cross product between vectors
    result.x = v.y * cardinalAxis.z - v.z * cardinalAxis.y;
    result.y = v.z * cardinalAxis.x - v.x * cardinalAxis.z;
    result.z = v.x * cardinalAxis.y - v.y * cardinalAxis.x;

    return result;
}

// Calculate vector length
float Vector3Length(const Vector3 v)
{
    float result = sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);

    return result;
}

// Calculate vector square length
float Vector3LengthSqr(const Vector3 v)
{
    float result = v.x * v.x + v.y * v.y + v.z * v.z;

    return result;
}

// Calculate two vectors dot product
float Vector3DotProduct(Vector3 v1, Vector3 v2)
{
    float result = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;

    return result;
}

// Calculate distance between two vectors
float Vector3Distance(Vector3 v1, Vector3 v2)
{
    float result = 0.0f;

    float dx = v2.x - v1.x;
    float dy = v2.y - v1.y;
    float dz = v2.z - v1.z;
    result = sqrtf(dx * dx + dy * dy + dz * dz);

    return result;
}

// Calculate angle between two vectors in XY and XZ

// Angle in XZ
// Angle in XY
Vector2 Vector3Angle(Vector3 v1, Vector3 v2)
{
    auto result = Vector2(0, 0);

    float dx = v2.x - v1.x;
    float dy = v2.y - v1.y;
    float dz = v2.z - v1.z;

    result.x = atan2f(dx, dz);                      // Angle in XZ
    result.y = atan2f(dy, sqrtf(dx * dx + dz * dz));// Angle in XY

    return result;
}
// Negate provided vector (invert direction)
Vector3 Vector3Negate(Vector3 v)
{
    Vector3 result = { -v.x, -v.y, -v.z };

    return result;
}

// Divide vector by vector
Vector3 Vector3Divide(Vector3 v1, Vector3 v2)
{
    Vector3 result = { v1.x / v2.x, v1.y / v2.y, v1.z / v2.z };

    return result;
}

// Normalize provided vector
Vector3 Vector3Normalize(Vector3 v)
{
    Vector3 result = v;

    float length = sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
    if (length == 0.0f) length = 1.0f;
    float ilength = 1.0f / length;

    result.x *= ilength;
    result.y *= ilength;
    result.z *= ilength;

    return result;
}
// Orthonormalize provided vectors
// Makes vectors normalized and orthogonal to each other
// Gram-Schmidt function implementation

// Vector3Normalize(*v1);

// Vector3CrossProduct(*v1, *v2)

// Vector3Normalize(vn1);

// Vector3CrossProduct(vn1, *v1)
void Vector3OrthoNormalize(Vector3* v1, Vector3* v2)
{
    float length = 0.0f;
    float ilength = 0.0f;

    // Vector3Normalize(*v1);
    Vector3 v = *v1;
    length = sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
    if (length == 0.0f) length = 1.0f;
    ilength = 1.0f/length;
    v1->x *= ilength;
    v1->y *= ilength;
    v1->z *= ilength;

    // Vector3CrossProduct(*v1, *v2)
    Vector3 vn1 = { v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x };

    // Vector3Normalize(vn1);
    v = vn1;
    length = sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
    if (length == 0.0f) length = 1.0f;
    ilength = 1.0f / length;
    vn1.x *= ilength;
    vn1.y *= ilength;
    vn1.z *= ilength;

    // Vector3CrossProduct(vn1, *v1)
    Vector3 vn2 = { vn1.y * v1.z - vn1.z * v1.y, vn1.z * v1.x - vn1.x * v1.z, vn1.x * v1.y - vn1.y * v1.x };

    *v2 = vn2;
}

// Transforms a Vector3 by a given Matrix
Vector3 Vector3Transform(Vector3 v, Matrix mat)
{
    auto result = Vector3(0, 0, 0);

    float x = v.x;
    float y = v.y;
    float z = v.z;

    result.x = mat.m0 * x + mat.m4 * y + mat.m8 * z + mat.m12;
    result.y = mat.m1 * x + mat.m5 * y + mat.m9 * z + mat.m13;
    result.z = mat.m2 * x + mat.m6 * y + mat.m10 * z + mat.m14;

    return result;
}

// Transform a vector by quaternion rotation
Vector3 Vector3RotateByQuaternion(Vector3 v, Quaternion q)
{
    auto result = Vector3(0, 0, 0);

    result.x = v.x * (q.x * q.x + q.w * q.w - q.y * q.y - q.z * q.z) + v.y * (2 * q.x * q.y - 2 * q.w * q.z) + v.z * (2 * q.x * q.z + 2 * q.w * q.y);
    result.y = v.x * (2 * q.w * q.z + 2 * q.x * q.y) + v.y * (q.w * q.w - q.x * q.x + q.y * q.y - q.z * q.z) + v.z * (-2 * q.w * q.x + 2 * q.y * q.z);
    result.z = v.x * (-2 * q.w * q.y + 2 * q.x * q.z) + v.y * (2 * q.w * q.x + 2 * q.y * q.z)+ v.z * (q.w * q.w - q.x * q.x - q.y * q.y + q.z * q.z);

    return result;
}

// Calculate linear interpolation between two vectors
Vector3 Vector3Lerp(Vector3 v1, Vector3 v2, float amount)
{
    auto result = Vector3(0, 0, 0);

    result.x = v1.x + amount * (v2.x - v1.x);
    result.y = v1.y + amount * (v2.y - v1.y);
    result.z = v1.z + amount * (v2.z - v1.z);

    return result;
}
// Calculate reflected vector to normal

// I is the original vector
// N is the normal of the incident plane
// R = I - (2*N*(DotProduct[I, N]))
Vector3 Vector3Reflect(Vector3 v, Vector3 normal)
{
   auto result = Vector3(0, 0, 0);

    // I is the original vector
    // N is the normal of the incident plane
    // R = I - (2*N*(DotProduct[I, N]))

    float dotProduct = v.x * normal.x + v.y * normal.y + v.z * normal.z;

    result.x = v.x - (2.0f * normal.x) * dotProduct;
    result.y = v.y - (2.0f * normal.y) * dotProduct;
    result.z = v.z - (2.0f * normal.z) * dotProduct;

    return result;
}

// Get min value for each pair of components
Vector3 Vector3Min(Vector3 v1, Vector3 v2)
{
    auto result = Vector3(0, 0, 0);

    result.x = fminf(v1.x, v2.x);
    result.y = fminf(v1.y, v2.y);
    result.z = fminf(v1.z, v2.z);

    return result;
}

// Get max value for each pair of components
Vector3 Vector3Max(Vector3 v1, Vector3 v2)

// Compute barycenter coordinates (u, v, w) for point p with respect to triangle (a, b, c)
// NOTE: Assumes P is on the plane of the triangle

// Vector3Subtract(b, a)
// Vector3Subtract(c, a)
// Vector3Subtract(p, a)
// Vector3DotProduct(v0, v0)
// Vector3DotProduct(v0, v1)
// Vector3DotProduct(v1, v1)
// Vector3DotProduct(v2, v0)
// Vector3DotProduct(v2, v1)
Vector3 Vector3Barycenter(Vector3 p, Vector3 a, Vector3 b, Vector3 c)

// Projects a Vector3 from screen space into object space
// NOTE: We are avoiding calling other raymath functions despite available

// Calculate unproject matrix (multiply view patrix by projection matrix) and invert it
// MatrixMultiply(view, projection);

// Calculate inverted matrix -> MatrixInvert(matViewProj);
// Cache the matrix values (speed optimization)

// Calculate the invert determinant (inlined to avoid double-caching)

// Create quaternion from source point

// Multiply quat point by unproject matrix
// QuaternionTransform(quat, matViewProjInv)

// Normalized world points in vectors
Vector3 Vector3Unproject(Vector3 source, Matrix projection, Matrix view)

// Get Vector3 as float array
float3 Vector3ToFloatV(Vector3 v)

//----------------------------------------------------------------------------------
// Module Functions Definition - Matrix math
//----------------------------------------------------------------------------------

// Compute matrix determinant

// Cache the matrix values (speed optimization)
float MatrixDeterminant(Matrix mat)

// Get the trace of the matrix (sum of the values along the diagonal)
float MatrixTrace(Matrix mat)

// Transposes provided matrix
Matrix MatrixTranspose(Matrix mat)

// Invert provided matrix

// Cache the matrix values (speed optimization)

// Calculate the invert determinant (inlined to avoid double-caching)
Matrix MatrixInvert(Matrix mat)

// Normalize provided matrix

// Cache the matrix values (speed optimization)

// MatrixDeterminant(mat)
Matrix MatrixNormalize(Matrix mat)

// Get identity matrix
Matrix MatrixIdentity()

// Add two matrices
Matrix MatrixAdd(Matrix left, Matrix right)

// Subtract two matrices (left - right)
Matrix MatrixSubtract(Matrix left, Matrix right)

// Get two matrix multiplication
// NOTE: When multiplying matrices... the order matters!
Matrix MatrixMultiply(Matrix left, Matrix right)

// Get translation matrix
Matrix MatrixTranslate(float x, float y, float z)

// Create rotation matrix from axis and angle
// NOTE: Angle should be provided in radians
Matrix MatrixRotate(Vector3 axis, float angle)

// Get x-rotation matrix (angle in radians)

// MatrixIdentity()
Matrix MatrixRotateX(float angle)

// Get y-rotation matrix (angle in radians)

// MatrixIdentity()
Matrix MatrixRotateY(float angle)

// Get z-rotation matrix (angle in radians)

// MatrixIdentity()
Matrix MatrixRotateZ(float angle)

// Get xyz-rotation matrix (angles in radians)

// MatrixIdentity()
Matrix MatrixRotateXYZ(Vector3 ang)

// Get zyx-rotation matrix (angles in radians)
Matrix MatrixRotateZYX(Vector3 ang)

// Get scaling matrix
Matrix MatrixScale(float x, float y, float z)

// Get perspective projection matrix
Matrix MatrixFrustum(
    double left,
    double right,
    double bottom,
    double top,
    double near,
    double far)

// Get perspective projection matrix
// NOTE: Angle should be provided in radians

// MatrixFrustum(-right, right, -top, top, near, far);
Matrix MatrixPerspective(double fovy, double aspect, double near, double far)

// Get orthographic projection matrix
Matrix MatrixOrtho(
    double left,
    double right,
    double bottom,
    double top,
    double near,
    double far)

// Get camera look-at matrix (view matrix)

// Vector3Subtract(eye, target)

// Vector3Normalize(vz)

// Vector3CrossProduct(up, vz)

// Vector3Normalize(x)

// Vector3CrossProduct(vz, vx)

// Vector3DotProduct(vx, eye)
// Vector3DotProduct(vy, eye)
// Vector3DotProduct(vz, eye)
Matrix MatrixLookAt(Vector3 eye, Vector3 target, Vector3 up)

// Get float array of matrix data
float16 MatrixToFloatV(Matrix mat)

//----------------------------------------------------------------------------------
// Module Functions Definition - Quaternion math
//----------------------------------------------------------------------------------

// Add two quaternions
Quaternion QuaternionAdd(Quaternion q1, Quaternion q2)

// Add quaternion and float value
Quaternion QuaternionAddValue(Quaternion q, float add)

// Subtract two quaternions
Quaternion QuaternionSubtract(Quaternion q1, Quaternion q2)

// Subtract quaternion and float value
Quaternion QuaternionSubtractValue(Quaternion q, float sub)

// Get identity quaternion
Quaternion QuaternionIdentity()

// Computes the length of a quaternion
float QuaternionLength(Quaternion q)

// Normalize provided quaternion
Quaternion QuaternionNormalize(Quaternion q)

// Invert provided quaternion
Quaternion QuaternionInvert(Quaternion q)

// Calculate two quaternion multiplication
Quaternion QuaternionMultiply(Quaternion q1, Quaternion q2)

// Scale quaternion by float value
Quaternion QuaternionScale(Quaternion q, float mul)

// Divide two quaternions
Quaternion QuaternionDivide(Quaternion q1, Quaternion q2)

// Calculate linear interpolation between two quaternions
Quaternion QuaternionLerp(Quaternion q1, Quaternion q2, float amount)

// Calculate slerp-optimized interpolation between two quaternions

// QuaternionLerp(q1, q2, amount)

// QuaternionNormalize(q);
Quaternion QuaternionNlerp(Quaternion q1, Quaternion q2, float amount)

// Calculates spherical linear interpolation between two quaternions
Quaternion QuaternionSlerp(Quaternion q1, Quaternion q2, float amount)

// Calculate quaternion based on the rotation from one vector to another

// Vector3DotProduct(from, to)
// Vector3CrossProduct(from, to)

// QuaternionNormalize(q);
// NOTE: Normalize to essentially nlerp the original and identity to 0.5
Quaternion QuaternionFromVector3ToVector3(Vector3 from, Vector3 to)

// Get a quaternion for a given rotation matrix
Quaternion QuaternionFromMatrix(Matrix mat)

// Get a matrix for a given quaternion

// MatrixIdentity()
Matrix QuaternionToMatrix(Quaternion q)

// Get rotation quaternion for an angle and axis
// NOTE: angle must be provided in radians

// Vector3Normalize(axis)

// QuaternionNormalize(q);
Quaternion QuaternionFromAxisAngle(Vector3 axis, float angle)

// Get the rotation angle and axis for a given quaternion

// QuaternionNormalize(q);

// This occurs when the angle is zero.
// Not a problem: just set an arbitrary normalized axis.
void QuaternionToAxisAngle(Quaternion q, Vector3* outAxis, float* outAngle)

// Get the quaternion equivalent to Euler angles
// NOTE: Rotation order is ZYX
Quaternion QuaternionFromEuler(float pitch, float yaw, float roll)

// Get the Euler angles equivalent to quaternion (roll, pitch, yaw)
// NOTE: Angles are returned in a Vector3 struct in radians

// Roll (x-axis rotation)

// Pitch (y-axis rotation)

// Yaw (z-axis rotation)
Vector3 QuaternionToEuler(Quaternion q)

// Transform a quaternion given a transformation matrix
Quaternion QuaternionTransform(Quaternion q, Matrix mat)

// RAYMATH_H
