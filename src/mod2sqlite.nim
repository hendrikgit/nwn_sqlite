import os, sequtils, streams, strutils
import neverwinter/[gff, key, resfile, resman, tlk]
import creature, db, helper

if paramCount() == 0:
  echo """
Please provide one or more directories or files as parameters.
All directories given will be searched for the following files:
.2da, .bif, .hak, .key, .tlk, .utc.

Subdirectories are ignored.

If one of the parameters is a module (.mod) file then it will
be checked that all ressources required by the module are found and
also read. Only one module at a time is valid.

A dialog.tlk and various .2da files will be needed as well,
add the path to them (or a directory with .key, .bif) as further parameters.

All .utc are read and their information will be written to the database
file in the "creatures" table. utc in bif files are ignored!

For now the database file is always called db.sqlite3.
Existing tables will be overwritten.
"""
  quit(QuitFailure)

let
  dataFiles = commandLineParams().getDataFiles
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

var cTlk: Option[SingleTlk]
let modFiles = dataFiles.filterIt it.endsWith(".mod")
if modFiles.len > 0:
  if modFiles.len > 1:
    echo "Only one .mod file at a time is supported: " & modFiles.join(", ")
    quit(QuitFailure)
  echo "Adding module: " & modFiles[0]
  let
    module = modFiles[0].getErf("MOD ")
    ifo = module[newResRef("module", "ifo".getResType)].get.readAll.newStringStream.readGffRoot
    cTlkName = ifo["Mod_CustomTlk", GffCExoString]
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
    if dataFiles.filterIt(it.endsWith(hakName)).len == 0:
      echo "Hak required by module not found: " & hakName
      quit(QuitFailure)
  rm.add(module)

for hak in dataFiles.filterIt it.endsWith(".hak"):
  echo "Adding hak: " & hak
  rm.add(hak.getErf("HAK "))

rm.addFiles(dataFiles, @[".2da", ".utc"])

var utcs = newSeq[ResRef]()
for container in rm.containers:
  # skip KeyTable, those are the base game resources
  if container of KeyTable: continue
  for rr in container.contents:
    if rr.resType == "utc".getResType:
      utcs &= rr

echo "\nCreatures (utc) found: " & $utcs.len
let creatures = utcs.creatureList(rm, dlg, cTlk)
creatures.writeTable("db.sqlite3", "creatures")
