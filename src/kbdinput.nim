import tables
import sequtils
import asyncdispatch
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
proc PeekMessage*(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT): WINBOOL {.winapi, stdcall, dynlib: "user32", importc: "PeekMessageA".}
proc TranslateMessage*(lpMsg: ptr MSG): WINBOOL {.winapi, stdcall, dynlib: "user32", importc.}
proc DispatchMessage*(lpMsg: ptr MSG): LRESULT {.winapi, stdcall, dynlib: "user32", importc: "DispatchMessageA".}
proc SetWindowsHookEx*(idHook: int32, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD): HHOOK {.winapi, stdcall, dynlib: "user32", importc: "SetWindowsHookExW".}
proc CallNextHookEx*(hhk: HHOOK, nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.winapi, stdcall, dynlib: "user32", importc.}

type
  Key* {.pure.} = enum
    ControlBreak,
    Backspace,
    Tab,
    Clear,
    Enter,
    Shift,
    Control,
    Alt,
    Pause,
    CapsLock,
    IMEKana,
    IMEJunja,
    IMEFinal,
    IMEHanja,
    Escape,
    IMEConvert,
    IMENonConvert,
    IMEAccept,
    IMEModeChange,
    Space,
    PageUp,
    PageDown,
    End,
    Home,
    LeftArrow,
    UpArrow,
    RightArrow,
    DownArrow,
    Select,
    Print,
    Execute,
    PrintScreen,
    Insert,
    Delete,
    Help,
    Key0,
    Key1,
    Key2,
    Key3,
    Key4,
    Key5,
    Key6,
    Key7,
    Key8,
    Key9,
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    LeftWindows,
    RightWindows,
    Applications,
    Sleep,
    NumPad0,
    NumPad1,
    NumPad2,
    NumPad3,
    NumPad4,
    NumPad5,
    NumPad6,
    NumPad7,
    NumPad8,
    NumPad9,
    NumPadMultiply,
    NumPadAdd,
    NumPadSeparator,
    NumPadSubtract,
    NumPadDecimal,
    NumPadDivide,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F20,
    F21,
    F22,
    F23,
    F24,
    NumLock,
    ScrollLock,
    LeftShift,
    RightShift,
    LeftControl,
    RightControl,
    LeftAlt,
    RightAlt,
    BrowserBack,
    BrowserForward,
    BrowserRefresh,
    BrowserStop,
    BrowserSearch,
    BrowserFavorites,
    BrowserHome,
    BrowserMute,
    VolumeDown,
    VolumeUp,
    MediaNextTrack,
    MediaPreviousTrack,
    MediaStop,
    MediaPlay,
    StartMail,
    MediaSelect,
    LaunchApplication1,
    LaunchApplication2,
    Semicolon,
    Equals,
    Comma,
    Minus,
    Period,
    Slash,
    Grave,
    LeftBracket,
    BackSlash,
    RightBracket,
    Apostrophe,
    IMEProcess,

proc toBiTable[K, V](entries: openArray[(K, V)]): (Table[K, V], Table[V, K]) =
  let reverseEntries = entries.mapIt((it[1], it[0]))
  result = (entries.toTable(), reverseEntries.toTable())

