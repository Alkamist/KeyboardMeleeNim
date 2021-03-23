import std/macros
import gccstate


macro winapi(x: untyped): untyped =
  when not defined(noDiscardableApi):
    x.addPragma(newIdentNode("discardable"))
  result = x

when defined(cpu64):
  type ULONG_PTR = uint64
when not defined(cpu64):
  type ULONG_PTR = int32

type
  VOID = void
  PVOID = pointer
  LPVOID = pointer
  LPCVOID = pointer
  HANDLE = int
  WINBOOL = int32
  DWORD = int32
  LPDWORD = ptr DWORD
  WCHAR = uint16
  LPCSTR = cstring
  LPCWSTR = ptr WCHAR
  SECURITY_ATTRIBUTES {.pure.} = object
    nLength*: DWORD
    lpSecurityDescriptor*: LPVOID
    bInheritHandle*: WINBOOL
  LPSECURITY_ATTRIBUTES = ptr SECURITY_ATTRIBUTES
  OVERLAPPED_UNION1_STRUCT1 {.pure.} = object
    Offset*: DWORD
    OffsetHigh*: DWORD
  OVERLAPPED_UNION1 {.pure, union.} = object
    struct1*: OVERLAPPED_UNION1_STRUCT1
    Pointer*: PVOID
  OVERLAPPED {.pure.} = object
    Internal*: ULONG_PTR
    InternalHigh*: ULONG_PTR
    union1*: OVERLAPPED_UNION1
    hEvent*: HANDLE
  LPOVERLAPPED = ptr OVERLAPPED

const
  GENERIC_WRITE = 0x40000000
  OPEN_EXISTING = 3
  INVALID_HANDLE_VALUE = HANDLE(-1)

proc CreateFile(lpFileName: LPCSTR,
                dwDesiredAccess: DWORD,
                dwShareMode: DWORD,
                lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
                dwCreationDisposition: DWORD,
                dwFlagsAndAttributes: DWORD,
                hTemplateFile: HANDLE): HANDLE {.winapi, stdcall, dynlib: "kernel32", importc: "CreateFileA".}
proc CreateFile(lpFileName: LPCWSTR,
                dwDesiredAccess: DWORD,
                dwShareMode: DWORD,
                lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
                dwCreationDisposition: DWORD,
                dwFlagsAndAttributes: DWORD,
                hTemplateFile: HANDLE): HANDLE {.winapi, stdcall, dynlib: "kernel32", importc: "CreateFileW".}
proc WriteFile(hFile: HANDLE,
               lpBuffer: LPCVOID,
               nNumberOfBytesToWrite: DWORD,
               lpNumberOfBytesWritten: LPDWORD,
               lpOverlapped: LPOVERLAPPED): WINBOOL {.winapi, stdcall, dynlib: "kernel32", importc.}
proc CloseHandle(hObject: HANDLE): WINBOOL {.winapi, stdcall, dynlib: "kernel32", importc.}

type
  Pipe = object
    handle: HANDLE
    bytesWritten: DWORD

proc initPipe(directory: string): Pipe =
  result.handle = CreateFile(directory.LPCSTR, GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0)
  if result.handle == INVALID_HANDLE_VALUE:
    echo "Could not connect to Dolphin pipe."
    quit(QuitFailure)

proc `=destroy`(pipe: var Pipe) =
  CloseHandle(pipe.handle)

proc write(pipe: var Pipe, output: string) =
  WriteFile(pipe.handle, output.cstring, (output.len + 1).DWORD, pipe.bytesWritten.addr, nil)

type
  DolphinController* = object
    state: GCCState
    pipe: Pipe

proc initDolphinController*(pipeNumber: int): DolphinController =
  result.pipe = initPipe("\\\\.\\pipe\\slippibot" & $pipeNumber)

proc setButton*(controller: var DolphinController, button: GCCButton, state: bool) =
  controller.state[button].isPressed = state

proc setAxis*(controller: var DolphinController, axis: GCCAxis, value: float) =
  controller.state[axis].value = 0.5 * (0.626 * value + 1.0 + 1.0 / 255.0)

proc setSlider*(controller: var DolphinController, slider: GCCSlider, value: float) =
  controller.state[slider].value = (value * 1.94).min(1.0)

proc writeControllerState*(controller: var DolphinController) =
  var outputStr = "\n"

  for buttonKind in GCCButton:
    let button = controller.state[buttonKind]
    if button.justChanged:
      let name = case buttonKind:
        of GCCButton.A: "A"
        of GCCButton.B: "B"
        of GCCButton.X: "X"
        of GCCButton.Y: "Y"
        of GCCButton.Z: "Z"
        of GCCButton.L: "L"
        of GCCButton.R: "R"
        of GCCButton.Start: "START"
        of GCCButton.DLeft: "D_LEFT"
        of GCCButton.DRight: "D_RIGHT"
        of GCCButton.DDown: "D_DOWN"
        of GCCButton.DUp: "D_UP"

      if button.isPressed:
        outputStr.add("PRESS " & name & "\n")
      else:
        outputStr.add("RELEASE " & name & "\n")

  let
    xAxis = controller.state[GCCAxis.X]
    yAxis = controller.state[GCCAxis.Y]
    cXAxis = controller.state[GCCAxis.CX]
    cYAxis = controller.state[GCCAxis.CY]

  if xAxis.justChanged or yAxis.justChanged:
    outputStr.add("SET MAIN " & $xAxis.value & " " & $yAxis.value & "\n")

  if cXAxis.justChanged or cYAxis.justChanged:
    outputStr.add("SET C " & $cXAxis.value & " " & $cYAxis.value & "\n")

  let
    lSlider = controller.state[GCCSlider.L]
    rSlider = controller.state[GCCSlider.R]

  if lSlider.justChanged:
    outputStr.add("SET L " & $lSlider.value & "\n")

  if rSlider.justChanged:
    outputStr.add("SET R " & $rSlider.value & "\n")

  if outputStr != "\n":
    outputStr.add("FLUSH\n")
    controller.pipe.write(outputStr)

  controller.state.update()