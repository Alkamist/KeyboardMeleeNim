type
  AnalogSlider* = object
    value*: float
    previousValue*: float

proc initAnalogSlider*(): AnalogSlider =
  result

proc justChanged*(slider: AnalogSlider): bool =
  slider.value != slider.previousValue

proc update*(slider: var AnalogSlider) =
  slider.previousValue = slider.value