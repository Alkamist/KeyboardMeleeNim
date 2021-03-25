import std/math
import std/options
import ../../melee
import ../../gccstate


const
  angleFromPi = arccos(0.95)
  angleStart = PI + angleFromPi
  angleMagnitude = PI - 2.0 * angleFromPi

type
  WaveLand* = object
    isInProgress*: bool
    frameCount*: int
    distance*: float

proc execute*(waveLand: var WaveLand,
              playerState: PlayerState,
              distance = none(float)) =
  waveLand.isInProgress = true
  waveLand.frameCount = 0
  if distance.isSome:
    waveLand.distance = distance.get

proc update*(waveLand: var WaveLand,
             controller: var GCCState,
             playerState: PlayerState) =
  if waveLand.isInProgress:
    if waveLand.frameCount == 0:
      let
        clampedDistance = waveLand.distance.max(-1.0).min(1.0)
        zeroToOneDistance = 0.5 * (clampedDistance + 1.0)

      controller.lButton.isPressed = true
      setAngle(controller.xAxis,
               controller.yAxis,
               zeroToOneDistance * angleMagnitude + angleStart)

    elif waveLand.frameCount == 1:
      controller.lButton.isPressed = false
      waveLand.isInProgress = false

    waveLand.frameCount += 1