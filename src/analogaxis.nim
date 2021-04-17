import std/math

type
  AnalogAxis* = object
    value*: float
    previousValue*: float
    deadZone*: float
    wasActive*: bool
    highStateWasFirst*: bool

proc initAnalogAxis*(): AnalogAxis =
  result.deadZone = 0.2875
  result.highStateWasFirst = true

proc direction*(axis: AnalogAxis): float =
  axis.value.sgn.float

proc justCrossedCenter*(axis: AnalogAxis): bool =
  (axis.value < 0.0 and axis.previousValue >= 0.0) or
  (axis.value > 0.0 and axis.previousValue <= 0.0)

proc isActive*(axis: AnalogAxis): bool =
  axis.value.abs >= axis.deadZone

proc justActivated*(axis: AnalogAxis): bool =
  axis.justCrossedCenter or axis.isActive and not axis.wasActive

proc justDeactivated*(axis: AnalogAxis): bool =
  axis.wasActive and not axis.isActive

proc justChanged*(axis: AnalogAxis): bool =
  axis.value != axis.previousValue

proc setValueFromStates*(axis: var AnalogAxis; lowState, highState: bool) =
  let
    lowAndHigh = lowState and highState
    onlyHigh = highState and not lowState
    onlyLow = lowState and not highState

  if onlyHigh:
    axis.highStateWasFirst = true
  elif onlyLow:
    axis.highStateWasFirst = false

  if onlyLow or (lowAndHigh and axis.highStateWasFirst):
    axis.value = -1.0
  elif onlyHigh or (lowAndHigh and not axis.highStateWasFirst):
    axis.value = 1.0
  else:
    axis.value = 0.0

proc update*(axis: var AnalogAxis) =
  axis.previousValue = axis.value
  axis.wasActive = axis.isActive

proc setAngle*(xAxis, yAxis: var AnalogAxis; angle: float) =
  xAxis.value = angle.cos
  yAxis.value = angle.sin

proc bipolarMax(value, magnitude: float): float =
  if value > 0.0: value.max(magnitude)
  elif value < 0.0: value.min(-magnitude)
  else: 0.0

proc scaleAxes(axisA, axisB: var AnalogAxis; scaleValue: float) =
  let axisAMagnitude = axisA.value.abs
  if axisAMagnitude > scaleValue:
    let scaleFactor = scaleValue / axisAMagnitude
    axisA.value = axisA.direction * scaleValue
    axisB.value = bipolarMax(axisB.value * scaleFactor, axisB.deadZone)

proc setMagnitude*(xAxis, yAxis: var AnalogAxis; scaleValue: float) =
  scaleAxes(xAxis, yAxis, scaleValue)
  scaleAxes(yAxis, xAxis, scaleValue)