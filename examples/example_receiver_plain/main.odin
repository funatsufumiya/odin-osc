package main

import "core:fmt"
import "core:net"
import "core:mem"
import osc "../.."
import util "../example_util"

main :: proc() {
    util.debug_tracking_allocator_init()

    endpoint := net.Endpoint{address = net.IP4_Address{0,0,0,0}, port = 9000}

    socket, err := net.create_socket(.IP4, .UDP)
    if err != .None {
        fmt.eprintfln("failed to create UDP socket: {}", err)
        return
    }
    defer net.close(socket)

    udp_socket := socket.(net.UDP_Socket)

    err2 := net.bind(udp_socket, endpoint)
    if err2 != .None {
        fmt.eprintfln("failed to bind UDP socket: {}", err2)
        return
    }

    addr_str := util.ip_address_to_str(endpoint.address)
	defer delete(addr_str)

    fmt.printfln("OSC listening to {}:{}", addr_str, endpoint.port)

    // // WARNING: dynamic slice cannot be used for net.recv_udp, because of C implementation
    // buf := make([dynamic]u8)
    // defer delete(buf)

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
}