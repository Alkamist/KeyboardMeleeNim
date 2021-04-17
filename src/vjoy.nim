import std/dynlib

type
  VJoyAxis* {.pure.} = enum
    X,
    Y,
    Z,
    XRotation,
    YRotation,
    ZRotation,
    Slider0,
    Slider1,

  JoystickPositionV2 = object
    # JOYSTICK_POSITION
    bDevice*: cuchar # Index of device. 1-based.
    wThrottle*: clong
    wRudder*: clong
    wAileron*: clong
    wAxisX*: clong
    wAxisY*: clong
    wAxisZ*: clong
    wAxisXRot*: clong
    wAxisYRot*: clong
    wAxisZRot*: clong
    wSlider*: clong
    wDial*: clong
    wWheel*: clong
    wAxisVX*: clong
    wAxisVY*: clong
    wAxisVZ*: clong
    wAxisVBRX*: clong
    wAxisVBRY*: clong
    wAxisVBRZ*: clong
    lButtons*: clong # 32 buttons: 0x00000001 means button1 is pressed, 0x80000000 -> button32 is pressed
    bHats*: cuint # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch
    bHatsEx1*: cuint # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch
    bHatsEx2*: cuint # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch
    bHatsEx3*: cuint # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch

    # JOYSTICK_POSITION_V2 Extension
    lButtonsEx1*: clong # Buttons 33-64
    lButtonsEx2*: clong # Buttons 65-96
    lButtonsEx3*: clong # Buttons 97-128

  VJoyDevice* = object
    id*: cuint
    state: JoystickPositionV2

template quitIfNil(message: string, input: untyped): untyped =
  if input == nil:
    echo message
    quit(QuitFailure)

var
  deviceIsAcquired = [false, false, false, false]
  vJoyLib: LibHandle
  vJoyEnabled: proc(): cint {.gcsafe, stdcall.}
  acquireVJD: proc(deviceId: cuint): cint {.gcsafe, stdcall.}
  relinquishVJD: proc(deviceId: cuint) {.gcsafe, stdcall.}
  updateVJD: proc(deviceId: cuint, state: JoystickPositionV2): cint {.gcsafe, stdcall.}

proc startVJoy*(dllPath: string) =
  vJoyLib = loadLib(dllPath)
  vJoyEnabled = cast[proc(): cint {.gcsafe, stdcall.}](vJoyLib.symAddr("vJoyEnabled"))
  acquireVJD = cast[proc(deviceId: cuint): cint {.gcsafe, stdcall.}](vJoyLib.symAddr("AcquireVJD"))
  relinquishVJD = cast[proc(deviceId: cuint) {.gcsafe, stdcall.}](vJoyLib.symAddr("RelinquishVJD"))
  updateVJD = cast[proc(deviceId: cuint, state: JoystickPositionV2): cint {.gcsafe, stdcall.}](vJoyLib.symAddr("UpdateVJD"))
  quitIfNil("Error loading 'vJoyEnabled'.", vJoyEnabled)
  quitIfNil("Error loading 'acquireVJD'.", acquireVJD)
  quitIfNil("Error loading 'relinquishVJD'.", relinquishVJD)
  quitIfNil("Error loading 'updateVJD'.", updateVJD)
  if vJoyEnabled() == 0:
    echo "vJoy is not enabled."
    quit(QuitFailure)

proc shutDownVJoy*() =
  for i in 0..3:
    if deviceIsAcquired[i]:
      relinquishVJD((i + 1).cuint)

  unloadLib(vJoyLib)

proc initVJoyDevice*(deviceId: cuint): VJoyDevice =
  if acquireVJD(deviceId) == 0:
    echo "Failed to acquire vJoy device."
    quit(QuitFailure)

  deviceIsAcquired[deviceId - 1] = true
  result.id = deviceId

proc scaledAxisValue(value: float): clong =
  let scaledValue = 0.5 * (0.626 * value + 1.0)
  (scaledValue * 0x8000.float).clong

proc scaledSliderValue(value: float): clong =
  (value * 0x8000.float).clong

proc setButton*(device: var VJoyDevice, buttonId: clong, state: bool) =
  let bitIndex: clong = buttonId - 1
  if state:
    device.state.lButtons = device.state.lButtons or (1 shl bitIndex).clong
  else:
    device.state.lButtons = device.state.lButtons and not (1 shl bitIndex).clong

proc setAxis*(device: var VJoyDevice, axis: VJoyAxis, value: float) =
  case axis:
  of VJoyAxis.X: device.state.wAxisX = scaledAxisValue(value)
  of VJoyAxis.Y: device.state.wAxisY = scaledAxisValue(value)
  of VJoyAxis.Z: device.state.wAxisZ = scaledAxisValue(value)
  of VJoyAxis.XRotation: device.state.wAxisXRot = scaledAxisValue(value)
  of VJoyAxis.YRotation: device.state.wAxisYRot = scaledAxisValue(value)
  of VJoyAxis.ZRotation: device.state.wAxisZRot = scaledAxisValue(value)
  of VJoyAxis.Slider0: device.state.wSlider = scaledSliderValue(value)
  of VJoyAxis.Slider1: device.state.wSlider = scaledSliderValue(value)

proc sendInputs*(device: var VJoyDevice) =
  if updateVJD(device.id, device.state) == 0:
    echo "Failed to update vJoy device."
    quit(QuitFailure)