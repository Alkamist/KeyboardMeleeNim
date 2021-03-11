import button
import analogaxis
import analogslider
import gamecubecontrollerstate
import jumplogic
import airdodgelogic
import sticktilter
import astick


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
    jumpLogic*: JumpLogic
    airDodgeLogic*: AirDodgeLogic
    tiltModifier*: StickTilter
    shieldTilter*: StickTilter
    aStick*: AStick

proc initDigitalMeleeController*(): DigitalMeleeController =
  result.jumpLogic = initJumpLogic()
  result.airDodgeLogic = initAirDodgeLogic()
  result.tiltModifier = initStickTilter(0.65)
  result.shieldTilter = initStickTilter(0.6625)
  result.aStick = initAStick()

proc updateActions(controller: var DigitalMeleeController) =
  for action in controller.actions.mitems:
    action.update()

proc updateAxesFromDirections(controller: var DigitalMeleeController) =
  controller.state.xAxis.setValueFromStates(controller.actions[Action.Left].isPressed, controller.actions[Action.Right].isPressed)
  controller.state.yAxis.setValueFromStates(controller.actions[Action.Down].isPressed, controller.actions[Action.Up].isPressed)
  controller.state.cXAxis.setValueFromStates(controller.actions[Action.CLeft].isPressed, controller.actions[Action.CRight].isPressed)
  controller.state.cYAxis.setValueFromStates(controller.actions[Action.CDown].isPressed, controller.actions[Action.CUp].isPressed)

proc handleAStick(controller: var DigitalMeleeController) =
  if not controller.actions[Action.Shield].isPressed:
    let aStickModifier = controller.actions[Action.Tilt].isPressed
    controller.aStick.update(controller.state.xAxis,
                             controller.state.yAxis,
                             controller.actions[Action.A].isPressed,
                             controller.actions[Action.CLeft].isPressed and aStickModifier,
                             controller.actions[Action.CRight].isPressed and aStickModifier,
                             controller.actions[Action.CDown].isPressed and aStickModifier,
                             controller.actions[Action.CUp].isPressed and aStickModifier)

    controller.state.aButton.isPressed = controller.aStick.outputState
    controller.state.xAxis.value = controller.aStick.xAxisOutput
    controller.state.yAxis.value = controller.aStick.yAxisOutput

    if aStickModifier:
      controller.state.cXAxis.value = 0.0
      controller.state.cYAxis.value = 0.0

  else:
    controller.state.aButton.isPressed = controller.actions[Action.A].isPressed

proc handleJumpLogic(controller: var DigitalMeleeController) =
  controller.jumpLogic.update(controller.actions[Action.ShortHop].isPressed,
                              controller.actions[Action.FullHop].isPressed)

proc handleAirDodgeLogic(controller: var DigitalMeleeController) =
  controller.airDodgeLogic.update(controller.state.xAxis,
                                  controller.state.yAxis,
                                  controller.actions[Action.AirDodge].isPressed,
                                  controller.actions[Action.Tilt].isPressed)

proc handleTiltModifier(controller: var DigitalMeleeController) =
  controller.tiltModifier.update(controller.state.xAxis,
                                 controller.state.yAxis,
                                 controller.actions[Action.Tilt].isPressed,
                                 false,
                                 controller.actions[Action.Shield].isPressed)

proc handleShieldTilt(controller: var DigitalMeleeController) =
  controller.shieldTilter.update(controller.state.xAxis,
                                 controller.state.yAxis,
                                 controller.actions[Action.Shield].isPressed,
                                 controller.actions[Action.Shield].justPressed,
                                 false)

proc setActionState*(controller: var DigitalMeleeController, action: Action, state: bool) =
  controller.actions[action].isPressed = state

proc update*(controller: var DigitalMeleeController) =
  controller.updateActions()

  controller.updateAxesFromDirections()
  controller.handleAStick()
  controller.handleTiltModifier()
  controller.handleShieldTilt()
  controller.handleJumpLogic()
  controller.handleAirDodgeLogic()

  controller.state.bButton.isPressed = controller.actions[Action.B].isPressed
  controller.state.zButton.isPressed = controller.actions[Action.Z].isPressed
  controller.state.xButton.isPressed = controller.jumpLogic.fullHopOutput
  controller.state.yButton.isPressed = controller.jumpLogic.shortHopOutput
  controller.state.lButton.isPressed = controller.actions[Action.AirDodge].isPressed
  controller.state.rButton.isPressed = controller.actions[Action.Shield].isPressed
  controller.state.startButton.isPressed = controller.actions[Action.Start].isPressed
  controller.state.dLeftButton.isPressed = controller.actions[Action.DLeft].isPressed
  controller.state.dRightButton.isPressed = controller.actions[Action.DRight].isPressed
  controller.state.dDownButton.isPressed = controller.actions[Action.DDown].isPressed
  controller.state.dUpButton.isPressed = controller.actions[Action.DUp].isPressed

  controller.state.update()