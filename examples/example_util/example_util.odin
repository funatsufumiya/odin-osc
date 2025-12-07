#+feature global-context

package example_util

import "core:fmt"
import "core:mem"

debug_tracking_allocator_or_not: Maybe(mem.Tracking_Allocator) = nil

debug_tracking_allocator_init :: proc() {
    // dummy function, do nothing relly here.
}

@(init)
_init :: proc() {
    when ODIN_DEBUG {
        fmt.println("[debug] using tracking allocator")
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)
        debug_tracking_allocator_or_not = track
    } else {
        debug_tracking_allocator_or_not = nil
    }
}

@(fini)
_deinit :: proc() {
    if debug_tracking_allocator_or_not != nil {
        track := debug_tracking_allocator_or_not.(mem.Tracking_Allocator)
        flag := false
        if len(track.allocation_map) > 0 {
            flag = true
            fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
            for _, entry in track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(track.bad_free_array) > 0 {
            flag = true
            fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
            for entry in track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        if !flag {
            fmt.println("[debug] tracking allocator test passed")
        }
        mem.tracking_allocator_destroy(&track)
    }
}