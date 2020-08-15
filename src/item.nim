import strutils, tables
import neverwinter/[gff, resman, tlk, twoda]
import helper

type
  Item = object
    name, resref, tag: string
    base_item: string
    base_item_id: int
    palette, palette_full: string
    palette_id: int
    identified: int
    stack_size, stacking_baseitems: int
    charges: int
    cost, add_cost: int
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
      name: uti["LocalizedName", GffCExoLocString].getStr(dlg, tlk),
      resref: rr.resRef,
      tag: uti["Tag", ""],
      base_item_id: baseItemId,
      base_item: baseItem,
      palette: palcusInfo.getOrDefault(paletteId).name,
      palette_full: palcusInfo.getOrDefault(paletteId).full,
      palette_id: paletteId,
      identified: uti["Identified", 0.GffByte].int,
      stack_size: uti["StackSize", 0.GffWord].int,
      stacking_baseitems: baseitems2da[baseItemId, "Stacking"].get.parseInt,
      charges: uti["Charges", 0.GffByte].int,
      cost: uti["Cost", 0.GffDword].int,
      add_cost: uti["AddCost", 0.GffDword].int,
      cursed: uti["Cursed", 0.GffByte].int,
      plot: uti["Plot", 0.GffByte].int,
      stolen: uti["Stolen", 0.GffByte].int,
      comment: uti["Comment", ""],
    )
