import encodings, os, sequtils, streams, strformat, strutils
import neverwinter/[gff, key, resfile, resman, tlk, util]
import area, creature, db, helper, item, placeable

const version = getEnv("VERSION")

let paths = commandLineParams().filterIt(not it.startsWith("-"))
if paths.len == 0 or not commandLineParams().anyIt it.startsWith("-o:"):
  echo &"""
(Version: {version})
Please provide one or more directories or files as parameters.
Subdirectories are ignored.

File types that will be read (directly or in a directory):
{dataFileExtensions.join(", ")}

A dialog.tlk and various .2da files will be needed,
add the path to them (or a directory with .key, .bif) as further parameters.

Use:
  -o:dbname.sqlite3        to specify the name of the output database file.
  -e:encoding              to specify the encoding of the input
                           (for example "cp1251" for Cyrillic)

Existing tables will be overwritten.
"""
  quit(QuitFailure)

let
  dbName = commandLineParams().findIt(it.startsWith("-o:")).get[3 .. ^1]
  encodingParam = commandLineParams().findIt(it.startsWith("-e:"))
  dataFiles = paths.getDataFiles
  rm = newResMan() # container added last to resman will be queried first

if encodingParam.isSome:
  let encoding = encodingParam.get[3 .. ^1]
  # try encoding here so a more helpful error message can be given
  try:
    discard convert("test", srcEncoding = encoding)
  except:
    echo "Error with the chosen encoding: " & encoding
    quit(QuitFailure)
  setNwnEncoding(encoding)

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
  let module = modFiles[0].getErf("MOD ")
  let modRes = module[newResRef("module", "ifo".getResType)]
  if modRes.isNone:
    echo "Error: module.ifo not found in module. The file might be corrupt."
    quit(QuitFailure)
  let ifo = modRes.get.readAll.newStringStream.readGffRoot
  let cTlkName = ifo["Mod_CustomTlk", GffCExoString]
  if cTlkName.len > 0:
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

rm.addFiles(dataFiles, @[".2da", ".are", ".git", ".utc", ".uti", ".utp"])

var
  ares = newSeq[ResRef]()
  utcs = newSeq[ResRef]()
  utis = newSeq[ResRef]()
  utps = newSeq[ResRef]()
for container in rm.containers:
  # skip KeyTable, those are the base game resources
  if container of KeyTable: continue
  for rr in container.contents:
    let restype = rr.resType
    if restype == "are".getResType:
      ares &= rr
    if restype == "utc".getResType:
      utcs &= rr
    elif restype == "uti".getResType:
      utis &= rr
    elif restype == "utp".getResType:
      utps &= rr

echo "\nCreatures (utc) found: " & $utcs.len
let creatures = utcs.creatureList(rm, dlg, cTlk)
creatures.writeTable(dbName, "creatures")

echo "\nItems (uti) found: " & $utis.len
let items = utis.itemList(rm, dlg, cTlk)
items.writeTable(dbName, "items")

echo "\nPlaceables (utp) found: " & $utps.len
let placeables = utps.placeableList(rm, dlg, cTlk)
placeables.writeTable(dbName, "placeables")

echo "\nAreas (are) found: " & $ares.len
let areas = ares.areaList(rm, dlg, cTlk)
areas.writeTable(dbName, "areas")
