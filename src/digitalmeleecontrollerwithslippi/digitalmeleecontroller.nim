import ../button
import ../analogaxis
import ../analogslider
import ../gccstate
import ../melee
import tech/spotdodge
import tech/wavedash
import tech/autolcancel

export gccstate


type
  Action* {.pure.} = enum
    Left,
    Right,
    Down,
    Up,
    XMod,
    YMod,
    Tilt,
    CLeft,
    CRight,
    CDown,
    CUp,
    ShortHop,
    FullHop,
    A,
    B,
    BUp,
    BSide,
    Z,
    Shield,
    ToggleLightShield,
    AirDodge,
    Start,
    DLeft,
    DRight,
    DDown,
    DUp,
    ChargeSmash,
    InvertXAxis,

  DigitalMeleeController* = object
    actions*: array[Action, Button]
    state*: GCCState
    gameState: GameState
    playerState: PlayerState
    opponentState: PlayerState
    spotDodge: SpotDodge
    waveDash: WaveDash
    autoLCancel: AutoLCancel

proc initDigitalMeleeController*(): DigitalMeleeController =
  result

proc updateActions(controller: var DigitalMeleeController) =
  for action in controller.actions.mitems:
    action.update()

proc setActionState*(controller: var DigitalMeleeController, action: Action, state: bool) =
  controller.actions[action].isPressed = state

proc opponentEnteredState(controller: DigitalMeleeController, state: ActionState): bool =
  controller.opponentState.actionState == state and controller.opponentState.actionFrame <= 1.0

proc onNewFrame*(controller: var DigitalMeleeController, gameState: GameState) =
  controller.gameState = gameState
  controller.playerState = gameState.playerStates[0]
  controller.opponentState = gameState.playerStates[1]

  if controller.opponentEnteredState(ActionState.Grab) or
     controller.opponentEnteredState(ActionState.GrabRunning):
    controller.spotDodge.execute(controller.playerState)
  controller.spotDodge.update(controller.state, controller.playerState)

  if controller.actions[Action.BUp].justPressed:
    controller.waveDash.execute(controller.playerState)
  let (meleeX, meleeY) = circularGate(controller.state.xAxis.value, controller.state.yAxis.value, 1.0)
  controller.waveDash.distance = meleeX
  controller.waveDash.update(controller.state, controller.playerState)

  controller.autoLCancel.update(controller.state, controller.playerState)


  if not controller.autoLCancel.isInProgress:
    controller.state.lSlider.value = 0
    controller.state.rSlider.value = 0


  controller.state.update()
  controller.updateActions()

proc hasControl(controller: DigitalMeleeController): bool =
  not controller.waveDash.isInProgress and
  not controller.spotDodge.isInProgress

proc update*(controller: var DigitalMeleeController) =
  if controller.hasControl:
    controller.state.xAxis.setValueFromStates(controller.actions[Action.Left].isPressed, controller.actions[Action.Right].isPressed)
    controller.state.yAxis.setValueFromStates(controller.actions[Action.Down].isPressed, controller.actions[Action.Up].isPressed)
    controller.state.cXAxis.setValueFromStates(controller.actions[Action.CLeft].isPressed, controller.actions[Action.CRight].isPressed)
    controller.state.cYAxis.setValueFromStates(controller.actions[Action.CDown].isPressed, controller.actions[Action.CUp].isPressed)
    controller.state.aButton.isPressed = controller.actions[Action.A].isPressed
    controller.state.bButton.isPressed = controller.actions[Action.B].isPressed
    controller.state.xButton.isPressed = controller.actions[Action.FullHop].isPressed
    controller.state.yButton.isPressed = controller.actions[Action.ShortHop].isPressed
    controller.state.zButton.isPressed = controller.actions[Action.Z].isPressed
    controller.state.lButton.isPressed = controller.actions[Action.AirDodge].isPressed
    controller.state.rButton.isPressed = controller.actions[Action.Shield].isPressed
    controller.state.startButton.isPressed = controller.actions[Action.Start].isPressed
    controller.state.dLeftButton.isPressed = controller.actions[Action.DLeft].isPressed
    controller.state.dRightButton.isPressed = controller.actions[Action.DRight].isPressed
    controller.state.dDownButton.isPressed = controller.actions[Action.DDown].isPressed
    controller.state.dUpButton.isPressed = controller.actions[Action.DUp].isPressed