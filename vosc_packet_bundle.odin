package vosc

VERBOSE :: #config(VERBOSE, false)

ReadPacketOrBundleError :: union {
    ReadBundleError,
    ReadPacketError,
    ReadMessageError
}

ReadPacketError :: enum {
    LENGTH_TOO_SHORT,
    PAYLOAD_NOT_FOUND
}

ReadBundleError :: enum {
    LENGTH_TOO_SHORT,
    HEADER_MISMATCH,
    OSC_TIME_PARSE_FAILED,
    OSC_BUNDLE_SIZE_TOO_SHORT,
    OSC_BUNDLE_SIZE_MISMATCH,
    READ_PACKET_FAILED
}

// Read an OscBundle from payload, starting at index i
// returns error at last parameter
read_bundle :: proc(payload: []u8, i: int) -> (OscBundle, ReadBundleError) {
    if len(payload) < 12 {
        return OscBundle{}, .LENGTH_TOO_SHORT;
    }
    if string(payload[i:i+8]) != "#bundle\x00" {
        return OscBundle{}, .HEADER_MISMATCH;
    }
    idx := i + 8;
    time, next_idx, ok := read_osc_time(payload, idx);
    if !ok {
        return OscBundle{}, .OSC_TIME_PARSE_FAILED;
    }
    idx = next_idx;
    contents := make([dynamic]OscPacket, 0);
    for idx < len(payload) {
        if idx + 4 > len(payload) {
            break;
        }
        size := int(u32(payload[idx]) << 24 | u32(payload[idx+1]) << 16 | u32(payload[idx+2]) << 8 | u32(payload[idx+3]));
        idx += 4;
        if size < 0 {
            return OscBundle{}, .OSC_BUNDLE_SIZE_TOO_SHORT;
        }
        if idx + size > len(payload) {
            return OscBundle{}, .OSC_BUNDLE_SIZE_MISMATCH;
        }
        packet, err := read_packet(payload[idx:idx+size]);
        if err != nil {
            return OscBundle{}, .READ_PACKET_FAILED;
        }
        append(&contents, packet);
        idx += size;
    }
    return OscBundle{time = time, contents = contents[:]}, nil;
}

// Read an OscPacket from payload, starting at index i
read_packet :: proc(payload: []u8) -> (OscPacket, ReadPacketOrBundleError) {
    if len(payload) < 4 {
        return OscPacket{}, ReadPacketError.LENGTH_TOO_SHORT;
    }
    if payload[0] == '#' {
        bundle, err := read_bundle(payload, 0);
        if err != nil {
            return OscPacket{}, err;
        }
        return OscPacket{kind = OscPacketKind.bundle, bundle = bundle}, nil;
    } else if payload[0] == '/' {
        msg, _, err := read_message(payload, 0);
        if err != nil {
            return OscPacket{}, err;
        }
        return OscPacket{kind = OscPacketKind.message, msg = msg}, nil;
    } else {
        return OscPacket{}, ReadPacketError.PAYLOAD_NOT_FOUND;
    }
}

// Add an OscBundle to buffer (OSC format)
add_bundle :: proc(buffer: ^[dynamic]u8, bundle: OscBundle) {
    tmp_buf := make([dynamic]u8);
    defer delete(tmp_buf)

    add_padded_str(buffer, "#bundle");
    append(buffer, u8(0));
    append(buffer, u8((bundle.time.seconds >> 24) & 0xff));
    append(buffer, u8((bundle.time.seconds >> 16) & 0xff));
    append(buffer, u8((bundle.time.seconds >> 8) & 0xff));
    append(buffer, u8(bundle.time.seconds & 0xff));
    append(buffer, u8((bundle.time.frac >> 24) & 0xff));
    append(buffer, u8((bundle.time.frac >> 16) & 0xff));
    append(buffer, u8((bundle.time.frac >> 8) & 0xff));
    append(buffer, u8(bundle.time.frac & 0xff));
    for packet in bundle.contents {
        tmp_buf_len := len(tmp_buf);
        tmp_buf_len = 0;
        add_packet(&tmp_buf, packet);
        size := len(tmp_buf);
        append(buffer, u8((size >> 24) & 0xff));
        append(buffer, u8((size >> 16) & 0xff));
        append(buffer, u8((size >> 8) & 0xff));
        append(buffer, u8(size & 0xff));
        append_slice(buffer, tmp_buf[:]);
    }
}

// Add an OscPacket to buffer (OSC format)
add_packet :: proc(buffer: ^[dynamic]u8, packet: OscPacket) {
    if packet.kind == OscPacketKind.message {
        add_message(buffer, packet.msg);
    } else if packet.kind == OscPacketKind.bundle {
        add_bundle(buffer, packet.bundle);
    }
}

// Serialize the given OscBundle to a new buffer and return it
dgram_bundle :: proc(bundle: OscBundle) -> [dynamic]u8 {
    dgram := make([dynamic]u8);
    add_bundle(&dgram, bundle);
    return dgram;
}
