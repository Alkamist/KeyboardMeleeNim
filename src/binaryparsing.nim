type Buffer = string | seq[uint8]

{.push inline.}

func swap*(value: uint8): uint8 =
  value

func swap*(value: uint16): uint16 =
  let tmp = cast[array[2, uint8]](value)
  (tmp[0].uint16 shl 8) or tmp[1].uint16

func swap*(value: uint32): uint32 =
  let tmp = cast[array[2, uint16]](value)
  (swap(tmp[0]).uint32 shl 16) or swap(tmp[1])

func swap*(value: uint64): uint64 =
  let tmp = cast[array[2, uint32]](value)
  (swap(tmp[0]).uint64 shl 32) or swap(tmp[1])

func swap*(value: int16): int16 =
  cast[int16](cast[uint16](value).swap())

func swap*(value: int32): int32 =
  cast[int32](cast[uint32](value).swap())

func swap*(value: int64): int64 =
  cast[int64](cast[uint64](value).swap())

func maybeSwap*[T](value: T, enable: bool): T =
  if enable:
    value.swap()
  else:
    value

func readUint8*(buffer: Buffer, location: int): uint8 =
  buffer[location].uint8

func readUint16*(buffer: Buffer, location: int): uint16 =
  cast[ptr uint16](buffer[location].unsafeAddr)[].maybeSwap(cpuEndian == littleEndian)

func readUint32*(buffer: Buffer, location: int): uint32 =
  cast[ptr uint32](buffer[location].unsafeAddr)[].maybeSwap(cpuEndian == littleEndian)

func readUint64*(buffer: Buffer, location: int): uint64 =
  cast[ptr uint64](buffer[location].unsafeAddr)[].maybeSwap(cpuEndian == littleEndian)

func readInt8*(buffer: Buffer, location: int): int8 =
  cast[int8](buffer.readUint8(location)).maybeSwap(cpuEndian == littleEndian)

func readInt16*(buffer: Buffer, location: int): int16 =
  cast[int16](buffer.readUint16(location)).maybeSwap(cpuEndian == littleEndian)

func readInt32*(buffer: Buffer, location: int): int32 =
  cast[int32](buffer.readUint32(location)).maybeSwap(cpuEndian == littleEndian)

func readInt64*(buffer: Buffer, location: int): int64 =
  cast[int64](buffer.readUint64(location)).maybeSwap(cpuEndian == littleEndian)

func readFloat32*(buffer: Buffer, location: int): float32 =
  cast[float32](buffer.readUint32(location)).maybeSwap(cpuEndian == littleEndian)

func readFloat64*(buffer: Buffer, location: int): float64 =
  cast[float64](buffer.readUint64(location)).maybeSwap(cpuEndian == littleEndian)

{.pop.}