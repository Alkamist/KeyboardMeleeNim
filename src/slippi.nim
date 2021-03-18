import json
import std/exitprocs
import enet


if enet_initialize() != 0:
  echo "Could not initialize ENet."
  quit(QuitFailure)

addExitProc(proc() = enet_deinitialize())

var address: ENetAddress
discard enet_address_set_host(address.addr, "127.0.0.1")
address.port = 51441

let
  host = enet_host_create(nil, 1, 0, 0, 0)
  peer = enet_host_connect(host, address.addr, 1, 0)

if peer == nil:
  echo "Could not create peer."
  quit(QuitFailure)

var event: ENetEvent

if (enet_host_service(host, event.addr, 1000) > 0 and event.`type` == ENetEventType.Connect):
  echo "Connected to Dolphin."

  let
    handshake = $ %* {"type": "connect_request", "cursor": 0}
    packet = enet_packet_create(handshake.cstring, (handshake.len + 1).csize_t, ENetPacketFlag.Reliable.cuint)

  discard enet_peer_send(peer, 0.cuchar, packet)

  while enet_host_service(host, event.addr, 1000) > 0:
    case event.`type`:

    of ENetEventType.None:
      discard

    of ENetEventType.Connect:
      echo "Connected to Dolphin."
      discard enet_peer_send(peer, 0.cuchar, packet)

    of ENetEventType.Disconnect:
      echo "Peer disconnected."

    of ENetEventType.Receive:
      echo "Received Packet: " & $event.packet.data
      enet_packet_destroy(event.packet)

else:
  echo "Connection with Dolphin failed."
  enet_peer_reset(peer)

enet_peer_disconnect(peer, 0)
enet_host_destroy(host)