// This file implements the filtering functionality for vosc messages.
// It exports functions for filtering messages based on specific criteria.

package vosc

OscPacketKind :: enum {
    message,
    bundle,
}

OscBundle :: struct {
    time: OscTime,
    contents: []OscPacket,
}

OscPacket :: struct {
    kind: OscPacketKind,
    msg: OscMessage,
    bundle: OscBundle,
}

filter_messages :: proc(packet: ^OscPacket, callback: proc(msg: ^OscMessage)) {
    if packet.kind == OscPacketKind.message {
        callback(&packet.msg);
    } else if packet.kind == OscPacketKind.bundle {
        bundle := packet.bundle;
        for pac in bundle.contents {
            if pac.kind == OscPacketKind.message {
                msg := pac.msg;
                callback(&msg);
            }
        }
    }
}

filter_address :: proc(packet: ^OscPacket, address: string, callback: proc(msg: ^OscMessage)) {
    if packet.kind == OscPacketKind.message {
        msg := &packet.msg;
        if msg.address == address {
            callback(msg);
        }
    } else if packet.kind == OscPacketKind.bundle {
        bundle := packet.bundle;
        for pac in bundle.contents {
            if pac.kind == OscPacketKind.message {
                msg := pac.msg;
                if msg.address == address {
                    callback(&msg);
                }
            }
        }
    }
}

// // Add an OscBundle to buffer (OSC format)
// add_bundle :: proc(buffer: ^[]u8, bundle: OscBundle) {
//     tmp_buf: []u8 = make([]u8, 0, 512);
//     add_padded_str(buffer, "#bundle");
//     buffer^.append(u8(0));
//     buffer^.append(u8((bundle.time.seconds >> 24) & 0xff));
//     buffer^.append(u8((bundle.time.seconds >> 16) & 0xff));
//     buffer^.append(u8((bundle.time.seconds >> 8) & 0xff));
//     buffer^.append(u8(bundle.time.seconds & 0xff));
//     buffer^.append(u8((bundle.time.frac >> 24) & 0xff));
//     buffer^.append(u8((bundle.time.frac >> 16) & 0xff));
//     buffer^.append(u8((bundle.time.frac >> 8) & 0xff));
//     buffer^.append(u8(bundle.time.frac & 0xff));
//     for packet in bundle.contents {
//         tmp_buf.len = 0;
//         add_packet(&tmp_buf, packet);
//         buffer^.append(u8((len(tmp_buf) >> 24) & 0xff));
//         buffer^.append(u8((len(tmp_buf) >> 16) & 0xff));
//         buffer^.append(u8((len(tmp_buf) >> 8) & 0xff));
//         buffer^.append(u8(len(tmp_buf) & 0xff));
//         buffer^.append_slice(tmp_buf);
//     }
// }

// // Add an OscPacket to buffer (OSC format)
// add_packet :: proc(buffer: ^[]u8, packet: OscPacket) {
//     if packet.kind == OscPacketKind.message {
//         add_message(buffer, packet.msg);
//     } else if packet.kind == OscPacketKind.bundle {
//         add_bundle(buffer, packet.bundle);
//     }
// }

// // Serialize the given OscBundle to a new buffer and return it
// dgram_bundle :: proc(bundle: OscBundle) -> []u8 {
//     dgram: []u8 = make([]u8, 0, 512);
//     add_bundle(&dgram, bundle);
//     return dgram;
// }