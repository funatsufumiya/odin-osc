package main

import "core:fmt"
import "core:net"
import "core:strings"
import "core:mem"
import vosc "../.."

ipv4_to_str :: proc(addr: net.IP4_Address, allocator: mem.Allocator = context.allocator) -> string {
    return fmt.aprintf("{}.{}.{}.{}", addr[0], addr[1], addr[2], addr[3], allocator=allocator)
}

// addr_to_str :: proc(addr: [4]u8, allocator: mem.Allocator = context.allocator) -> string {
//     return fmt.aprintf("{}.{}.{}.{}", addr[0], addr[1], addr[2], addr[3], allocator=allocator)
// }

main :: proc() {
	endpoint := net.Endpoint{address = net.IP4_Address{127,0,0,1}, port = 9000}

	// UDPソケット作成
	socket, err := net.create_socket(.IP4, .UDP)
	if err != .None {
		fmt.printfln("failed to create UDP socket: {}", err)
		return
	}
	defer net.close(socket)

    udp_socket := socket.(net.UDP_Socket)

	msg := vosc.OscMessage{address = "/hello", args = {int(1), f32(2.3), "world"}}

	buf := make([dynamic]u8)
	defer delete(buf)
	vosc.add_message(&buf, msg)

	bytes_written, send_err := net.send_udp(udp_socket, buf[:], endpoint)
	if send_err != net.UDP_Send_Error.None {
		fmt.printfln("failed to send UDP: {}", send_err)
		return
	}
    addr_str := ipv4_to_str(endpoint.address.(net.IP4_Address))
	fmt.printfln("OSC sent to {}:{} ({} bytes)", addr_str, endpoint.port, bytes_written)
	fmt.printfln("Content: {}", msg)
}
