import neverwinter/[gff, resman, tlk]
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
    hp: int
    `static`: int
    plot: int
    conversation: string
    comment: string

proc placeableList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Placeable] =
  for rr in list:
    let utp = rm.getGffRoot(rr)
    result &= Placeable(
      name: utp["LocName", GffCExoLocString].getStr(dlg, tlk),
      resref: rr.resRef,
      tag: utp["Tag", ""],
    )
