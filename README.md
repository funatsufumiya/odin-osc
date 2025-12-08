# odin-osc

A pure Odin implementation of the [OSC(Open Sound Control) 1.0](https://opensoundcontrol.stanford.edu/spec-1_0.html) protocol.

Ported from [funatsufumiya/vosc](https://github.com/funatsufumiya/vosc) (based on [Okabintaro/nosc](https://github.com/Okabintaro/nosc))

## Usage

### Sender

see [sender example](./examples/example_sender/main.odin).

```odin
// NOTE: partial code, not full code

msg := osc.OscMessage{address = "/hello", args = {int(1), f32(2.3), "world"}}

buf := make([dynamic]u8)
defer delete(buf)

osc.add_message(&buf, msg)

bytes_written, send_err := net.send_udp(udp_socket, buf[:], endpoint)
```

### Receiver (using filter)

#### filter messages

show all messages even if wrapped in OSC Bundle.

see [filter messages example](./examples/example_receiver_filter_msg/main.odin).

```odin
// NOTE: partial code, not full code

buf : [2048]u8
buf = {}

for {
    bytes_read, remote_endpoint, recv_err := net.recv_udp(udp_socket, buf[:])
    if recv_err != net.UDP_Recv_Error.None || bytes_read == 0 {
        continue
    }

    fmt.printfln("bytes_read: {}", bytes_read)

    packet, err := osc.read_packet(buf[:bytes_read])
    defer osc.delete_osc_packet(packet)
    
    if err != nil {
        fmt.eprintfln("failed to parse OSC packet: {}", err)
        continue
    }

    osc.filter_messages(&packet, proc(msg: ^osc.OscMessage) {
        fmt.printfln("{}", msg.address)
        fmt.printfln("{}", msg.args)
    })
}
```

#### filter addresses

see [filter addresses example](./examples/example_receiver_filter_addr/main.odin).

```odin
// NOTE: partial code, not full code

buf : [2048]u8
buf = {}

for {
    bytes_read, remote_endpoint, recv_err := net.recv_udp(udp_socket, buf[:])
    if recv_err != net.UDP_Recv_Error.None || bytes_read == 0 {
        continue
    }

    // fmt.printfln("bytes_read: {}", bytes_read)

    packet, err := osc.read_packet(buf[:bytes_read])
    defer osc.delete_osc_packet(packet)

    if err != nil {
        fmt.eprintfln("failed to parse OSC packet: {}", err)
        continue
    }

    osc.filter_address(&packet, "/hello", proc(msg: ^osc.OscMessage) {
        fmt.printfln("{}", msg.address)
        fmt.printfln("{}", msg.args)
    })
    osc.filter_address(&packet, "/test", proc(msg: ^osc.OscMessage) {
        fmt.printfln("{}", msg.address)
        fmt.printfln("{}", msg.args)
    })
}
```

### Receiver (plain)

see [receiver plain example](./examples/example_receiver_plain/main.odin).

```odin
// NOTE: partial code, not full code

buf : [2048]u8
buf = {}

for {
    bytes_read, remote_endpoint, recv_err := net.recv_udp(udp_socket, buf[:])
    if recv_err != net.UDP_Recv_Error.None || bytes_read == 0 {
        continue
    }

    fmt.printfln("bytes_read: {}", bytes_read)

    packet, err := osc.read_packet(buf[:bytes_read])
    defer osc.delete_osc_packet(packet)

    if err != nil {
        fmt.eprintfln("failed to parse OSC packet: {}", err)
        continue
    }

    fmt.printfln("{}", packet)

    // results for example:

    // bytes_read: 64
    // OscBundle{time = OscTime{seconds = 3974158153, frac = 2931715041}, contents = [OscMessage{address = "/_samplerate", args = [60]}, OscMessage{address = "/chan1", args = [0.60837448]}]}
    // bytes_read: 32
    // OscMessage{address = "/hello", args = [1, 2, "hello"]}
}
```

## Tests

```bash
$ odin test tests
```

## License

see [LICENSE](./LICENSE).
