import
  std/times,
  button,
  analogaxis,
  analogslider,
  gccstate

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

  StickTilter* = object
    isTilting: bool
    tiltLevel: float
    tiltTime: float

  DigitalMeleeController* = object
    useShortHopMacro*: bool
    useCStickTilting*: bool
    xModX*: float
    xModY*: float
    yModX*: float
    yModY*: float
    actions*: array[Action, Button]
    state*: GCCState
    tiltModifier: StickTilter
    shieldTilter: StickTilter
    chargeSmash: bool
    isLightShielding: bool
    delayBackdash: bool
    backdashTime: float
    isDoingSafeDownB: bool
    safeDownBTime: float
    isShortHopping: bool
    isFullHopping: bool
    shortHopTime: float
    fullHopTime: float
    airDodgeTime: float
    isAirDodging: bool
    airDodgeXLevel: float
    airDodgeYLevel: float
    aAttackTime: float
    isUpTilting: bool
    isDownTilting: bool
    isLeftTilting: bool
    isRightTilting: bool
    isDoingNeutralA: bool

proc bipolarMax(value, magnitude: float): float =
  if value > 0.0: value.max(magnitude)
  elif value < 0.0: value.min(-magnitude)
  else: 0.0

proc scaleAxes(axisA, axisB: var AnalogAxis; scaleValue: float) =
  let axisAMagnitude = axisA.value.abs
  if axisAMagnitude > scaleValue:
    let scaleFactor = scaleValue / axisAMagnitude
    axisA.value = axisA.direction * scaleValue
    axisB.value = bipolarMax(axisB.value * scaleFactor, axisB.dead_zone)

proc setMagnitude(xAxis, yAxis: var AnalogAxis; scaleValue: float) =
  scaleAxes(xAxis, yAxis, scaleValue)
  scaleAxes(yAxis, xAxis, scaleValue)

proc initStickTilter*(tiltLevel = 1.0): StickTilter =
  result.tiltTime = cpuTime()
  result.tiltLevel = tiltLevel

proc update*(tilter: var StickTilter;
             xAxis, yAxis: var AnalogAxis;
             allowTilt, resetTilt, holdTilt: bool) =
  let resetTiltConditions = xAxis.justActivated or xAxis.justCrossedCenter or
                            yAxis.justActivated or yAxis.justCrossedCenter or
                            resetTilt

  if allowTilt and resetTiltConditions:
    tilter.tiltTime = cpuTime()
    tilter.isTilting = true

  if tilter.isTilting or (allowTilt and holdTilt):
    setMagnitude(xAxis, yAxis, tilter.tiltLevel)

    if cpuTime() - tilter.tiltTime >= 0.117:
      tilter.isTilting = false

proc initDigitalMeleeController*(): DigitalMeleeController =
  result.tiltModifier = initStickTilter(0.65)
  result.shieldTilter = initStickTilter(0.6625)
  result.xModX = 0.2875
  result.xModY = 0.95
  result.yModX = 0.95
  result.yModY = 0.2875
  result.airDodgeXLevel = 0.9
  result.airDodgeYLevel = -0.4125
  result.useShortHopMacro = true
  result.useCStickTilting = true
  result.backdashTime = cpuTime()
  result.safeDownBTime = cpuTime()
  result.shortHopTime = cpuTime()
  result.fullHopTime = cpuTime()
  result.airDodgeTime = cpuTime()
  result.aAttackTime = cpuTime()

proc updateActions(controller: var DigitalMeleeController) =
  for action in controller.actions.mitems:
    action.update()

