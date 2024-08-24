#if defined(__APPLE__)
    #define mach_vm_range_flags_t uint64_t
    #define mach_vm_range_tag_t uint16_t
    #include <mach/clock.h>
    #include <mach/mach.h>
#endif
