import std/math
import ../../melee
import ../../gccstate


const
  angleFromPi = arccos(0.95)
  angleStart = PI + angleFromPi
  angleMagnitude = PI - 2.0 * angleFromPi

type
  WaveLand* = object
    isInProgress*: bool
    startingFrame*: int
    distance*: float

proc execute*(waveLand: var WaveLand, playerState: PlayerState) =
  waveLand.isInProgress = true
  waveLand.startingFrame = playerState.frameCount

proc update*(waveLand: var WaveLand, controller: var GCCState, playerState: PlayerState) =
  if waveLand.isInProgress:
    let frameCount = playerState.frameCount - waveLand.startingFrame

    if frameCount == 0:
      let
        clampedDistance = waveLand.distance.max(-1.0).min(1.0)
        zeroToOneDistance = 0.5 * (clampedDistance + 1.0)

      controller.lButton.isPressed = true
      setAngle(controller.xAxis,
               controller.yAxis,
               zeroToOneDistance * angleMagnitude + angleStart)

    elif frameCount == 1:
      waveLand.isInProgress = false