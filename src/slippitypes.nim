import math
import tables


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

  # EventPayloadsData* = object
  #   payloadSize*: uint8
  #   otherCommandByte*: uint8
  #   otherCommandPayloadSize*: uint16

  # GameStartData* = object
  #   version*: array[4, uint8]
  #   gameInfoBlock*: array[312, uint8]
  #   randomSeed*: uint32
  #   dashbackFix*: uint32
  #   shieldDropFix*: uint32
  #   nameTag*: array[8, int16]
  #   pal*: bool
  #   frozenPs*: bool
  #   minorScene*: uint8
  #   majorScene*: uint8

  # FrameStartData* = object
  #   frameNumber*: int32
  #   randomSeed*: uint32

  # PreFrameUpdateData* = object
  #   frameNumber*: int32
  #   playerIndex*: uint8
  #   isFollower*: bool
  #   randomSeed*: uint32
  #   actionStateId*: uint16
  #   xPosition*: float32
  #   yPosition*: float32
  #   facingDirection*: float32
  #   joystickX*: float32
  #   joystickY*: float32
  #   cStickX*: float32
  #   cStickY*: float32
  #   trigger*: float32
  #   processedButtons*: uint32
  #   physicalButtons*: uint16
  #   physicalLTrigger*: float32
  #   physicalRTrigger*: float32
  #   xAnalogForUcf*: uint8
  #   percent*: float32

  # PostFrameUpdateData* = object
  #   frameNumber*: int32
  #   playerIndex*: uint8
  #   isFollower*: bool
  #   internalCharacterId*: uint8
  #   actionStateId*: uint16
  #   xPosition*: float32
  #   yPosition*: float32
  #   facingDirection*: float32
  #   percent*: float32
  #   shieldSize*: float32
  #   lastHittingAttackId*: uint8
  #   currentComboCount*: uint8
  #   lastHitBy*: uint8
  #   stocksRemaining*: uint8
  #   actionStateFrameCounter*: float32
  #   stateBitFlags1*: uint8
  #   stateBitFlags2*: uint8
  #   stateBitFlags3*: uint8
  #   stateBitFlags4*: uint8
  #   stateBitFlags5: uint8
  #   miscActionState*: float32
  #   isAirborne*: bool
  #   lastGroundId*: uint16
  #   jumpsRemaining*: uint8
  #   lCancelStatus*: uint8
  #   hurtboxCollisionState*: uint8
  #   selfInducedAirXSpeed*: float32
  #   selfInducedYSpeed*: float32
  #   attackBasedXSpeed*: float32
  #   attackBasedYSpeed*: float32
  #   selfInducedGroundXSpeed*: float32
  #   hitlagFramesRemaining*: float32

  # ItemUpdateData* = object
  #   frameNumber*: int32
  #   typeId*: uint16
  #   state*: uint8
  #   facingDirection*: float32
  #   xVelocity*: float32
  #   yVelocity*: float32
  #   xPosition*: float32
  #   yPosition*: float32
  #   damageTaken*: uint16
  #   expirationTimer*: float32
  #   spawnId*: uint32
  #   misc1*: uint8
  #   misc2*: uint8
  #   misc3*: uint8
  #   misc4*: uint8
  #   owner*: int8

  # FrameBookendData* = object
  #   frameNumber*: int32
  #   latestFinalizedFrame*: int32

  # GameEndData* = object
  #   gameEndMethod*: uint8
  #   lrasInitiator*: int8

proc readUint8*(input: string, location: int): uint8 {.inline.} =
  input[location].uint8

proc readUint16*(input: string, location: int): uint16 {.inline.} =
  result = cast[ptr uint16](input[location].unsafeAddr)[]

let payload = readFile("payload.txt")

let
  payloadSize = readUint8(payload, 0x1)
  numberOfCommands = (payloadSize - 1).floorDiv(3).int

echo "Payload Size: " & $payloadSize
echo "Number of Commands: " & $numberOfCommands

var location = 0x2

for _ in 0..<numberOfCommands:
  let
    commandKind = CommandKind(readUint8(payload, location))
    commandLength = readUint16(payload, location + 0x1)

  echo "Command Kind: " & $commandKind
  echo "Command Length: " & $commandLength

  location += 0x3