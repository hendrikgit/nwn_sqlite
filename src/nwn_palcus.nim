import os, sequtils, streams, strutils, tables
import neverwinter/[erf, gff, key, resfile, resman, resmemfile, tlk, twoda]
import db, helper

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
  dataDirs = commandLineParams()[1 .. ^1]
  palcusNames = [
    "creaturepalcus",
    #"itempalcus",
    #"placeablepalcus",
  ]
  rm = newResMan() # container added last to resman will be queried first

var keys, bifs, haks, tlks: seq[string]
for dir in dataDirs:
  if not dir.dirExists:
    echo "Directory not found: " & dir
    quit(QuitFailure)
  for file in dir.joinPath("*").walkFiles:
    case file.splitFile.ext
    of ".key":
      keys &= file
    of ".bif":
      bifs &= file
    of ".hak":
      haks &= file
    of ".tlk":
      tlks &= file

template findIt(s, pred: untyped): untyped =
  var result: Option[type(s[0])]
  for it {.inject.} in s.items:
    if result.isNone and pred:
      result = some it
  result

let mTlkName = tlks.findIt it.endsWith("dialog.tlk")
if mTlkName.isSome:
  echo "Adding dialog.tlk: " & mTlkName.get
  rm.add(mTlkName.get.newResFile)
else:
  echo "dialog.tlk not found"
  quit(QuitFailure)
let mTlk = rm[newResRef("dialog", "tlk".getResType)].get.readAll.newStringStream.readSingleTlk

for key in keys:
  echo "Adding key: " & key
  let keytable = key.openFileStream.readKeyTable(key, proc (fn: string): Stream =
    let bif = bifs.findIt it.endsWith(fn)
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
  let tlk = tlks.findIt it.endsWith(cTlkName & ".tlk")
  if tlk.isSome:
    echo "Adding custom tlk: " & cTlkName & ".tlk"
    cTlk = some tlk.get.openFileStream.readSingleTlk
  else:
    echo "Custom tlk file required by module not found: " & cTlkName & ".tlk"
    quit(QuitFailure)

proc tlkText(strref: StrRef): string =
  if strref < 0x01_000_000:
    let tlk = mTlk[strref]
    if tlk.isSome:
      return tlk.get.text
  elif cTlk.isSome:
    let tlk = cTlk.get[strref - 0x01_000_000]
    if tlk.isSome:
      return tlk.get.text

proc tlkText(strref: string): string =
  tlkText(strref.parseInt.StrRef)

for hak in ifo["Mod_HakList", GffList]:
  let hakName = hak["Mod_Hak", GffCExoString] & ".hak"
  let hak = haks.findIt it.endsWith(hakName)
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

type
  Creature = object
    name, resref, tag: string
    cr, hp: int
    level: int
    class1: string
    class1Level: int
    class2: string
    class2Level: int
    class3: string
    class3Level: int
    faction, parentFaction: string

proc flatten(list: GffList): GffList =
  for li in list:
    if li.hasField("LIST", GffList):
      result.insert li["LIST", GffList].flatten
    else:
      result &= li

proc getGff(resref, restype: string): GffRoot =
  let resref = newResRef(resref, restype.getResType)
  # get from module first, then from resman
  var gffContent = ""
  if module[resref].isSome:
    gffContent = module[resref].get.readAll
  elif rm[resref].isSome:
    gffContent = rm[resref].get.readAll
  else:
    echo "Error: GFF " & $resref & " not found."
    quit(QuitFailure)
  gffContent.newStringStream.readGffRoot

proc classes(classList: GffList): tuple[class1, class2, class3: string, level1, level2, level3: int] =
  result.class1 = classes2da[classList[0]["Class", GffInt], "Name"].get.tlkText
  result.level1 = classList[0]["ClassLevel", GffShort]
  if classList.len >= 2:
    result.class2 = classes2da[classList[1]["Class", GffInt], "Name"].get.tlkText
    result.level2 = classList[1]["ClassLevel", GffShort]
  if classList.len == 3:
    result.class3 = classes2da[classList[2]["Class", GffInt], "Name"].get.tlkText
    result.level3 = classList[2]["ClassLevel", GffShort]

proc creaturelist(list: GffList): seq[Creature] =
  let
    facGffRoot = "repute".getGff("fac")
    facNames = newTable[int, string]()
    facParents = newTable[string, string]()
  for fac in facGffRoot["FactionList", GffList]:
    let name = fac["FactionName", GffCExoString]
    facNames[fac.id] = name
    facParents[name] = facNames.getOrDefault(fac["FactionParentID", GffDword].int, name)
  for li in list:
    if not li.hasField("RESREF", GffResRef): continue
    let
      faction = li["FACTION", GffCExoString]
      resref = $li["RESREF", GffResRef]
      name = if li.hasField("NAME", GffCExoString): li["NAME", GffCExoString] else: li["STRREF", GffDword].tlkText
      utc = resref.getGff("utc")
      (class1, class2, class3, level1, level2, level3) = utc["ClassList", GffList].classes
    result &= Creature(
      name: name,
      resref: resref,
      tag: utc["Tag", GffCExoString],
      cr: li["CR", GffFloat].toInt,
      hp: utc["MaxHitPoints", GffShort],
      class1: class1,
      class1Level: level1,
      class2: class2,
      class2Level: level2,
      class3: class3,
      class3Level: level3,
      level: level1 + level2 + level3,
      faction: faction,
      parentFaction: facParents[faction]
    )
    # todo: Race, Alignment

for palcus in palcusNames:
  echo palcus
  let
    itpGffRoot = palcus.getGff("itp")
    list = itpGffRoot["MAIN", GffList].flatten
  case palcus
  of "creaturepalcus":
    let creatures = list.creatureList
    echo "Entries: " & $creatures.len
    let dbfilename = palcus & ".sqlite3"
    echo "Writing sqlite db file: " & dbfilename
    creatures.writeDb(dbfilename, palcus)
