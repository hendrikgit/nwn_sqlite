import strutils
import neverwinter/[gff, resman, tlk, twoda]
import helper

type
  Item = object
    name, resref, tag: string
    base_item: string
    base_item_id: int
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
  for rr in list:
    let
      uti = rm.getGffRoot(rr)
      baseItemId = uti["BaseItem", GffInt].int
      baseItem = baseitems2da[baseItemId, "Name"].get.tlkText(dlg, tlk)
    result &= Item(
      name: uti["LocalizedName", GffCExoLocString].getStr(dlg, tlk),
      resref: rr.resRef,
      tag: uti["Tag", ""],
      base_item_id: baseItemId,
      base_item: baseItem,
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
