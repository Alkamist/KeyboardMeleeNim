import std/times
import ../button


type
  DelayedButton* = object
    isPressed*: bool
    wasPressed*: bool
    shouldPress: bool
    delay*: float
    minHoldTime*: float
    outputPressTime: float
    inputPressTime: float
    inputButton: Button

proc initDelayedButton*(delay, minHoldTime: float): DelayedButton =
  result.delay = delay
  result.minHoldTime = minHoldTime
  result.outputPressTime = cpuTime()
  result.inputPressTime = cpuTime()

proc setState*(button: var DelayedButton, state: bool) =
    button.inputButton.isPressed = state

    if button.inputButton.justPressed:
      button.shouldPress = true
      button.inputPressTime = cpuTime()

    if button.shouldPress and cpuTime() - button.inputPressTime >= button.delay:
      button.outputPressTime = cpuTime()
      button.shouldPress = false
      button.isPressed = true

    let stopPress = button.isPressed and not button.inputButton.isPressed and
                     cpuTime() - button.outputPressTime >= button.minHoldTime

    if stopPress:
      button.isPressed = false

proc justPressed*(button: DelayedButton): bool =
  button.isPressed and not button.wasPressed

proc justReleased*(button: DelayedButton): bool =
  button.wasPressed and not button.isPressed

proc update*(button: var DelayedButton) =
  button.inputButton.update()
  button.wasPressed = button.isPressed