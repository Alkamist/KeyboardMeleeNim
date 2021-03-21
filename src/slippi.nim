import std/json
import std/math
import std/tables
import std/options
import std/exitprocs
import std/base64
import enet
import binaryreading
import melee


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
    currentPayload: string
    currentCommandKind: CommandKind
    gameState: MeleeGameState


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

proc `=destroy`(slippi: var SlippiStream) =
  enet_peer_disconnect(slippi.peer, 0)
  enet_host_destroy(slippi.host)

proc connect*(slippi: var SlippiStream) =
  var event: ENetEvent

  for _ in 0..<5:
    if (enet_host_service(slippi.host, event.addr, 5000) > 0 and event.`type` == ENetEventType.Connect):
      echo "Connected to Dolphin."
      let packet = enet_packet_create(handshake.cstring, (handshake.len + 1).csize_t, ENetPacketFlag.Reliable.cuint)
      discard enet_peer_send(slippi.peer, 0.cuchar, packet)

      discard enet_host_service(slippi.host, event.addr, 5000)

      if event.`type` == ENetEventType.Receive:
        let packetData = parseJson(($event.packet.data)[0..<event.packet.dataLength])
        enet_packet_destroy(event.packet)

        slippi.isConnected = true
        slippi.nickName = packetData["nick"].getStr
        slippi.version = packetData["version"].getStr
        slippi.cursor = packetData["cursor"].getInt

      return

  echo "Connection with Dolphin failed."
  enet_peer_reset(slippi.peer)

proc poll*(slippi: SlippiStream): Option[JsonNode] =
  var event: ENetEvent

  discard enet_host_service(slippi.host, event.addr, 0)

  if event.`type` == ENetEventType.Receive:
    let packetData = parseJson(($event.packet.data)[0..<event.packet.dataLength])
    enet_packet_destroy(event.packet)
    return some(packetData)

proc shiftPayloadToNextEvent(slippi: var SlippiStream) =
  slippi.currentPayload = slippi.currentPayload[slippi.commandLengths[slippi.currentCommandKind] + 1..<slippi.currentPayload.len]

proc readEventPayloads(slippi: var SlippiStream) =
  let payloadSize = readUint8(slippi.currentPayload, 0x1)
  slippi.numberOfCommands = (payloadSize - 1).floorDiv(3).int

  var location = 0x2
  for _ in 0..<slippi.numberOfCommands:
    let commandKind = CommandKind(readUint8(slippi.currentPayload, location))
    slippi.commandLengths[commandKind] = readUint16(slippi.currentPayload, location + 0x1).int
    location += 0x3

  slippi.currentPayload = slippi.currentPayload[(payloadSize + 1).int..<slippi.currentPayload.len]

