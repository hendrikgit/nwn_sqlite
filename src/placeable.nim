import tables, strutils
import neverwinter/[gff, resman, tlk, twoda]
import helper

type
  Placeable = object
    locName, templateResRef, tag: string
    paletteID: int
    xPalette, xPaletteFull: string
    faction: int
    xParentFactionID: int
    xFactionName, xParentFactionName: string
    `static`, plot, useable: int
    hasInventory: int
    hP, hardness: int
    fort, will: int
    locked, lockable, keyRequired: int
    keyName: string
    openLockDC, closeLockDC: int
    disarmDC: int
    interruptable: int
    trapDetectable, trapDetectDC, trapDisarmable, trapFlag, trapOneShot: int
    trapType: int
    xTrapTypeName: string
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
    var placeable = Placeable(
      locName: utp["LocName", GffCExoLocString].getStr(dlg, tlk),
      templateResRef: rr.resRef,
      tag: utp["Tag", GffCExoString],
      paletteId: paletteId,
      xPalette: palcusInfo.getOrDefault(paletteId).name,
      xPaletteFull: palcusInfo.getOrDefault(paletteId).full,
      faction: factionId,
      xParentFactionId: parentFactionId,
      xFactionName: factionName,
      xParentFactionName: parentFactionName,
      hP: utp["HP", GffShort],
      conversation: $utp["Conversation", GffResRef],
      comment: utp["Comment", GffCExoString],
      keyName: utp["KeyName", GffCExoString],
      trapType: trapTypeId,
      xTrapTypeName: traps2da[trapTypeId, "TrapName"].get.tlkText(dlg, tlk),
    )
    for k, v in placeable.fieldPairs:
      when v is int:
        let label = k.capitalizeAscii
        case label
        of "Static", "Plot", "Useable", "HasInventory", "Hardness", "Fort", "Will",
            "Locked", "Lockable", "KeyRequired", "OpenLockDC", "CloseLockDC", "DisarmDC",
            "Interruptable", "TrapDetectable", "TrapDetectDC", "TrapDisarmable", "TrapFlag",
            "TrapOneShot":
          v = utp[label, GffByte].int
    result &= placeable
