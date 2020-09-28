import neverwinter/[gff, resman, tlk]
import db, helper

const fields = [
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

proc encounterList*(list: seq[ResRef], rm: ResMan, dlg, tlk: Option[SingleTlk]): seq[seq[string]] =
  for rr in list:
    let ute = rm.getGffRoot(rr)
    var row = newSeq[string]()
    for f in fields:
      row.add case f[1]
      of "byte": $ute[f[0], 0.GffByte]
      of "cexolocstring": ute[f[0], GffCExoLocString].getStr(dlg, tlk)
      of "cexostring": ute[f[0], "".GffCExoString]
      of "dword": $ute[f[0], 0.GffDword]
      of "int": $ute[f[0], -1.GffInt]
      of "resref": $ute[f[0], "".GffResRef]
      else:
        echo "Error: Handling of field type " & f[1] & " not implemented."
        quit(QuitFailure)
    result &= row

proc encounterCols*(): seq[Column] =
  for f in fields:
    let coltype = case f[1]
      of "byte", "dword", "int": sqliteInteger
      of "float": sqliteReal
      else: sqliteText
    result &= (name: f[0], coltype: coltype)
