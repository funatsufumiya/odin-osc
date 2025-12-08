package tests

import "core:testing"
import "core:math"
// import "core:fmt"
import osc ".."

@(test)
test_i32_u32_transmut :: proc(t: ^testing.T) {
    a: i32 = -300
    b: u32 = u32(a)
    c: i32 = i32(b)
    testing.expect_value(t, a, c)
}

@(test)
test_nano_to_fraction_to_nano :: proc(t: ^testing.T) {
    // want: u32 = 1_000_000_000
    want: u32 = 900_000_000
    fr := osc.nano_to_fraction(want)
    result := osc.fraction_to_nano(fr)
    // testing.expect_value(t,result, want)
    diff : i64 = abs(i64(result) - i64(want))
    testing.expect(t, abs(diff) < 2, "abs(result - want) < 2 failed")
}

@(test)
test_to_color :: proc(t: ^testing.T) {
    osc_color := osc.OscColor{r = 0x12, g = 0x34, b = 0x56, a = 0xff}
    color := osc.to_color(osc_color)
    testing.expect_value(t, color, 0x123456)
}

@(test)
test_to_osc_color :: proc(t: ^testing.T) {
    c: u32 = 0x123456
    alpha: u8 = 128
    osc_color := osc.to_osc_color(c, alpha)
    testing.expect_value(t, osc_color.r, 0x12)
    testing.expect_value(t, osc_color.g, 0x34)
    testing.expect_value(t, osc_color.b, 0x56)
    testing.expect_value(t, osc_color.a, 128)
}

@(test)
test_padded4 :: proc(t: ^testing.T) {
    testing.expect_value(t, osc.padded4(0), 0)
    testing.expect_value(t, osc.padded4(1), 4)
    testing.expect_value(t, osc.padded4(2), 4)
    testing.expect_value(t, osc.padded4(3), 4)
    testing.expect_value(t, osc.padded4(5), 8)
    testing.expect_value(t, osc.padded4(9), 12)
}

@(test)
test_index_byte :: proc(t: ^testing.T) {
    testing.expect_value(t, osc.index_byte({u8(1), u8(2), u8(3), u8(4)}, u8(3)), 2)
    testing.expect_value(t, osc.index_byte({u8(9), u8(2), u8(3)}, u8(9)), 0)
    testing.expect_value(t, osc.index_byte({u8(1), u8(2), u8(3)}, u8(4)), -1)
    testing.expect_value(t, osc.index_byte({}, u8(1)), -1)
}

@(test)
test_read_osc_time :: proc(t: ^testing.T) {
    payload: [8]u8 = {u8(0x12), 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0}
    osc_time, next_index, ok := osc.read_osc_time(payload[:], 0)
    testing.expect_value(t, ok, true)
    testing.expect_value(t, osc_time.seconds, 0x12345678)
    testing.expect_value(t, osc_time.frac, 0x9abcdef0)
    testing.expect_value(t, next_index, 8)

    payload2: [12]u8 = {u8(0), 0, 0, 0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08}
    osc_time2, next_index2, ok2 := osc.read_osc_time(payload2[:], 4)
    testing.expect_value(t, ok2, true)
    testing.expect_value(t, osc_time2.seconds, 0x01020304)
    testing.expect_value(t, osc_time2.frac, 0x05060708)
    testing.expect_value(t, next_index2, 12)
}

@(test)
test_add_color :: proc(t: ^testing.T) {
    buf := make([dynamic]u8)
    defer delete(buf)

    osc_color := osc.OscColor{r = 0x11, g = 0x22, b = 0x33, a = 0x44}
    osc.add_color(&buf, osc_color)
    expected: [4]u8 = {u8(0x11), 0x22, 0x33, 0x44}
    testing.expect_value(t, len(buf), len(expected))
    for i in 0..<len(buf) {
        testing.expect_value(t, buf[i], expected[i])
    }
}

@(test)
test_add_midi :: proc(t: ^testing.T) {
    midi_buf := make([dynamic]u8)
    defer delete(midi_buf)
    
    osc_midi := osc.OscMidi{port_id = 0x55, status = 0x66, data1 = 0x77, data2 = 0x88}
    osc.add_midi(&midi_buf, osc_midi)
    expected: [4]u8 = {u8(0x55), 0x66, 0x77, 0x88}
    testing.expect_value(t, len(midi_buf), len(expected))
    for i in 0..<len(midi_buf) {
        testing.expect_value(t, midi_buf[i], expected[i])
    }
}

@(test)
test_roundtrip_message :: proc(t: ^testing.T) {
    msgs : []osc.OscMessage
    msgs = {
        osc.OscMessage{address = "/int", args = {int(42)}},
        osc.OscMessage{address = "/float", args = {f32(3.14)}},
        osc.OscMessage{address = "/str", args = {"hello"}},
        osc.OscMessage{address = "/mix", args = {int(-1), f32(2.71), "abc"}},
    }

    for msg in msgs {
        buf := make([dynamic]u8)
        defer delete(buf)
        osc.add_message(&buf, msg)

        decoded, _, err := osc.read_message(buf[:], 0)
        defer osc.delete_osc_message(decoded)

        testing.expect(t, err == nil, "decode error")
        testing.expect_value(t, decoded.address, msg.address)
        testing.expect_value(t, len(decoded.args), len(msg.args))

        for i in 0..<len(msg.args) {
            want := msg.args[i]
            result := decoded.args[i]
            #partial switch _ in result {
                case int:
                    testing.expect_value(t, result.(int), want.(int))
                case f32:
                    testing.expect_value(t, result.(f32), want.(f32))
                case string:
                    testing.expect_value(t, result.(string), want.(string))
                case:
                    // just ignore
            }
        }
    }
}

