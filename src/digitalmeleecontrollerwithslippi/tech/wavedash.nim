import ../../melee
import ../../gccstate
import waveland


type
  WaveDash* = object
    isInProgress*: bool
    startingFrame*: int
    waveLand*: WaveLand

proc `distance`*(waveDash: var WaveDash): float =
  waveDash.waveLand.distance

proc `distance=`*(waveDash: var WaveDash, value: float) =
  waveDash.waveLand.distance = value

proc execute*(waveDash: var WaveDash, playerState: PlayerState) =
  if not playerState.isAirborne:
    waveDash.isInProgress = true
    waveDash.startingFrame = playerState.frameCount

proc update*(waveDash: var WaveDash, controller: var GCCState, playerState: PlayerState) =
  if waveDash.isInProgress:
    let frameCount = playerState.frameCount - waveDash.startingFrame

    if frameCount == 0:
      controller.yButton.isPressed = true

    elif frameCount == 1:
      controller.lButton.isPressed = false
      controller.yButton.isPressed = false

    elif playerState.actionState == ActionState.JumpSquat and
         playerState.actionFrame >= (jumpSquatFrames(playerState.character) - 1).float:
      waveDash.waveLand.execute(playerState)

    elif frameCount >= jumpSquatFrames(playerState.character):
      waveDash.isInProgress = false

    waveDash.waveLand.update(controller, playerState)