proc readPostFrameUpdate(slippi: var SlippiStream) =
  let
    playerIndex = readUint8(slippi.currentPayload, 0x5).int
    isFollower = readUint8(slippi.currentPayload, 0x6).bool

  template performRead(state: untyped): untyped =
    state.playerIndex = playerIndex
    state.isFollower = isFollower
    state.character = MeleeCharacter(readUint8(slippi.currentPayload, 0x7))
    state.actionState = MeleeActionState(readUint16(slippi.currentPayload, 0x8))
    state.xPosition = readFloat32(slippi.currentPayload, 0xa)
    state.yPosition = readFloat32(slippi.currentPayload, 0xe)
    state.isFacingRight = readFloat32(slippi.currentPayload, 0x12) >= 0.0
    state.percent = readFloat32(slippi.currentPayload, 0x16)
    state.shieldSize = readFloat32(slippi.currentPayload, 0x1a)
    state.lastHittingAttack = MeleeAttack(readUint8(slippi.currentPayload, 0x1e))
    state.currentComboCount = readUint8(slippi.currentPayload, 0x1f).int
    state.lastHitBy = readUint8(slippi.currentPayload, 0x20).int
    state.stocksRemaining = readUint8(slippi.currentPayload, 0x21).int
    state.actionStateFrameCounter = readFloat32(slippi.currentPayload, 0x22)
    state.currentComboCount = readUint8(slippi.currentPayload, 0x1f).int

    # State bit flags:
    let
      stateBitFlags1 = readUint8(slippi.currentPayload, 0x26)
      stateBitFlags2 = readUint8(slippi.currentPayload, 0x27)
      stateBitFlags3 = readUint8(slippi.currentPayload, 0x28)
      stateBitFlags4 = readUint8(slippi.currentPayload, 0x29)
      stateBitFlags5 = readUint8(slippi.currentPayload, 0x2a)

    state.reflectIsActive = (0x10 and stateBitFlags1).bool
    state.isInvincible = (0x04 and stateBitFlags2).bool
    state.isFastFalling = (0x08 and stateBitFlags2).bool
    state.isInHitlag = (0x20 and stateBitFlags2).bool
    state.isShielding = (0x80 and stateBitFlags3).bool
    state.isInHitstun = (0x02 and stateBitFlags4).bool
    state.detectionHitboxIsTouchingShield = (0x04 and stateBitFlags4).bool
    state.isPowershielding = (0x20 and stateBitFlags4).bool
    state.isSleeping = (0x10 and stateBitFlags5).bool
    state.isDead = (0x40 and stateBitFlags5).bool
    state.isOffscreen = (0x80 and stateBitFlags5).bool

    state.hitstunRemaining = readFloat32(slippi.currentPayload, 0x2b)
    state.isAirborne = readUint8(slippi.currentPayload, 0x2f).bool
    state.lastGroundId = readUint16(slippi.currentPayload, 0x30).int
    state.jumpsRemaining = readUint8(slippi.currentPayload, 0x32).int
    state.lCancelStatus = MeleeLCancelStatus(readUint8(slippi.currentPayload, 0x33))
    state.hurtboxCollisionState = MeleeHurtboxCollisionState(readUint8(slippi.currentPayload, 0x34))
    state.selfInducedAirXSpeed = readFloat32(slippi.currentPayload, 0x35)
    state.selfInducedYSpeed = readFloat32(slippi.currentPayload, 0x39)
    state.attackBasedXSpeed = readFloat32(slippi.currentPayload, 0x3d)
    state.attackBasedYSpeed = readFloat32(slippi.currentPayload, 0x41)
    state.selfInducedGroundXSpeed = readFloat32(slippi.currentPayload, 0x45)
    state.hitlagFramesRemaining = readFloat32(slippi.currentPayload, 0x49)

  if isFollower:
    performRead(slippi.gameState.followerStates[playerIndex])
  else:
    performRead(slippi.gameState.playerStates[playerIndex])

  slippi.shiftPayloadToNextEvent()


var slippi = initSlippiStream()

slippi.connect()

while true:
  let message = slippi.poll()
  if message.isSome:
    if message.get["type"].getStr == "game_event":
      slippi.currentPayload = decode(message.get["payload"].getStr)

      while slippi.currentPayload.len > 0:
        slippi.currentCommandKind = CommandKind(readUint8(slippi.currentPayload, 0x0))
        #echo "Command Kind: " & $slippi.currentCommandKind

        case slippi.currentCommandKind:
        of CommandKind.Unknown: slippi.shiftPayloadToNextEvent()
        of CommandKind.EventPayloads: slippi.readEventPayloads()
        of CommandKind.GameStart: slippi.shiftPayloadToNextEvent()
        of CommandKind.PreFrameUpdate: slippi.shiftPayloadToNextEvent()
        of CommandKind.PostFrameUpdate: slippi.readPostFrameUpdate()
        of CommandKind.GameEnd: slippi.shiftPayloadToNextEvent()
        of CommandKind.FrameStart: slippi.shiftPayloadToNextEvent()
        of CommandKind.ItemUpdate: slippi.shiftPayloadToNextEvent()
        of CommandKind.FrameBookend: slippi.shiftPayloadToNextEvent()
        of CommandKind.GeckoList: slippi.shiftPayloadToNextEvent()