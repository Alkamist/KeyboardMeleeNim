import
  std/json,
  std/tables,
  std/strutils,
  std/os,
  kbdinput,
  vjoy,
  digitalmeleecontroller,
  dolphincontroller

# Force the console window to stay open on exceptions to give the user error feedback.
globalRaiseHook = proc (e: ref Exception): bool =
  echo "Error: " & e.msg
  while true:
    sleep(1)

proc parseKeyBindsJson(inputBinds: JsonNode): Table[Action, seq[Key]] =
  for action, bindList in inputBinds.pairs:
    var parsedBindList: seq[Key]
    for keyBind in bindList.items:
      parsedBindList.add(parseEnum[Key](keyBind.getStr))
    result[parseEnum[Action](action)] = parsedBindList

proc parseVJoyButtonBindsJson(inputBinds: JsonNode): Table[GCCButton, clong] =
  for button, bindId in inputBinds.pairs:
    result[parseEnum[GCCButton](button)] = bindId.getInt.clong

proc parseVJoyAxisBindsJson(inputBinds: JsonNode): Table[GCCAxis, VJoyAxis] =
  for axis, bindId in inputBinds.pairs:
    result[parseEnum[GCCAxis](axis)] = parseEnum[VJoyAxis](bindId.getStr)

proc parseVJoySliderBindsJson(inputBinds: JsonNode): Table[GCCSlider, VJoyAxis] =
  for slider, bindId in inputBinds.pairs:
    result[parseEnum[GCCSlider](slider)] = parseEnum[VJoyAxis](bindId.getStr)

template insertIfMissing(node: var JsonNode, key: string, value: untyped): untyped =
  if not node.hasKey(key):
    node{key} = %* value

let configExistedBeforeLaunch = fileExists("config.json")
var configJson = parseJson("{}")

if configExistedBeforeLaunch:
  configJson = parseJson(readFile("config.json"))

configJson.insertIfMissing("useVJoy", false)
configJson.insertIfMissing("vJoyDeviceId", 1)
configJson.insertIfMissing("vJoyDllPath", "C:\\Program Files\\vJoy\\x64\\vJoyInterface.dll")
configJson.insertIfMissing("useShortHopMacro", true)
configJson.insertIfMissing("useShieldTilt", true)
configJson.insertIfMissing("useWavelandHelper", true)
configJson.insertIfMissing("onOffToggleKey", Key.Key8)
configJson.insertIfMissing("keyBinds", {
  $Action.Left: [Key.A],
  $Action.Right: [Key.D],
  $Action.Down: [Key.S],
  $Action.Up: [Key.W],
  $Action.SoftLeft: [Key.Q],
  $Action.SoftRight: [Key.E],
  $Action.CLeft: [Key.L],
  $Action.CRight: [Key.P],
  $Action.CDown: [Key.RightBracket],
  $Action.CUp: [Key.Apostrophe],
  $Action.Mod1: [Key.Space],
  $Action.Mod2: [Key.LeftAlt],
  $Action.Start: [Key.Key5],
  $Action.A: [Key.RightWindows],
  $Action.B: [Key.RightAlt],
  $Action.UpB: [Key.Minus],
  $Action.Z: [Key.Backspace],
  $Action.ShortHop: [Key.LeftBracket, Key.Equals],
  $Action.FullHop: [Key.BackSlash],
  $Action.Shield: [Key.CapsLock],
  $Action.AirDodge: [Key.Semicolon],
  $Action.DLeft: [Key.V],
  $Action.DRight: [Key.N],
  $Action.DDown: [Key.B],
  $Action.DUp: [Key.G],
  $Action.ToggleLightShield: [Key.LeftAlt],
  $Action.ChargeSmash: [Key.Space],
  $Action.WankDI: [Key.Enter],
})
configJson.insertIfMissing("vJoyButtonBinds", {
  $GCCButton.A: 1,
  $GCCButton.B: 2,
  $GCCButton.X: 3,
  $GCCButton.Y: 4,
  $GCCButton.Z: 5,
  $GCCButton.L: 6,
  $GCCButton.R: 7,
  $GCCButton.Start: 8,
  $GCCButton.DLeft: 9,
  $GCCButton.DRight: 11,
  $GCCButton.DDown: 12,
  $GCCButton.DUp: 10,
})
configJson.insertIfMissing("vJoyAxisBinds", {
  $GCCAxis.X: $VJoyAxis.X,
  $GCCAxis.Y: $VJoyAxis.Y,
  $GCCAxis.CX: $VJoyAxis.XRotation,
  $GCCAxis.CY: $VJoyAxis.YRotation,
})
configJson.insertIfMissing("vJoySliderBinds", {
  $GCCSlider.L: $VJoyAxis.Slider0,
})

