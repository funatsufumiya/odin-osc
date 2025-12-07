package tests

import "core:testing"
import "core:math"
// import "core:fmt"
import vosc ".."

@(test)
test_i32_u32_transmut :: proc(t: ^testing.T) {
    a: i32 = -300
    b: u32 = u32(a)
    c: i32 = i32(b)
    testing.expect_value(t, a, c);
}

@(test)
test_nano_to_fraction_to_nano :: proc(t: ^testing.T) {
    want: u32 = 1_000_000_000;
    fr := vosc.nano_to_fraction(want);
    result := vosc.fraction_to_nano(fr);
    // fmt.printfln("result: {}", result)
    testing.expect_value(t, result, want);
}

@(test)
test_to_color :: proc(t: ^testing.T) {
    osc_color := vosc.OscColor{r = 0x12, g = 0x34, b = 0x56, a = 0xff};
    color := vosc.to_color(osc_color);
    testing.expect_value(t, color, 0x123456);
}

@(test)
test_to_osc_color :: proc(t: ^testing.T) {
    c: u32 = 0x123456;
    alpha: u8 = 128;
    osc_color := vosc.to_osc_color(c, alpha);
    testing.expect_value(t, osc_color.r, 0x12);
    testing.expect_value(t, osc_color.g, 0x34);
    testing.expect_value(t, osc_color.b, 0x56);
    testing.expect_value(t, osc_color.a, 128);
}

@(test)
test_padded4 :: proc(t: ^testing.T) {
    testing.expect_value(t, vosc.padded4(0), 0);
    testing.expect_value(t, vosc.padded4(1), 4);
    testing.expect_value(t, vosc.padded4(2), 4);
    testing.expect_value(t, vosc.padded4(3), 4);
    testing.expect_value(t, vosc.padded4(5), 8);
    testing.expect_value(t, vosc.padded4(9), 12);
}

@(test)
test_index_byte :: proc(t: ^testing.T) {
    testing.expect_value(t, vosc.index_byte({u8(1), u8(2), u8(3), u8(4)}, u8(3)), 2);
    testing.expect_value(t, vosc.index_byte({u8(9), u8(2), u8(3)}, u8(9)), 0);
    testing.expect_value(t, vosc.index_byte({u8(1), u8(2), u8(3)}, u8(4)), -1);
    testing.expect_value(t, vosc.index_byte({}, u8(1)), -1);
}

@(test)
test_read_osc_time :: proc(t: ^testing.T) {
    payload: [8]u8 = {u8(0x12), 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0};
    osc_time, next_index, ok := vosc.read_osc_time(payload[:], 0);
    testing.expect_value(t, ok, true);
    testing.expect_value(t, osc_time.seconds, 0x12345678);
    testing.expect_value(t, osc_time.frac, 0x9abcdef0);
    testing.expect_value(t, next_index, 8);

    payload2: [12]u8 = {u8(0), 0, 0, 0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
    osc_time2, next_index2, ok2 := vosc.read_osc_time(payload2[:], 4);
    testing.expect_value(t, ok2, true);
    testing.expect_value(t, osc_time2.seconds, 0x01020304);
    testing.expect_value(t, osc_time2.frac, 0x05060708);
    testing.expect_value(t, next_index2, 12);
}

@(test)
test_add_color :: proc(t: ^testing.T) {
    buf := make([dynamic]u8);
    defer delete(buf)

    osc_color := vosc.OscColor{r = 0x11, g = 0x22, b = 0x33, a = 0x44};
    vosc.add_color(&buf, osc_color);
    expected: [4]u8 = {u8(0x11), 0x22, 0x33, 0x44};
    testing.expect_value(t, len(buf), len(expected));
    for i in 0..<len(buf) {
        testing.expect_value(t, buf[i], expected[i]);
    }
}

@(test)
test_add_midi :: proc(t: ^testing.T) {
    midi_buf := make([dynamic]u8);
    defer delete(midi_buf)
    
    osc_midi := vosc.OscMidi{port_id = 0x55, status = 0x66, data1 = 0x77, data2 = 0x88};
    vosc.add_midi(&midi_buf, osc_midi);
    expected: [4]u8 = {u8(0x55), 0x66, 0x77, 0x88};
    testing.expect_value(t, len(midi_buf), len(expected));
    for i in 0..<len(midi_buf) {
        testing.expect_value(t, midi_buf[i], expected[i]);
    }
}

