import aloganimisc/naturalsortalgos {.all.}
import std/unittest

import std/[parseutils, unicode]


func toAsciiList(runesList: seq[seq[Rune]]): seq[string] =
    result = newSeqofCap[string](runesList.len())
    for sentence in runesList:
        result.add $sentence

func toRuneList(strList: seq[string]): seq[seq[Rune]] =
    result = newSeqofCap[seq[Rune]](strList.len())
    for sentence in strList:
        result.add sentence.toRunes()

func withRuneSort(strList: seq[string], ignoreCase: bool): seq[string] =
    if ignoreCase:
        strList.toRuneList().naturalSortIgnoreCase().toAsciiList()
    else:
        strList.toRuneList().naturalSort().toAsciiList()

test "parseInt":
    var resInt: BiggestInt
    check rawParseInt("12323dsdsd".toRunes(), resInt) == parseBiggestInt("12323dsdsd", resInt)
    check rawParseInt("fdf+34".toRunes(), resInt) == parseBiggestInt("fdf+34", resInt)
    check rawParseInt("-32lfd".toRunes(), resInt) == parseBiggestInt("-32lfd", resInt)
    check rawParseInt("+3sd2lfd".toRunes(), resInt) == parseBiggestInt("+3sd2lfd", resInt)

test "ascii sort":
    var l_ascii = @["d", "a", "cdrom1","cdrom10","cdrom102","cdrom11","cdrom2","cdrom20","cdrom3","cdrom30","cdrom4","cdrom40","cdrom100","cdrom101","cdrom103","cdrom110"]
    var solution = @["a", "cdrom1", "cdrom2", "cdrom3", "cdrom4", "cdrom10", "cdrom11", "cdrom20", "cdrom30", "cdrom40", "cdrom100", "cdrom101", "cdrom102", "cdrom103", "cdrom110", "d"]
    let sortedList_ascii = l_ascii.naturalSort()
    check sortedList_ascii == solution
    check l_ascii.withRuneSort(false) == sortedList_ascii

test "ascii sortInsenstive":
    var l_ascii = @["d", "a", "cDrom1","cdrom10","cdrOm102","cDrom11","cdrom2","cdroM20","cdROM3","cdrom30","CDrom4","cdrom40","cdrom100","cdrom101","cdrom103","cdrom110"]
    var solution = @["a", "cDrom1", "cdrom2", "cdROM3", "CDrom4", "cdrom10", "cDrom11", "cdroM20", "cdrom30", "cdrom40", "cdrom100", "cdrom101", "cdrOm102", "cdrom103", "cdrom110", "d"]
    let sortedList_ascii = l_ascii.naturalSortIgnoreCase()
    check sortedList_ascii == solution
    check l_ascii.withRuneSort(true) == sortedList_ascii

test "CornerCase1":
    check @["!a", "[b"].withRuneSort(false) == @["!a", "[b"]

test "Special characters":
    var strings = @["Héllo Wørld!", "Jåpånēsē 日本語", "Ça va bien.", "Привет, мир!", "Γειά σου κόσμε!", "مرحباً بالعالم!", "नमस्ते दुनिया!", "안녕하세요!", "שלום עולם!", "こんにちは世界!"]
    ## According to python:
    var solution = @["Héllo Wørld!", "Jåpånēsē 日本語", "Ça va bien.", "Γειά σου κόσμε!", "Привет, мир!", "שלום עולם!", "مرحباً بالعالم!", "नमस्ते दुनिया!", "こんにちは世界!", "안녕하세요!"]
    check strings.withRuneSort(false) == solution
    check strings.withRuneSort(true) == solution
    check strings.naturalSort() == solution

test "Special characters and nums":
    var strings = @["日本10語", "日本1043語", "日本104343語", "日本2語", "日本20語"]
    var solution = @["日本2語", "日本10語", "日本20語", "日本1043語", "日本104343語"]
    check strings.withRuneSort(false) == solution
    check strings.withRuneSort(true) == solution

