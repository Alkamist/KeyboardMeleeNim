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

  DigitalMeleeController* = object
    useShortHopMacro*: bool
    useCStickTilting*: bool
    useShieldTilt*: bool
    useWavelandHelper*: bool
    actions*: array[Action, Button]
    state*: GCCState
    isLightShielding: bool
    isDoingSafeDownB: bool
    delayBackdash: bool
    isShortHopping: bool
    isFullHopping: bool
    isAirDodging: bool
    isUpTilting: bool
    isDownTilting: bool
    isLeftTilting: bool
    isRightTilting: bool
    isDoingNeutralA: bool
    backdashTime: float
    safeDownBTime: float
    shortHopTime: float
    fullHopTime: float
    airDodgeTime: float
    aAttackTime: float

proc initDigitalMeleeController*(): DigitalMeleeController =
  result.state = initGCCState()
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

  let
    tilt = controller.actions[Action.XMod].isPressed or
           controller.actions[Action.YMod].isPressed
    enableCStick = controller.actions[Action.Shield].isPressed or
                   not controller.useCStickTilting or
                   not tilt

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
            controller.actions[Action.B].isPressed):
      controller.state.xAxis.value = 0.0

    if cpuTime() - controller.backdashTime >= 0.05:
      controller.delayBackdash = false

proc handleModifierAngles(controller: var DigitalMeleeController) =
  let diagonal = (controller.actions[Action.Left].isPressed or
                  controller.actions[Action.Right].isPressed) and
                 (controller.actions[Action.Down].isPressed or
                  controller.actions[Action.Up].isPressed)

  if controller.actions[Action.XMod].isPressed:
    let
      x = if diagonal: 0.7375 else: 0.6625
      y = if diagonal: 0.3125 else: 0.5375

    controller.state.xAxis.value = controller.state.xAxis.direction * x
    controller.state.yAxis.value = controller.state.yAxis.direction * y

  elif controller.actions[Action.YMod].isPressed:
    let
      x = if diagonal: 0.3125 else: 0.3325
      y = 0.7375

    controller.state.xAxis.value = controller.state.xAxis.direction * x
    controller.state.yAxis.value = controller.state.yAxis.direction * y

proc handleShieldTilt(controller: var DigitalMeleeController) =
  let
    shoulder = controller.actions[Action.Shield].isPressed or
               controller.actions[Action.AirDodge].isPressed
    down = controller.actions[Action.Down].isPressed
    xMod = controller.actions[Action.XMod].isPressed
    yMod = controller.actions[Action.YMod].isPressed
    diagonal = (controller.actions[Action.Left].isPressed or
                controller.actions[Action.Right].isPressed) and
               (down or controller.actions[Action.Up].isPressed)

  if shoulder:
    if diagonal and xMod:
      controller.state.xAxis.value = controller.state.xAxis.direction * 0.6375
      controller.state.yAxis.value = controller.state.yAxis.direction * 0.375

    elif diagonal and yMod and down:
      controller.state.xAxis.value = controller.state.xAxis.direction * 0.5
      controller.state.yAxis.value = controller.state.yAxis.direction * 0.85

    elif diagonal and ((not controller.useShieldTilt) or controller.actions[Action.AirDodge].isPressed):
      controller.state.xAxis.value = controller.state.xAxis.direction * 0.7
      controller.state.yAxis.value = controller.state.yAxis.direction * 0.6875

  if controller.useShieldTilt and controller.actions[Action.Shield].isPressed:
    setMagnitude(controller.state.xAxis, controller.state.yAxis, 0.6625)

proc handleCStickTilting(controller: var DigitalMeleeController) =
  controller.state.aButton.isPressed = controller.actions[Action.A].isPressed

  if controller.useCStickTilting:
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

    if not controller.actions[Action.Shield].isPressed:
      let tilt = controller.actions[Action.XMod].isPressed or
                 controller.actions[Action.YMod].isPressed

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

proc handleWavelandHelper(controller: var DigitalMeleeController) =
  if controller.useWavelandHelper:
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
          controller.state.xAxis.value = controller.state.xAxis.direction * 0.6375
          controller.state.yAxis.value = -0.375

        elif not isDown:
          controller.state.yAxis.value = -0.3

      else:
        controller.isAirDodging = false

proc handleAngledSmashes(controller: var DigitalMeleeController) =
  let
    tilt = controller.actions[Action.XMod].isPressed or
           controller.actions[Action.YMod].isPressed
    cAngled = (controller.actions[Action.CLeft].isPressed or
               controller.actions[Action.CRight].isPressed) and
              (controller.actions[Action.Down].isPressed or
               controller.actions[Action.Up].isPressed)

  if cAngled and not tilt:
    controller.state.cYAxis.value = controller.state.yAxis.direction * 0.4

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
  controller.handleShieldTilt()
  controller.handleCStickTilting()
  controller.handleSafeDownB()
  controller.handleWavelandHelper()
  controller.handleAngledSmashes()
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