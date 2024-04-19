import std/math

proc rounddiv*(x, y: int): int =
    let (q, r) = divmod(x, y)
    if 2 * r >= y:
        q + 1
    else:
        q