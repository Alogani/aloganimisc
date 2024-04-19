type
    DiffKind* = enum
        Added, Deleted, Changed

    LineDiff* = object
        lineA*: int
        lineB*: int
        case kind*: DiffKind
        of Changed:
            added: seq[string]
            deleted: seq[string]
        else:
            content*: seq[string]

proc getLineStr(line: int, len: int): string =
    if len == 1:
        $(line + 1)
    else:
        $(line + 1) & "," & $(line + len)

proc pretty*(lineDiff: LineDiff): string =
    result.add (
        if lineDiff.kind == Added: $lineDiff.lineA & "a" & getLineStr(lineDiff.lineB, lineDiff.content.len())
        elif lineDiff.kind == Deleted: getLineStr(lineDiff.lineA, lineDiff.content.len()) & "d" & $lineDiff.lineB
        else: (let len = lineDiff.deleted.len(); getLineStr(lineDiff.lineA, len) & "c" & getLineStr(lineDiff.lineB, len))
    )
    if lineDiff.kind == Added or lineDiff.kind == Changed:
        for line in (if lineDiff.kind == Changed: lineDiff.added else: lineDiff.content):
            result.add "\n> " & line
    if lineDiff.kind == Changed:
        result.add "\n---"
    if lineDiff.kind == Deleted or lineDiff.kind == Changed:
        for line in (if lineDiff.kind == Changed: lineDiff.deleted else: lineDiff.content):
            result.add "\n< " & line



iterator countupPairs(maxA, maxB: int): (int, int) =
    var
        ia = 0
        ib = 0
    while ia < maxA and ib < maxB:
        yield (ia, ib)
        if ia == ib + 1:
            ia = 0
            ib += 1
        elif ia == ib:
            ia += 1
            ib = 0
        elif ia < ib:
            ia += 1
        else:
            ib += 1

proc diffLines*(a, b: seq[string]): seq[LineDiff] =
    ## Naive approach, but memory O(1), and complexity between O(m + n) to O(m * n) depending on the number of modifications
    ## This is not based on longest common subsequence, so it might have different results
    var
        ia = 0
        ib = 0
    block outer:
        while true:
            for (ja, jb) in countupPairs(high(int), high(int)):
                if ia + ja >= a.len() or ib + jb >= b.len():
                    if ia + ja >= a.len() and ib + jb >= b.len():
                        break outer
                    else:
                        continue
                if a[ia + ja] == b[ib + jb]:
                    let minDiff = min(ja, jb)
                    if minDiff > 0:
                        result.add LineDiff(lineA: ia, lineB: ib, kind: Changed, added: a[ia ..< ia + minDiff], deleted: b[ib ..< ib + minDiff])
                    if ja > minDiff:
                        result.add LineDiff(lineA: ia + minDiff, lineB: ib + minDiff, kind: Deleted, content: a[ia + minDiff ..< ia + ja - minDiff])
                    elif jb > minDiff:
                        result.add LineDiff(lineA: ia + minDiff, lineB: ib + minDiff, kind: Added, content: b[ib + minDiff ..< ib + jb - minDiff])
                    ia += ja + 1
                    ib += jb + 1
                    break
    let
        ja = a.len() - ia
        jb = b.len() - ib
        minDiff = max(0, min(ja, jb))
    if minDiff > 0:
        result.add LineDiff(lineA: ia, lineB: ib, kind: Changed, added: a[ia ..< ia + minDiff], deleted: b[ib ..< ib + minDiff])
    if ja > minDiff:
        result.add LineDiff(lineA: ia + minDiff, lineB: ib + minDiff, kind: Deleted, content: a[ia + minDiff ..< ia + ja - minDiff])
    elif jb > minDiff:
        result.add LineDiff(lineA: ia + minDiff, lineB: ib + minDiff, kind: Added, content: b[ib + minDiff ..< ib + jb - minDiff])


