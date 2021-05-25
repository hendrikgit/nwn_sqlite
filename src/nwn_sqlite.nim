import encodings, os, sequtils, streams, strformat, strutils, sugar
import neverwinter/[gff, key, resman, tlk, twoda, util]
import area, creature, db, encounter, helper, item, placeable, restables

const version = getEnv("VERSION")

const usage = &"""
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
                           (for example "cp1251" for Cyrillic).
  -withkey                 to include the resources indexed by .key files in the output.
  -2da:filename.2da        to create a table with the contents of that 2da file,
                           this paramneter can be used multiple times.
  -2daonly                 only create tables for files specified by -2da: parameters.

Existing tables will be overwritten.
"""

let paths = commandLineParams().filterIt(not it.startsWith("-"))
let twodaOnly = commandLineParams().findItIdx(it == "-2daonly") != -1
if not commandLineParams().anyIt it.startsWith("-o:"):
  echo usage
  echo "Error: Missing \"-o:\" parameter"
  quit(QuitFailure)
if paths.len == 0 and not twodaOnly:
  echo usage
  echo "Error: No files given as parameters"
  quit(QuitFailure)

let
  dbName = commandLineParams().findIt(it.startsWith("-o:")).get[3 .. ^1].expandTilde
  encodingParam = commandLineParams().findIt(it.startsWith("-e:"))
  withKey = commandLineParams().findItIdx(it == "-withkey") != -1
  twodasParams = commandLineParams().filterIt(it.startsWith("-2da:")).mapIt(it[5 .. ^1].expandTilde)
  dataFiles = paths.getDataFiles
  rm = newResMan() # container added last to resman will be queried first

for twodaFn in twodasParams:
  if not twodaFn.fileExists:
    echo "File from \"-2da:\" parameter not found: " & twodaFn
  else:
    let
      twoda = twodaFn.newFileStream.readTwoDA
      columns = @[("id", sqliteInteger)].concat(twoda.columns.mapIt((name: it, coltype: sqliteText)))
      rows = collect(newSeq):
        for idx, row in twoda.rows: @[$idx].concat(row.mapIt(it.get("")))
      table = "2da_" & twodaFn.splitFile.name
    echo "Writing 2da table for: " & twodaFn
    writeTable(rows, columns, dbName, table)

if twodaOnly:
  if twodasParams.len == 0:
    echo "Warning: \"-2daonly\" parameter set but no \"-2da:\" parameters. No tables will be written to the output file."
  echo "\"-2daonly\" parameter set, skipping creation of all other tables."
  quit(QuitSuccess)

if encodingParam.isSome:
  let encoding = encodingParam.get[3 .. ^1]
  # try encoding here so a more helpful error message can be given
  try:
    discard convert("test", srcEncoding = encoding)
  except:
    echo "Error with the chosen encoding: " & encoding
    quit(QuitFailure)
  setNwnEncoding(encoding)

var dlg: Option[SingleTlk]
let dlgPath = dataFiles.findIt it.endsWith("dialog.tlk")
if dlgPath.isSome:
  echo "Adding dialog.tlk: " & dlgPath.get
  dlg = some dlgPath.get.openFileStream.readSingleTlk
else:
  echo "Warning: dialog.tlk not found, some names and texts will be missing"

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
      echo "Warning: Custom tlk file required by module not found: " & cTlkName & ".tlk"
  for hak in ifo["Mod_HakList", @[].GffList]:
    let hakName = hak["Mod_Hak", GffCExoString] & ".hak"
    if dataFiles.filterIt(it.endsWith(hakName)).len == 0:
      echo "Warning: Hak required by module not found: " & hakName
  rm.add(module)

for hak in dataFiles.filterIt it.endsWith(".hak"):
  echo "Adding hak: " & hak
  rm.add(hak.getErf("HAK "))

rm.addFiles(
  dataFiles,
  dataFileExtensions.filterIt it notin [".bif", ".hak", ".key", ".mod", ".tlk"]
)

var
  ares = newSeq[ResRef]()
  utcs = newSeq[ResRef]()
  utes = newSeq[ResRef]()
  utis = newSeq[ResRef]()
  utps = newSeq[ResRef]()
  sets = newSeq[ResRef]()
for container in rm.containers:
  if container of KeyTable and not withKey:
    # KeyTable are the base game resources
    # only add tilesets from here, unless -withkey parameter was given
    for rr in container.contents:
      if rr.restype == "set".getResType:
        sets &= rr
    continue
  for rr in container.contents:
    let restype = rr.resType
    if restype == "are".getResType:
      ares &= rr
    elif restype == "utc".getResType:
      utcs &= rr
    elif restype == "ute".getResType:
      utes &= rr
    elif restype == "uti".getResType:
      utis &= rr
    elif restype == "utp".getResType:
      utps &= rr
    elif restype == "set".getResType:
      sets &= rr

if utcs.len > 0:
  echo "Creatures (utc) found: " & $utcs.len
# writeTable with empty list will remove the table
let creatures = utcs.creatureList(rm, dlg, cTlk)
creatures.writeTable(dbName, "creatures")

if utes.len > 0:
  echo "Encounters (ute) found: " & $utes.len
utes.writeEncounterTables(rm, dlg, cTlk, dbName)

if utis.len > 0:
  echo "Items (uti) found: " & $utis.len
let items = utis.itemList(rm, dlg, cTlk)
items.writeTable(dbName, "items")

if utps.len > 0:
  echo "Placeables (utp) found: " & $utps.len
let placeables = utps.placeableList(rm, dlg, cTlk)
placeables.writeTable(dbName, "placeables")

if ares.len > 0:
  echo "Areas (are) found: " & $ares.len
  ares.writeAreaTables(rm, dlg, cTlk, dbName)

if sets.len > 0:
  echo "Tilesets (set) found: " & $sets.len
writeTable(sets.mapIt((resref: it.resRef, name: rm.demand(it).readAll.getTilesetName(dlg, cTlk))), dbName, "tilesets")

write2daTable(rm, dlg, cTlk, dbName, "appearance", "appearance2da", (id: 0, LABEL: "", xSTRING_REF: "strref"))
write2daTable(rm, dlg, cTlk, dbName, "placeables", "placeables2da", (id: 0, Label: "", ModelName: "", xStrRef: "strref"))
write2daTable(rm, dlg, cTlk, dbName, "ambientmusic", "ambientmusic2da", (id: 0, Resource: "", xDescription: "strref"))
write2daTable(rm, dlg, cTlk, dbName, "ambientsound", "ambientsound2da", (id: 0, Resource: "", xDescription: "strref"))
