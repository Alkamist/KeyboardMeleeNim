import button
import analogaxis
import analogslider
import gamecubecontrollerstate
import jumplogic
import airdodgelogic
import sticktilter
import astick
import bstick
import backdashoutofcrouchfix


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
    bStick*: BStick
    backdashOutOfCrouchFix*: BackdashOutOfCrouchFix
    previousDirectionIsRight: bool
    xModX: float
    xModY: float
    yModX: float
    yModY: float
    chargeSmash: bool
    isLightShielding: bool

proc initDigitalMeleeController*(): DigitalMeleeController =
  result.jumpLogic = initJumpLogic()
  result.airDodgeLogic = initAirDodgeLogic()
  result.tiltModifier = initStickTilter(0.65)
  result.shieldTilter = initStickTilter(0.6625)
  result.aStick = initAStick()
  result.bStick = initBStick()
  result.backdashOutOfCrouchFix = initBackdashOutOfCrouchFix()
  result.previousDirectionIsRight = true
  result.xModX = 0.2875
  result.xModY = 0.95
  result.yModX = 0.95
  result.yModY = 0.2875

proc updateActions(controller: var DigitalMeleeController) =
  for action in controller.actions.mitems:
    action.update()

proc updateAxesFromDirections(controller: var DigitalMeleeController) =
  controller.state.xAxis.setValueFromStates(controller.actions[Action.Left].isPressed, controller.actions[Action.Right].isPressed)
  controller.state.yAxis.setValueFromStates(controller.actions[Action.Down].isPressed, controller.actions[Action.Up].isPressed)
  controller.state.cXAxis.setValueFromStates(controller.actions[Action.CLeft].isPressed, controller.actions[Action.CRight].isPressed)
  controller.state.cYAxis.setValueFromStates(controller.actions[Action.CDown].isPressed, controller.actions[Action.CUp].isPressed)

proc handleBackdashOutOfCrouchFix(controller: var DigitalMeleeController) =
  controller.backdashOutOfCrouchFix.update(controller.state.xAxis,
                                           controller.actions[Action.Left].isPressed,
                                           controller.actions[Action.Right].isPressed,
                                           controller.actions[Action.Down].isPressed)

  # Only fix backdash out of crouch if you are not doing anything else important.
  if not (controller.actions[Action.FullHop].isPressed or
          controller.actions[Action.ShortHop].isPressed or
          controller.actions[Action.AirDodge].isPressed or
          controller.actions[Action.Shield].isPressed or
          controller.actions[Action.Z].isPressed or
          controller.actions[Action.A].isPressed or
          controller.actions[Action.B].isPressed or
          controller.actions[Action.BSide].isPressed or
          controller.actions[Action.BUp].isPressed or
          controller.actions[Action.Tilt].isPressed):
    controller.state.xAxis.value = controller.backdashOutOfCrouchFix.xAxisOutput

proc handleXAxisInversion(controller: var DigitalMeleeController) =
  if controller.actions[Action.InvertXAxis].isPressed:
    controller.state.xAxis.value = -controller.state.xAxis.value

proc handleChargedSmashes(controller: var DigitalMeleeController) =
  let cIsPressed = controller.actions[Action.CLeft].isPressed or
                   controller.actions[Action.CRight].isPressed or
                   controller.actions[Action.CDown].isPressed or
                   controller.actions[Action.CUp].isPressed

  if controller.actions[Action.ChargeSmash].isPressed and cIsPressed:
    controller.chargeSmash = true

  if not cIsPressed:
    controller.chargeSmash = false

  if controller.chargeSmash:
    controller.state.aButton.isPressed = true

proc handleAngledSmashes(controller: var DigitalMeleeController) =
  let cAngled = (controller.actions[Action.CLeft].isPressed or
                 controller.actions[Action.CRight].isPressed) and
                (controller.actions[Action.Down].isPressed or
                 controller.actions[Action.Up].isPressed)

  if cAngled and not controller.actions[Action.Tilt].isPressed:
    controller.state.cYAxis.value = controller.state.yAxis.direction * 0.4

proc handleModifierAngles(controller: var DigitalMeleeController) =
  if controller.actions[Action.YMod].isPressed:
    controller.state.xAxis.value = controller.state.xAxis.direction * controller.yModX
    controller.state.yAxis.value = controller.state.yAxis.direction * controller.yModY

  elif controller.actions[Action.XMod].isPressed:
    controller.state.xAxis.value = controller.state.xAxis.direction * controller.xModX
    controller.state.yAxis.value = controller.state.yAxis.direction * controller.xModY

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

proc handleBStick(controller: var DigitalMeleeController) =
  if controller.state.xAxis.value > 0.0:
    controller.previousDirectionIsRight = true

  elif controller.state.xAxis.value < 0.0:
    controller.previousDirectionIsRight = false

  controller.bStick.update(controller.state.xAxis,
                           controller.state.yAxis,
                           controller.actions[Action.B].isPressed and not controller.actions[Action.Down].isPressed,
                           controller.actions[Action.BSide].isPressed and not controller.previousDirectionIsRight,
                           controller.actions[Action.BSide].isPressed and controller.previousDirectionIsRight,
                           controller.actions[Action.B].isPressed and controller.actions[Action.Down].isPressed,
                           controller.actions[Action.BUp].isPressed,
                           controller.actions[Action.Shield].isPressed)

  controller.state.bButton.isPressed = controller.bStick.outputState
  controller.state.xAxis.value = controller.bStick.xAxisOutput
  controller.state.yAxis.value = controller.bStick.yAxisOutput

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

proc handleShield(controller: var DigitalMeleeController) =
  # Allow for a special button to toggle light shield while the shield button is held.
  if controller.actions[Action.ToggleLightShield].justPressed and
     controller.actions[Action.Shield].isPressed:
    controller.isLightShielding = not controller.isLightShielding

  if controller.actions[Action.Shield].justReleased:
    controller.isLightShielding = false

  if controller.isLightShielding:
    controller.state.rButton.isPressed = false
    controller.state.lSlider.value = (43 + 1).float / 255.0

  else:
    controller.state.rButton.isPressed = controller.actions[Action.Shield].isPressed
    controller.state.lSlider.value = 0.0

proc setActionState*(controller: var DigitalMeleeController, action: Action, state: bool) =
  controller.actions[action].isPressed = state

proc update*(controller: var DigitalMeleeController) =
  controller.updateAxesFromDirections()
  controller.handleXAxisInversion()
  controller.handleBackdashOutOfCrouchFix()
  controller.handleModifierAngles()
  controller.handleAStick()
  controller.handleTiltModifier()
  controller.handleBStick()
  controller.handleShieldTilt()
  controller.handleChargedSmashes()
  controller.handleJumpLogic()
  controller.handleAirDodgeLogic()
  controller.handleAngledSmashes()
  controller.handleShield()

  controller.state.zButton.isPressed = controller.actions[Action.Z].isPressed
  controller.state.xButton.isPressed = controller.jumpLogic.fullHopOutput
  controller.state.yButton.isPressed = controller.jumpLogic.shortHopOutput
  controller.state.lButton.isPressed = controller.actions[Action.AirDodge].isPressed
  controller.state.startButton.isPressed = controller.actions[Action.Start].isPressed
  controller.state.dLeftButton.isPressed = controller.actions[Action.DLeft].isPressed
  controller.state.dRightButton.isPressed = controller.actions[Action.DRight].isPressed
  controller.state.dDownButton.isPressed = controller.actions[Action.DDown].isPressed
  controller.state.dUpButton.isPressed = controller.actions[Action.DUp].isPressed

  controller.state.update()
  controller.updateActions()