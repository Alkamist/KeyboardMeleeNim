{.experimental: "overloadableEnums".}

import std/tables

type
  KeyboardKey* = enum
    Unknown,
    Space, Apostrophe, Comma,
    Minus, Period, Slash,
    Key0, Key1, Key2, Key3, Key4,
    Key5, Key6, Key7, Key8, Key9,
    Semicolon, Equal,
    A, B, C, D, E, F, G, H, I,
    J, K, L, M, N, O, P, Q, R,
    S, T, U, V, W, X, Y, Z,
    LeftBracket, Backslash,
    RightBracket, Backtick,
    World1, World2, Escape, Enter,
    Tab, Backspace, Insert, Delete,
    RightArrow, LeftArrow,
    DownArrow, UpArrow,
    PageUp, PageDown, Home,
    End, CapsLock,
    ScrollLock, NumLock,
    PrintScreen, Pause,
    F1, F2, F3, F4, F5, F6, F7, F8, F9,
    F10, F11, F12, F13, F14, F15, F16,
    F17, F18, F19, F20, F21, F22,
    F23, F24, F25,
    Pad0, Pad1, Pad2, Pad3, Pad4,
    Pad5, Pad6, Pad7, Pad8, Pad9,
    PadDecimal, PadDivide, PadMultiply,
    PadSubtract, PadAdd, PadEnter, PadEqual,
    LeftShift, LeftControl,
    LeftAlt, LeftSuper,
    RightShift, RightControl,
    RightAlt, RightSuper,
    Menu,

const keyCodeToKeyboardKeyTable = {
  8: KeyboardKey.Backspace,
  9: KeyboardKey.Tab,
  13: KeyboardKey.Enter,
  19: KeyboardKey.Pause,
  20: KeyboardKey.CapsLock,
  27: KeyboardKey.Escape,
  32: KeyboardKey.Space,
  33: KeyboardKey.PageUp,
  34: KeyboardKey.PageDown,
  35: KeyboardKey.End,
  36: KeyboardKey.Home,
  37: KeyboardKey.LeftArrow,
  38: KeyboardKey.UpArrow,
  39: KeyboardKey.RightArrow,
  40: KeyboardKey.DownArrow,
  44: KeyboardKey.PrintScreen,
  45: KeyboardKey.Insert,
  46: KeyboardKey.Delete,
  48: KeyboardKey.Key0,
  49: KeyboardKey.Key1,
  50: KeyboardKey.Key2,
  51: KeyboardKey.Key3,
  52: KeyboardKey.Key4,
  53: KeyboardKey.Key5,
  54: KeyboardKey.Key6,
  55: KeyboardKey.Key7,
  56: KeyboardKey.Key8,
  57: KeyboardKey.Key9,
  65: KeyboardKey.A,
  66: KeyboardKey.B,
  67: KeyboardKey.C,
  68: KeyboardKey.D,
  69: KeyboardKey.E,
  70: KeyboardKey.F,
  71: KeyboardKey.G,
  72: KeyboardKey.H,
  73: KeyboardKey.I,
  74: KeyboardKey.J,
  75: KeyboardKey.K,
  76: KeyboardKey.L,
  77: KeyboardKey.M,
  78: KeyboardKey.N,
  79: KeyboardKey.O,
  80: KeyboardKey.P,
  81: KeyboardKey.Q,
  82: KeyboardKey.R,
  83: KeyboardKey.S,
  84: KeyboardKey.T,
  85: KeyboardKey.U,
  86: KeyboardKey.V,
  87: KeyboardKey.W,
  88: KeyboardKey.X,
  89: KeyboardKey.Y,
  90: KeyboardKey.Z,
  91: KeyboardKey.LeftSuper,
  92: KeyboardKey.RightSuper,
  96: KeyboardKey.Pad0,
  97: KeyboardKey.Pad1,
  98: KeyboardKey.Pad2,
  99: KeyboardKey.Pad3,
  100: KeyboardKey.Pad4,
  101: KeyboardKey.Pad5,
  102: KeyboardKey.Pad6,
  103: KeyboardKey.Pad7,
  104: KeyboardKey.Pad8,
  105: KeyboardKey.Pad9,
  106: KeyboardKey.PadMultiply,
  107: KeyboardKey.PadAdd,
  109: KeyboardKey.PadSubtract,
  110: KeyboardKey.PadDecimal,
  111: KeyboardKey.PadDivide,
  112: KeyboardKey.F1,
  113: KeyboardKey.F2,
  114: KeyboardKey.F3,
  115: KeyboardKey.F4,
  116: KeyboardKey.F5,
  117: KeyboardKey.F6,
  118: KeyboardKey.F7,
  119: KeyboardKey.F8,
  120: KeyboardKey.F9,
  121: KeyboardKey.F10,
  122: KeyboardKey.F11,
  123: KeyboardKey.F12,
  124: KeyboardKey.F13,
  125: KeyboardKey.F14,
  126: KeyboardKey.F15,
  127: KeyboardKey.F16,
  128: KeyboardKey.F17,
  129: KeyboardKey.F18,
  130: KeyboardKey.F20,
  131: KeyboardKey.F21,
  132: KeyboardKey.F22,
  133: KeyboardKey.F23,
  134: KeyboardKey.F24,
  144: KeyboardKey.NumLock,
  145: KeyboardKey.ScrollLock,
  160: KeyboardKey.LeftShift,
  161: KeyboardKey.RightShift,
  162: KeyboardKey.LeftControl,
  163: KeyboardKey.RightControl,
  164: KeyboardKey.LeftAlt,
  165: KeyboardKey.RightAlt,
  186: KeyboardKey.Semicolon,
  187: KeyboardKey.Equal,
  188: KeyboardKey.Comma,
  189: KeyboardKey.Minus,
  190: KeyboardKey.Period,
  191: KeyboardKey.Slash,
  192: KeyboardKey.Backtick,
  219: KeyboardKey.LeftBracket,
  220: KeyboardKey.BackSlash,
  221: KeyboardKey.RightBracket,
  222: KeyboardKey.Apostrophe,
}.toTable()

