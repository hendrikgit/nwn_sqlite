import options, tables
import neverwinter/[erf, gff, resman, tlk, twoda]
import helper

type
  Creature* = object
    name*, resref*, tag*: string
    cr*, cr_adjust*, hp*: int
    level*: int
    class1*: string
    class1_id*: int
    class1_level*: int
    class2*: string
    class2_id*: int
    class2_level*: int
    class3*: string
    class3_id*: int
    class3_level*: int
    faction*: string
    faction_id*: int
    parent_faction*: string
    parent_faction_id*: int
    race*: string
    race_id*: int
    gender*: string
    gender_id*: int
    alignment*: string
    alignment_lawful_chaotic*, alignment_good_evil*: int
    natural_ac*: int
    str*, dex*, con*, int*, wis*, cha*: int
    lootable*, disarmable*, is_immortal*, no_perm_death*, plot*, interruptable*: int
    walk_rate: int
    conversation: string
    comment: string

  ClassInfo = object
    name1, name2, name3: string
    id1, id2, id3: int
    level1, level2, level3: int

  AlignmentRange = range[0 .. 100]

  Alignment = object
    lawfulChaotic, goodEvil: AlignmentRange

proc toClassInfo(classList: GffList, classes2da: TwoDA, dlg: SingleTlk, tlk: Option[SingleTlk]): ClassInfo =
  result.id1 = classList[0]["Class", GffInt]
  result.name1 = classes2da[result.id1, "Name"].get.tlkText(dlg, tlk)
  result.level1 = classList[0]["ClassLevel", GffShort]
  if classList.len >= 2:
    result.id2 = classList[1]["Class", GffInt]
    result.name2 = classes2da[result.id2, "Name"].get.tlkText(dlg, tlk)
    result.level2 = classList[1]["ClassLevel", GffShort]
  if classList.len == 3:
    result.id3 = classList[2]["Class", GffInt]
    result.name3 = classes2da[result.id3, "Name"].get.tlkText(dlg, tlk)
    result.level3 = classList[2]["ClassLevel", GffShort]

proc name(utc: GffRoot, dlg: SingleTlk, tlk: Option[SingleTlk]): string =
  result = utc["FirstName", GffCExoLocString].getStr(dlg, tlk)
  let last = utc["LastName", GffCExoLocString].getStr(dlg, tlk)
  if last != "":
    result &= " " & last

proc name(a: Alignment): string =
  let lc = case a.lawfulChaotic
  of 70 .. 100: "L"
  of 31 .. 69: "N"
  of 0 .. 30: "C"
  let ge = case a.goodEvil
  of 70 .. 100: "G"
  of 31 .. 69: "N"
  of 0 .. 30: "E"
  if lc == ge: "TN" else: lc & ge

proc parentFactionTable(repute: GffRoot): Table[string, string] =
  let names = newTable[int, string]()
  for fac in repute["FactionList", GffList]:
    let name = fac["FactionName", GffCExoString]
    names[fac.id] = name
    result[name] = names.getOrDefault(fac["FactionParentID", GffDword].int, name)

proc factionIdTable(repute: GffRoot): Table[string, int] =
  for fac in repute["FactionList", GffList]:
    result[fac["FactionName", GffCExoString]] = fac.id

proc creatureList*(list: GffList, module: Erf, rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Creature] =
  let
    reputeGffRoot = getGffRoot("repute", "fac", module, rm)
    parentFactions = reputeGffRoot.parentFactionTable
    factionIds = reputeGffRoot.factionIdTable
    classes2da = get2da("classes", rm)
    racialtypes = get2da("racialtypes", rm)
    gender = get2da("gender", rm)
  for li in list:
    if not li.hasField("RESREF", GffResRef): continue
    let
      factionName = li["FACTION", GffCExoString]
      parentFactionName = parentFactions[factionName]
      resref = $li["RESREF", GffResRef]
      utc = resref.getGffRoot("utc", module, rm)
      name = utc.name(dlg, tlk)
      classInfo = utc["ClassList", GffList].toClassInfo(classes2da, dlg, tlk)
      alignment = Alignment(lawfulChaotic: utc["LawfulChaotic", GffByte], goodEvil: utc["GoodEvil", GffByte])
    result &= Creature(
      name: name,
      resref: resref,
      tag: utc["Tag", GffCExoString],
      cr: li["CR", GffFloat].toInt,
      cr_adjust: utc["CRAdjust", GffInt],
      hp: utc["MaxHitPoints", GffShort],
      class1: classInfo.name1,
      class1Id: classInfo.id1,
      class1Level: classInfo.level1,
      class2: classInfo.name2,
      class2Id: classInfo.id2,
      class2Level: classInfo.level2,
      class3: classInfo.name3,
      class3Id: classInfo.id3,
      class3Level: classInfo.level3,
      level: classInfo.level1 + classInfo.level2 + classInfo.level3,
      faction: factionName,
      faction_id: factionIds[factionName],
      parentFaction: parentFactionName,
      parentFactionId: factionIds[parentFactionName],
      race: racialtypes[utc["Race", GffByte], "Name"].get.tlkText(dlg, tlk),
      race_id: utc["Race", GffByte].int,
      gender: gender[utc["Gender", GffByte], "Name"].get.tlkText(dlg, tlk),
      gender_id: utc["Gender", GffByte].int,
      alignment: alignment.name,
      alignment_lawful_chaotic: alignment.lawfulChaotic,
      alignment_good_evil: alignment.goodEvil,
      natural_ac: utc["NaturalAC", GffByte].int,
      str: utc["Str", GffByte].int,
      dex: utc["Dex", GffByte].int,
      con: utc["Con", GffByte].int,
      int: utc["Int", GffByte].int,
      wis: utc["Wis", GffByte].int,
      cha: utc["Cha", GffByte].int,
      lootable: utc["Lootable", GffByte].int,
      disarmable: utc["Disarmable", GffByte].int,
      is_immortal: utc["IsImmortal", GffByte].int,
      no_perm_death: utc["NoPermDeath", GffByte].int,
      plot: utc["Plot", GffByte].int,
      interruptable: utc["Interruptable", GffByte].int,
      walk_rate: utc["WalkRate", GffInt],
      conversation: $utc["Conversation", GffResRef],
      comment: utc["Comment", GffCExoString],
    )
