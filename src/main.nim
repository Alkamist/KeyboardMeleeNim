import json
import tables
import strutils
import asyncdispatch
from os import fileExists
import kbdinput
import vjoy
import digitalmeleecontroller/digitalmeleecontroller


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

configJson.insertIfMissing("vJoyDeviceId", 1)
configJson.insertIfMissing("vJoyDllPath", "C:\\Program Files\\vJoy\\x64\\vJoyInterface.dll")
configJson.insertIfMissing("useShortHopMacro", true)
configJson.insertIfMissing("useCStickTilting", true)
configJson.insertIfMissing("useExtraBButtons", true)
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
  $Action.BUp: [Key.Period],
  $Action.BSide: [Key.Backspace],
  $Action.Z: [Key.Equals],
  $Action.ShortHop: [Key.LeftBracket, Key.Minus],
  $Action.FullHop: [Key.BackSlash],
  $Action.Shield: [Key.RightBracket],
  $Action.AirDodge: [Key.Semicolon],
  $Action.ChargeSmash: [Key.Space],
  $Action.DLeft: [Key.V],
  $Action.DRight: [Key.N],
  $Action.DDown: [Key.B],
  $Action.DUp: [Key.G],
  $Action.ToggleLightShield: [Key.Space],
  $Action.InvertXAxis: [Key.Enter],
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
  $GCCButton.DRight: 10,
  $GCCButton.DDown: 11,
  $GCCButton.DUp: 12,
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

startVJoy(configJson["vJoyDllPath"].getStr)

let
  keyBinds = parseKeyBindsJson(configJson["keyBinds"])
  vJoyButtonBinds = parseVJoyButtonBindsJson(configJson["vJoyButtonBinds"])
  vJoyAxisBinds = parseVJoyAxisBindsJson(configJson["vJoyAxisBinds"])
  vJoySliderBinds = parseVJoySliderBindsJson(configJson["vJoySliderBinds"])

var
  vJoyDevice = initVJoyDevice(configJson["vJoyDeviceId"].getInt.cuint)
  controller = initDigitalMeleeController()

controller.useShortHopMacro = configJson["useShortHopMacro"].getBool
controller.useCStickTilting = configJson["useCStickTilting"].getBool
controller.useExtraBButtons = configJson["useExtraBButtons"].getBool

proc main() {.async.} =
  while true:
    for action, keyBindList in keyBinds.pairs:
      var bindState = false
      for keyBind in keyBindList:
        bindState = bindState or keyIsPressed(keyBind)
      controller.setActionState(action, bindState)

    controller.update()

    for button, bindId in vJoyButtonBinds.pairs:
      vJoyDevice.setButton(bindId, controller.state[button].isPressed)

    for axis, bindId in vJoyAxisBinds.pairs:
      vJoyDevice.setAxis(bindId, controller.state[axis].value)

    for slider, bindId in vJoySliderBinds.pairs:
      vJoyDevice.setAxis(bindId, controller.state[slider].value)

    vJoyDevice.sendInputs()

    await sleepAsync(1)

#setAllKeysBlocked(true)

asyncCheck runHook()

waitFor main()

shutDownVJoy()