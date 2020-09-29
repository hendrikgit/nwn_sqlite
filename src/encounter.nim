import sequtils
import neverwinter/[gff, resman, tlk]
import db, helper

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

# todo: add looked up names for faction and parent faction
proc writeEncounterTables*(list: seq[ResRef], rm: ResMan, dlg, tlk: Option[SingleTlk], dbName: string) =
  var encounters = newSeq[seq[string]]()
  var creatures = newSeq[seq[string]]()
  for idx, rr in list:
    let id = $(idx + 1)
    let ute = rm.getGffRoot(rr)
    encounters &= fields.mapIt ute.getStringValue(it, dlg, tlk, id)
    for c in ute["CreatureList", GffList]:
      creatures &= @[id, $c["ResRef", "".GffResRef], $c["SingleSpawn", 0.GffByte]]
  encounters.writeTable(fields.toColumns, dbName, "encounters")
  let encountersCreaturesCols = [("encounter_id", sqliteInteger), ("ResRef", sqliteText), ("SingleSpawn", sqliteText)]
  creatures.writeTable(encountersCreaturesCols, dbName, "encounters_creatures")
