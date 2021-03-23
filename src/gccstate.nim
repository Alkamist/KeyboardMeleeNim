import button
import analogaxis
import analogslider

export button
export analogaxis
export analogslider


type
  GCCButton* {.pure.} = enum
    A,
    B,
    X,
    Y,
    Z,
    L,
    R,
    Start,
    DLeft,
    DRight,
    DDown,
    DUp,

  GCCAxis* {.pure.} = enum
    X,
    Y,
    CX,
    CY,

  GCCSlider* {.pure.} = enum
    L,
    R,

  GCCState* = object
    xAxis*: AnalogAxis
    yAxis*: AnalogAxis
    cXAxis*: AnalogAxis
    cYAxis*: AnalogAxis
    aButton*: Button
    bButton*: Button
    xButton*: Button
    yButton*: Button
    zButton*: Button
    lButton*: Button
    rButton*: Button
    startButton*: Button
    dLeftButton*: Button
    dRightButton*: Button
    dDownButton*: Button
    dUpButton*: Button
    lSlider*: AnalogSlider
    rSlider*: AnalogSlider

proc justChanged*(state: GCCState): bool =
  for field in state.fields:
    if field.justChanged():
      return true

proc update*(state: var GCCState) =
  for field in state.fields:
    field.update()

proc `[]`*(state: GCCState, button: GCCButton): Button =
  case button:
  of GCCButton.A: return state.aButton
  of GCCButton.B: return state.bButton
  of GCCButton.X: return state.xButton
  of GCCButton.Y: return state.yButton
  of GCCButton.Z: return state.zButton
  of GCCButton.L: return state.lButton
  of GCCButton.R: return state.rButton
  of GCCButton.Start: return state.startButton
  of GCCButton.DLeft: return state.dLeftButton
  of GCCButton.DRight: return state.dRightButton
  of GCCButton.DDown: return state.dDownButton
  of GCCButton.DUp: return state.dUpButton

proc `[]`*(state: var GCCState, button: GCCButton): var Button =
  case button:
  of GCCButton.A: return state.aButton
  of GCCButton.B: return state.bButton
  of GCCButton.X: return state.xButton
  of GCCButton.Y: return state.yButton
  of GCCButton.Z: return state.zButton
  of GCCButton.L: return state.lButton
  of GCCButton.R: return state.rButton
  of GCCButton.Start: return state.startButton
  of GCCButton.DLeft: return state.dLeftButton
  of GCCButton.DRight: return state.dRightButton
  of GCCButton.DDown: return state.dDownButton
  of GCCButton.DUp: return state.dUpButton

proc `[]`*(state: GCCState, axis: GCCAxis): AnalogAxis =
  case axis:
  of GCCAxis.X: return state.xAxis
  of GCCAxis.Y: return state.yAxis
  of GCCAxis.CX: return state.cXAxis
  of GCCAxis.CY: return state.cYAxis

proc `[]`*(state: var GCCState, axis: GCCAxis): var AnalogAxis =
  case axis:
  of GCCAxis.X: return state.xAxis
  of GCCAxis.Y: return state.yAxis
  of GCCAxis.CX: return state.cXAxis
  of GCCAxis.CY: return state.cYAxis

proc `[]`*(state: GCCState, slider: GCCSlider): AnalogSlider =
  case slider:
  of GCCSlider.L: return state.lSlider
  of GCCSlider.R: return state.rSlider

proc `[]`*(state: var GCCState, slider: GCCSlider): var AnalogSlider =
  case slider:
  of GCCSlider.L: return state.lSlider
  of GCCSlider.R: return state.rSlider