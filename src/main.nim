import json
import tables
import strutils
import asyncdispatch
from os import fileExists
import kbdinput
import vjoy
import digitalmeleecontroller/digitalmeleecontroller


proc parseKeyBindsJson(inputBinds: JsonNode): OrderedTable[Action, seq[Key]] =
  for action, bindList in inputBinds.pairs:
    var parsedBindList: seq[Key]
    for keyBind in bindList.items:
      parsedBindList.add(parseEnum[Key](keyBind.getStr()))
    result[parseEnum[Action](action)] = parsedBindList

var keyBindsJson: JsonNode

if fileExists("config.txt"):
  keyBindsJson = parseJson(readFile("config.txt"))

else:
  keyBindsJson = %* {
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
    $Action.InvertXAxis: [Key.Enter]
  }
  writeFile("config.txt", pretty(keyBindsJson))

let keyBinds = parseKeyBindsJson(keyBindsJson)

var
  vJoyDevice = initVJoyDevice(1)
  controller = initDigitalMeleeController()

proc main() {.async.} =
  while true:
    for action, keyBindList in keyBinds.pairs:
      var bindState = false
      for keyBind in keyBindList:
        bindState = bindState or keyIsPressed(keyBind)
      controller.setActionState(action, bindState)

    controller.update()

    vJoyDevice.setButton(1, controller.state.aButton.isPressed)
    vJoyDevice.setButton(2, controller.state.bButton.isPressed)
    vJoyDevice.setButton(3, controller.state.xButton.isPressed)
    vJoyDevice.setButton(4, controller.state.yButton.isPressed)
    vJoyDevice.setButton(5, controller.state.zButton.isPressed)
    vJoyDevice.setButton(6, controller.state.lButton.isPressed)
    vJoyDevice.setButton(7, controller.state.rButton.isPressed)
    vJoyDevice.setButton(8, controller.state.startButton.isPressed)
    vJoyDevice.setButton(9, controller.state.dLeftButton.isPressed)
    vJoyDevice.setButton(10, controller.state.dUpButton.isPressed)
    vJoyDevice.setButton(11, controller.state.dRightButton.isPressed)
    vJoyDevice.setButton(12, controller.state.dDownButton.isPressed)
    vJoyDevice.setAxis(VJoyAxis.X, controller.state.xAxis.value)
    vJoyDevice.setAxis(VJoyAxis.Y, controller.state.yAxis.value)
    vJoyDevice.setAxis(VJoyAxis.XRotation, controller.state.cXAxis.value)
    vJoyDevice.setAxis(VJoyAxis.YRotation, controller.state.cYAxis.value)
    vJoyDevice.setAxis(VJoyAxis.Slider0, controller.state.lSlider.value)

    vJoyDevice.sendInputs()

    await sleepAsync(1)

#setAllKeysBlocked(true)

asyncCheck runHook()

waitFor main()

shutDownVJoy()