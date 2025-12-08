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

OscPacket :: union {
    OscMessage,
    OscBundle,
}

filter_messages :: proc(packet: ^OscPacket, callback: proc(msg: ^OscMessage)) {
    switch _ in packet {
        case OscMessage:
            msg := packet.(OscMessage)
            callback(&msg)
        case OscBundle:
            bundle := packet.(OscBundle)
            // fmt.printfln("time: {}", bundle.time)
            for &pac in bundle.contents {
                // call recursive
                filter_messages(&pac, callback)
            }
    }
}

filter_address :: proc(packet: ^OscPacket, address: string, callback: proc(msg: ^OscMessage)) {
    switch _ in packet {
        case OscMessage:
            msg := packet.(OscMessage)
            if msg.address == address {
                callback(&msg)
            }
        case OscBundle:
            bundle := packet.(OscBundle)
            // fmt.printfln("time: {}", bundle.time)
            for &pac in bundle.contents {
                // call recursive
                filter_messages(&pac, callback)
            }
    }
}