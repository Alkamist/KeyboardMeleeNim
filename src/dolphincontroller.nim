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
  LPCSTR = cstring
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
  LPOVERLAPPED_COMPLETION_ROUTINE* = proc (dwErrorCode: DWORD, dwNumberOfBytesTransfered: DWORD, lpOverlapped: LPOVERLAPPED): VOID {.stdcall.}

const
  GENERIC_WRITE = 0x40000000
  OPEN_EXISTING = 3

proc CreateFileA(lpFileName: LPCSTR,
                 dwDesiredAccess: DWORD,
                 dwShareMode: DWORD,
                 lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
                 dwCreationDisposition: DWORD,
                 dwFlagsAndAttributes: DWORD,
                 hTemplateFile: HANDLE): HANDLE {.winapi, stdcall, dynlib: "kernel32", importc.}
proc WriteFileEx(hFile: HANDLE,
                 lpBuffer: LPCVOID,
                 nNumberOfBytesToWrite: DWORD,
                 lpOverlapped: LPOVERLAPPED,
                 lpCompletionRoutine: LPOVERLAPPED_COMPLETION_ROUTINE): WINBOOL {.winapi, stdcall, dynlib: "kernel32", importc.}
proc CloseHandle(hObject: HANDLE): WINBOOL {.winapi, stdcall, dynlib: "kernel32", importc.}

type
  Pipe = object
    handle: HANDLE

proc initPipe(directory: string): Pipe =
  result.handle = CreateFileA(directory.LPCSTR, GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0)

proc `=destroy`(pipe: var Pipe) =
  CloseHandle(pipe.handle)

proc write(pipe: Pipe, output: string) =
  var overlapped: OVERLAPPED
  WriteFileEx(pipe.handle, output.cstring, (output.len + 1).DWORD, overlapped.addr, nil)

type
  DolphinController* = object
    state: GCCState
    pipe: Pipe

proc initDolphinController*(pipeNumber: int): DolphinController =
  result.pipe = initPipe("\\\\.\\pipe\\slippibot" & $pipeNumber)

proc setButton*(controller: var DolphinController, button: GCCButton, state: bool) =
  controller.state[button].isPressed = state

proc setAxis*(controller: var DolphinController, axis: GCCAxis, value: float) =
  controller.state[axis].value = value

proc setSlider*(controller: var DolphinController, slider: GCCSlider, value: float) =
  controller.state[slider].value = value

proc writeControllerState*(controller: var DolphinController) =
  var outputStr = ""

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

  # let
  #   xAxis = controller.state[GCCAxis.X]
  #   yAxis = controller.state[GCCAxis.Y]
  #   cXAxis = controller.state[GCCAxis.CX]
  #   cYAxis = controller.state[GCCAxis.CY]

  # if xAxis.justChanged or yAxis.justChanged:
  #   outputStr.add("SET MAIN " & $xAxis.value & " " & $yAxis.value & "\n")

  # if cXAxis.justChanged or cYAxis.justChanged:
  #   outputStr.add("SET C " & $cXAxis.value & " " & $cYAxis.value & "\n")

  # let
  #   lSlider = controller.state[GCCSlider.L]
  #   rSlider = controller.state[GCCSlider.R]

  # if lSlider.justChanged:
  #   outputStr.add("SET L " & $lSlider.value & "\n")

  # if rSlider.justChanged:
  #   outputStr.add("SET R " & $rSlider.value & "\n")

  if outputStr != "":
   outputStr.add("FLUSH\n")
   echo outputStr
   controller.pipe.write(outputStr)

  controller.state.update()

  # outputStr.add("FLUSH\n")
  # if outputStr != "FLUSH\n":
  #   echo outputStr
  # controller.pipe.write(outputStr)


# const output = """
# RELEASE A
# RELEASE B
# FLUSH

# """

# let handle = CreateFileA("\\\\.\\pipe\\slippibot1".LPCSTR, GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0)

# var overlapped: OVERLAPPED
# WriteFileEx(handle, output.cstring, (output.len + 1).DWORD, overlapped.addr, nil)

# CloseHandle(handle)