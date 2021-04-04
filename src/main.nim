import json
import tables
import strutils
import asyncdispatch
from os import fileExists
import kbdinput
import vjoy
import digitalmeleecontroller/digitalmeleecontroller
import dolphincontroller


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

var configJson = parseJson("{}")

if fileExists("config.json"):
  configJson = parseJson(readFile("config.json"))

configJson.insertIfMissing("useVJoy", false)
configJson.insertIfMissing("vJoyDeviceId", 1)
configJson.insertIfMissing("vJoyDllPath", "C:\\Program Files\\vJoy\\x64\\vJoyInterface.dll")
configJson.insertIfMissing("useShortHopMacro", true)
configJson.insertIfMissing("useCStickTilting", true)
configJson.insertIfMissing("useExtraBButtons", false)
configJson.insertIfMissing("onOffToggleKey", Key.Key8)
configJson.insertIfMissing("keyBinds", {
  $Action.Left: [Key.A],
  $Action.Right: [Key.D],
  $Action.Down: [Key.S],
  $Action.Up: [Key.W],
  $Action.CLeft: [Key.L],
  $Action.CRight: [Key.Slash],
  $Action.CDown: [Key.Apostrophe],
  $Action.CUp: [Key.P],
  $Action.Tilt: [Key.CapsLock],
  $Action.XMod: [Key.LeftAlt],
  $Action.YMod: [Key.Space],
  $Action.Start: [Key.Key5],
  $Action.A: [Key.RightWindows],
  $Action.B: [Key.RightAlt],
  $Action.BUp: [],
  $Action.BSide: [],
  $Action.Z: [Key.RightBracket],
  $Action.ShortHop: [Key.LeftBracket],
  $Action.FullHop: [Key.Minus],
  $Action.Shield: [Key.BackSlash],
  $Action.AirDodge: [Key.Semicolon],
  $Action.ChargeSmash: [Key.Space],
  $Action.DLeft: [Key.V],
  $Action.DRight: [Key.N],
  $Action.DDown: [Key.B],
  $Action.DUp: [Key.G],
  $Action.ToggleLightShield: [Key.Space],
  $Action.InvertYAxis: [],
  $Action.HoldCDown: [Key.BackSpace],
  $Action.StopHoldingCDown: [Key.Equals],
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
  dolphinCtrl = initDolphinController(1)

controller.useShortHopMacro = configJson["useShortHopMacro"].getBool
controller.useCStickTilting = configJson["useCStickTilting"].getBool
controller.useExtraBButtons = configJson["useExtraBButtons"].getBool

proc main() {.async.} =
  while true:
    onOffToggle = keyIsPressed(onOffToggleKey)
    if onOffToggle and not onOffTogglePrevious:
      isEnabled = not isEnabled
      setAllKeysBlocked(isEnabled)

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

    await sleepAsync(1)

setAllKeysBlocked(true)

asyncCheck runHook()
waitFor main()

shutDownVJoy()