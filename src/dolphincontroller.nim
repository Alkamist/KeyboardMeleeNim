import
  std/os,
  systempipe,
  gccstate

proc getDolphinPipePath(portNumber: int, dolphinDirectory: string): string =
  if defined(windows):
    result = "\\\\.\\pipe\\"

  elif defined(linux):
    if dirExists(dolphinDirectory & "/User/"):
      result = dolphinDirectory & "/User/Pipes/"
    else:
      result = getHomeDir() & "/.config/SlippiOnline/Pipes"

  elif defined(macosx):
    result = dolphinDirectory & "/Contents/Resources/User/Pipes/"

  result &= "slippibot" & $portNumber

type
  DolphinController* = object
    state: GCCState
    pipe: SystemPipe

proc initDolphinController*(portNumber: int, dolphinDirectory: string): DolphinController =
  result.pipe = initSystemPipe(getDolphinPipePath(portNumber, dolphinDirectory))

proc setButton*(controller: var DolphinController, button: GCCButton, state: bool) =
  controller.state[button].isPressed = state

proc setAxis*(controller: var DolphinController, axis: GCCAxis, value: float) =
  controller.state[axis].value = 0.5 * (0.626 * value + 1.0 + 1.0 / 255.0)

proc setSlider*(controller: var DolphinController, slider: GCCSlider, value: float) =
  controller.state[slider].value = (value * 1.94).min(1.0)

proc writeControllerState*(controller: var DolphinController) =
  var outputStr = "\n"

  for buttonKind in GCCButton:
    let button = controller.state[buttonKind]
    if button.justChanged:
      let name = case buttonKind:
        of GCCButton.A: "A"
        of GCCButton.B: "B"
        of GCCButton.X: "X"
        of GCCButton.Y: "Y"
        of GCCButton.Z: "Z"
        of GCCButton.L: "L"
        of GCCButton.R: "R"
        of GCCButton.Start: "START"
        of GCCButton.DLeft: "D_LEFT"
        of GCCButton.DRight: "D_RIGHT"
        of GCCButton.DDown: "D_DOWN"
        of GCCButton.DUp: "D_UP"

      if button.isPressed:
        outputStr.add("PRESS " & name & "\n")
      else:
        outputStr.add("RELEASE " & name & "\n")

  let
    xAxis = controller.state[GCCAxis.X]
    yAxis = controller.state[GCCAxis.Y]
    cXAxis = controller.state[GCCAxis.CX]
    cYAxis = controller.state[GCCAxis.CY]

  if xAxis.justChanged or yAxis.justChanged:
    outputStr.add("SET MAIN " & $xAxis.value & " " & $yAxis.value & "\n")

  if cXAxis.justChanged or cYAxis.justChanged:
    outputStr.add("SET C " & $cXAxis.value & " " & $cYAxis.value & "\n")

  let
    lSlider = controller.state[GCCSlider.L]
    rSlider = controller.state[GCCSlider.R]

  if lSlider.justChanged:
    outputStr.add("SET L " & $lSlider.value & "\n")

  if rSlider.justChanged:
    outputStr.add("SET R " & $rSlider.value & "\n")

  if outputStr != "\n":
    outputStr.add("FLUSH\n")
    controller.pipe.write(outputStr)

  controller.state.update()

when isMainModule:
  import times

  var
    controller = initDolphinController(1, dolphinDirectory="")
    buttonChangeTime = cpuTime()
    buttonState = true

  while true:
    if cpuTime() - buttonChangeTime > 0.5:
      controller.setButton(GCCButton.A, buttonState)
      controller.writeControllerState()
      buttonState = not buttonState
      buttonChangeTime = cpuTime()