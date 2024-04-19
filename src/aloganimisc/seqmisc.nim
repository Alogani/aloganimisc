import std/[algorithm, strutils, parseutils]

proc find_nth*[T, S](a: T, item: S, nth: int): int =
    var count: int
    for i, x in a:
        if x == item:
            if nth == count:
                return i
            count += 1
    return -1

proc flatten*[T](a: seq[seq[T]]): seq[T] =
    var aFlat = newSeq[T](0)
    for subseq in a:
        aFlat &= subseq
    return aFlat

proc naturalSort*(l: openArray[string]): seq[string] =
    l.sorted(
        proc(a, b: string): int =
            var ai = 0
            var bi = 0
            while true:
                if ai > high(a) or bi > high(b):
                    return a.len() - ai - b.len() + bi
                if not (a[ai].isDigit() and b[bi].isDigit()):
                    let diff = cmp(a[ai], b[bi])
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