const (keyCodes, keyCodeKeys) = {
  Key.ControlBreak: 3,
  Key.Backspace: 8,
  Key.Tab: 9,
  Key.Clear: 12,
  Key.Enter: 13,
  Key.Shift: 16,
  Key.Control: 17,
  Key.Alt: 18,
  Key.Pause: 19,
  Key.CapsLock: 20,
  Key.IMEKana: 21,
  Key.IMEJunja: 23,
  Key.IMEFinal: 24,
  Key.IMEHanja: 25,
  Key.Escape: 27,
  Key.IMEConvert: 28,
  Key.IMENonConvert: 29,
  Key.IMEAccept: 30,
  Key.IMEModeChange: 31,
  Key.Space: 32,
  Key.PageUp: 33,
  Key.PageDown: 34,
  Key.End: 35,
  Key.Home: 36,
  Key.LeftArrow: 37,
  Key.UpArrow: 38,
  Key.RightArrow: 39,
  Key.DownArrow: 40,
  Key.Select: 41,
  Key.Print: 42,
  Key.Execute: 43,
  Key.PrintScreen: 44,
  Key.Insert: 45,
  Key.Delete: 46,
  Key.Help: 47,
  Key.Key0: 48,
  Key.Key1: 49,
  Key.Key2: 50,
  Key.Key3: 51,
  Key.Key4: 52,
  Key.Key5: 53,
  Key.Key6: 54,
  Key.Key7: 55,
  Key.Key8: 56,
  Key.Key9: 57,
  Key.A: 65,
  Key.B: 66,
  Key.C: 67,
  Key.D: 68,
  Key.E: 69,
  Key.F: 70,
  Key.G: 71,
  Key.H: 72,
  Key.I: 73,
  Key.J: 74,
  Key.K: 75,
  Key.L: 76,
  Key.M: 77,
  Key.N: 78,
  Key.O: 79,
  Key.P: 80,
  Key.Q: 81,
  Key.R: 82,
  Key.S: 83,
  Key.T: 84,
  Key.U: 85,
  Key.V: 86,
  Key.W: 87,
  Key.X: 88,
  Key.Y: 89,
  Key.Z: 90,
  Key.LeftWindows: 91,
  Key.RightWindows: 92,
  Key.Applications: 93,
  Key.Sleep: 95,
  Key.NumPad0: 96,
  Key.NumPad1: 97,
  Key.NumPad2: 98,
  Key.NumPad3: 99,
  Key.NumPad4: 100,
  Key.NumPad5: 101,
  Key.NumPad6: 102,
  Key.NumPad7: 103,
  Key.NumPad8: 104,
  Key.NumPad9: 105,
  Key.NumPadMultiply: 106,
  Key.NumPadAdd: 107,
  Key.NumPadSeparator: 108,
  Key.NumPadSubtract: 109,
  Key.NumPadDecimal: 110,
  Key.NumPadDivide: 111,
  Key.F1: 112,
  Key.F2: 113,
  Key.F3: 114,
  Key.F4: 115,
  Key.F5: 116,
  Key.F6: 117,
  Key.F7: 118,
  Key.F8: 119,
  Key.F9: 120,
  Key.F10: 121,
  Key.F11: 122,
  Key.F12: 123,
  Key.F13: 124,
  Key.F14: 125,
  Key.F15: 126,
  Key.F16: 127,
  Key.F17: 128,
  Key.F18: 129,
  Key.F20: 130,
  Key.F21: 131,
  Key.F22: 132,
  Key.F23: 133,
  Key.F24: 134,
  Key.NumLock: 144,
  Key.ScrollLock: 145,
  Key.LeftShift: 160,
  Key.RightShift: 161,
  Key.LeftControl: 162,
  Key.RightControl: 163,
  Key.LeftAlt: 164,
  Key.RightAlt: 165,
  Key.BrowserBack: 166,
  Key.BrowserForward: 167,
  Key.BrowserRefresh: 168,
  Key.BrowserStop: 169,
  Key.BrowserSearch: 170,
  Key.BrowserFavorites: 171,
  Key.BrowserHome: 172,
  Key.BrowserMute: 173,
  Key.VolumeDown: 174,
  Key.VolumeUp: 175,
  Key.MediaNextTrack: 176,
  Key.MediaPreviousTrack: 177,
  Key.MediaStop: 178,
  Key.MediaPlay: 179,
  Key.StartMail: 180,
  Key.MediaSelect: 181,
  Key.LaunchApplication1: 182,
  Key.LaunchApplication2: 183,
  Key.Semicolon: 186,
  Key.Equals: 187,
  Key.Comma: 188,
  Key.Minus: 189,
  Key.Period: 190,
  Key.Slash: 191,
  Key.Grave: 192,
  Key.LeftBracket: 219,
  Key.BackSlash: 220,
  Key.RightBracket: 221,
  Key.Apostrophe: 222,
  Key.IMEProcess: 229,
}.toBiTable()

var keyStates: array[Key.low..Key.high, bool]
var keyBlockStates: array[Key.low..Key.high, bool]

proc windowsHook(code: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  var blockKeyPress = false

  if code == HC_ACTION:
    let p: PKBDLLHOOKSTRUCT = cast[PKBDLLHOOKSTRUCT](lParam)
    let keyCode = p.vkCode
    let keyIndex = keyCodeKeys[keyCode]

    blockKeyPress = keyBlockStates[keyIndex];

    if wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN:
      keyStates[keyIndex] = true

    elif wParam == WM_KEYUP or wParam == WM_SYSKEYUP:
      keyStates[keyIndex] = false

  if blockKeyPress:
    result = 1
  else:
    result = CallNextHookEx(0, code, wParam, lParam)

proc runHook*() {.async.} =
  SetWindowsHookEx(WH_KEYBOARD_LL, windowsHook, 0, 0)

  while true:
    var msg: LPMSG

    while PeekMessage(msg, 0, 0, 0, 0) != 0:
      TranslateMessage(msg)
      DispatchMessage(msg)

    await sleepAsync(1)

proc keyIsPressed*(key: Key): bool =
  keyStates[key]

proc keyIsBlocked*(key: Key): bool =
  keyBlockStates[key]

proc setKeyBlocked*(key: Key, state: bool) =
  keyBlockStates[key] = state

proc setAllKeysBlocked*(state: bool) =
  for key in Key:
    keyBlockStates[key] = state