#+feature global-context

package example_util

import "core:fmt"
import "core:mem"
import "core:net"

debug_tracking_allocator_or_not: Maybe(mem.Tracking_Allocator) = nil

ipv6_to_str :: proc(addr: net.IP6_Address, allocator: mem.Allocator = context.allocator) -> string {
    return fmt.aprintf("{}:{}:{}:{}:{}:{}:{}:{}",
        addr[0], addr[1], addr[2], addr[3],
        addr[4], addr[5], addr[6], addr[7],
        allocator=allocator)
}

ipv4_to_str :: proc(addr: net.IP4_Address, allocator: mem.Allocator = context.allocator) -> string {
    return fmt.aprintf("{}.{}.{}.{}",
        addr[0], addr[1], addr[2], addr[3], allocator=allocator)
}

ip_address_to_str :: proc(addr: net.Address, allocator: mem.Allocator = context.allocator) -> string {
    switch _ in addr {
        case net.IP4_Address:
            return ipv4_to_str(addr.(net.IP4_Address))
        case net.IP6_Address:
            return ipv6_to_str(addr.(net.IP6_Address))
    }

    panic("unreachable")
}

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