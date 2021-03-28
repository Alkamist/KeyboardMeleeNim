import std/json
import std/math
import std/tables
import std/options
import std/exitprocs
import std/base64
import std/times
import enet
import binaryreading
import melee

export melee


type
  CommandKind {.pure.} = enum
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
    dolphinVersion*: string
    extractionCodeVersion*: string
    cursor*: int
    gameState*: GameState
    host: ptr ENetHost
    peer: ptr ENetPeer
    address: ENetAddress
    numberOfCommands: int
    commandLengths: Table[CommandKind, int]
    currentPayload: string
    currentCommandKind: CommandKind

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

proc disconnect*(slippi: var SlippiStream) =
  enet_peer_disconnect(slippi.peer, 0)
  slippi.isConnected = false

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

proc readGameStart(slippi: var SlippiStream) =
  slippi.gameState = GameState()

  let
    versionMajor = readUint8(slippi.currentPayload, 0x1)
    versionMinor = readUint8(slippi.currentPayload, 0x2)
    versionBuild = readUint8(slippi.currentPayload, 0x3)

  slippi.extractionCodeVersion = $versionMajor & "." & $versionMinor & "." & $versionBuild

  slippi.gameState.isInProgress = true
  slippi.gameState.isOnline = GameNetworkKind(readUint8(slippi.currentPayload, 0x1a4)) == GameNetworkKind.Online

  template setPlayerAndFollowerStateField(fieldName: untyped, value: untyped): untyped =
    slippi.gameState.playerStates[playerIndex].fieldName = value
    slippi.gameState.followerStates[playerIndex].fieldName = value

  for playerIndex in 0..<4:
    setPlayerAndFollowerStateField(playerKind, PlayerKind(readUint8(slippi.currentPayload, 0x66 + (0x24 * playerIndex))))
    setPlayerAndFollowerStateField(costumeId, readUint8(slippi.currentPayload, 0x68 + (0x24 * playerIndex)).int)
    setPlayerAndFollowerStateField(cpuLevel, readUint8(slippi.currentPayload, 0x74 + (0x24 * playerIndex)).int)

    #if slippi.gameState.isOnline:
    #  setPlayerAndFollowerStateField(slippiName, cast[string](readUint16(slippi.currentPayload, 0x1a5 + (0x1f * playerIndex))))

  slippi.shiftPayloadToNextEvent()

proc readFrameStart(slippi: var SlippiStream) =
  slippi.gameState.frameCount = readInt32(slippi.currentPayload, 0x1).int
  slippi.gameState.randomSeed = readUint32(slippi.currentPayload, 0x5)
  slippi.shiftPayloadToNextEvent()

proc readPreFrameUpdate(slippi: var SlippiStream) =
  let
    playerIndex = readUint8(slippi.currentPayload, 0x5).int
    isFollower = readUint8(slippi.currentPayload, 0x6).bool

  template readPlayerState(state: untyped): untyped =
    state.playerIndex = playerIndex
    state.isFollower = isFollower
    state.frameCount = readInt32(slippi.currentPayload, 0x1)
    state.gccState.xAxis.value = readFloat32(slippi.currentPayload, 0x19)
    state.gccState.yAxis.value = readFloat32(slippi.currentPayload, 0x1d)
    state.gccState.cXAxis.value = readFloat32(slippi.currentPayload, 0x21)
    state.gccState.cYAxis.value = readFloat32(slippi.currentPayload, 0x25)
    state.gccState.lSlider.value = readFloat32(slippi.currentPayload, 0x29)

    let buttonsBitfield = readUint32(slippi.currentPayload, 0x2d)
    state.gccState.dLeftButton.isPressed = (0x1 and buttonsBitfield).bool
    state.gccState.dRightButton.isPressed = (0x2 and buttonsBitfield).bool
    state.gccState.dDownButton.isPressed = (0x4 and buttonsBitfield).bool
    state.gccState.dUpButton.isPressed = (0x8 and buttonsBitfield).bool
    state.gccState.zButton.isPressed = (0x10 and buttonsBitfield).bool
    state.gccState.rButton.isPressed = (0x20 and buttonsBitfield).bool
    state.gccState.lButton.isPressed = (0x40 and buttonsBitfield).bool
    state.gccState.aButton.isPressed = (0x100 and buttonsBitfield).bool
    state.gccState.bButton.isPressed = (0x200 and buttonsBitfield).bool
    state.gccState.xButton.isPressed = (0x400 and buttonsBitfield).bool
    state.gccState.yButton.isPressed = (0x800 and buttonsBitfield).bool
    state.gccState.startButton.isPressed = (0x1000 and buttonsBitfield).bool

  if isFollower:
    readPlayerState(slippi.gameState.followerStates[playerIndex])
  else:
    readPlayerState(slippi.gameState.playerStates[playerIndex])

  slippi.shiftPayloadToNextEvent()

