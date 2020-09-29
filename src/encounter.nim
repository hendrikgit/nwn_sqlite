import neverwinter/[gff, resman, tlk]
import db, helper

type
  FieldType = enum
    ftId
    ftByte, ftDword, ftInt
    ftFloat
    ftResRef, ftCExoString,
    ftCExoLocString

  Field = tuple
    name: string
    fieldType: FieldType

const fields: array[22, Field] = [
  ("id", ftId),
  ("Active", ftByte),
  ("Comment", ftCExoString),
  ("Difficulty", ftInt),
  ("DifficultyIndex", ftInt),
  ("Faction", ftDword),
  ("LocalizedName", ftCExoLocString),
  ("MaxCreatures", ftInt),
  ("OnEntered", ftResRef),
  ("OnExhausted", ftResRef),
  ("OnExit", ftResRef),
  ("OnHeartbeat", ftResRef),
  ("OnUserDefined", ftResRef),
  ("PaletteID", ftByte),
  ("PlayerOnly", ftByte),
  ("RecCreatures", ftInt),
  ("Reset", ftByte),
  ("ResetTime", ftInt),
  ("Respawns", ftInt),
  ("SpawnOption", ftInt),
  ("Tag", ftCExoString),
  ("TemplateResRef", ftResRef),
]

proc encounterCols(): seq[Column] =
  for f in fields:
    let coltype = case f.fieldType
      of ftId, ftByte, ftDword, ftInt: sqliteInteger
      of ftFloat: sqliteReal
      of ftResRef, ftCExoString, ftCExoLocString: sqliteText
    result &= (name: f.name, coltype: coltype)

# todo: add looked up names for faction and parent faction
proc writeEncounterTables*(list: seq[ResRef], rm: ResMan, dlg, tlk: Option[SingleTlk], dbName: string) =
  var encounters = newSeq[seq[string]]()
  var creatures = newSeq[seq[string]]()
  for idx, rr in list:
    let id = $(idx + 1)
    let ute = rm.getGffRoot(rr)
    var row = newSeq[string]()
    for f in fields:
      row.add case f.fieldType
      of ftId: id # id is added "manually" just in case sqlite does not number the rows as expected
      of ftByte: $ute[f.name, 0.GffByte]
      of ftDword: $ute[f.name, 0.GffDword]
      of ftInt: $ute[f.name, -1.GffInt]
      of ftFloat: $ute[f.name, -1.GffFloat]
      of ftResRef: $ute[f.name, "".GffResRef]
      of ftCExoString: ute[f.name, "".GffCExoString]
      of ftCExoLocString: ute[f.name, GffCExoLocString].getStr(dlg, tlk)
    encounters &= row
    for c in ute["CreatureList", GffList]:
      creatures &= @[id, $c["ResRef", "".GffResRef], $c["SingleSpawn", 0.GffByte]]
  encounters.writeTable(encounterCols(), dbName, "encounters")
  let encountersCreaturesCols = [("encounter_id", sqliteInteger), ("ResRef", sqliteText), ("SingleSpawn", sqliteText)]
  creatures.writeTable(encountersCreaturesCols, dbName, "encounters_creatures")
