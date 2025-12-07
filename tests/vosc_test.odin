package tests

import "core:testing"
import "core:math"
import vosc ".."

@(test)
test_i32_u32_transmut :: proc(t: ^testing.T) {
    a: i32 = -300
    b: u32 = u32(a)
    c: i32 = i32(b)
    testing.expect(t, a == c, "i32 u32 transmut test failed");
}

@(test)
test_nano_to_fraction_to_nano :: proc(t: ^testing.T) {
    want: u32 = 1_000_000_000;
    fr := vosc.nano_to_fraction(want);
    result := vosc.fraction_to_nano(fr);
    testing.expect(t, result == want, "fraction_to_nano roundtrip failed");
}

@(test)
test_to_color :: proc(t: ^testing.T) {
    osc_color := vosc.OscColor{r = 0x12, g = 0x34, b = 0x56, a = 0xff};
    color := vosc.to_color(osc_color);
    testing.expect(t, color == 0x123456, "to_color failed");
}

@(test)
test_to_osc_color :: proc(t: ^testing.T) {
    c: u32 = 0x123456;
    alpha: u8 = 128;
    osc_color := vosc.to_osc_color(c, alpha);
    testing.expect(t, osc_color.r == 0x12, "to_osc_color.r failed");
    testing.expect(t, osc_color.g == 0x34, "to_osc_color.g failed");
    testing.expect(t, osc_color.b == 0x56, "to_osc_color.b failed");
    testing.expect(t, osc_color.a == 128, "to_osc_color.a failed");
}

@(test)
test_padded4 :: proc(t: ^testing.T) {
    testing.expect(t, vosc.padded4(0) == 0, "padded4(0) failed");
    testing.expect(t, vosc.padded4(1) == 4, "padded4(1) failed");
    testing.expect(t, vosc.padded4(2) == 4, "padded4(2) failed");
    testing.expect(t, vosc.padded4(3) == 4, "padded4(3) failed");
    testing.expect(t, vosc.padded4(5) == 8, "padded4(5) failed");
    testing.expect(t, vosc.padded4(9) == 12, "padded4(9) failed");
}

@(test)
test_index_byte :: proc(t: ^testing.T) {
    testing.expect(t, vosc.index_byte({u8(1), u8(2), u8(3), u8(4)}, u8(3)) == 2, "index_byte basic failed");
    testing.expect(t, vosc.index_byte({u8(9), u8(2), u8(3)}, u8(9)) == 0, "index_byte start failed");
    testing.expect(t, vosc.index_byte({u8(1), u8(2), u8(3)}, u8(4)) == -1, "index_byte not found failed");
    testing.expect(t, vosc.index_byte({}, u8(1)) == -1, "index_byte empty failed");
}

@(test)
test_read_osc_time :: proc(t: ^testing.T) {
    payload: [8]u8 = {u8(0x12), 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0};
    osc_time, next_index, ok := vosc.read_osc_time(payload[:], 0);
    testing.expect(t, ok, "read_osc_time failed");
    testing.expect(t, osc_time.seconds == 0x12345678, "osc_time.seconds failed");
    testing.expect(t, osc_time.frac == 0x9abcdef0, "osc_time.frac failed");
    testing.expect(t, next_index == 8, "next_index failed");

    payload2: [12]u8 = {u8(0), 0, 0, 0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
    osc_time2, next_index2, ok2 := vosc.read_osc_time(payload2[:], 4);
    testing.expect(t, ok2, "read_osc_time offset failed");
    testing.expect(t, osc_time2.seconds == 0x01020304, "osc_time2.seconds failed");
    testing.expect(t, osc_time2.frac == 0x05060708, "osc_time2.frac failed");
    testing.expect(t, next_index2 == 12, "next_index2 failed");
}

@(test)
test_add_color :: proc(t: ^testing.T) {
    buf := make([dynamic]u8);
    defer delete(buf)

    osc_color := vosc.OscColor{r = 0x11, g = 0x22, b = 0x33, a = 0x44};
    vosc.add_color(&buf, osc_color);
    expected: [4]u8 = {u8(0x11), 0x22, 0x33, 0x44};
    testing.expect(t, len(buf) == len(expected), "add_color length failed");
    for i in 0..<len(buf) {
        testing.expect(t, buf[i] == expected[i], "add_color value failed");
    }
}

@(test)
test_add_midi :: proc(t: ^testing.T) {
    midi_buf := make([dynamic]u8);
    defer delete(midi_buf)
    
    osc_midi := vosc.OscMidi{port_id = 0x55, status = 0x66, data1 = 0x77, data2 = 0x88};
    vosc.add_midi(&midi_buf, osc_midi);
    expected: [4]u8 = {u8(0x55), 0x66, 0x77, 0x88};
    testing.expect(t, len(midi_buf) == len(expected), "add_midi length failed");
    for i in 0..<len(midi_buf) {
        testing.expect(t, midi_buf[i] == expected[i], "add_midi value failed");
    }
}

