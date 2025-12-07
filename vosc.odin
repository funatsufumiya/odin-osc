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
add_time :: proc(buffer: ^[]u8, time: OscTime) {
    buffer^.append(u8((time.seconds >> 24) & 0xff));
    buffer^.append(u8((time.seconds >> 16) & 0xff));
    buffer^.append(u8((time.seconds >> 8) & 0xff));
    buffer^.append(u8(time.seconds & 0xff));
    buffer^.append(u8((time.frac >> 24) & 0xff));
    buffer^.append(u8((time.frac >> 16) & 0xff));
    buffer^.append(u8((time.frac >> 8) & 0xff));
    buffer^.append(u8(time.frac & 0xff));
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

// Add a padded string to buffer (OSC format)
add_padded_str :: proc(buffer: ^[]u8, val: string) {
    buffer^.append_slice(val.bytes);
    rem := 4 - (len(val) % 4);
    for _ in 0 .. rem {
        buffer^.append(u8(0));
    }
}

// Add a blob to buffer (OSC format)
add_blob :: proc(buffer: ^[]u8, val: []u8) {
    buffer^.append_slice(val);
    if len(val) % 4 != 0 {
        rem := 4 - (len(val) % 4);
        for _ in 0 .. rem {
            buffer^.append(u8(0));
        }
    }
}

// index_byte: Find index of sep in slice
index_byte :: proc(s: []u8, sep: u8) -> int {
    for i in 0 .. len(s) {
        if s[i] == sep {
            return i;
        }
    }
    return -1;
}

// Read a padded string from payload, updating index
// last bool return error or not
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
    return string_from_bytes(result), next_index, true
}

// Read OscTime from payload, updating index
read_osc_time :: proc(payload: []u8, i: int) -> (OscTime, int) {
    result: OscTime;
    result.seconds = u32(payload[i]) << 24 | u32(payload[i+1]) << 16 | u32(payload[i+2]) << 8 | u32(payload[i+3])
    result.frac = u32(payload[i+4]) << 24 | u32(payload[i+5]) << 16 | u32(payload[i+6]) << 8 | u32(payload[i+7])
    return result, i + 8;
}

// Add OscColor to buffer (OSC format)
add_color :: proc(buffer: ^[]u8, val: OscColor) {
    buffer^.append(val.r)
    buffer^.append(val.g)
    buffer^.append(val.b)
    buffer^.append(val.a)
}

// Add OscMidi to buffer (OSC format)
add_midi :: proc(buffer: ^[]u8, val: OscMidi) {
    buffer^.append(val.port_id)
    buffer^.append(val.status)
    buffer^.append(val.data1)
    buffer^.append(val.data2)
}
