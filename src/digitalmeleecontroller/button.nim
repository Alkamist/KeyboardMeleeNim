type
  Button* = object
    isPressed*: bool
    wasPressed*: bool

proc update*(button: var Button) =
  button.wasPressed = button.isPressed

proc justPressed*(button: Button): bool =
  button.isPressed and not button.wasPressed

proc justReleased*(button: Button): bool =
  button.wasPressed and not button.isPressed