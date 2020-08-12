import options, strutils, tables
import neverwinter/[erf, gff, resman, tlk, twoda]
import helper

type
  Creature* = object
    name*, resref*, tag*: string
    cr*, hp*: int
    level*: int
    class1*: string
    class1Level*: int
    class2*: string
    class2Level*: int
    class3*: string
    class3Level*: int
    faction*, parentFaction*: string

  Classes* = tuple
    class1, class2, class3: string
    level1, level2, level3: int

proc classes*(classList: GffList, classes2da: TwoDA, dlg: SingleTlk, tlk: Option[SingleTlk]): Classes =
  result.class1 = classes2da[classList[0]["Class", GffInt], "Name"].get.parseInt.StrRef.tlkText(dlg, tlk)
  result.level1 = classList[0]["ClassLevel", GffShort]
  if classList.len >= 2:
    result.class2 = classes2da[classList[1]["Class", GffInt], "Name"].get.parseInt.StrRef.tlkText(dlg, tlk)
    result.level2 = classList[1]["ClassLevel", GffShort]
  if classList.len == 3:
    result.class3 = classes2da[classList[2]["Class", GffInt], "Name"].get.parseInt.StrRef.tlkText(dlg, tlk)
    result.level3 = classList[2]["ClassLevel", GffShort]

proc parentFactionTable(repute: GffRoot): Table[string, string] =
  let names = newTable[int, string]()
  for fac in repute["FactionList", GffList]:
    let name = fac["FactionName", GffCExoString]
    names[fac.id] = name
    result[name] = names.getOrDefault(fac["FactionParentID", GffDword].int, name)

proc creatureList*(list: GffList, module: Erf, rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk], classes2da: TwoDA): seq[Creature] =
  let facParents = "repute".getGffRoot("fac", module, rm).parentFactionTable
  for li in list:
    if not li.hasField("RESREF", GffResRef): continue
    let
      faction = li["FACTION", GffCExoString]
      resref = $li["RESREF", GffResRef]
      name = if li.hasField("NAME", GffCExoString): li["NAME", GffCExoString] else: li["STRREF", GffDword].tlkText(dlg, tlk)
      utc = resref.getGffRoot("utc", module, rm)
      classes = utc["ClassList", GffList].classes(classes2da, dlg, tlk)
    result &= Creature(
      name: name,
      resref: resref,
      tag: utc["Tag", GffCExoString],
      cr: li["CR", GffFloat].toInt,
      hp: utc["MaxHitPoints", GffShort],
      class1: classes.class1,
      class1Level: classes.level1,
      class2: classes.class2,
      class2Level: classes.level2,
      class3: classes.class3,
      class3Level: classes.level3,
      level: classes.level1 + classes.level2 + classes.level3,
      faction: faction,
      parentFaction: facParents[faction]
    )
