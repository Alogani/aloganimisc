import std/cmdline
import std/[os, paths, strutils, sequtils]
import mylib/sys
import mylib/asyncproc


let
    folderPath = Path(commandLineParams()[0])
    folderName = folderPath.extractFilename()
    importFilePath = folderPath.addFileExt("nim")
var files = waitFor sh.runGetLines(@["find", folderPath.string, "-type", "f", "-printf", "%P\n"], ProcArgsModifier(toRemove: {Interactive, ShowCommand}))
files = files.filter(proc(file: string): bool = not file.contains("private"))
files = files.naturalSort()

if fileExists(importFilePath.string):
    echo "Import file: " & importFilePath.string & "already exists. Do you want to remove it ? [y/n]"
    if stdin.readLine() != "y":
        raise newException(OsError, "Can't overwrite file")

let f = open(importFilePath.string, fmWrite)
for fileToImport in files:
    f.writeLine("import ./" & string(folderName / Path(fileToImport.changeFileExt(""))))
    f.writeLine("export " & Path(fileToImport).splitFile().name.string)
f.close()