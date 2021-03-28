import ../../melee
import ../../gccstate


type
  SpotDodge* = object
    isInProgress*: bool
    startingFrame: int

proc execute*(spotDodge: var SpotDodge, playerState: PlayerState) =
  if not playerState.isAirborne:
    spotDodge.isInProgress = true
    spotDodge.startingFrame = playerState.frameCount

proc update*(spotDodge: var SpotDodge, controller: var GCCState, playerState: PlayerState) =
  if spotDodge.isInProgress:
    let frameCount = playerState.frameCount - spotDodge.startingFrame

    if frameCount == 0:
      controller.rButton.isPressed = true
      controller.yAxis.value = -1.0

    else:
      spotDodge.isInProgress = false