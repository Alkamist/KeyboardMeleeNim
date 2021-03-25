import ../../melee
import ../../gccstate


type
  SpotDodge* = object
    hasControl*: bool
    startTime: int

proc execute*(spotDodge: var SpotDodge, gameState: GameState) =
  spotDodge.hasControl = true
  spotDodge.startTime = gameState.frameCount

proc update*(spotDodge: var SpotDodge,
             controller: var GCCState,
             gameState: GameState,
             playerState: PlayerState) =
  if spotDodge.hasControl:
    if playerState.isAirborne or gameState.frameCount - spotDodge.startTime >= 2:
      spotDodge.hasControl = false
      return

    controller.rButton.isPressed = true
    controller.yAxis.value = -1.0