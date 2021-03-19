proc readUint8*(input: string, location: int): uint8 {.inline.} =
  input[location].uint8

proc readUint16*(input: string, location: int): uint16 {.inline.} =
  result = cast[ptr uint16](input[location].unsafeAddr)[]