writeFile("config.json", pretty(configJson))
if configExistedBeforeLaunch:
  echo "Using existing config.json."
else:
  echo "Created config.json."

let
  onOffToggleKey = parseEnum[Key](configJson["onOffToggleKey"].getStr)
  keyBinds = parseKeyBindsJson(configJson["keyBinds"])
  useVJoy = configJson["useVJoy"].getBool
  vJoyButtonBinds = parseVJoyButtonBindsJson(configJson["vJoyButtonBinds"])
  vJoyAxisBinds = parseVJoyAxisBindsJson(configJson["vJoyAxisBinds"])
  vJoySliderBinds = parseVJoySliderBindsJson(configJson["vJoySliderBinds"])

var
  isEnabled = true
  onOffToggle = false
  onOffTogglePrevious = false
  vJoyDevice: VJoyDevice
  controller = initDigitalMeleeController()
  dolphinCtrl: DolphinController

if useVJoy:
  startVJoy(configJson["vJoyDllPath"].getStr)
  vJoyDevice = initVJoyDevice(configJson["vJoyDeviceId"].getInt.cuint)
else:
  dolphinCtrl = initDolphinController(1, "")

controller.useShortHopMacro = configJson["useShortHopMacro"].getBool
controller.useShieldTilt = configJson["useShieldTilt"].getBool
controller.useWavelandHelper = configJson["useWavelandHelper"].getBool

initKeyboardHook()
setAllKeysBlocked(true)

while true:
  pollKeyboard()

  onOffToggle = keyIsPressed(onOffToggleKey)
  if onOffToggle and not onOffTogglePrevious:
    isEnabled = not isEnabled
    setAllKeysBlocked(isEnabled)
    if isEnabled: echo "Keyboard Melee enabled."
    else: echo "Keyboard Melee disabled."

  if isEnabled:
    for action, keyBindList in keyBinds.pairs:
      var bindState = false
      for keyBind in keyBindList:
        bindState = bindState or keyIsPressed(keyBind)
      controller.setActionState(action, bindState)

    controller.update()

    if useVJoy:
      for button, bindId in vJoyButtonBinds.pairs:
        vJoyDevice.setButton(bindId, controller.state[button].isPressed)

      for axis, bindId in vJoyAxisBinds.pairs:
        vJoyDevice.setAxis(bindId, controller.state[axis].value)

      for slider, bindId in vJoySliderBinds.pairs:
        vJoyDevice.setAxis(bindId, controller.state[slider].value)

      vJoyDevice.sendInputs()

    else:
      for button in GCCButton:
        dolphinCtrl.setButton(button, controller.state[button].isPressed)

      for axis in GCCAxis:
        dolphinCtrl.setAxis(axis, controller.state[axis].value)

      for slider in GCCSlider:
        dolphinCtrl.setSlider(slider, controller.state[slider].value)

      dolphinCtrl.writeControllerState()

  onOffTogglePrevious = onOffToggle

  sleep(1)

if useVJoy:
  shutDownVJoy()