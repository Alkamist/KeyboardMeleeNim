when defined(posix):
  type
    SystemPipe* = object
      file: File

  proc initSystemPipe*(directory: string): SystemPipe =
    result.file = open(directory, fmWrite)

  proc `=destroy`(pipe: var SystemPipe) =
    pipe.file.close()

  proc write*(pipe: SystemPipe, output: string) =
    pipe.file.write(output)

elif defined(windows):
  import std/macros

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
    SystemPipe* = object
      handle: HANDLE
      bytesWritten: DWORD

  proc initSystemPipe*(directory: string): SystemPipe =
    result.handle = CreateFile(directory.LPCSTR, GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0)
    if result.handle == INVALID_HANDLE_VALUE:
      raise newException(IOError, "Could not connect to Dolphin pipe. Make sure Dolphin is running before launching KeyboardMelee if you are not using VJoy.")

  proc `=destroy`(pipe: var SystemPipe) =
    CloseHandle(pipe.handle)

  proc write*(pipe: var SystemPipe, output: string) =
    WriteFile(pipe.handle, output.cstring, (output.len + 1).DWORD, pipe.bytesWritten.addr, nil)