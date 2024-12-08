#if defined(__APPLE__)
    #define mach_vm_range_flags_t uint64_t
    #define mach_vm_range_tag_t uint16_t
    #include <mach/clock.h>
    //#include <mach/mach.h> // Note, importC is broken for this: https://issues.dlang.org/show_bug.cgi?id=24718
    // Workaround, include things that are needed, define one piece that is problematic
    #include <mach/mach_host.h>
    #include <mach/mach_init.h>
    #include <mach/mach_port.h>
    struct mach_vm_range {
        mach_vm_offset_t        min_address;
        mach_vm_offset_t        max_address;
    };
    typedef struct mach_vm_range *mach_vm_range_t;

#endif
