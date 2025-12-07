package vosc

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:math"

// OscTime
OscTime :: struct {
    seconds: u32,
    frac:    u32,
}
osc_time_immediate: OscTime = OscTime{seconds=0, frac=1}

// OscColor
OscColor :: struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}

// OscBlob
OscBlob :: struct {
    blob: []u8,
}

// OscMidi
OscMidi :: struct {
    port_id: u8,
    status:  u8,
    data1:   u8,
    data2:   u8,
}

// OscBigIntValue
OscBigIntValue :: struct {
    big_int_val: i64,
}

// OscNilValue, OscInfValue
OscNilValue :: struct {}
OscInfValue :: struct {}

// OscValue union
OscValue :: union {
    int,
    f32,
    f64,
    string,
    bool,
    OscBlob,
    rune,
    OscBigIntValue,
    OscTime,
    OscColor,
    OscMidi,
    []OscValue,
    OscNilValue,
    OscInfValue,
}

// OscMessage
OscMessage :: struct {
    address: string,
    args:    []OscValue,
}

fraction_to_nano :: proc(fraction: u32) -> u32 {
    return u32((u64(fraction) * 1_000_000_000) / (1 << 32))
}

nano_to_fraction :: proc(nanoseconds: u32) -> u32 {
    return u32((u64(nanoseconds) * (1 << 32)) / 1_000_000_000)
}

is_immediate :: proc(t: OscTime) -> bool {
    return t.seconds == osc_time_immediate.seconds && t.frac == osc_time_immediate.frac
}

to_color :: proc(c: OscColor) -> u32 {
    return (u32(c.r) << 16) | (u32(c.g) << 8) | u32(c.b)
}

extract_rgb :: proc(a: u32) -> OscColor {
    return OscColor{
        r = u8((a >> 16) & 0xff),
        g = u8((a >> 8) & 0xff),
        b = u8(a & 0xff),
        a = 255,
    };
}

// Add time to buffer (big-endian)
add_time :: proc(buffer: ^[dynamic]u8, time: OscTime) {
    append(buffer, u8((time.seconds >> 24) & 0xff));
    append(buffer, u8((time.seconds >> 16) & 0xff));
    append(buffer, u8((time.seconds >> 8) & 0xff));
    append(buffer, u8(time.seconds & 0xff));
    append(buffer, u8((time.frac >> 24) & 0xff));
    append(buffer, u8((time.frac >> 16) & 0xff));
    append(buffer, u8((time.frac >> 8) & 0xff));
    append(buffer, u8(time.frac & 0xff));
}

// to_osc_color: Convert u32 color + alpha to OscColor
to_osc_color :: proc(c: u32, alpha: u8) -> OscColor {
    rgb := extract_rgb(c);
    return OscColor{
        r = rgb.r,
        g = rgb.g,
        b = rgb.b,
        a = alpha,
    };
}

// Pad the given length to the next multiple of 4.
padded4 :: proc(length: int) -> int {
    if length % 4 != 0 {
        return length + (4 - length % 4);
    } else {
        return length;
    }
}

append_slice :: proc(buffer: ^[dynamic]u8, val: []u8) {
    for v in val {
        append(buffer, v)
    }
}

str_bytes :: proc(s: string, allocator: mem.Allocator = context.allocator) -> []u8 {
    bytes := make([dynamic]u8, allocator)
    for r in s {
        u := u8(r)
        append(&bytes, u)
    }
    return bytes[:]
}

// Add a padded string to buffer (OSC format)
add_padded_str :: proc(buffer: ^[dynamic]u8, val: string) {
    bytes := str_bytes(val)
    defer delete(bytes)

    append_slice(buffer, bytes);
    rem := 4 - (len(val) % 4)
    for _ in 0..<rem {
        append(buffer, u8(0))
    }
}

// Add a blob to buffer (OSC format)
add_blob :: proc(buffer: ^[dynamic]u8, val: []u8) {
    append_slice(buffer, val);
    if len(val) % 4 != 0 {
        rem := 4 - (len(val) % 4);
        for _ in 0..<rem {
            append(buffer, u8(0));
        }
    }
}

// index_byte: Find index of sep in slice
index_byte :: proc(s: []u8, sep: u8) -> int {
    for i in 0..<len(s) {
        if s[i] == sep {
            return i;
        }
    }
    return -1;
}

// Read a padded string from payload, updating index
// last bool (ok) return error or not
read_padded_str :: proc(payload: []u8, i: int) -> (string, int, bool) {
    if i >= len(payload) {
        return "", i, false
    }
    buf := payload[i:];
    len_ := index_byte(buf, 0);
    if len_ == -1 {
        return "", i, false
    }
    result := buf[:len_];
    next_index := i + padded4(len_ + 1); // len + 1 for the \0
    return string(result), next_index, true
}

// Read OscTime from payload, updating index
// last bool (ok) return error or not
read_osc_time :: proc(payload: []u8, i: int) -> (OscTime, int, bool) {
    if i+8 > len(payload) {
        return OscTime{}, i, false
    }
    result: OscTime;
    result.seconds = u32(payload[i]) << 24 | u32(payload[i+1]) << 16 | u32(payload[i+2]) << 8 | u32(payload[i+3])
    result.frac = u32(payload[i+4]) << 24 | u32(payload[i+5]) << 16 | u32(payload[i+6]) << 8 | u32(payload[i+7])
    return result, i + 8, true;
}

// Add OscColor to buffer (OSC format)
add_color :: proc(buffer: ^[dynamic]u8, val: OscColor) {
    append(buffer, val.r)
    append(buffer, val.g)
    append(buffer, val.b)
    append(buffer, val.a)
}

// Add OscMidi to buffer (OSC format)
add_midi :: proc(buffer: ^[dynamic]u8, val: OscMidi) {
    append(buffer, val.port_id)
    append(buffer, val.status)
    append(buffer, val.data1)
    append(buffer, val.data2)
}
