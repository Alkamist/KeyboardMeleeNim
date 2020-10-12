import macros

macro winapi*(x: untyped): untyped =
  when not defined(noDiscardableApi):
    x.addPragma(newIdentNode("discardable"))
  result = x

when defined(cpu64):
  type
    UINT_PTR* = uint64
    LONG_PTR* = int64
    ULONG_PTR* = uint64
when not defined(cpu64):
  type
    UINT_PTR* = int32
    LONG_PTR* = int32
    ULONG_PTR* = int32

type
  HANDLE* = int
  HINSTANCE* = HANDLE
  HWND* = HANDLE
  HHOOK* = HANDLE
  WINBOOL* = int32
  DWORD* = int32
  LONG* = int32
  UINT* = int32
  WPARAM* = UINT_PTR
  LPARAM* = LONG_PTR
  LRESULT* = LONG_PTR
  HOOKPROC* = proc (code: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}
  KBDLLHOOKSTRUCT* {.pure.} = object
    vkCode*: DWORD
    scanCode*: DWORD
    flags*: DWORD
    time*: DWORD
    dwExtraInfo*: ULONG_PTR
  PKBDLLHOOKSTRUCT* = ptr KBDLLHOOKSTRUCT
  POINT* {.pure.} = object
    x*: LONG
    y*: LONG
  MSG* {.pure.} = object
    hwnd*: HWND
    message*: UINT
    wParam*: WPARAM
    lParam*: LPARAM
    time*: DWORD
    pt*: POINT
  LPMSG* = ptr MSG

const
  HC_ACTION* = 0
  WH_KEYBOARD_LL* = 13
  WM_KEYDOWN* = 0x0100
  WM_KEYUP* = 0x0101
  WM_SYSKEYDOWN* = 0x0104
  WM_SYSKEYUP* = 0x0105

proc GetMessage*(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT): WINBOOL {.winapi, stdcall, dynlib: "user32", importc: "GetMessageW".}
proc TranslateMessage*(lpMsg: ptr MSG): WINBOOL {.winapi, stdcall, dynlib: "user32", importc.}
proc DispatchMessage*(lpMsg: ptr MSG): LRESULT {.winapi, stdcall, dynlib: "user32", importc: "DispatchMessageA".}
proc SetWindowsHookEx*(idHook: int32, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD): HHOOK {.winapi, stdcall, dynlib: "user32", importc: "SetWindowsHookExW".}
proc CallNextHookEx*(hhk: HHOOK, nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.winapi, stdcall, dynlib: "user32", importc.}