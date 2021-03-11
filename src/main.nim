import asyncdispatch
import kbdinput
import vjoy
import digitalmeleecontroller/digitalmeleecontroller


var
  vJoyDevice = initVJoyDevice(1)
  controller = initDigitalMeleeController()

proc main() {.async.} =
  while true:
    controller.setActionState(Action.Left, keyIsPressed(Key.A))
    controller.setActionState(Action.Right, keyIsPressed(Key.D))
    controller.setActionState(Action.Down, keyIsPressed(Key.S))
    controller.setActionState(Action.Up, keyIsPressed(Key.W))
    controller.setActionState(Action.CLeft, keyIsPressed(Key.L))
    controller.setActionState(Action.CRight, keyIsPressed(Key.Slash))
    controller.setActionState(Action.CDown, keyIsPressed(Key.Apostrophe))
    controller.setActionState(Action.CUp, keyIsPressed(Key.P))
    controller.setActionState(Action.Tilt, keyIsPressed(Key.CapsLock))
    controller.setActionState(Action.XMod, keyIsPressed(Key.LeftAlt))
    controller.setActionState(Action.YMod, keyIsPressed(Key.Space))
    controller.setActionState(Action.Start, keyIsPressed(Key.Key5))
    controller.setActionState(Action.A, keyIsPressed(Key.RightWindows))
    controller.setActionState(Action.B, keyIsPressed(Key.RightAlt))
    controller.setActionState(Action.BUp, keyIsPressed(Key.Period))
    controller.setActionState(Action.BSide, keyIsPressed(Key.Backspace))
    controller.setActionState(Action.Z, keyIsPressed(Key.Equals))
    controller.setActionState(Action.ShortHop, keyIsPressed(Key.LeftBracket) or keyIsPressed(Key.Minus))
    controller.setActionState(Action.FullHop, keyIsPressed(Key.BackSlash))
    controller.setActionState(Action.Shield, keyIsPressed(Key.RightBracket))
    controller.setActionState(Action.AirDodge, keyIsPressed(Key.Semicolon))
    controller.setActionState(Action.ChargeSmash, keyIsPressed(Key.Space))
    controller.setActionState(Action.DLeft, keyIsPressed(Key.V))
    controller.setActionState(Action.DRight, keyIsPressed(Key.N))
    controller.setActionState(Action.DDown, keyIsPressed(Key.B))
    controller.setActionState(Action.DUp, keyIsPressed(Key.G))
    controller.setActionState(Action.ToggleLightShield, keyIsPressed(Key.Space))
    controller.setActionState(Action.InvertXAxis, keyIsPressed(Key.Enter))

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

setAllKeysBlocked(true)

asyncCheck runHook()

waitFor main()

shutDownVJoy()