import neverwinter/[gff, resman, tlk]
import helper

type
  Item = object
    name, resref, tag: string
    base_item: string
    base_item_id: int
    identified: int
    stack_size: int
    charges: int
    cost, add_cost: int
    cursed: int
    plot: int
    stolen: int
    comment: string

proc itemList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, cTlk: Option[SingleTlk]): seq[Item] =
  for rr in list:
    let
      uti = rm.getGffRoot(rr)
      baseItemId = uti["BaseItem", GffInt]
    result &= Item(
      name: uti["LocalizedName", GffCExoLocString].getStr(dlg, cTlk),
      resref: rr.resRef,
      tag: uti["Tag", ""],
      base_item_id: baseItemId,
      base_item: "todo",
      identified: uti["Identified", 0.GffByte].int,
      stack_size: uti["StackSize", 0.GffWord].int,
      charges: uti["Charges", 0.GffByte].int,
      cost: uti["Cost", 0.GffDword].int,
      add_cost: uti["AddCost", 0.GffDword].int,
      cursed: uti["Cursed", 0.GffByte].int,
      plot: uti["Plot", 0.GffByte].int,
      stolen: uti["Stolen", 0.GffByte].int,
      comment: uti["Comment", ""],
    )
