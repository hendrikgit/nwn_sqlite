import os, sequtils, streams, strutils
import neverwinter/[erf, gff, key, resfile, resman, resmemfile, tlk, twoda]
import creature, db, helper

if paramCount() < 2:
  echo """
First parameter: A module file.
All other paramters: Directories that will be searched for
.key, .bif, .hak and .tlk files.

At least one directory is required. Please make sure a dialog.tlk
and all files the module requires are in the directories you
provided as parameters.
"""
  quit(QuitFailure)

echo "Module: " & paramStr(1)
if not paramStr(1).fileExists:
  echo "Module file not found."
  quit(QuitFailure)

let
  module = paramStr(1).getErf("MOD ")
  dataFiles = commandLineParams()[1 .. ^1].getDataFiles
  palcusNames = [
    "creaturepalcus",
    #"itempalcus",
    #"placeablepalcus",
  ]
  rm = newResMan() # container added last to resman will be queried first

let dlgPath = dataFiles.findIt it.endsWith("dialog.tlk")
if dlgPath.isSome:
  echo "Adding dialog.tlk: " & dlgPath.get
  rm.add(dlgPath.get.newResFile)
else:
  echo "dialog.tlk not found"
  quit(QuitFailure)
let dlg = rm[newResRef("dialog", "tlk".getResType)].get.readAll.newStringStream.readSingleTlk

for key in dataFiles.filterIt it.endsWith(".key"):
  echo "Adding key: " & key
  let keytable = key.openFileStream.readKeyTable(key, proc (fn: string): Stream =
    let bif = dataFiles.findIt it.endsWith(fn)
    if bif.isSome:
      bif.get.openFileStream
    else:
      echo "File referenced by key not found: " & fn
      quit(QuitFailure)
  )
  rm.add(keytable)

let ifo = module[newResRef("module", "ifo".getResType)].get.readAll.newStringStream.readGffRoot

let cTlkName = ifo["Mod_CustomTlk", GffCExoString]
var cTlk: Option[SingleTlk]
if cTlkName != "":
  let tlk = dataFiles.findIt it.endsWith(cTlkName & ".tlk")
  if tlk.isSome:
    echo "Adding custom tlk: " & cTlkName & ".tlk"
    cTlk = some tlk.get.openFileStream.readSingleTlk
  else:
    echo "Custom tlk file required by module not found: " & cTlkName & ".tlk"
    quit(QuitFailure)

for hak in ifo["Mod_HakList", GffList]:
  let hakName = hak["Mod_Hak", GffCExoString] & ".hak"
  let hak = dataFiles.findIt it.endsWith(hakName)
  if hak.isSome:
    echo "Hak: " & hakName
    let hakErf = hak.get.getErf("HAK ")
    for rr in hakErf.contents:
      if rr.resType == "2da".getResType:
        let content = hakErf[rr].get.readAll
        echo "  " & $rr
        rm.add content.newStringStream.newResMemFile(rr, content.len, $rr)
  else:
    echo "Hak required by module not found: " & hakName
    quit(QuitFailure)

let classes2da = if rm.contains(newResRef("classes", "2da".getResType)):
  rm[newResRef("classes", "2da".getResType)].get.readAll.newStringStream.readTwoDA
else:
  echo "classes.2da not found"
  quit(QuitFailure)

proc getGffRoot(resref, restype: string): GffRoot =
  getGffRoot(resref, restype, module, rm)

for palcus in palcusNames:
  echo palcus
  let
    itpGffRoot = palcus.getGffRoot("itp")
    list = itpGffRoot["MAIN", GffList].flatten
  case palcus
  of "creaturepalcus":
    let creatures = list.creatureList(module, rm, dlg, cTlk, classes2da)
    echo "Entries: " & $creatures.len
    let dbfilename = palcus & ".sqlite3"
    echo "Writing sqlite db file: " & dbfilename
    creatures.writeDb(dbfilename, palcus)
