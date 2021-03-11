type
  AnalogSlider* = object
    value*: float
    previousValue*: float

proc update*(slider: var AnalogSlider) =
  slider.previousValue = slider.value