import macros


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


const output = """
PRESS A
FLUSH

"""

let handle = CreateFileA("\\\\.\\pipe\\slippibot1".LPCSTR, GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0)

var overlapped: OVERLAPPED
WriteFileEx(handle, output.cstring, (output.len + 1).DWORD, overlapped.addr, nil)

CloseHandle(handle)