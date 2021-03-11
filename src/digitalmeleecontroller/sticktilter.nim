import times
import analogaxis

type
  StickTilter* = object
    isTilting: bool
    tiltLevel: float
    tiltTime: float

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