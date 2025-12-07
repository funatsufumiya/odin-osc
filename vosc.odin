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

// // Enum for OscValue type dispatch
// OscValueKind :: enum {
//     Int,
//     F32,
//     F64,
//     String,
//     Bool,
//     OscBlob,
//     Rune,
//     OscBigIntValue,
//     OscTime,
//     OscColor,
//     OscMidi,
//     Array,
//     OscNilValue,
//     OscInfValue,
//     Unknown,
// }

// osc_value_kind_of_int :: proc(val: int) -> OscValueKind { return OscValueKind.Int; }
// osc_value_kind_of_f32 :: proc(val: f32) -> OscValueKind { return OscValueKind.F32; }
// osc_value_kind_of_f64 :: proc(val: f64) -> OscValueKind { return OscValueKind.F64; }
// osc_value_kind_of_string :: proc(val: string) -> OscValueKind { return OscValueKind.String; }
// osc_value_kind_of_bool :: proc(val: bool) -> OscValueKind { return OscValueKind.Bool; }
// osc_value_kind_of_OscBlob :: proc(val: OscBlob) -> OscValueKind { return OscValueKind.OscBlob; }
// osc_value_kind_of_rune :: proc(val: rune) -> OscValueKind { return OscValueKind.Rune; }
// osc_value_kind_of_OscBigIntValue :: proc(val: OscBigIntValue) -> OscValueKind { return OscValueKind.OscBigIntValue; }
// osc_value_kind_of_OscTime :: proc(val: OscTime) -> OscValueKind { return OscValueKind.OscTime; }
// osc_value_kind_of_OscColor :: proc(val: OscColor) -> OscValueKind { return OscValueKind.OscColor; }
// osc_value_kind_of_OscMidi :: proc(val: OscMidi) -> OscValueKind { return OscValueKind.OscMidi; }
// osc_value_kind_of_array :: proc(val: []OscValue) -> OscValueKind { return OscValueKind.Array; }
// osc_value_kind_of_OscNilValue :: proc(val: OscNilValue) -> OscValueKind { return OscValueKind.OscNilValue; }
// osc_value_kind_of_OscInfValue :: proc(val: OscInfValue) -> OscValueKind { return OscValueKind.OscInfValue; }

// osc_value_kind_of :: proc {
//     osc_value_kind_of_int,
//     osc_value_kind_of_f32,
//     osc_value_kind_of_f64,
//     osc_value_kind_of_string,
//     osc_value_kind_of_bool,
//     osc_value_kind_of_OscBlob,
//     osc_value_kind_of_rune,
//     osc_value_kind_of_OscBigIntValue,
//     osc_value_kind_of_OscTime,
//     osc_value_kind_of_OscColor,
//     osc_value_kind_of_OscMidi,
//     osc_value_kind_of_array,
//     osc_value_kind_of_OscNilValue,
//     osc_value_kind_of_OscInfValue
// }

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
    }
}

// Add time to buffer (big-endian)
add_time :: proc(buffer: ^[dynamic]u8, time: OscTime) {
    append(buffer, u8((time.seconds >> 24) & 0xff))
    append(buffer, u8((time.seconds >> 16) & 0xff))
    append(buffer, u8((time.seconds >> 8) & 0xff))
    append(buffer, u8(time.seconds & 0xff))
    append(buffer, u8((time.frac >> 24) & 0xff))
    append(buffer, u8((time.frac >> 16) & 0xff))
    append(buffer, u8((time.frac >> 8) & 0xff))
    append(buffer, u8(time.frac & 0xff))
}

// to_osc_color: Convert u32 color + alpha to OscColor
to_osc_color :: proc(c: u32, alpha: u8) -> OscColor {
    rgb := extract_rgb(c)
    return OscColor{
        r = rgb.r,
        g = rgb.g,
        b = rgb.b,
        a = alpha,
    }
}

