import threadpool
import os
import times
import kbdinput

proc main =
  setAllKeysBlocked(true)

  spawn runHook()

  let pollDuration = initDuration(milliseconds = 1)
  while true:
    let timeOfNextLoop = getTime() + pollDuration

    echo keyIsPressed(Key.A)

    let now = getTime()
    if timeOfNextLoop > now:
      sleep (timeOfNextLoop - now).inMilliseconds.int

  sync()

main()