@(test)
test_roundtrip_bundle :: proc(t: ^testing.T) {
    // Create a bundle with two messages
    msg1 := osc.OscMessage{address = "/foo", args = {int(1), f32(2.0)}}
    msg2 := osc.OscMessage{address = "/bar", args = {"baz"}}
    packet1 := osc.OscPacket{kind = osc.OscPacketKind.message, msg = msg1}
    packet2 := osc.OscPacket{kind = osc.OscPacketKind.message, msg = msg2}
    bundle := osc.OscBundle{
        time = osc.OscTime{seconds = 123, frac = 456},
        contents = {packet1, packet2},
    }

    buf := make([dynamic]u8)
    defer delete(buf)
    osc.add_bundle(&buf, bundle)

    decoded, decode_err := osc.read_bundle(buf[:], 0)
    defer osc.delete_osc_bundle(decoded)
    testing.expect_value(t, decode_err, nil)
    testing.expect_value(t, decoded.time.seconds, bundle.time.seconds)
    testing.expect_value(t, decoded.time.frac, bundle.time.frac)
    testing.expect_value(t, len(decoded.contents), len(bundle.contents))
    for i in 0..<len(bundle.contents) {
        want := bundle.contents[i].msg
        result := decoded.contents[i].msg
        testing.expect_value(t, result.address, want.address)
        testing.expect_value(t, len(result.args), len(want.args))
        for j in 0..<len(want.args) {
            #partial switch _ in result.args[j] {
                case int:
                    testing.expect_value(t, result.args[j].(int), want.args[j].(int))
                case f32:
                    testing.expect_value(t, result.args[j].(f32), want.args[j].(f32))
                case string:
                    testing.expect_value(t, result.args[j].(string), want.args[j].(string))
                case:
                    // ignore
            }
        }
    }
}

@(test)
test_roundtrip_packet :: proc(t: ^testing.T) {
    // Test both message and bundle packets
    msg := osc.OscMessage{address = "/msg", args = {int(99), f32(1.23), "abc"}}
    packet_msg := osc.OscPacket{kind = osc.OscPacketKind.message, msg = msg}

    // Message packet roundtrip
    buf_msg := make([dynamic]u8)
    defer delete(buf_msg)

    osc.add_packet(&buf_msg, packet_msg)
    decoded_msg, err_msg := osc.read_packet(buf_msg[:])
    defer osc.delete_osc_packet(decoded_msg)

    testing.expect_value(t, err_msg, nil)
    if err_msg == nil {
        testing.expect_value(t, decoded_msg.kind, osc.OscPacketKind.message)
        testing.expect_value(t, decoded_msg.msg.address, msg.address)
        testing.expect_value(t, len(decoded_msg.msg.args), len(msg.args))

        for i in 0..<len(msg.args) {
            #partial switch _ in decoded_msg.msg.args[i] {
                case int:
                    testing.expect_value(t, decoded_msg.msg.args[i].(int), msg.args[i].(int))
                case f32:
                    testing.expect_value(t, decoded_msg.msg.args[i].(f32), msg.args[i].(f32))
                case string:
                    testing.expect_value(t, decoded_msg.msg.args[i].(string), msg.args[i].(string))
                case:
                    // ignore
            }
        }
    }

    // Bundle packet roundtrip
    msg1 := osc.OscMessage{address = "/a", args = {int(1)}}
    msg2 := osc.OscMessage{address = "/b", args = {f32(2.0)}}
    packet1 := osc.OscPacket{kind = osc.OscPacketKind.message, msg = msg1}
    packet2 := osc.OscPacket{kind = osc.OscPacketKind.message, msg = msg2}
    bundle := osc.OscBundle{time = osc.OscTime{seconds = 1, frac = 2}, contents = {packet1, packet2}}
    packet_bundle := osc.OscPacket{kind = osc.OscPacketKind.bundle, bundle = bundle}

    buf_bundle := make([dynamic]u8)
    defer delete(buf_bundle)

    osc.add_packet(&buf_bundle, packet_bundle)
    decoded_bundle, bundle_decode_err := osc.read_packet(buf_bundle[:])
    defer osc.delete_osc_packet(decoded_bundle)

    testing.expect_value(t, bundle_decode_err, nil)
    testing.expect_value(t, decoded_bundle.kind, osc.OscPacketKind.bundle)
    testing.expect_value(t, decoded_bundle.bundle.time.seconds, bundle.time.seconds)
    testing.expect_value(t, decoded_bundle.bundle.time.frac, bundle.time.frac)
    testing.expect_value(t, len(decoded_bundle.bundle.contents), len(bundle.contents))

    for i in 0..<len(bundle.contents) {
        want := bundle.contents[i].msg
        result := decoded_bundle.bundle.contents[i].msg
        testing.expect_value(t, result.address, want.address)
        testing.expect_value(t, len(result.args), len(want.args))

        for j in 0..<len(want.args) {
            #partial switch _ in result.args[j] {
                case int:
                    testing.expect_value(t, result.args[j].(int), want.args[j].(int))
                case f32:
                    testing.expect_value(t, result.args[j].(f32), want.args[j].(f32))
                case string:
                    testing.expect_value(t, result.args[j].(string), want.args[j].(string))
                case:
                    // ignore
            }
        }
    }
}