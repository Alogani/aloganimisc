import std/strutils

proc head*(count: int, data: string): string
proc tail*(count: int, data: string): string


proc head*(count: int, data: string): string =
    let lines = data.splitLines()
    result = lines[0 ..< min(count, lines.len())].join("\n")

proc tail*(count: int, data: string): string =
    let lines = data.splitLines()
    let addOne = lines[^1] == ""
    result = lines[^min(if addOne: count + 1 else: count, lines.len()) .. ^1].join("\n")

template ternary*(predicate: bool, valueIfTrue: string, valueIfFalse = ""): string =
    ## Optional valueIfFalse
    if predicate:
        valueIfTrue
    else:
        valueIfFalse