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
    SoftLeft,
    SoftRight,
    Mod1,
    Mod2,
    CLeft,
    CRight,
    CDown,
    CUp,
    ShortHop,
    FullHop,
    A,
    B,
    UpB,
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
    InvertYAxis

  DigitalMeleeController* = object
    useShortHopMacro*: bool
    useCStickTilting*: bool
    useShieldTilt*: bool
    useWavelandHelper*: bool
    actions*: array[Action, Button]
    state*: GCCState
    chargeSmash: bool
    isLightShielding: bool
    isDoingSafeDownB: bool
    delayBackdash: bool
    pressUpB: bool
    delayUpB: bool
    isShortHopping: bool
    isFullHopping: bool
    isAirDodging: bool
    isUpTilting: bool
    isDownTilting: bool
    isLeftTilting: bool
    isRightTilting: bool
    isDoingNeutralA: bool
    isDoingSoftDirection: bool
    isDoingSoftUp: bool
    isDoingSoftDown: bool
    backdashTime: float
    safeDownBTime: float
    shortHopTime: float
    fullHopTime: float
    airDodgeTime: float
    aAttackTime: float
    upBTime: float
    delayUpBTime: float
    softDirectionTime: float
    softUpTime: float
    softDownTime: float
    pushDownTime: float

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
  controller.state.xAxis.setValueFromStates(controller.actions[Action.Left].isPressed or
                                            controller.actions[Action.SoftLeft].isPressed,
                                            controller.actions[Action.Right].isPressed or
                                            controller.actions[Action.SoftRight].isPressed)
  controller.state.yAxis.setValueFromStates(controller.actions[Action.Down].isPressed,
                                            controller.actions[Action.Up].isPressed)

  let
    tilt = controller.actions[Action.Mod1].isPressed or
           controller.actions[Action.Mod2].isPressed
    enableCStick = controller.actions[Action.Shield].isPressed or
                   not controller.useCStickTilting or
                   not tilt

  controller.state.cXAxis.setValueFromStates(controller.actions[Action.CLeft].isPressed and enableCStick,
                                             controller.actions[Action.CRight].isPressed and enableCStick)
  controller.state.cYAxis.setValueFromStates((controller.actions[Action.CDown].isPressed and enableCStick),
                                             controller.actions[Action.CUp].isPressed and enableCStick)

proc handleSoftDirections(controller: var DigitalMeleeController) =
  let
    hardPress = controller.actions[Action.Left].isPressed or
                controller.actions[Action.Right].isPressed
    softPress = controller.actions[Action.SoftLeft].justPressed or
                controller.actions[Action.SoftRight].justPressed
    softHeld = controller.actions[Action.SoftLeft].isPressed or
               controller.actions[Action.SoftRight].isPressed
    directionRelease = controller.actions[Action.SoftLeft].justReleased or
                       controller.actions[Action.SoftRight].justReleased or
                       controller.actions[Action.Left].justReleased or
                       controller.actions[Action.Right].justReleased

  # Soft left and right:

  if softPress or softHeld and directionRelease:
    controller.isDoingSoftDirection = true
    controller.softDirectionTime = cpuTime()

  if softHeld and
     (controller.actions[Action.Up].isPressed or
      controller.actions[Action.Down].isPressed):
    controller.state.xAxis.value = controller.state.xAxis.direction * 0.4125
    controller.state.yAxis.value = controller.state.yAxis.direction * 0.65

  elif controller.isDoingSoftDirection:
    controller.state.xAxis.value = controller.state.xAxis.direction * 0.65

    if cpuTime() - controller.softDirectionTime > 0.034:
      controller.isDoingSoftDirection = false

  # Soft up:

  if controller.actions[Action.Up].justPressed and
     not controller.actions[Action.AirDodge].isPressed:
    controller.isDoingSoftUp = true
    controller.softUpTime = cpuTime()

  if controller.isDoingSoftUp:
    if controller.state.yAxis.value > 0.0:
      controller.state.yAxis.value = controller.state.yAxis.direction * 0.65

      #if softHeld:
      #  controller.state.xAxis.value = controller.state.xAxis.direction * 0.4125

      if hardPress:
        controller.state.xAxis.value = controller.state.xAxis.direction * 0.65

    if cpuTime() - controller.softUpTime > 0.051:
      controller.isDoingSoftUp = false

  # Soft down:

  if controller.actions[Action.Down].justPressed:
    controller.pushDownTime = cpuTime()

  if cpuTime() - controller.pushDownTime <= 0.051 and
     controller.actions[Action.A].justPressed:
    controller.softDownTime = cpuTime()
    controller.isDoingSoftDown = true

  if controller.isDoingSoftDown:
    if controller.state.yAxis.value < 0.0:
      controller.state.yAxis.value = controller.state.yAxis.direction * 0.65

      #if softHeld:
      #  controller.state.xAxis.value = controller.state.xAxis.direction * 0.4125

    if cpuTime() - controller.softDownTime > 0.051:
      controller.isDoingSoftDown = false

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

    if cpuTime() - controller.backdashTime >= 0.017:
      controller.delayBackdash = false

