import tables, strutils
import neverwinter/[gff, resman, tlk]
import helper

type
  Placeable = object
    locName, xNameLowercase, templateResRef, tag: string
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
    conversation: string
    comment: string
    onClosed, onDamaged, onDeath, onDisarm, onHeartbeat, onInvDisturbed: string
    onLock, onMeleeAttacked, onOpen, onSpellCastAt, onTrapTriggered, onUnlock: string
    onUsed, onUserDefined: string

proc placeableList*(list: seq[ResRef], rm: ResMan, dlg, tlk: Option[SingleTlk]): seq[Placeable] =
  let
    palcusInfo = if rm.contains(newResRef("placeablepalcus", "itp".getResType)):
      rm.getGffRoot("placeablepalcus", "itp")["MAIN", GffList].toPalcusInfo(dlg, tlk) else: PalcusInfo()
    factionInfo = if rm.contains(newResRef("repute", "fac".getResType)):
      rm.getGffRoot("repute", "fac").toFactionInfo else: FactionInfo()
  for rr in list:
    let
      utp = rm.getGffRoot(rr)
      name = utp["LocName", GffCExoLocString].getStr(dlg, tlk)
      paletteId = utp["PaletteID", 0.GffByte].int
      factionId = utp["Faction", 0.GffDword].int
      factionName = factionInfo.names.getOrDefault(factionId, "")
      parentFactionId = factionInfo.parents.getOrDefault(factionId, -1)
      parentFactionName = factionInfo.names.getOrDefault(parentFactionId, "")
      trapTypeId = utp["TrapType", 0.GffByte].int
    var placeable = Placeable(
      locName: name,
      xNameLowercase: name.toLower,
      templateResRef: rr.resRef,
      tag: utp["Tag", "".GffCExoString],
      paletteId: paletteId,
      xPalette: palcusInfo.getOrDefault(paletteId).name,
      xPaletteFull: palcusInfo.getOrDefault(paletteId).full,
      faction: factionId,
      xParentFactionId: parentFactionId,
      xFactionName: factionName,
      xParentFactionName: parentFactionName,
      hP: utp["HP", GffShort],
      conversation: $utp["Conversation", "".GffResRef],
      comment: utp["Comment", "".GffCExoString],
      keyName: utp["KeyName", "".GffCExoString],
      trapType: trapTypeId,
    )
    for k, v in placeable.fieldPairs:
      let label = k.capitalizeAscii
      when v is int:
        case label
        of "Static", "Plot", "Useable", "HasInventory", "Hardness", "Fort", "Will",
            "Locked", "Lockable", "KeyRequired", "OpenLockDC", "CloseLockDC", "DisarmDC",
            "Interruptable", "TrapDetectable", "TrapDetectDC", "TrapDisarmable", "TrapFlag",
            "TrapOneShot":
          v = utp[label, 0.GffByte].int
      when v is string:
        case label
        of "OnClosed", "OnDamaged", "OnDeath", "OnDisarm", "OnHeartbeat", "OnInvDisturbed",
            "OnLock", "OnMeleeAttacked", "OnOpen", "OnSpellCastAt", "OnTrapTriggered",
            "OnUnlock", "OnUsed", "OnUserDefined":
          v = $utp[label, "".GffResRef]
    result &= placeable