// Pad the given length to the next multiple of 4.
padded4 :: proc(length: int) -> int {
    if length % 4 != 0 {
        return length + (4 - length % 4)
    } else {
        return length
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

    append_slice(buffer, bytes)
    rem := 4 - (len(val) % 4)
    for _ in 0..<rem {
        append(buffer, u8(0))
    }
}

// Add a blob to buffer (OSC format)
add_blob :: proc(buffer: ^[dynamic]u8, val: []u8) {
    append_slice(buffer, val)
    if len(val) % 4 != 0 {
        rem := 4 - (len(val) % 4)
        for _ in 0..<rem {
            append(buffer, u8(0))
        }
    }
}

// index_byte: Find index of sep in slice
index_byte :: proc(s: []u8, sep: u8) -> int {
    for i in 0..<len(s) {
        if s[i] == sep {
            return i
        }
    }
    return -1
}

// Read a padded string from payload, updating index
// last bool (ok) return error or not
read_padded_str :: proc(payload: []u8, i: int) -> (string, int, bool) {
    if i >= len(payload) {
        return "", i, false
    }
    buf := payload[i:]
    len_ := index_byte(buf, 0)
    if len_ == -1 {
        return "", i, false
    }
    result := buf[:len_]
    next_index := i + padded4(len_ + 1); // len + 1 for the \0
    return string(result), next_index, true
}

// Read OscTime from payload, updating index
// last bool (ok) return error or not
read_osc_time :: proc(payload: []u8, i: int) -> (OscTime, int, bool) {
    if i+8 > len(payload) {
        return OscTime{}, i, false
    }
    result: OscTime
    result.seconds = u32(payload[i]) << 24 | u32(payload[i+1]) << 16 | u32(payload[i+2]) << 8 | u32(payload[i+3])
    result.frac = u32(payload[i+4]) << 24 | u32(payload[i+5]) << 16 | u32(payload[i+6]) << 8 | u32(payload[i+7])
    return result, i + 8, true
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

// Read an OscMessage from payload, starting at index i
// Returns: OscMessage, next index, ok
read_message :: proc(payload: []u8, i: int) -> (OscMessage, int, bool) {
    idx := i
    if idx >= len(payload) {
        return OscMessage{}, idx, false
    }
    if payload[idx] != '/' {
        return OscMessage{}, idx, false
    }
    // Read address
    address, next_idx, ok := read_padded_str(payload, idx)
    if !ok {
        return OscMessage{}, idx, false
    }
    idx = next_idx
    if idx >= len(payload) {
        return OscMessage{address=address, args=make([]OscValue, 0)}, idx, true
    }
    // Read type tags
    type_tags, next_idx2, ok2 := read_padded_str(payload, idx)
    if !ok2 {
        return OscMessage{}, idx, false
    }
    idx = next_idx2
    // Parse arguments
    args := make([dynamic]OscValue, 0)
    tag_idx := 0
    for tag_idx < len(type_tags) {
        t := type_tags[tag_idx]
        tag_idx += 1
        switch t {
        case ',':
            continue
        case 'f':
            if idx+4 > len(payload) { return OscMessage{}, idx, false; }
            bits := u32(payload[idx]) << 24 | u32(payload[idx+1]) << 16 | u32(payload[idx+2]) << 8 | u32(payload[idx+3])
            val := transmute(f32)(bits)
            append(&args, val)
            idx += 4
        case 'i':
            if idx+4 > len(payload) { return OscMessage{}, idx, false; }
            val := int(u32(payload[idx]) << 24 | u32(payload[idx+1]) << 16 | u32(payload[idx+2]) << 8 | u32(payload[idx+3]))
            append(&args, val)
            idx += 4
        case 's':
            str, next_idx3, ok := read_padded_str(payload, idx)
            if !ok { return OscMessage{}, idx, false; }
            append(&args, str)
            idx = next_idx3
        case 'b':
            if idx+4 > len(payload) { return OscMessage{}, idx, false; }
            length := int(u32(payload[idx]) << 24 | u32(payload[idx+1]) << 16 | u32(payload[idx+2]) << 8 | u32(payload[idx+3]))
            idx += 4
            if length < 0 || idx+length > len(payload) { return OscMessage{}, idx, false; }
            val := payload[idx:idx+length]
            append(&args, OscBlob{blob=val})
            idx += padded4(length)
        case 'T':
            append(&args, true)
        case 'F':
            append(&args, false)
        case 'N':
            append(&args, OscNilValue{})
        // Add more type tags as needed (t, h, d, I, c, r, m, etc.)
        case:
            // skip unknown type
            continue
        }
    }
    return OscMessage{address=address, args=args[:]}, idx, true
}

t_or_f :: proc(b: bool) -> u8 {
    if b { 
        return 'T'
    } else {
        return 'F'
    }
}

// Add an OscMessage to buffer (OSC format)
add_message :: proc(buffer: ^[dynamic]u8, msg: OscMessage) {
    add_padded_str(buffer, msg.address)
    // Add type tags (only basic types for now)
    append(buffer, u8(','))
    for arg in msg.args {
        switch _ in arg {
        case int:    append(buffer, u8('i'))
        case f32:    append(buffer, u8('f'))
        case f64:    append(buffer, u8('d'))
        case string: append(buffer, u8('s'))
        case bool:   append(buffer, u8(t_or_f(arg.(bool))))
        case OscBlob: append(buffer, u8('b'))
        case OscNilValue: append(buffer, u8('N'))
        case OscInfValue: append(buffer, u8('I'))
        case OscBigIntValue: append(buffer, u8('h'))
        case OscTime: append(buffer, u8('t'))
        case OscColor: append(buffer, u8('r'))
        case OscMidi: append(buffer, u8('m'))
        case rune: append(buffer, u8('c'))
        case []OscValue: append(buffer, u8('['))
        case: append(buffer, u8('?'))
        }
    }
    // Pad type tags to 4 bytes
    tags_len := 1 + len(msg.args); // ',' + args
    rem := 4 - (tags_len % 4)
    for _ in 0..<rem {
        append(buffer, u8(0))
    }
    // Add arguments
    for arg in msg.args {
        append_osc_value(buffer, arg)
    }
}

// Serialize OscValue to buffer
append_osc_value :: proc(buffer: ^[dynamic]u8, value: OscValue) {
    switch _ in value {
    case int:
        v := value.(int)
        append(buffer, u8((u32(v) >> 24) & 0xff))
        append(buffer, u8((u32(v) >> 16) & 0xff))
        append(buffer, u8((u32(v) >> 8) & 0xff))
        append(buffer, u8(u32(v) & 0xff))
    case f32:
        v := value.(f32)
        bits := transmute(u32)(v)
        append(buffer, u8((bits >> 24) & 0xff))
        append(buffer, u8((bits >> 16) & 0xff))
        append(buffer, u8((bits >> 8) & 0xff))
        append(buffer, u8(bits & 0xff))
    case f64:
        v := value.(f64)
        bits := transmute(u64)(v)
        append(buffer, u8((bits >> 56) & 0xff))
        append(buffer, u8((bits >> 48) & 0xff))
        append(buffer, u8((bits >> 40) & 0xff))
        append(buffer, u8((bits >> 32) & 0xff))
        append(buffer, u8((bits >> 24) & 0xff))
        append(buffer, u8((bits >> 16) & 0xff))
        append(buffer, u8((bits >> 8) & 0xff))
        append(buffer, u8(bits & 0xff))
    case string:
        add_padded_str(buffer, value.(string))
    case bool:
    case OscNilValue:
    case OscInfValue:
        // No data for these types
    case OscBlob:
        b := value.(OscBlob).blob
        l := len(b)
        append(buffer, u8((u32(l) >> 24) & 0xff))
        append(buffer, u8((u32(l) >> 16) & 0xff))
        append(buffer, u8((u32(l) >> 8) & 0xff))
        append(buffer, u8(u32(l) & 0xff))
        append_slice(buffer, b)
        if l % 4 != 0 {
            rem := 4 - (l % 4)
            for _ in 0..<rem {
                append(buffer, u8(0))
            }
        }
    case OscBigIntValue:
        v := value.(OscBigIntValue).big_int_val
        bits := u64(v)
        append(buffer, u8((bits >> 56) & 0xff))
        append(buffer, u8((bits >> 48) & 0xff))
        append(buffer, u8((bits >> 40) & 0xff))
        append(buffer, u8((bits >> 32) & 0xff))
        append(buffer, u8((bits >> 24) & 0xff))
        append(buffer, u8((bits >> 16) & 0xff))
        append(buffer, u8((bits >> 8) & 0xff))
        append(buffer, u8(bits & 0xff))
    case OscTime:
        t := value.(OscTime)
        append(buffer, u8((t.seconds >> 24) & 0xff))
        append(buffer, u8((t.seconds >> 16) & 0xff))
        append(buffer, u8((t.seconds >> 8) & 0xff))
        append(buffer, u8(t.seconds & 0xff))
        append(buffer, u8((t.frac >> 24) & 0xff))
        append(buffer, u8((t.frac >> 16) & 0xff))
        append(buffer, u8((t.frac >> 8) & 0xff))
        append(buffer, u8(t.frac & 0xff))
    case OscColor:
        c := value.(OscColor)
        append(buffer, c.r)
        append(buffer, c.g)
        append(buffer, c.b)
        append(buffer, c.a)
    case OscMidi:
        m := value.(OscMidi)
        append(buffer, m.port_id)
        append(buffer, m.status)
        append(buffer, m.data1)
        append(buffer, m.data2)
    case rune:
        v := value.(rune)
        bits := u32(v)
        append(buffer, u8((bits >> 24) & 0xff))
        append(buffer, u8((bits >> 16) & 0xff))
        append(buffer, u8((bits >> 8) & 0xff))
        append(buffer, u8(bits & 0xff))
    case []OscValue:
        arr := value.([]OscValue)
        for elem in arr {
            append_osc_value(buffer, elem)
        }
    case:
        // skip unknown type
        return
    }
}