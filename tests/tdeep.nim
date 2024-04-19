import aloganimisc/deep

import std/[sets, strtabs, tables, sequtils]
import std/unittest

var initIncrement = 1


test "Acyclic data structure":
    type
        TestEnum = enum
            AEnum, BEnum, CEnum

        TestRef = ref object
            field1: int

        TestObj = object
            refField: TestRef

        MainRef = ref object
            intField: int
            strField: string
            cstrField: cstring
            tupleField: (TestObj, string)
            setField: set[TestEnum]
            objField: TestObj
            refField: TestRef
            nilField: TestRef
            arrayField: array[1, TestObj]
            seqField: seq[TestObj]
            strtabField: StringTableRef
            tableField: Table[string, TestRef]
            stringSeq: seq[string]
            cstrArray: cstringArray
            nilPtr: TestRef
            intRef: ref int
            intPtr: ptr int
            strRef: ref string
            strPtr: ptr string


    proc new(T: type TestRef): T =
        result = TestRef(field1: initIncrement)
        initIncrement += 1

    proc init(T: type TestObj): T =
        result = TestObj(refField: TestRef.new())

    proc new(T: type MainRef): T =
        var
            strVal = "Hello"
            stringSeq = @["World"]
            intRef = new int
            strRef = new string
        intRef[] = 5
        strRef[] = "from nim"
        result = MainRef(
            intField: 42,
            strField: strVal,
            cstrField: strVal.cstring,
            tupleField: (TestObj.init(), "tuple"),
            setField: { AEnum, BEnum },
            objField: TestObj.init(),
            refField: TestRef.new(),
            nilField: nil,
            arrayField: [TestObj.init()],
            seqField: @[TestObj.init()],
            strtabField: {"KEY": "VALUE"}.newStringTable(),
            tableField: {"KEY": TestRef.new()}.toTable(),
            stringSeq: stringSeq,
            cstrArray: allocCStringArray(stringSeq),
            nilPtr: nil,
            intRef: intRef,
            intPtr: cast[ptr int](intRef),
            strRef: strRef,
            strPtr: cast[ptr string](strRef),
        )

    
    proc compare(a, b: TestRef) =
        check a != b
        check a.field1 == b.field1

    proc compare(a, b: TestObj) =
        check a != b # Because contains a ref field
        compare(a.refField, b.refField)

    proc compare(a, b: MainRef) =
        var key: string
        check a.intField == b.intField
        check addr(a.strField) != addr(b.strField)
        check a.strField == b.strField
        check addr(a.cstrField) != addr(b.cstrField)
        check a.cstrField == b.cstrField 
        compare(a.tupleField[0], b.tupleField[0])
        check a.tupleField[1] == b.tupleField[1]
        check a.setField == b.setField
        compare(a.objField, b.objField)
        compare(a.refField, b.refField)
        check a.nilField == nil
        check b.nilField == nil
        compare(a.arrayField[0], b.arrayField[0])
        compare(a.seqField[0], b.seqField[0])
        check a.strtabField.len() > 0
        key = a.strtabField.keys().toSeq()[0]
        check a.strtabField[key] == b.strtabField[key]
        check a.tableField.len() > 0
        key = a.tableField.keys().toSeq()[0]
        check a.tableField[key] != b.tableField[key]
        check a.cstrArray != b.cstrArray # Fail with system.deepCopy(). Not copied ?
        check a.cstrArray[0] == b.cstrArray[0]
        check a.nilPtr == nil
        check b.nilPtr == nil
        check a.intRef != b.intRef
        check a.intRef[] == b.intRef[]
        check cast[int](a.intPtr) != cast[int](b.intPtr) # Fail with system.deepCopy() -> same address
        check a.intPtr[] == b.intPtr[] 
        check a.strRef != b.strRef
        check a.strRef[] == b.strRef[]
        check cast[int](a.strPtr) != cast[int](b.strPtr) # Fail with system.deepCopy() -> same address
        check a.strPtr[] == b.strPtr[]
    
    let a = MainRef.new()
    var b: MainRef
    when false: # use --deepcopy:on and set to true
        runBench("system"):
            system.deepCopy(b, a)
        compare(a, b)
        b = nil
    deep.deepCopy(b, a)
    compare(a, b)
    check deep.deepEqual(a, b)


