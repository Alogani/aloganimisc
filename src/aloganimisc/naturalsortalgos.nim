import std/[algorithm, strutils, parseutils, unicode]

const allZeros = [48, 1632, 1776, 1984, 2406, 2534, 2662, 2790, 2918, 3046, 3174, 3302, 3430, 3558, 3664, 3792, 3872, 4160, 4240, 6112, 6160, 6470, 6608, 6784, 6800, 6992, 7088, 7232, 7248, 42528, 43216, 43264, 43472, 43504, 43600, 44016, 65296, 4170, 4307, 4358, 4367, 4371, 4381, 4399, 4421, 4429, 4453, 4460, 4467, 4494, 4501, 4549, 4565, 4570, 4597, 5798, 5804, 5813, 7548, 7549, 7550, 7550, 7551, 7700, 7727, 7759, 7829, 8127]

func toDigitImpl(r: Rune): int =
    let codePoint = ord(r)
    for z in allZeros:
        # not a binary search, because first runes are more common
        if codePoint >= z:
            return codePoint - z
    return -1

func isDigit*(r: Rune): bool =
    let digit = r.toDigitImpl()
    digit in {0..9}

func toDigit*(r: Rune): int =
    result = r.toDigitImpl()
    if result notin {0..9}:
        raise newException(RangeDefect, "rune is not a valid digit")

func cmpIgnoreCase(a, b: char): int =
    ord(toLowerAscii(a)) - ord(toLowerAscii(b))

func cmp(a, b: Rune): int =
    a.int - b.int

func cmpIgnoreCase(a, b: Rune): int =
    a.toLower().int - b.toLower().int

proc integerOutOfRangeError() {.noinline.} =
    raise newException(ValueError, "Parsed integer outside of valid range")

proc rawParseInt(s: openArray[Rune], b: var BiggestInt): int =
    var
        sign: BiggestInt = -1
        i = 0
    if i < s.len:
        if s[i] == '+'.Rune: inc(i)
        elif s[i] == '-'.Rune:
            inc(i)
            sign = 1
    
    if i < s.len:
        b = 0
        while i < s.len and (let c = toDigitImpl(s[i]); c in {0..9}):
            if b >= (low(BiggestInt) + c) div 10:
                b = b * 10 - c
            else:
                integerOutOfRangeError()
            inc(i)
            while i < s.len and s[i] == '_'.Rune: inc(i) # underscores are allowed and ignored
        if sign == -1 and b == low(BiggestInt):
            integerOutOfRangeError()
        else:
            b = b * sign
            result = i

func naturalSortImpl(l: openArray[string], ignoreCase: bool): seq[string] =
    let comparator: proc(a, b: char): int = if ignoreCase: cmpIgnoreCase else: cmp
    l.sorted(
        proc(a, b: string): int =
            var ai = 0
            var bi = 0
            while true:
                if ai > high(a) or bi > high(b):
                    return a.len() - ai - b.len() + bi
                if not (a[ai].isDigit() and b[bi].isDigit()):
                    let diff = comparator(a[ai], b[bi])
                    if diff != 0:
                        return diff
                    ai += 1; bi += 1
                else:
                    var
                        aNum: int
                        bNum: int
                    ai += parseInt(a[ai .. ^1], aNum)
                    bi += parseInt(b[bi .. ^1], bNum)
                    let diff = cmp(aNum, bNum)
                    if diff != 0:
                        return diff
    )

func naturalSort*(l: openArray[string]): seq[string] =
    naturalSortImpl(l, false)

func naturalSortIgnoreCase*(l: openArray[string]): seq[string] =
    naturalSortImpl(l, true)

func naturalSortImpl*(l: openArray[seq[Rune]], ignoreCase: bool): seq[seq[Rune]] =
    let comparator: proc(a, b: Rune): int = if ignoreCase: cmpIgnoreCase else: cmp
    l.sorted(
        proc(a, b: seq[Rune]): int =
            var ai = 0
            var bi = 0
            while true:
                if ai > high(a) or bi > high(b):
                    return a.len() - ai - b.len() + bi
                if not(a[ai].isDigit() and b[bi].isDigit()):
                    let diff = comparator(a[ai], b[bi])
                    if diff != 0:
                        return diff
                    ai += 1; bi += 1
                else:
                    var
                        aNum: Biggestint
                        bNum: Biggestint
                    ai += rawParseInt(a[ai .. ^1], aNum)
                    bi += rawParseInt(b[bi .. ^1], bNum)
                    let diff = cmp(aNum, bNum)
                    if diff != 0:
                        return diff
    )

func naturalSort*(l: openArray[seq[Rune]]): seq[seq[Rune]] =
    naturalSortImpl(l, false)

func naturalSortIgnoreCase*(l: openArray[seq[Rune]]): seq[seq[Rune]] =
    naturalSortImpl(l, true)