proc updateAxesFromDirections(controller: var DigitalMeleeController) =
  controller.state.xAxis.setValueFromStates(controller.actions[Action.Left].isPressed, controller.actions[Action.Right].isPressed)
  controller.state.yAxis.setValueFromStates(controller.actions[Action.Down].isPressed, controller.actions[Action.Up].isPressed)

  let enableCStick = controller.actions[Action.Shield].isPressed or
                     not controller.useCStickTilting or
                     not controller.actions[Action.Tilt].isPressed

  controller.state.cXAxis.setValueFromStates(controller.actions[Action.CLeft].isPressed and enableCStick,
                                             controller.actions[Action.CRight].isPressed and enableCStick)
  controller.state.cYAxis.setValueFromStates((controller.actions[Action.CDown].isPressed and enableCStick),
                                             controller.actions[Action.CUp].isPressed and enableCStick)

proc handleBackdashOutOfCrouchFix(controller: var DigitalMeleeController) =
  if controller.actions[Action.Down].isPressed and
     (controller.actions[Action.Left].justPressed or
      controller.actions[Action.Right].justPressed):
    controller.delayBackdash = true
    controller.backdashTime = cpuTime()

  if controller.actions[Action.Down].justReleased:
    controller.delayBackdash = false

  if controller.delayBackdash:
    if not (controller.actions[Action.FullHop].isPressed or
            controller.actions[Action.ShortHop].isPressed or
            controller.actions[Action.AirDodge].isPressed or
            controller.actions[Action.Shield].isPressed or
            controller.actions[Action.Z].isPressed or
            controller.actions[Action.A].isPressed or
            controller.actions[Action.B].isPressed or
            controller.actions[Action.Tilt].isPressed):
      controller.state.xAxis.value = 0.0

    if cpuTime() - controller.backdashTime >= 0.05:
      controller.delayBackdash = false

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

proc handleCStickTilting(controller: var DigitalMeleeController) =
  controller.state.aButton.isPressed = controller.actions[Action.A].isPressed

  if controller.useCStickTilting and not controller.actions[Action.Shield].isPressed:
    template aAttack(activation, attackState, xValue, yValue: untyped): untyped =
      if activation:
        controller.aAttackTime = cpuTime()
        attackState = true

      if attackState:
        controller.state.aButton.isPressed = true
        controller.state.xAxis.value = xValue
        controller.state.yAxis.value = yValue

      if cpuTime() - controller.aAttackTime >= 0.034:
        attackState = false

    let tilt = controller.actions[Action.Tilt].isPressed

    aAttack(tilt and controller.actions[Action.CLeft].justPressed,
            controller.isLeftTilting,
            -0.6,
            controller.state.yAxis.direction * 0.35)

    aAttack(tilt and controller.actions[Action.CRight].justPressed,
            controller.isRightTilting,
            0.6,
            controller.state.yAxis.direction * 0.35)

    aAttack(tilt and controller.actions[Action.CDown].justPressed,
            controller.isDownTilting,
            controller.state.xAxis.direction * 0.35,
            -0.6)

    aAttack(tilt and controller.actions[Action.CUp].justPressed,
            controller.isUpTilting,
            controller.state.xAxis.direction * 0.35,
            0.6)

    aAttack(controller.actions[Action.A].justPressed,
            controller.isDoingNeutralA,
            0.0,
            0.0)

proc handleSafeDownB(controller: var DigitalMeleeController) =
  if controller.actions[Action.B].justPressed and
     (controller.actions[Action.Down].isPressed or
      controller.actions[Action.Up].isPressed):
    controller.isDoingSafeDownB = true
    controller.safeDownBTime = cpuTime()

  if controller.isDoingSafeDownB:
    if cpuTime() - controller.safeDownBTime < 0.025:
      controller.state.xAxis.value = controller.state.xAxis.direction * 0.5875
      controller.state.yAxis.value = controller.state.yAxis.direction * 0.6

    else:
      controller.isDoingSafeDownB = false

