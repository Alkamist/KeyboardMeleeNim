import std/times
import delayedbutton
import analogaxis


type
  BStick* = object
    outputState*: bool
    xAxisOutput*: float
    yAxisOutput*: float
    outputXAxis: AnalogAxis
    outputYAxis: AnalogAxis
    outputButton: DelayedButton
    neutralButton: DelayedButton
    leftButton: DelayedButton
    rightButton: DelayedButton
    downButton: DelayedButton
    upButton: DelayedButton
    axisHoldDuration: float
    activationTime: float

proc initBStick*(): BStick =
  result.neutralButton = initDelayedButton(0.0, 0.034)
  result.leftButton = initDelayedButton(0.0, 0.034)
  result.rightButton = initDelayedButton(0.0, 0.034)
  result.downButton = initDelayedButton(0.0, 0.034)
  result.upButton = initDelayedButton(0.0, 0.050)
  result.activationTime = cpuTime()

proc update*(stick: var BStick;
             xAxis, yAxis: AnalogAxis;
             neutral, left, right, down, up, shield: bool) =
  stick.xAxisOutput = xAxis.value
  stick.yAxisOutput = yAxis.value

  stick.outputButton.update()
  stick.neutralButton.update()
  stick.leftButton.update()
  stick.rightButton.update()
  stick.downButton.update()
  stick.upButton.update()

  stick.neutralButton.setState(neutral)
  stick.leftButton.setState(left)
  stick.rightButton.setState(right)
  stick.downButton.setState(down)
  stick.upButton.setState(up)

  if stick.upButton.justPressed:
    stick.activationTime = cpuTime()

    if yAxis.value <= 0.6 or shield:
      stick.outputButton.delay = 0.017

    else:
      stick.outputButton.delay = 0.0

    stick.axisHoldDuration = 0.05

  if stick.downButton.justPressed or
     stick.leftButton.justPressed or
     stick.rightButton.justPressed:
    stick.activationTime = cpuTime()
    stick.outputButton.delay = 0.0
    stick.axisHoldDuration = 0.05

  if stick.neutralButton.justPressed:
    stick.activationTime = cpuTime()
    stick.outputButton.delay = 0.0
    stick.axisHoldDuration = 0.025

  stick.outputButton.setState(stick.neutralButton.isPressed or
                              stick.leftButton.isPressed or
                              stick.rightButton.isPressed or
                              stick.downButton.isPressed or
                              stick.upButton.isPressed)

  stick.outputXAxis.setValueFromStates(stick.leftButton.isPressed, stick.rightButton.isPressed)
  stick.outputYAxis.setValueFromStates(stick.downButton.isPressed, stick.upButton.isPressed)

  if cpuTime() - stick.activationTime <= stick.axisHoldDuration:
    let shouldBiasX = stick.downButton.isPressed or stick.upButton.isPressed or
                      (xAxis.isActive and stick.neutralButton.isPressed)
    var xBias = 0.0
    if shouldBiasX:
      xBias = 0.5 * xAxis.direction

    stick.xAxisOutput = stick.outputXAxis.value * 0.6 + xBias

    if stick.outputYAxis.value < 0.0:
      stick.yAxisOutput = stick.outputYAxis.value * 0.6

    else:
      stick.yAxisOutput = stick.outputYAxis.value

  stick.outputState = stick.outputButton.isPressed