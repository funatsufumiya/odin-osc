package main

import "core:fmt"
import vosc "../.."

main :: proc() {
    // Create a new VOSC message
    msg := vosc.OscMessage{address = "/example", args = {int(1), f32(2.0), "hello"}}

    fmt.printfln("{}", msg)

    buf := make([dynamic]u8)
    defer delete(buf)

    vosc.add_message(&buf, msg)
    fmt.printfln("{}", buf)

    msg2, _, _ := vosc.read_message(buf[:], 0)
    fmt.printfln("{}", msg2)
}