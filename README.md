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

see [plain receiver example](./examples/example_receiver_plain/main.odin).

## Tests

```bash
$ odin test tests
```

## License

see [LICENSE](./LICENSE).

Please note that the original [Okabintaro/nosc](https://github.com/Okabintaro/nosc) (base code of [osc](https://github.com/funatsufumiya/osc)) contains codes by [treeform](https://github.com/treeform) codes, see [LICENSE_treeform](./LICENSE_treeform) and [original README](https://github.com/Okabintaro/nosc/blob/master/README.md).
