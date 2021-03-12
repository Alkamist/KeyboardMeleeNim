import times
import button
import analogaxis


type
  BackdashOutOfCrouchFix* = object
    xAxisOutput*: float
    downInput: Button
    leftInput: Button
    rightInput: Button
    delayBackdash: bool
    backdashTime: float
    backdashFixDuration: float

proc initBackdashOutOfCrouchFix*(): BackdashOutOfCrouchFix =
  result.backdashTime = cpuTime()
  result.backdashFixDuration = 0.05

proc update*(fix: var BackdashOutOfCrouchFix;
             xAxis: AnalogAxis;
             left, right, down: bool) =
  fix.xAxisOutput = xAxis.value

  fix.downInput.update()
  fix.leftInput.update()
  fix.rightInput.update()

  fix.downInput.isPressed = down
  fix.leftInput.isPressed = left
  fix.rightInput.isPressed = right

  if fix.downInput.isPressed and (fix.leftInput.justPressed or
                                  fix.rightInput.justPressed):
    fix.delayBackdash = true
    fix.backdashTime = cpuTime()

  if fix.downInput.justReleased:
    fix.delayBackdash = false

  if fix.delayBackdash:
    fix.xAxisOutput = 0.0

    if cpuTime() - fix.backdashTime >= fix.backdashFixDuration:
      fix.delayBackdash = false