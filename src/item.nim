import strutils, tables
import neverwinter/[gff, resman, tlk, twoda]
import helper

type
  Item = object
    localizedName, templateResRef, tag: string
    baseItem: int
    xBaseItemName: string
    paletteID: int
    xPalette, xPaletteFull: string
    identified: int
    stackSize, xStackingBaseitems2da: int
    charges: int
    cost, addCost: int
    cursed: int
    plot: int
    stolen: int
    comment: string

proc itemList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Item] =
  let baseitems2da = rm.get2da("baseitems")
  let isMod = rm[newResRef("module", "ifo".getResType)].isSome
  var palcusInfo: PalcusInfo
  if isMod:
    let itempalcus = rm.getGffRoot("itempalcus", "itp")
    palcusInfo = toPalcusInfo(itempalcus["MAIN", GffList], dlg, tlk)
  for rr in list:
    let
      uti = rm.getGffRoot(rr)
      baseItemId = uti["BaseItem", GffInt].int
      baseItem = baseitems2da[baseItemId, "Name"].get.tlkText(dlg, tlk)
      paletteId = uti["PaletteID", 0.GffByte].int
    result &= Item(
      localizedName: uti["LocalizedName", GffCExoLocString].getStr(dlg, tlk),
      templateResRef: rr.resRef,
      tag: uti["Tag", ""],
      baseItem: baseItemId,
      xBaseItemName: baseItem,
      xPalette: palcusInfo.getOrDefault(paletteId).name,
      xPaletteFull: palcusInfo.getOrDefault(paletteId).full,
      paletteId: paletteId,
      identified: uti["Identified", 0.GffByte].int,
      stackSize: uti["StackSize", 0.GffWord].int,
      xStackingBaseitems2da: baseitems2da[baseItemId, "Stacking"].get.parseInt,
      charges: uti["Charges", 0.GffByte].int,
      cost: uti["Cost", 0.GffDword].int,
      addCost: uti["AddCost", 0.GffDword].int,
      cursed: uti["Cursed", 0.GffByte].int,
      plot: uti["Plot", 0.GffByte].int,
      stolen: uti["Stolen", 0.GffByte].int,
      comment: uti["Comment", ""],
    )
