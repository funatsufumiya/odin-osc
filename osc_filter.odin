// This file implements the filtering functionality for osc messages.
// It exports functions for filtering messages based on specific criteria.

package osc

import "core:fmt"

OscPacketKind :: enum {
    message,
    bundle,
}

OscBundle :: struct {
    time: OscTime,
    contents: []OscPacket,
}

OscPacket :: struct {
    kind: OscPacketKind,
    msg: OscMessage,
    bundle: OscBundle,
}

filter_messages :: proc(packet: ^OscPacket, callback: proc(msg: ^OscMessage)) {
    if packet.kind == OscPacketKind.message {
        callback(&packet.msg)
    } else if packet.kind == OscPacketKind.bundle {
        bundle := packet.bundle
        // fmt.printfln("time: {}", bundle.time)
        for pac in bundle.contents {
            if pac.kind == OscPacketKind.message {
                msg := pac.msg
                callback(&msg)
            }
        }
    }
}

filter_address :: proc(packet: ^OscPacket, address: string, callback: proc(msg: ^OscMessage)) {
    if packet.kind == OscPacketKind.message {
        msg := &packet.msg
        if msg.address == address {
            callback(msg)
        }
    } else if packet.kind == OscPacketKind.bundle {
        bundle := packet.bundle
        // fmt.printfln("time: {}", bundle.time)
        for pac in bundle.contents {
            if pac.kind == OscPacketKind.message {
                msg := pac.msg
                if msg.address == address {
                    callback(&msg)
                }
            }
        }
    }
}