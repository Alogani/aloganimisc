import std/[math, parseutils]
import mylib/math

type
    StorageSize* = distinct int

    StorageUnit* = enum
        None, B, kB, MB, GB, TB

converter intToStorage*(x: int): StorageSize =
    StorageSize(x)

proc `*`*(x: StorageSize, y: int): StorageSize {.borrow.}
proc `*`*(x: int, y: StorageSize): StorageSize {.borrow.}
proc `+`*(x, y: StorageSize): StorageSize {.borrow.}
proc `/`*(x: StorageSize, y: int): StorageSize = x.int div y
proc `/`*(x, y: StorageSize): float = x.int / y.int
proc `div`*(x, y: StorageSize): int = rounddiv(x.int, y.int)

proc B*(size: int): StorageSize = StorageSize(size)
proc kB*(size: int): StorageSize = StorageSize(size * 2 ^ 10)
proc MB*(size: int): StorageSize = StorageSize(size * 2 ^ 20)
proc GB*(size: int): StorageSize = StorageSize(size * 2 ^ 30)
proc TB*(size: int): StorageSize = StorageSize(size * 2 ^ 40)
proc B*(size: float): StorageSize = StorageSize(int(size))
proc kB*(size: float): StorageSize = StorageSize(int(size * pow(2.0, 10.0)))
proc MB*(size: float): StorageSize = StorageSize(int(size * pow(2.0, 20.0)))
proc GB*(size: float): StorageSize = StorageSize(int(size * pow(2.0, 30.0)))
proc TB*(size: float): StorageSize = StorageSize(int(size * pow(2.0, 40.0)))

proc roundToStr(val: float, signifiantDigits: int): string =
    var rounded = round(val, signifiantDigits)
    if rounded == round(rounded, 0):
        $(int(rounded))
    else:
        $rounded

proc toString*(size: Storagesize, inUnit: StorageUnit = None, signifiantDigits = 2, suffix = "iB", decimal=false): string =
    if inUnit == None:
        if decimal:
            case int(size):
            of 0 .. 10 ^ 3 - 1:
                $int(size)
            of 10 ^ 3 .. 10 ^ 6 - 1:
                roundToStr(size.float / pow(10.0, 3.0), signifiantDigits) & "k" & suffix
            of 10 ^ 6 .. 10 ^ 9 - 1:
                roundToStr(size.float / pow(10.0, 6.0), signifiantDigits) & "M" & suffix
            of 10 ^ 9 .. 10 ^ 12 - 1:
                roundToStr(size.float / pow(10.0, 9.0), signifiantDigits) & "G" & suffix
            else:
                roundToStr(size.float / pow(10.0, 12.0), signifiantDigits) & "T" & suffix
        else:
            case int(size):
            of 0 .. int(1.kB) - 1:
                $int(size)
            of int(1.kB) .. int(1.MB) - 1:
                roundToStr(size.float / 1.kB.float, signifiantDigits) & "k" & suffix
            of int(1.MB) .. int(1.GB) - 1:
                roundToStr(size.float / 1.MB.float, signifiantDigits) & "M" & suffix
            of int(1.GB) .. int(1.TB) - 1:
                roundToStr(size.float / 1.GB.float, signifiantDigits) & "G" & suffix
            else:
                roundToStr(size.float / 1.TB.float, signifiantDigits) & "T" & suffix
    else:
        if decimal:
            case inUnit:
            of B:
                $int(size)
            of kB:
                roundToStr(size.float / pow(10.0, 3.0), signifiantDigits) & "k" & suffix
            of MB:
                roundToStr(size.float / pow(10.0, 6.0), signifiantDigits) & "M" & suffix
            of GB:
                roundToStr(size.float / pow(10.0, 9.0), signifiantDigits) & "G" & suffix
            else:
                roundToStr(size.float / pow(10.0, 12.0), signifiantDigits) & "T" & suffix
        else:
            case inUnit:
            of B:
                $int(size)
            of kB:
                roundToStr(size.float / 1.kB.float, signifiantDigits) & "k" & suffix
            of MB:
                roundToStr(size.float / 1.MB.float, signifiantDigits) & "M" & suffix
            of GB:
                roundToStr(size.float / 1.GB.float, signifiantDigits) & "G" & suffix
            else:
                roundToStr(size.float / 1.TB.float, signifiantDigits) & "T" & suffix


proc parseSize*(str: string, decimal = false): StorageSize =
    if '.' in str:
        var num: BiggestFloat
        let count = parseBiggestFloat(str, num)
        if count == 0:
            raise newException(ValueError, "No number found")
        if str.len() == count or str[count] == 'B':
            return num.B
        case str[count ..< count + 2]:
        of "kB", "KiB":
            return if decimal: num.B * 10 ^ 3 else: num.kB
        of "MB", "MiB":
            return if decimal: num.B * 10 ^ 6 else: num.MB
        of "GB", "GiB":
            return if decimal: num.B * 10 ^ 9 else: num.GB
        of "TB", "TiB":
            return if decimal: num.B * 10 ^ 12 else: num.TB
        else:
            raise newException(ValueError, "No number found")
    else:
        var num: BiggestInt
        let count = parseBiggestInt(str, num)
        if count == 0:
            raise newException(ValueError, "No number found")
        if str.len() == count or str[count] == 'B':
            return num.B
        case str[count ..< count + 2]:
        of "kB", "KiB":
            return if decimal: num.B * 10 ^ 3 else: num.kB
        of "MB", "MiB":
            return if decimal: num.B * 10 ^ 6 else: num.MB
        of "GB", "GiB":
            return if decimal: num.B * 10 ^ 9 else: num.GB
        of "TB", "TiB":
            return if decimal: num.B * 10 ^ 12 else: num.TB
        else:
            raise newException(ValueError, "No number found")