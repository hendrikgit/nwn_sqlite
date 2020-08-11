import os, sequtils, streams, strutils, tables
import neverwinter/[erf, gff, key, resfile, resman, tlk, twoda]

# todo: provide module and all other dirs via arguments, first one has to be module, rest dirs that will be searched and added to resman
# todo: check that module file exists and is indeed of type mod

const
  moduleName = "/home/hal/git/sfee/server/modules/SoulForge.mod"
  dataDirs = [
    "/home/hal/git/sfee/nwn-data/data",
    "/home/hal/git/sfee/server/hak",
    "/home/hal/git/sfee/server/tlk",
  ]

let
  palcusNames = [
    "creaturepalcus",
    #"itempalcus",
    #"placeablepalcus",
  ]
  module = moduleName.openFileStream.readErf
  rm = newResMan() # container added last to resman will be queried first

var keys, bifs, haks, tlks: seq[string]
for dir in dataDirs:
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
  echo "Adding dialog.tlk"
  rm.add(mTlkName.get.newResFile)
else:
  echo "dialog.tlk not found"
  quit(QuitFailure)
let mTlk = rm[newResRef("dialog", "tlk".getResType)].get.readAll.newStringStream.readSingleTlk

for key in keys:
  echo "Adding key: " & key
  let keytable = key.openFileStream.readKeyTable proc (fn: string): Stream =
    let bif = bifs.findIt it.endsWith(fn)
    if bif.isSome:
      bif.get.openFileStream
    else:
      echo "File referenced by key not found: " & fn
      quit(QuitFailure)
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
    echo "Adding hak: " & hakName
    rm.add(hak.get.newResFile)
  else:
    echo "Hak required by module not found: " & hakName
    quit(QuitFailure)

let classes2da = rm[newResRef("classes", "2da".getResType)].get.readAll.newStringStream.readTwoDA

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
  let
    resref = newResRef(resref, restype.getResType)
    modRes = module[resref]
  # get from module first, then from resman (or error)
  let gff = if modRes.isSome: modRes.get.readAll else: rm[resref].get.readAll
  gff.newStringStream.readGffRoot

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
    echo creatures[0]
    echo creatures[^1]
