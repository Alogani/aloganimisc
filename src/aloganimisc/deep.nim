import std/[tables, sets]

func deepEqualImpl[T](a, b: T, alreadyCompared: var HashSet[(pointer, pointer)]): bool =
    result = true
    when a is seq or a is array:
        for i in 0..high(a):
            if not deepEqualImpl(a[i], b[i], alreadyCompared):
                return false
    elif a is cstringArray:
        # Must be nil terminated
        var L = 0
        while a[L] != nil: inc(L)
        let rawSize = L * sizeof(cstring)
        if cmpMem(a, b, rawSize) != 0:
            return false
    elif a is pointer:
        ## Don't be ambigous even if both have same addr or are nil
        error("Can't compare pointer of unknown size")
    elif a is ref or a is ptr:
        if a == nil or b == nil:
            return a == b
        else:
            let ptrTuple = (cast[pointer](a), cast[pointer](b))
            if ptrTuple in alreadyCompared:
                return true
            else:
                alreadyCompared.incl ptrTuple
                result = deepEqualImpl(a[], b[], alreadyCompared)
    elif a is object or a is tuple:
        for name, v1, v2 in fieldPairs(a, b):
            if not deepEqualImpl(v1, v2, alreadyCompared):
                return false
    else:
        return a == b


func deepEqual*[T](a, b: T): bool =
    ## Check values recursively
    ## Ignore References/adresse inequality
    var alreadyCompared: HashSet[(pointer, pointer)]
    deepEqualImpl(a, b, alreadyCompared)


proc deepCopyImpl[T](dest: var T; src: T, alreadyCopied: var Table[pointer, pointer]) =
    # An optimisation could be made if it is possible to have the info about if object is acyclic (compiler knows it ?)
    when src is seq or src is array:
        dest = src
        for i in 0..high(src):
            deepCopyImpl(dest[i], src[i], alreadyCopied)
    elif src is cstringArray:
        # Must be nil terminated
        var L = 0
        while src[L] != nil: inc(L)
        let rawSize = L * sizeof(cstring)
        dest = cast[cstringArray](alloc(rawSize))
        copyMem(dest, src, rawSize)
    elif src is pointer:
        error("Can't copy pointer of unknown size")
    elif src is ref or src is ptr:
        if src != nil:
            let
                srcPtr = cast[pointer](src)
                associatedDest = alreadyCopied.getOrDefault(srcPtr, nil)
            if associatedDest != nil:
                when src is ptr:
                    dest = cast[T](associatedDest)
                else:
                    dest = new T
                    dest[] = cast[T](associatedDest)[]
            else:
                when src is ptr:
                    dest = cast[T](alloc(sizeof(src)))
                else:
                    dest = new T
                alreadyCopied[srcPtr] = cast[pointer](dest)
                dest[] = src[]
                deepCopyImpl(dest[], src[], alreadyCopied)
    elif src is object or src is tuple:
        for _, v1, v2 in fieldPairs(dest, src):
            deepCopyImpl(v1, v2, alreadyCopied)
    else:
        # cstring is copied here
        dest = src

proc deepCopy*[T](dest: var T; src: T) =
    ## This procedure copies values and create new object for references
    ## Also copies typed pointer, so unmanaged memory is unsafe if pointer is not wrapped into an object with a destructor
    # Should behave exactly like system.deepCopy
    dest = src
    var alreadyCopied: Table[pointer, pointer]
    deepCopyImpl(dest, src, alreadyCopied)