import std/times
import button


type
  JumpLogic* = object
    shortHopOutput*: bool
    fullHopOutput*: bool
    shortHopInput: Button
    fullHopInput: Button
    isShortHopping: bool
    isFullHopping: bool
    shortHopTime: float
    fullHopTime: float

proc initJumpLogic*(): JumpLogic =
  result.shortHopTime = cpuTime()
  result.fullHopTime = cpuTime()

proc update*(jumpLogic: var JumpLogic; shortHop, fullHop: bool) =
  jumpLogic.shortHopInput.update()
  jumpLogic.fullHopInput.update()
  jumpLogic.shortHopInput.isPressed = shortHop
  jumpLogic.fullHopInput.isPressed = fullHop

  # Short hop handling.
  let startShortHop = jumpLogic.shortHopInput.justPressed or
                      (jumpLogic.isFullHopping and jumpLogic.fullHopInput.justPressed)

  if startShortHop:
    jumpLogic.shortHopOutput = true
    jumpLogic.isShortHopping = true
    jumpLogic.shortHopTime = cpuTime()

  if jumpLogic.isShortHopping and cpuTime() - jumpLogic.shortHopTime >= 0.025:
    jumpLogic.shortHopOutput = false
    jumpLogic.isShortHopping = false

  # Full hop handling.
  let startFullHop = jumpLogic.fullHopInput.justPressed

  if startFullHop:
    jumpLogic.isFullHopping = true
    jumpLogic.fullHopOutput = true
    jumpLogic.fullHopTime = cpuTime()

  if jumpLogic.isFullHopping and not jumpLogic.fullHopInput.isPressed:
    if cpuTime() - jumpLogic.fullHopTime >= 0.134:
      jumpLogic.fullHopOutput = false

    # Wait one extra frame so you can't miss a double jump by
    # pushing the full hop button on the same frame of release.
    if cpuTime() - jumpLogic.fullHopTime >= 0.150:
      jumpLogic.isFullHopping = false