import options, tables
import neverwinter/[erf, gff, resman, tlk, twoda]
import helper

type
  Creature* = object
    name*, resref*, tag*: string
    cr*, hp*: int
    level*: int
    class1*: string
    class1_level*: int
    class2*: string
    class2_level*: int
    class3*: string
    class3_level*: int
    faction*, parent_faction*: string
    race*, gender*: string

  Classes* = tuple
    class1, class2, class3: string
    level1, level2, level3: int

proc classes*(classList: GffList, classes2da: TwoDA, dlg: SingleTlk, tlk: Option[SingleTlk]): Classes =
  result.class1 = classes2da[classList[0]["Class", GffInt], "Name"].get.tlkText(dlg, tlk)
  result.level1 = classList[0]["ClassLevel", GffShort]
  if classList.len >= 2:
    result.class2 = classes2da[classList[1]["Class", GffInt], "Name"].get.tlkText(dlg, tlk)
    result.level2 = classList[1]["ClassLevel", GffShort]
  if classList.len == 3:
    result.class3 = classes2da[classList[2]["Class", GffInt], "Name"].get.tlkText(dlg, tlk)
    result.level3 = classList[2]["ClassLevel", GffShort]

proc name(utc: GffRoot, dlg: SingleTlk, tlk: Option[SingleTlk]): string =
  result = utc["FirstName", GffCExoLocString].getStr(dlg, tlk)
  let last = utc["LastName", GffCExoLocString].getStr(dlg, tlk)
  if last != "":
    result &= " " & last

proc parentFactionTable(repute: GffRoot): Table[string, string] =
  let names = newTable[int, string]()
  for fac in repute["FactionList", GffList]:
    let name = fac["FactionName", GffCExoString]
    names[fac.id] = name
    result[name] = names.getOrDefault(fac["FactionParentID", GffDword].int, name)

proc creatureList*(list: GffList, module: Erf, rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Creature] =
  let
    facParents = getGffRoot("repute", "fac", module, rm).parentFactionTable
    classes2da = get2da("classes", rm)
    racialtypes = get2da("racialtypes", rm)
    gender = get2da("gender", rm)
  for li in list:
    if not li.hasField("RESREF", GffResRef): continue
    let
      faction = li["FACTION", GffCExoString]
      resref = $li["RESREF", GffResRef]
      utc = resref.getGffRoot("utc", module, rm)
      name = utc.name(dlg, tlk)
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
      parentFaction: facParents[faction],
      race: racialtypes[utc["Race", GffByte], "Name"].get.tlkText(dlg, tlk),
      gender: gender[utc["Gender", GffByte], "Name"].get.tlkText(dlg, tlk),
    )