proc handleModifierAngles(controller: var DigitalMeleeController) =
  template stickMod(x, y: float): untyped =
    controller.state.xAxis.value = controller.state.xAxis.direction * x
    controller.state.yAxis.value = controller.state.yAxis.direction * y

  let
    down = controller.actions[Action.Down].isPressed
    b = controller.actions[Action.B].isPressed or
        controller.actions[Action.UpB].isPressed
    diagonal = (controller.actions[Action.Left].isPressed or
                controller.actions[Action.Right].isPressed) and
               (down or
                controller.actions[Action.Up].isPressed)

  if controller.actions[Action.Mod1].isPressed:
    if diagonal:
      if b: stickMod(0.9125, 0.3875)
      else: stickMod(0.7375, 0.3125)

    else:
      if not b: stickMod(0.6625, 0.5375)

  if controller.actions[Action.Mod2].isPressed:
    if diagonal:
      if b: stickMod(0.3875, 0.9125)
      else: stickMod(0.3125, 0.7375)

    else:
      if not b: stickMod(0.3375, 0.7375)

proc handleShieldTilt(controller: var DigitalMeleeController) =
  template stickMod(x, y: float): untyped =
    controller.state.xAxis.value = controller.state.xAxis.direction * x
    controller.state.yAxis.value = controller.state.yAxis.direction * y

  let
    shield = controller.actions[Action.Shield].isPressed
    airDodge = controller.actions[Action.AirDodge].isPressed
    down = controller.actions[Action.Down].isPressed
    mod1 = controller.actions[Action.Mod1].isPressed
    mod2 = controller.actions[Action.Mod2].isPressed
    diagonal = (controller.actions[Action.Left].isPressed or
                controller.actions[Action.Right].isPressed) and
               (down or controller.actions[Action.Up].isPressed)

  if airDodge:
    if diagonal:
      if mod1: stickMod(0.5, 0.85)
      elif mod2: stickMod(0.6375, 0.375)
      elif down: stickMod(0.7, 0.6875)

  elif shield:
    if controller.useShieldTilt:
      setMagnitude(controller.state.xAxis, controller.state.yAxis, 0.6625)

    else:
      if diagonal:
        if mod1 or mod2: stickMod(0.6625, 0.6625)
        elif down: stickMod(0.7, 0.6875)

      else:
        if mod1 and down: stickMod(1.0, 0.6625)

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
      let tilt = controller.actions[Action.Mod1].isPressed or
                 controller.actions[Action.Mod2].isPressed

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
          if controller.actions[Action.SoftLeft].isPressed or
             controller.actions[Action.SoftRight].isPressed:
            controller.state.xAxis.value = controller.state.xAxis.direction * 0.5
            controller.state.yAxis.value = -0.85
          else:
            controller.state.xAxis.value = controller.state.xAxis.direction * 0.6375
            controller.state.yAxis.value = -0.375

        elif not isDown:
          controller.state.yAxis.value = -1.0

      else:
        controller.isAirDodging = false

proc handleAngledSmashes(controller: var DigitalMeleeController) =
  let
    tilt = controller.actions[Action.Mod1].isPressed or
           controller.actions[Action.Mod2].isPressed
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

proc handleB(controller: var DigitalMeleeController) =
  controller.state.bButton.isPressed = controller.actions[Action.B].isPressed

  if controller.actions[Action.UpB].justPressed:
    controller.delayUpB = true
    controller.delayUpBTime = cpuTime()

  if controller.delayUpB:
    controller.state.yAxis.value = 1.0

    if cpuTime() - controller.delayUpBTime > 0.017:
      controller.delayUpB = false
      controller.pressUpB = true
      controller.upBTime = cpuTime()

  if controller.pressUpB:
    controller.state.yAxis.value = 1.0
    controller.state.bButton.isPressed = true

    if cpuTime() - controller.upBTime > 0.017:
      controller.pressUpB = false

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

proc handleYAxisInversion(controller: var DigitalMeleeController) =
  if controller.actions[Action.InvertYAxis].isPressed:
    controller.state.yAxis.value = -controller.state.yAxis.value

proc setActionState*(controller: var DigitalMeleeController, action: Action, state: bool) =
  controller.actions[action].isPressed = state

proc update*(controller: var DigitalMeleeController) =
  controller.updateAxesFromDirections()
  controller.handleBackdashOutOfCrouchFix()
  controller.handleSoftDirections()
  controller.handleModifierAngles()
  controller.handleShieldTilt()
  controller.handleCStickTilting()
  controller.handleSafeDownB()
  controller.handleWavelandHelper()
  controller.handleAngledSmashes()
  controller.handleJumpLogic()
  controller.handleShield()
  controller.handleB()
  controller.handleChargedSmashes()
  controller.handleYAxisInversion()

  controller.state.zButton.isPressed = controller.actions[Action.Z].isPressed
  controller.state.lButton.isPressed = controller.actions[Action.AirDodge].isPressed
  controller.state.startButton.isPressed = controller.actions[Action.Start].isPressed
  controller.state.dLeftButton.isPressed = controller.actions[Action.DLeft].isPressed
  controller.state.dRightButton.isPressed = controller.actions[Action.DRight].isPressed
  controller.state.dDownButton.isPressed = controller.actions[Action.DDown].isPressed
  controller.state.dUpButton.isPressed = controller.actions[Action.DUp].isPressed

  controller.state.update()
  controller.updateActions()