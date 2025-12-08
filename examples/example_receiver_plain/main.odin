package main

import "core:fmt"
import "core:net"
import "core:mem"
import vosc "../.."
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

	buf : [2048]u8
	buf = {}

	for {
		bytes_read, remote_endpoint, recv_err := net.recv_udp(udp_socket, buf[:])
		if recv_err != net.UDP_Recv_Error.None || bytes_read == 0 {
			continue
		}

		packet, err := vosc.read_packet(buf[:bytes_read])
		if err != nil {
			fmt.eprintfln("failed to parse OSC packet: {}", err)
			continue
		}

		if packet.kind == vosc.OscPacketKind.message {
			fmt.printfln("{}", packet.msg)
		} else if packet.kind == vosc.OscPacketKind.bundle {
			fmt.printfln("bundle time: {}", packet.bundle.time)
			for pac in packet.bundle.contents {
				if pac.kind == vosc.OscPacketKind.message {
					fmt.printfln("{}", pac.msg)
				}
			}
		}
	}
}
