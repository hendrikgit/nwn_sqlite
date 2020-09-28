import neverwinter/[gff, resman, tlk]
import db, helper

const fields = [
  ["id", "id"],
  ["Active", "byte"],
  ["Comment", "cexostring"],
  ["Difficulty", "int"],
  ["DifficultyIndex", "int"],
  ["Faction", "dword"],
  ["LocalizedName", "cexolocstring"],
  ["MaxCreatures", "int"],
  ["OnEntered", "resref"],
  ["OnExhausted", "resref"],
  ["OnExit", "resref"],
  ["OnHeartbeat", "resref"],
  ["OnUserDefined", "resref"],
  ["PaletteID", "byte"],
  ["PlayerOnly", "byte"],
  ["RecCreatures", "int"],
  ["Reset", "byte"],
  ["ResetTime", "int"],
  ["Respawns", "int"],
  ["SpawnOption", "int"],
  ["Tag", "cexostring"],
  ["TemplateResRef", "resref"],
]

# todo: can this be done at compile time?
proc encounterCols(): seq[Column] =
  for f in fields:
    let coltype = case f[1]
      of "id", "byte", "dword", "int": sqliteInteger
      of "float": sqliteReal
      else: sqliteText
    result &= (name: f[0], coltype: coltype)

# todo: add looked up names for faction and parent faction
proc writeEncounterTables*(list: seq[ResRef], rm: ResMan, dlg, tlk: Option[SingleTlk], dbName: string) =
  var encounters = newSeq[seq[string]]()
  var creatures = newSeq[seq[string]]()
  for idx, rr in list:
    let id = $(idx + 1)
    let ute = rm.getGffRoot(rr)
    var row = newSeq[string]()
    for f in fields:
      row.add case f[1]
      of "id": id # id is added "manually" just in case sqlite does not number the rows as expected
      of "byte": $ute[f[0], 0.GffByte]
      of "cexolocstring": ute[f[0], GffCExoLocString].getStr(dlg, tlk)
      of "cexostring": ute[f[0], "".GffCExoString]
      of "dword": $ute[f[0], 0.GffDword]
      of "int": $ute[f[0], -1.GffInt]
      of "resref": $ute[f[0], "".GffResRef]
      else:
        echo "Error: Handling of field type " & f[1] & " not implemented."
        quit(QuitFailure)
    encounters &= row
    for c in ute["CreatureList", GffList]:
      creatures &= @[id, $c["ResRef", "".GffResRef], $c["SingleSpawn", 0.GffByte]]
  encounters.writeTable(encounterCols(), dbName, "encounters")
  let encountersCreaturesCols = [("encounter_id", sqliteInteger), ("ResRef", sqliteText), ("SingleSpawn", sqliteText)]
  creatures.writeTable(encountersCreaturesCols, dbName, "encounters_creatures")