proc handleJumpLogic(controller: var DigitalMeleeController) =
  if controller.useShortHopMacro:
    # Short hop handling.
    let startShortHop = controller.actions[Action.ShortHop].justPressed or
                        (controller.isFullHopping and
                         controller.actions[Action.FullHop].justPressed)

    if startShortHop:
      controller.state.yButton.isPressed = true
      controller.isShortHopping = true
      controller.shortHopTime = cpuTime()

    if controller.isShortHopping and cpuTime() - controller.shortHopTime >= 0.025:
      controller.state.yButton.isPressed = false
      controller.isShortHopping = false

    # Full hop handling.
    let startFullHop = controller.actions[Action.FullHop].justPressed

    if startFullHop:
      controller.state.xButton.isPressed = true
      controller.isFullHopping = true
      controller.fullHopTime = cpuTime()

    if controller.isFullHopping and not controller.actions[Action.FullHop].isPressed:
      if cpuTime() - controller.fullHopTime >= 0.134:
        controller.state.xButton.isPressed = false

      # Wait one extra frame so you can't miss a double jump by
      # pushing the full hop button on the same frame of release.
      if cpuTime() - controller.fullHopTime >= 0.150:
        controller.isFullHopping = false

  else:
    controller.state.xButton.isPressed = controller.actions[Action.FullHop].isPressed
    controller.state.yButton.isPressed = controller.actions[Action.ShortHop].isPressed

proc handleAirDodgeLogic(controller: var DigitalMeleeController) =
  let
    isLeft = controller.state.xAxis.isActive and controller.state.xAxis.value < 0.0
    isRight = controller.state.xAxis.isActive and controller.state.xAxis.value > 0.0
    isDown = controller.state.yAxis.isActive and controller.state.yAxis.value < 0.0
    isUp = controller.state.yAxis.isActive and controller.state.yAxis.value > 0.0
    isSideways = (isLeft or isRight) and not isDown

  if controller.actions[Action.AirDodge].justPressed:
    controller.isAirDodging = true
    controller.airDodgeTime = cpuTime()

  if controller.isAirDodging and not isUp:
    if cpuTime() - controller.airDodgeTime < 0.051:
      if isSideways:
        controller.state.xAxis.value = controller.state.xAxis.direction * controller.airDodgeXLevel
        controller.state.yAxis.value = controller.airDodgeYLevel

      elif not isDown:
        controller.state.yAxis.value = -0.3

    else:
      controller.isAirDodging = false

proc handleTiltModifier(controller: var DigitalMeleeController) =
  controller.tiltModifier.update(controller.state.xAxis,
                                 controller.state.yAxis,
                                 controller.actions[Action.Tilt].isPressed,
                                 false,
                                 controller.actions[Action.Shield].isPressed)

proc handleShieldTilt(controller: var DigitalMeleeController) =
  controller.shieldTilter.update(controller.state.xAxis,
                                 controller.state.yAxis,
                                 controller.actions[Action.Shield].isPressed or
                                 controller.actions[Action.Z].isPressed,
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
  controller.handleBackdashOutOfCrouchFix()
  controller.handleModifierAngles()
  controller.handleCStickTilting()
  controller.handleTiltModifier()
  controller.handleSafeDownB()
  controller.handleShieldTilt()
  controller.handleAirDodgeLogic()
  controller.handleAngledSmashes()
  controller.handleChargedSmashes()
  controller.handleJumpLogic()
  controller.handleShield()

  controller.state.bButton.isPressed = controller.actions[Action.B].isPressed
  controller.state.zButton.isPressed = controller.actions[Action.Z].isPressed
  controller.state.lButton.isPressed = controller.actions[Action.AirDodge].isPressed
  controller.state.startButton.isPressed = controller.actions[Action.Start].isPressed
  controller.state.dLeftButton.isPressed = controller.actions[Action.DLeft].isPressed
  controller.state.dRightButton.isPressed = controller.actions[Action.DRight].isPressed
  controller.state.dDownButton.isPressed = controller.actions[Action.DDown].isPressed
  controller.state.dUpButton.isPressed = controller.actions[Action.DUp].isPressed

  controller.state.update()
  controller.updateActions()