proc readPostFrameUpdate(slippi: var SlippiStream) =
  let
    playerIndex = readUint8(slippi.currentPayload, 0x5).int
    isFollower = readUint8(slippi.currentPayload, 0x6).bool

  template readPlayerState(state: untyped): untyped =
    state.playerIndex = playerIndex
    state.isFollower = isFollower
    state.frameCount = readInt32(slippi.currentPayload, 0x1)
    state.character = Character(readUint8(slippi.currentPayload, 0x7))
    state.actionState = ActionState(readUint16(slippi.currentPayload, 0x8))
    state.xPosition = readFloat32(slippi.currentPayload, 0xa)
    state.yPosition = readFloat32(slippi.currentPayload, 0xe)
    state.isFacingRight = readFloat32(slippi.currentPayload, 0x12) >= 0.0
    state.percent = readFloat32(slippi.currentPayload, 0x16)
    state.shieldSize = readFloat32(slippi.currentPayload, 0x1a)
    state.lastHittingAttack = Attack(readUint8(slippi.currentPayload, 0x1e))
    state.currentComboCount = readUint8(slippi.currentPayload, 0x1f).int
    state.lastHitBy = readUint8(slippi.currentPayload, 0x20).int
    state.stocksRemaining = readUint8(slippi.currentPayload, 0x21).int
    state.actionFrame = readFloat32(slippi.currentPayload, 0x22)
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
    state.lCancelStatus = LCancelStatus(readUint8(slippi.currentPayload, 0x33))
    state.hurtboxCollisionState = HurtboxCollisionState(readUint8(slippi.currentPayload, 0x34))
    state.selfInducedAirXSpeed = readFloat32(slippi.currentPayload, 0x35)
    state.selfInducedYSpeed = readFloat32(slippi.currentPayload, 0x39)
    state.attackBasedXSpeed = readFloat32(slippi.currentPayload, 0x3d)
    state.attackBasedYSpeed = readFloat32(slippi.currentPayload, 0x41)
    state.selfInducedGroundXSpeed = readFloat32(slippi.currentPayload, 0x45)
    state.hitlagFramesRemaining = readFloat32(slippi.currentPayload, 0x49)

  if isFollower:
    readPlayerState(slippi.gameState.followerStates[playerIndex])
  else:
    readPlayerState(slippi.gameState.playerStates[playerIndex])

  slippi.shiftPayloadToNextEvent()

proc readGameEnd(slippi: var SlippiStream) =
  slippi.gameState.isInProgress = false
  slippi.gameState.gameEndMethod = some(GameEndMethod(readUint8(slippi.currentPayload, 0x1)))
  slippi.gameState.lrasInitiator = readInt8(slippi.currentPayload, 0x2).int
  slippi.shiftPayloadToNextEvent()

proc poll*(slippi: var SlippiStream): bool =
  var event: ENetEvent
  discard enet_host_service(slippi.host, event.addr, 0)

  if event.`type` == ENetEventType.Receive:
    let packetData = parseJson(($event.packet.data)[0..<event.packet.dataLength])
    enet_packet_destroy(event.packet)

    if packetData["type"].getStr == "game_event":
      slippi.currentPayload = decode(packetData["payload"].getStr)

      while slippi.currentPayload.len > 0:
        slippi.currentCommandKind = CommandKind(readUint8(slippi.currentPayload, 0x0))
        case slippi.currentCommandKind:
        of CommandKind.Unknown: slippi.shiftPayloadToNextEvent()
        of CommandKind.EventPayloads: slippi.readEventPayloads()
        of CommandKind.GameStart: slippi.readGameStart()
        of CommandKind.PreFrameUpdate: slippi.readPreFrameUpdate()
        of CommandKind.PostFrameUpdate: slippi.readPostFrameUpdate()
        of CommandKind.GameEnd: slippi.readGameEnd()
        of CommandKind.FrameStart: slippi.readFrameStart()
        of CommandKind.ItemUpdate: slippi.shiftPayloadToNextEvent()
        of CommandKind.FrameBookend:
          slippi.shiftPayloadToNextEvent()
          return true
        of CommandKind.GeckoList: slippi.shiftPayloadToNextEvent()

proc skipToRealTime(slippi: var SlippiStream) =
  let startTime = cpuTime()
  var lastFrameTime = none(float)
  while true:
    let frameEnded = slippi.poll()
    if frameEnded:
      if lastFrameTime.isSome and cpuTime() - lastFrameTime.get > 0.014:
        echo "Skipped to realtime."
        return

      lastFrameTime = some(cpuTime())

    if cpuTime() - startTime > 1.0 and not slippi.gameState.isInProgress:
      echo "There is no game in progress."
      return

proc connect*(slippi: var SlippiStream, cursor = none(int)) =
  let
    shouldSkipToRealTime = cursor.isNone
    handshake = $ %* {"type": "connect_request", "cursor": cursor.get(0)}

  var event: ENetEvent

  if (enet_host_service(slippi.host, event.addr, 5000) > 0 and event.`type` == ENetEventType.Connect):
    echo "Slippi stream connected."
    let packet = enet_packet_create(handshake.cstring, (handshake.len + 1).csize_t, ENetPacketFlag.Reliable.cuint)
    discard enet_peer_send(slippi.peer, 0.cuchar, packet)

    discard enet_host_service(slippi.host, event.addr, 5000)

    if event.`type` == ENetEventType.Receive:
      let packetData = parseJson(($event.packet.data)[0..<event.packet.dataLength])
      enet_packet_destroy(event.packet)

      slippi.isConnected = true
      slippi.nickName = packetData["nick"].getStr
      slippi.dolphinVersion = packetData["version"].getStr
      slippi.cursor = packetData["cursor"].getInt

      if shouldSkipToRealTime:
        slippi.skipToRealTime()

    return

  echo "Slippi stream connection failed."
  enet_peer_reset(slippi.peer)


when isMainModule:
  var stream = initSlippiStream()

  stream.connect()

  while true:
    if stream.poll():
      echo stream.gameState.playerStates[0].xPosition