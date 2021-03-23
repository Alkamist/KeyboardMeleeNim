import std/times
import ../button
import ../analogaxis


type
  AirDodgeLogic* = object
    airDodgeInput: Button
    airDodgeTime: float
    isAirDodging: bool
    xLevelLong: float
    yLevelLong: float
    xLevelMedium: float
    yLevelMedium: float
    xLevelShort: float
    yLevelShort: float

proc initAirDodgeLogic*(): AirDodgeLogic =
  result.airDodgeTime = cpuTime()
  result.xLevelLong = 0.925
  result.yLevelLong = -0.35
  result.xLevelMedium = 0.8125
  result.yLevelMedium = -0.575
  result.xLevelShort = 0.5
  result.yLevelShort = -0.85

proc update*(airDodgeLogic: var AirDodgeLogic,
             xAxis: var AnalogAxis,
             yAxis: var AnalogAxis,
             airDodge: bool,
             shorten: bool) =
    airDodgeLogic.airDodgeInput.update()
    airDodgeLogic.airDodgeInput.isPressed = airDodge

    let
      isLeft = xAxis.isActive and xAxis.value < 0.0
      isRight = xAxis.isActive and xAxis.value > 0.0
      isDown = yAxis.isActive and yAxis.value < 0.0
      isUp = yAxis.isActive and yAxis.value > 0.0
      isSideways = (isLeft or isRight) and not isDown
      isDiagonal = (isLeft or isRight) and (isDown or isUp)
      airDodgeShort = isDiagonal and shorten
      airDodgeMedium = isSideways and shorten
      airDodgeLong = isSideways and not shorten

    if airDodgeLogic.airDodgeInput.justPressed:
      airDodgeLogic.isAirDodging = true
      airDodgeLogic.airDodgeTime = cpuTime()

    if airDodgeLogic.isAirDodging and not isUp:
      if cpuTime() - airDodgeLogic.airDodgeTime < 0.051:
        if airDodgeLong:
          xAxis.value = xAxis.direction * airDodgeLogic.xLevelLong
          yAxis.value = airDodgeLogic.yLevelLong

        elif airDodgeMedium:
          xAxis.value = xAxis.direction * airDodgeLogic.xLevelMedium
          yAxis.value = airDodgeLogic.yLevelMedium

        elif airDodgeShort:
          xAxis.value = xAxis.direction *  airDodgeLogic.xLevelShort
          yAxis.value = airDodgeLogic.yLevelShort

        elif not isDown:
          yAxis.value = -0.3

      else:
        airDodgeLogic.isAirDodging = false