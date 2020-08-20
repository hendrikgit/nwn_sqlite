import strutils, tables
import neverwinter/[gff, resman, tlk, twoda]
import helper

type
  Item = object
    localizedName, xNameLowercase, templateResRef, tag: string
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

proc itemList*(list: seq[ResRef], rm: ResMan, dlg, tlk: Option[SingleTlk]): seq[Item] =
  let baseitems2da = rm.get2da("baseitems")
  var palcusInfo: PalcusInfo
  if rm.contains(newResRef("itempalcus", "itp".getResType)):
    let itempalcus = rm.getGffRoot("itempalcus", "itp")
    palcusInfo = toPalcusInfo(itempalcus["MAIN", GffList], dlg, tlk)
  for rr in list:
    let
      uti = rm.getGffRoot(rr)
      name = uti["LocalizedName", GffCExoLocString].getStr(dlg, tlk)
      baseItemId = uti["BaseItem", GffInt].int
      baseItem = baseitems2da.get(TwoDA())[baseItemId, "Name", "0"].tlkText(dlg, tlk)
      paletteId = uti["PaletteID", 0.GffByte].int
    result &= Item(
      localizedName: name,
      xNameLowercase: name.toLower,
      templateResRef: rr.resRef,
      tag: uti["Tag", ""],
      baseItem: baseItemId,
      xBaseItemName: baseItem,
      xPalette: palcusInfo.getOrDefault(paletteId).name,
      xPaletteFull: palcusInfo.getOrDefault(paletteId).full,
      paletteId: paletteId,
      identified: uti["Identified", 0.GffByte].int,
      stackSize: uti["StackSize", 0.GffWord].int,
      xStackingBaseitems2da: baseitems2da.get(TwoDA())[baseItemId, "Stacking", "0"].parseInt,
      charges: uti["Charges", 0.GffByte].int,
      cost: uti["Cost", 0.GffDword].int,
      addCost: uti["AddCost", 0.GffDword].int,
      cursed: uti["Cursed", 0.GffByte].int,
      plot: uti["Plot", 0.GffByte].int,
      stolen: uti["Stolen", 0.GffByte].int,
      comment: uti["Comment", ""],
    )
