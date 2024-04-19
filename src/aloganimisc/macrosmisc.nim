import std/macros
when defined(python):
    import nimpy

proc newRefOf*[T](val: T): ref T =
    result = new T
    result[] = val

template unref*[T](arg: typedesc[ref T]): untyped =
    ## Useful to get plain object type from ref without explicitly creating one
    T

macro forEachStmt*(modifierMacro: untyped, argsAndBody: varargs[untyped]): untyped =
    result = nnkStmtList.newTree()
    for stmtExpr in argsAndBody[^1].items():
        var callTree = nnkCall.newTree()
        callTree.add(ident(modifierMacro.repr))
        for arg in argsAndBody[0 ..< ^1]:
            callTree.add(arg)
        callTree.add(stmtExpr)
        result.add(callTree)

template expandFirst*(macroOrTemplateCall, body: untyped): untyped =
    # https://github.com/demotomohiro/littlesugar
    macro innerMacro(macroOrTemplateCallNimNode, inBody: untyped): untyped {.genSym.} =
        replaceRecursively(inBody, macroOrTemplateCallNimNode, getAst(macroOrTemplateCall))
    innerMacro(macroOrTemplateCall, body)

template exportMacro*(body: untyped) =
    when defined(python):
        exportpy(body)
    else:
        body

proc mapRecursively*(node: NimNode, applyFn: proc(n: NimNode): (NimNode, bool)): NimNode =
    let (newNode, hasBeenModified) = node.applyFn()
    if hasBeenModified:
        result = newNode
    else:
        result = node.copyNimNode()
        for child in node:
            result.add child.mapRecursively(applyFn)

proc replaceRecursively*(node, target, dest: NimNode): NimNode =
    # https://github.com/demotomohiro/littlesugar
    if node == target:
        result = dest.copyNimTree
    else:
        result = node.copyNimNode
        for n in node:
            result.add replaceRecursively(n, target, dest)
