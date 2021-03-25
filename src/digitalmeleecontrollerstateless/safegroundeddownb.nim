import std/times
import ../button
import ../analogaxis


type
  SafeGroundedDownB* = object
    xAxisOutput*: float
    yAxisOutput*: float
    bInput: Button
    isDoingSafeB: bool
    safeBTime: float
    safeBDuration: float

proc initSafeGroundedDownB*(): SafeGroundedDownB =
  result.safeBTime = cpuTime()
  result.safeBDuration = 0.025

proc update*(safeDownB: var SafeGroundedDownB;
             xAxis, yAxis: AnalogAxis;
             b, down, up: bool) =
  safeDownB.xAxisOutput = xAxis.value
  safeDownB.yAxisOutput = yAxis.value

  safeDownB.bInput.update()
  safeDownB.bInput.isPressed = b

  if safeDownB.bInput.justPressed and (down or up):
    safeDownB.isDoingSafeB = true
    safeDownB.safeBTime = cpuTime()

  if safeDownB.isDoingSafeB:
    if cpuTime() - safeDownB.safeBTime < safeDownB.safeBDuration:
      safeDownB.xAxisOutput = xAxis.direction * 0.5875
      safeDownB.yAxisOutput = yAxis.direction * 0.6

    else:
      safeDownB.isDoingSafeB = false