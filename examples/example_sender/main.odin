package main

import "core:fmt"
import "core:net"
import "core:strings"
import "core:mem"
import osc "../.."
import util "../example_util"

main :: proc() {
	util.debug_tracking_allocator_init()

	endpoint := net.Endpoint{address = net.IP4_Address{127,0,0,1}, port = 9000}

	socket, err := net.create_socket(.IP4, .UDP)
	if err != .None {
		fmt.eprintfln("failed to create UDP socket: {}", err)
		return
	}
	defer net.close(socket)

    udp_socket := socket.(net.UDP_Socket)

	msg := osc.OscMessage{address = "/hello", args = {int(1), f32(2.3), "world"}}

	buf := make([dynamic]u8)
	defer delete(buf)

	osc.add_message(&buf, msg)

	bytes_written, send_err := net.send_udp(udp_socket, buf[:], endpoint)
	if send_err != net.UDP_Send_Error.None {
		fmt.eprintfln("failed to send UDP: {}", send_err)
		return
	}
    addr_str := util.ip_address_to_str(endpoint.address)
	defer delete(addr_str)
	fmt.printfln("OSC sent to {}:{} ({} bytes)", addr_str, endpoint.port, bytes_written)
	fmt.printfln("Content: {}", msg)
}
