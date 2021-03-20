import std/json
import std/math
import std/tables
import std/options
import std/exitprocs
import std/base64
import enet
import binaryparsing


let handshake = $ %* {"type": "connect_request", "cursor": 0}

type
  CommandKind* {.pure.} = enum
    Unknown = 0x10,
    EventPayloads = 0x35,
    GameStart = 0x36,
    PreFrameUpdate = 0x37,
    PostFrameUpdate = 0x38,
    GameEnd = 0x39,
    FrameStart = 0x3a,
    ItemUpdate = 0x3b,
    FrameBookend = 0x3c,
    GeckoList = 0x3d,

  SlippiStream* = object
    isConnected*: bool
    nickName*: string
    version*: string
    cursor*: int
    host: ptr ENetHost
    peer: ptr ENetPeer
    address: ENetAddress
    numberOfCommands: int
    commandLengths: Table[CommandKind, int]

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

# proc readEventPayloads(stream: var SlippiStream, payload: string) =
#   let payloadSize = readUint8(payload, 0x1)
#   stream.numberOfCommands = (payloadSize - 1).floorDiv(3).int

#   var location = 0x2
#   for _ in 0..<stream.numberOfCommands:
#     let commandKind = CommandKind(readUint8(payload, location))
#     stream.commandLengths[commandKind] = readUint16(payload, location + 0x1).int
#     location += 0x3


var slippi = initSlippiStream()

slippi.connect()

while true:
  let message = slippi.poll()
  if message.isSome:
    if message.get["type"].getStr == "game_event":
      var payloadStr = decode(message.get["payload"].getStr)

      while payloadStr.len > 0:
        let commandKind = CommandKind(readUint8(payloadStr, 0x0))
        echo "Command Kind: " & $commandKind

        case commandKind:

        of CommandKind.Unknown:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.EventPayloads:
          let payloadSize = readUint8(payloadStr, 0x1)
          slippi.numberOfCommands = (payloadSize - 1).floorDiv(3).int

          var location = 0x2
          for _ in 0..<slippi.numberOfCommands:
            let commandKind = CommandKind(readUint8(payloadStr, location))
            slippi.commandLengths[commandKind] = readUint16(payloadStr, location + 0x1).int
            location += 0x3

          payloadStr = payloadStr[payloadSize + 1..<payloadStr.len]

        of CommandKind.GameStart:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.PreFrameUpdate:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.PostFrameUpdate:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.GameEnd:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.FrameStart:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.ItemUpdate:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.FrameBookend:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]

        of CommandKind.GeckoList:
          payloadStr = payloadStr[slippi.commandLengths[commandKind] + 1..<payloadStr.len]