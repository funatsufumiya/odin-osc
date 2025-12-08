package osc

import "core:mem"
import "core:fmt"

ReadPacketBundleMessageError :: union {
    ReadBundleError,
    ReadPacketError,
    ReadMessageError
}

ReadPacketError :: enum {
    NONE,
    LENGTH_TOO_SHORT,
    PAYLOAD_NOT_FOUND
}

ReadBundleError :: enum {
    NONE,
    LENGTH_TOO_SHORT,
    HEADER_MISMATCH,
    OSC_TIME_PARSE_FAILED,
    OSC_BUNDLE_SIZE_TOO_SHORT,
    OSC_BUNDLE_SIZE_MISMATCH,
    READ_PACKET_FAILED
}

delete_osc_packet :: proc(packet: OscPacket) {
    delete_osc_bundle(packet.bundle)
    delete_osc_message(packet.msg)
}

delete_osc_bundle :: proc(bundle: OscBundle) {
    for c in bundle.contents {
        delete_osc_packet(c)
    }
}

// Read an OscBundle from payload, starting at index i
// returns error at last parameter
read_bundle :: proc(payload: []u8, i: int, allocator: mem.Allocator = context.allocator) -> (OscBundle, ReadBundleError) {
    if len(payload) < 12 {
        return OscBundle{}, .LENGTH_TOO_SHORT
    }
    if string(payload[i:i+8]) != "#bundle\x00" {
        return OscBundle{}, .HEADER_MISMATCH
    }
    idx := i + 8
    time, next_idx, ok := read_osc_time(payload, idx)
    if !ok {
        return OscBundle{}, .OSC_TIME_PARSE_FAILED
    }
    idx = next_idx
    contents := make([dynamic]OscPacket, 0, allocator)
    for idx < len(payload) {
        if idx + 4 > len(payload) {
            break
        }
        bytes, new_idx := read_u32(payload, idx)
        size := int(bytes)
        if size < 0 {
            return OscBundle{}, .OSC_BUNDLE_SIZE_TOO_SHORT
        }
        if idx + size > len(payload) {
            when VERBOSE {
                fmt.printfln("payload: {}", payload)
                fmt.printfln("idx: {}", idx)
                fmt.printfln("payload[idx]: {}", payload[idx])
                fmt.printfln("bytes: {}", bytes)
                fmt.printfln("size: {}", size)
            }
            return OscBundle{}, .OSC_BUNDLE_SIZE_MISMATCH
        }
        packet, err := read_packet(payload[idx:idx+size], allocator)
        if err != nil {
            return OscBundle{}, .READ_PACKET_FAILED
        }
        append(&contents, packet)
        // idx += size
        idx = new_idx
    }
    return OscBundle{time = time, contents = contents[:]}, nil
}

// Read an OscPacket from payload, starting at index i
read_packet :: proc(payload: []u8, allocator: mem.Allocator = context.allocator) -> (OscPacket, ReadPacketBundleMessageError) {
    if len(payload) < 4 {
        return OscPacket{}, ReadPacketError.LENGTH_TOO_SHORT
    }
    if payload[0] == '#' {
        bundle, err := read_bundle(payload, 0)
        if err != nil {
            return OscPacket{}, err
        }
        return OscPacket{kind = OscPacketKind.bundle, bundle = bundle}, nil
    } else if payload[0] == '/' {
        msg, _, err := read_message(payload, 0, allocator)
        if err != nil {
            return OscPacket{}, err
        }
        return OscPacket{kind = OscPacketKind.message, msg = msg}, nil
    } else {
        return OscPacket{}, ReadPacketError.PAYLOAD_NOT_FOUND
    }
}

// Add an OscBundle to buffer (OSC format)
add_bundle :: proc(buffer: ^[dynamic]u8, bundle: OscBundle) {
    tmp_buf := make([dynamic]u8)
    defer delete(tmp_buf)

    add_padded_str(buffer, "#bundle")
    append(buffer, u8(0))
    append_u32(buffer, bundle.time.seconds)
    append_u32(buffer, bundle.time.frac)
    for packet in bundle.contents {
        tmp_buf_len := len(tmp_buf)
        tmp_buf_len = 0
        add_packet(&tmp_buf, packet)
        size := len(tmp_buf)
        when VERBOSE {
            fmt.printfln("add_bundle size {}", size)
        }
        append_u32(buffer, u32(size))
        append_slice(buffer, tmp_buf[:])
    }
}

// Add an OscPacket to buffer (OSC format)
add_packet :: proc(buffer: ^[dynamic]u8, packet: OscPacket) {
    if packet.kind == OscPacketKind.message {
        add_message(buffer, packet.msg)
    } else if packet.kind == OscPacketKind.bundle {
        add_bundle(buffer, packet.bundle)
    }
}

// Serialize the given OscBundle to a new buffer and return it
dgram_bundle :: proc(bundle: OscBundle, allocator: mem.Allocator = context.allocator) -> [dynamic]u8 {
    dgram := make([dynamic]u8, allocator)
    add_bundle(&dgram, bundle)
    return dgram
}
