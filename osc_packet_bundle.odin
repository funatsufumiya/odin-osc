package osc

import "core:mem"
import "core:fmt"
import "core:time"

OscBundle :: struct {
    // time: OscTime,
    time: time.Time,
    contents: []OscPacket,
}

OscPacket :: union {
    OscMessage,
    OscBundle,
}

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
    OSC_BUNDLE_SIZE_PARSE_FAILED,
    OSC_BUNDLE_SIZE_TOO_SHORT,
    READ_PACKET_FAILED
}

delete_osc_packet :: proc(packet: OscPacket) {
    switch _ in packet {
        case OscMessage:
            delete_osc_message(packet.(OscMessage))
        case OscBundle:
            delete_osc_bundle(packet.(OscBundle))
    }
}

delete_osc_bundle :: proc(bundle: OscBundle) {
    for c in bundle.contents {
        delete_osc_packet(c)
    }

    delete(bundle.contents)
}

// Read an OscBundle from payload, starting at index i
// returns error at last parameter
read_bundle :: proc(payload: []u8, i: int, allocator: mem.Allocator = context.allocator) -> (OscBundle, ReadBundleError) {
    if len(payload) < 12 {
        return OscBundle{}, .LENGTH_TOO_SHORT
    }
    if string(payload[i:i+8]) != "#bundle\x00" {
        fmt.printfln("read_bundle: HEADER_MISMATCH, expected '#bundle\\x00' but {}", string(payload[i:i+8]))
        return OscBundle{}, .HEADER_MISMATCH
    }
    idx := i + 8
    time, next_idx, ok := read_osc_time(payload, idx)
    if !ok {
        return OscBundle{}, .OSC_TIME_PARSE_FAILED
    }

    when VERBOSE {
        fmt.printfln("read_bundle: idx {}", idx)
        fmt.printfln("read_bundle: bundle.time {}", time)
    }

    idx = next_idx
    contents := make([dynamic]OscPacket, 0, allocator)
    i := 0
    for idx < len(payload) {
        when VERBOSE {
            fmt.printfln("read_bundle: reading contents {}, idx = {}, len payload = {}", i, idx, len(payload))
        }

        if idx + 4 > len(payload) {
            when VERBOSE {
                fmt.printfln("payload EOF")
            }
            break
        }
        bytes, new_idx := read_u32(payload, idx)
        size := int(bytes)
        when VERBOSE {
            fmt.printfln("read_bundle: packet size {}", size)
        }
        if size < 0 {
            when VERBOSE {
                fmt.printfln("read_bundle: OSC_BUNDLE_SIZE_PARSE_FAILED")
            }
            return OscBundle{}, .OSC_BUNDLE_SIZE_PARSE_FAILED
        }
        if idx + size > len(payload) {
            when VERBOSE {
                fmt.printfln("read_bundle: OSC_BUNDLE_SIZE_TOO_SHORT, info below:")
                fmt.printfln("size specified: {}", size)
                fmt.printfln("size left: {}", len(payload) - idx)
                fmt.printfln("payload: {}", payload)
                fmt.printfln("idx: {}", idx)
                fmt.printfln("payload[idx]: {}", payload[idx])
                fmt.printfln("bytes: {}", bytes)
            }

            return OscBundle{}, .OSC_BUNDLE_SIZE_TOO_SHORT
        }
        idx = new_idx

        when VERBOSE {
            fmt.printfln("read_bundle: reading packet idx = {}, size = {}", idx, size)
        }

        packet, err := read_packet(payload[idx:idx+size])

        if err != nil {
            when VERBOSE {
                fmt.printfln("read_bundle: READ_PACKET_FAILED, info below:")
                fmt.printfln("packet size: {}", size)
                fmt.printfln("packet payload: {}", payload[idx:idx+size])
                fmt.printfln("idx from bundle: {}", idx)
            }

            return OscBundle{}, .READ_PACKET_FAILED
        }

        when VERBOSE {
            fmt.printfln("read_bundle: packet {} payload: {}", i, payload[idx:idx+size])
            fmt.printfln("read_bundle: content {} = {}", i, packet)
        }

        append(&contents, packet)
        idx += size

        i += 1
    }

    // result_bundle := OscBundle{time = time, contents = contents[:]}
    result_bundle := OscBundle{time = to_time(time), contents = contents[:]}

    when VERBOSE {
        fmt.printfln("read_bundle: result_bundle = {}", result_bundle)
    }

    return result_bundle, nil
}

// Read an OscPacket from payload, starting at index i
read_packet :: proc(payload: []u8, allocator: mem.Allocator = context.allocator) -> (OscPacket, ReadPacketBundleMessageError) {
    if len(payload) < 4 {
        return OscPacket{}, ReadPacketError.LENGTH_TOO_SHORT
    }
    if payload[0] == '#' {
        bundle, err := read_bundle(payload, 0, allocator)
        if err != nil {
            return OscPacket{}, err
        }
        return bundle, nil
    } else if payload[0] == '/' {
        msg, _, err := read_message(payload, 0, allocator)
        if err != nil {
            return OscPacket{}, err
        }
        return msg, nil
    } else {
        return OscPacket{}, ReadPacketError.PAYLOAD_NOT_FOUND
    }
}

// Add an OscBundle to buffer (OSC format)
add_bundle :: proc(buffer: ^[dynamic]u8, bundle: OscBundle) {
    tmp_buf := make([dynamic]u8)
    defer delete(tmp_buf)

    // add_padded_str(buffer, "#bundle\\x00")
    // append(buffer, u8(0))
    append_string(buffer, "#bundle\x00")

    osc_time := from_time(bundle.time)
    append_u32(buffer, osc_time.seconds)
    append_u32(buffer, osc_time.frac)

    when VERBOSE {
        fmt.printfln("add_bundle: time {}", bundle.time)
    }

    when VERBOSE {
        fmt.printfln("add_bundle: contents = {}", bundle.contents)
    }

    i := 0
    for packet in bundle.contents {
        when VERBOSE {
            fmt.printfln("add_bundle: add content {}: {}", i, packet)
        }

        pre_idx := len(tmp_buf)

        tmp_buf_len := len(tmp_buf)
        tmp_buf_len = 0
        add_packet(&tmp_buf, packet)
        size := len(tmp_buf) - pre_idx

        when VERBOSE {
            fmt.printfln("add_bundle: packet {}: {}", i, tmp_buf[pre_idx:pre_idx+size])
        }

        when VERBOSE {
            fmt.printfln("add_bundle: packet size {}", size)
        }

        append_u32(buffer, u32(size))
        append_slice(buffer, tmp_buf[pre_idx:pre_idx+size])

        i += 1
    }

    when VERBOSE {
        fmt.printfln("add_bundle: len(contents) = {}", i)
    }
}

// Add an OscPacket to buffer (OSC format)
add_packet :: proc(buffer: ^[dynamic]u8, packet: OscPacket) {
    switch _ in packet {
        case OscMessage:
            add_message(buffer, packet.(OscMessage))
        case OscBundle:
            add_bundle(buffer, packet.(OscBundle))
    }
}

// Serialize the given OscBundle to a new buffer and return it
dgram_bundle :: proc(bundle: OscBundle, allocator: mem.Allocator = context.allocator) -> [dynamic]u8 {
    dgram := make([dynamic]u8, allocator)
    add_bundle(&dgram, bundle)
    return dgram
}