when defined(cpu64):
  type
    UINT_PTR = uint64
    LONG_PTR = int64
    ULONG_PTR = uint64
when not defined(cpu64):
  type
    UINT_PTR = int32
    LONG_PTR = int32
    ULONG_PTR = int32

type
  HANDLE = int
  HINSTANCE = HANDLE
  HWND = HANDLE
  HHOOK = HANDLE
  WINBOOL = int32
  DWORD = int32
  LONG = int32
  UINT = int32
  WPARAM = UINT_PTR
  LPARAM = LONG_PTR
  LRESULT = LONG_PTR
  HOOKPROC = proc (code: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}
  KBDLLHOOKSTRUCT {.pure.} = object
    vkCode*: DWORD
    scanCode*: DWORD
    flags*: DWORD
    time*: DWORD
    dwExtraInfo*: ULONG_PTR
  PKBDLLHOOKSTRUCT = ptr KBDLLHOOKSTRUCT
  POINT {.pure.} = object
    x*: LONG
    y*: LONG
  MSG {.pure.} = object
    hwnd*: HWND
    message*: UINT
    wParam*: WPARAM
    lParam*: LPARAM
    time*: DWORD
    pt*: POINT
  LPMSG = ptr MSG

const HC_ACTION = 0
const WH_KEYBOARD_LL = 13
const WM_KEYDOWN = 0x0100
const WM_KEYUP = 0x0101
const WM_SYSKEYDOWN = 0x0104
const WM_SYSKEYUP = 0x0105

proc PeekMessage(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT): WINBOOL {.discardable, stdcall, dynlib: "user32", importc: "PeekMessageA".}
proc TranslateMessage(lpMsg: ptr MSG): WINBOOL {.discardable, stdcall, dynlib: "user32", importc.}
proc DispatchMessage(lpMsg: ptr MSG): LRESULT {.discardable, stdcall, dynlib: "user32", importc: "DispatchMessageA".}
proc SetWindowsHookEx(idHook: int32, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD): HHOOK {.discardable, stdcall, dynlib: "user32", importc: "SetWindowsHookExW".}
proc CallNextHookEx(hhk: HHOOK, nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.discardable, stdcall, dynlib: "user32", importc.}

var keyStates: array[KeyboardKey.low..KeyboardKey.high, bool]
var keyBlockStates: array[KeyboardKey.low..KeyboardKey.high, bool]

proc windowsKeyboardHook(code: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  if code == HC_ACTION:
    let hookStruct = cast[PKBDLLHOOKSTRUCT](lParam)
    let keyCode = hookStruct.vkCode
    let key = keyCodeToKeyboardKeyTable[keyCode]

    if wParam in {WM_KEYDOWN, WM_SYSKEYDOWN}:
      keyStates[key] = true
    elif wParam in {WM_KEYUP, WM_SYSKEYUP}:
      keyStates[key] = false

    if keyBlockStates[key]:
      return 1

  CallNextHookEx(0, code, wParam, lParam)

proc pollKeyboard*() =
  var msg: LPMSG
  while PeekMessage(msg, 0, 0, 0, 0) != 0:
    TranslateMessage(msg)
    DispatchMessage(msg)

proc keyIsPressed*(key: KeyboardKey): bool =
  keyStates[key]

proc keyIsBlocked*(key: KeyboardKey): bool =
  keyBlockStates[key]

proc setKeyBlocked*(key: KeyboardKey, state: bool) =
  keyBlockStates[key] = state

proc setAllKeysBlocked*(state: bool) =
  for key in KeyboardKey:
    keyBlockStates[key] = state

SetWindowsHookEx(WH_KEYBOARD_LL, windowsKeyboardHook, 0, 0)