import std/options
import ../../melee
import ../../gccstate
import waveland


type
  WaveDash* = object
    isInProgress*: bool
    frameCount*: int
    waveLand*: WaveLand

proc `distance`*(waveDash: var WaveDash): float =
  waveDash.waveLand.distance

proc `distance=`*(waveDash: var WaveDash, value: float) =
  waveDash.waveLand.distance = value

proc execute*(waveDash: var WaveDash,
              playerState: PlayerState,
              distance = none(float)) =
  if not playerState.isAirborne:
    waveDash.isInProgress = true
    waveDash.frameCount = 0
    if distance.isSome:
      waveDash.waveLand.distance = distance.get

proc update*(waveDash: var WaveDash,
             controller: var GCCState,
             playerState: PlayerState) =
  if waveDash.isInProgress:
    if waveDash.frameCount == 0:
      controller.yButton.isPressed = true

    elif waveDash.frameCount == 1:
      controller.lButton.isPressed = false
      controller.yButton.isPressed = false

    elif playerState.actionState == ActionState.JumpSquat and
         playerState.actionFrame >= (jumpSquatFrames(playerState.character) - 1).float:
      waveDash.waveLand.execute(playerState)

    elif waveDash.frameCount >= jumpSquatFrames(playerState.character):
      controller.lButton.isPressed = false
      waveDash.isInProgress = false

    waveDash.waveLand.update(controller, playerState)

    waveDash.frameCount += 1