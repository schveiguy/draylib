#include "config.h"     // Defines module configuration flags
#if defined(SUPPORT_FILEFORMAT_OBJ) || defined(SUPPORT_FILEFORMAT_MTL)
    #define TINYOBJ_LOADER_C_IMPLEMENTATION
    #include "external/tinyobj_loader_c.h"      // OBJ/MTL file formats loading
#endif

#if defined(SUPPORT_FILEFORMAT_GLTF)
    #define CGLTF_IMPLEMENTATION
    #include "external/cgltf.h"         // glTF file format loading
#endif

#if defined(SUPPORT_FILEFORMAT_VOX)
    #define VOX_LOADER_IMPLEMENTATION
    #include "external/vox_loader.h"    // VOX file format loading (MagikaVoxel)
#endif

#if defined(SUPPORT_MESH_GENERATION)
    #define PAR_SHAPES_IMPLEMENTATION
    #include "external/par_shapes.h"    // Shapes 3d parametric generation
#endif
