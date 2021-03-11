import button
import analogaxis
import analogslider


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
    DUp,
    DDown,

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

proc update*(state: var GCCState) =
  for field in state.fields:
    field.update()