test "Cyclic data structure":
    type Node = ref object
        last {.cursor.}: Node
        next: Node
        data: int

    proc main() =
        for i in 0..100:
            var a = Node()
            a.last = a
            a.next = a
            for i in 0..10:
                var n = Node()
                a.last.next = n
                n.next = a

            var aCopy: Node
            deep.deepCopy(aCopy, a)
            check aCopy.data == a.data
            check aCopy.next.data == a.next.data
            check aCopy.next.next.data == a.next.next.data
            check aCopy.next.next.next.data == a.next.next.next.data
            check deep.deepEqual(aCopy, a)
            aCopy.data = 42
            check not deep.deepEqual(aCopy, a)
    main()

#[
## From https://github.com/nim-lang/Nim/blob/version-2-0/tests/system/tdeepcopy.nim

discard """
  matrix: "--mm:refc; --mm:orc --deepcopy:on"
  output: "ok"
"""

import lists #tables, lists


type
  ListTable[K, V] = object
    valList: DoublyLinkedList[V]
    table: Table[K, DoublyLinkedNode[V]]

  ListTableRef*[K, V] = ref ListTable[K, V]

proc initListTable*[K, V](initialSize = 64): ListTable[K, V] =
  result.valList = initDoublyLinkedList[V]()
  result.table = initTable[K, DoublyLinkedNode[V]]()

proc newListTable*[K, V](initialSize = 64): ListTableRef[K, V] =
  new(result)
  result[] = initListTable[K, V](initialSize)

proc `[]=`*[K, V](t: var ListTable[K, V], key: K, val: V) =
  if key in t.table:
    t.table[key].value = val
  else:
    let node = newDoublyLinkedNode(val)
    t.valList.append(node)
    t.table[key] = node

proc `[]`*[K, V](t: ListTable[K, V], key: K): var V {.inline.} =
  result = t.table[key].value

proc len*[K, V](t: ListTable[K, V]): Natural {.inline.} =
  result = t.table.len

iterator values*[K, V](t: ListTable[K, V]): V =
  for val in t.valList.items():
    yield val

proc `[]=`*[K, V](t: ListTableRef[K, V], key: K, val: V) =
  t[][key] = val

proc `[]`*[K, V](t: ListTableRef[K, V], key: K): var V {.inline.} =
  t[][key]

proc len*[K, V](t: ListTableRef[K, V]): Natural {.inline.} =
  t[].len

iterator values*[K, V](t: ListTableRef[K, V]): V =
  for val in t[].values:
    yield val

proc main() =
    type SomeObj = ref object

    for outer in 0..1:
        let myObj = new(SomeObj)
        let table = newListTable[int, SomeObj]()

        table[0] = myObj
        for i in 1..10_000:
            table[i] = new(SomeObj)

        var myObj2: SomeObj
        for val in table.values():
            if myObj2.isNil:
                myObj2 = val
        doAssert(myObj == myObj2) # passes
        #doAssert deepEqual(myObj, myObj2)

        var tableCopy: ListTableRef[int, SomeObj]
        deep.deepCopy(tableCopy, table)

        let myObjCopy = tableCopy[0]
        var myObjCopy2: SomeObj = nil
        for val in tableCopy.values():
            if myObjCopy2.isNil:
                myObjCopy2 = val

        #echo cast[int](myObj)
        #echo cast[int](myObjCopy)
        #echo cast[int](myObjCopy2)

        doAssert(myObjCopy == myObjCopy2) # passes
        #doAssert deepEqual(myObjCopy, myObjCopy2)


main()
echo "ok"
]#