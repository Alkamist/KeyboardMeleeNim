import times
import delayedbutton
import analogaxis

type
  AStick* = object
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

proc initAStick*(): AStick =
  result.neutralButton = initDelayedButton(0.0, 0.034)
  result.leftButton = initDelayedButton(0.0, 0.05)
  result.rightButton = initDelayedButton(0.0, 0.05)
  result.downButton = initDelayedButton(0.0, 0.034)
  result.upButton = initDelayedButton(0.0, 0.034)
  result.activationTime = cpuTime()

proc update*(stick: var AStick;
             xAxis, yAxis: AnalogAxis;
             neutral, left, right, down, up: bool) =
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

    let
      turnAroundLeftTilt = stick.leftButton.justPressed and xAxis.value > 0.0
      turnAroundRightTilt = stick.rightButton.justPressed and xAxis.value < 0.0

    if turnAroundLeftTilt or turnAroundRightTilt:
      stick.activationTime = cpuTime()
      stick.outputButton.delay = 0.034
      stick.axisHoldDuration = 0.067

    elif stick.leftButton.justPressed or stick.rightButton.justPressed:
      stick.activationTime = cpuTime()
      stick.outputButton.delay = 0.017
      stick.axisHoldDuration = 0.067

    if stick.downButton.justPressed or stick.upButton.justPressed:
      stick.activationTime = cpuTime()
      stick.outputButton.delay = 0.0
      stick.axisHoldDuration = 0.067

    if stick.neutralButton.justPressed:
      stick.activationTime = cpuTime()
      stick.outputButton.delay = 0.0
      stick.axisHoldDuration = 0.025

    stick.outputButton.setState(stick.neutralButton.isPressed or
                                stick.leftButton.isPressed or
                                stick.rightButton.isPressed or
                                stick.downButton.isPressed or
                                stick.upButton.isPressed)

    stick.outputXAxis.setValueFromStates(stick.leftButton.isPressed,
                                         stick.rightButton.isPressed)

    stick.outputYAxis.setValueFromStates(stick.downButton.isPressed,
                                         stick.upButton.isPressed)

    if cpuTime() - stick.activationTime <= stick.axisHoldDuration:
      let shouldBiasX = not (stick.leftButton.isPressed or
                             stick.rightButton.isPressed or
                             stick.neutralButton.isPressed)
      var xBias = 0.0
      if shouldBiasX:
        xBias = 0.35 * xAxis.direction

      stick.xAxisOutput = stick.outputXAxis.value * 0.6 + xBias

      let shouldBiasY = yAxis.isActive and not
                        (stick.downButton.isPressed or
                         stick.upButton.isPressed or
                         stick.neutralButton.isPressed)
      var yBias = 0.0
      if shouldBiasY:
          yBias = 0.5 * yAxis.direction

      stick.yAxisOutput = stick.outputYAxis.value * 0.6 + yBias;

    stick.outputState = stick.outputButton.isPressed