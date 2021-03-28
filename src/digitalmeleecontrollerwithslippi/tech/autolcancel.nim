import ../../melee
import ../../gccstate


type
  AutoLCancel* = object
    isInProgress*: bool

proc update*(autoLCancel: var AutoLCancel, controller: var GCCState, playerState: PlayerState) =
  if playerState.actionState == ActionState.ForwardAir or
     playerState.actionState == ActionState.BackAir or
     playerState.actionState == ActionState.DownAir or
     playerState.actionState == ActionState.UpAir or
     playerState.actionState == ActionState.NeutralAir:
    let frameAlternator = playerState.frameCount mod 2 == 0

    if frameAlternator:
      controller.lSlider.value = (43 + 1).float / 255.0
    else:
      controller.lSlider.value = 0

    autoLCancel.isInProgress = true

  else:
    autoLCancel.isInProgress = false