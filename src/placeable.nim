import tables
import neverwinter/[gff, resman, tlk, twoda]
import helper

type
  Placeable = object
    name, resref, tag: string
    palette, palette_full: string
    palette_id: int
    faction: string
    faction_id: int
    parent_faction: string
    parent_faction_id: int
    `static`, plot, useable: int
    has_inventory: int
    hp, hardness: int
    fort, will: int
    locked, lockable, key_required: int
    key_name: string
    open_lock_dc, close_lock_dc: int
    disarm_dc: int
    interruptable: int
    trap_detectable, trap_detect_dc, trap_disarmable, trap_flag, trap_one_shot: int
    trap_type: string
    trap_type_id: int
    conversation: string
    comment: string

proc placeableList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Placeable] =
  let
    isMod = rm[newResRef("module", "ifo".getResType)].isSome
    palcusInfo = if isMod: rm.getGffRoot("placeablepalcus", "itp")["MAIN", GffList].toPalcusInfo(dlg, tlk) else: PalcusInfo()
    factionInfo = if isMod: rm.getGffRoot("repute", "fac").toFactionInfo else: FactionInfo()
    traps2da = rm.get2da("traps")
  for rr in list:
    let
      utp = rm.getGffRoot(rr)
      paletteId = utp["PaletteID", 0.GffByte].int
      factionId = utp["Faction", 0.GffDword].int
      factionName = factionInfo.names.getOrDefault(factionId, "")
      parentFactionId = factionInfo.parents.getOrDefault(factionId, -1)
      parentFactionName = factionInfo.names.getOrDefault(parentFactionId, "")
      trapTypeId = utp["TrapType", 0.GffByte].int
    result &= Placeable(
      name: utp["LocName", GffCExoLocString].getStr(dlg, tlk),
      resref: rr.resRef,
      tag: utp["Tag", ""],
      palette: palcusInfo.getOrDefault(paletteId).name,
      paletteFull: palcusInfo.getOrDefault(paletteId).full,
      paletteId: paletteId,
      faction: factionName,
      factionId: factionId,
      parentFaction: parentFactionName,
      parentFactionId: parentFactionId,
      `static`: utp["Static", 0.GffByte].int,
      plot: utp["Plot", 0.GffByte].int,
      useable: utp["Useable", 0.GffByte].int,
      hasInventory: utp["HasInventory", 0.GffByte].int,
      hp: utp["HP", GffShort],
      hardness: utp["Hardness", 0.GffByte].int,
      fort: utp["Fort", 0.GffByte].int,
      will: utp["Will", 0.GffByte].int,
      locked: utp["Locked", 0.GffByte].int,
      lockable: utp["Lockable", 0.GffByte].int,
      keyRequired: utp["KeyRequired", 0.GffByte].int,
      keyName: utp["KeyName", ""],
      openLockDc: utp["OpenLockDC", 0.GffByte].int,
      closeLockDc: utp["CloseLockDC", 0.GffByte].int,
      disarmDc: utp["DisarmDC", 0.GffByte].int,
      interruptable: utp["Interruptable", 0.GffByte].int,
      trapDetectable: utp["TrapDetectable", 0.GffByte].int,
      trapDetectDc: utp["TrapDetectDC", 0.GffByte].int,
      trapDisarmable: utp["TrapDisarmable", 0.GffByte].int,
      trapFlag: utp["TrapFlag", 0.GffByte].int,
      trapOneShot: utp["TrapOneShot", 0.GffByte].int,
      trapType: traps2da[trapTypeId, "TrapName"].get.tlkText(dlg, tlk),
      trapTypeId: trapTypeId,
      conversation: $utp["Conversation", GffResRef],
      comment: utp["Comment", ""],
    )
