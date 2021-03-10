import os
import times
import asyncdispatch
import kbdinput
import vjoy


proc main() {.async.} =
  while true:
    echo keyIsPressed(Key.A)

    await sleepAsync(1)

setAllKeysBlocked(true)

asyncCheck runHook()

waitFor main()