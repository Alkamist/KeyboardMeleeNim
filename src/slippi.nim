import json
import options
import std/exitprocs
import enet


let handshake = $ %* {"type": "connect_request", "cursor": 0}

type
  SlippiStream* = object
    isConnected*: bool
    nickName*: string
    version*: string
    cursor*: int
    host: ptr ENetHost
    peer: ptr ENetPeer
    address: ENetAddress

proc initSlippiStream*(address = "127.0.0.1",
                       port = 51441): SlippiStream =
  if enet_initialize() != 0:
    echo "Could not initialize ENet."
    quit(QuitFailure)

  addExitProc(proc() = enet_deinitialize())

  discard enet_address_set_host(result.address.addr, address)
  result.address.port = port.cushort
  result.host = enet_host_create(nil, 1, 0, 0, 0)
  result.peer = enet_host_connect(result.host, result.address.addr, 1, 0)

  if result.peer == nil:
    echo "Could not create peer."
    quit(QuitFailure)

proc `=destroy`(stream: var SlippiStream) =
  enet_peer_disconnect(stream.peer, 0)
  enet_host_destroy(stream.host)

proc connect*(stream: var SlippiStream) =
  var event: ENetEvent

  for _ in 0..<5:
    if (enet_host_service(stream.host, event.addr, 5000) > 0 and event.`type` == ENetEventType.Connect):
      echo "Connected to Dolphin."
      let packet = enet_packet_create(handshake.cstring, (handshake.len + 1).csize_t, ENetPacketFlag.Reliable.cuint)
      discard enet_peer_send(stream.peer, 0.cuchar, packet)

      discard enet_host_service(stream.host, event.addr, 5000)

      if event.`type` == ENetEventType.Receive:
        let packetData = parseJson(($event.packet.data)[0..<event.packet.dataLength])
        enet_packet_destroy(event.packet)

        stream.isConnected = true
        stream.nickName = packetData["nick"].getStr
        stream.version = packetData["version"].getStr
        stream.cursor = packetData["cursor"].getInt

      return

  echo "Connection with Dolphin failed."
  enet_peer_reset(stream.peer)

proc poll*(stream: SlippiStream): Option[JsonNode] =
  var event: ENetEvent

  discard enet_host_service(stream.host, event.addr, 0)

  if event.`type` == ENetEventType.Receive:
    let packetData = parseJson(($event.packet.data)[0..<event.packet.dataLength])
    enet_packet_destroy(event.packet)
    return some(packetData)


var stream = initSlippiStream()

stream.connect()

echo stream.nickName
echo stream.version
echo stream.cursor

while true:
  let message = stream.poll()
  if message.isSome:
    echo message.get