import neverwinter/[gff, resman, tlk]
import helper

type
  Item = object
    name, resref, tag: string

proc itemList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, cTlk: Option[SingleTlk]): seq[Item] =
  for rr in list:
    let uti = rm.getGffRoot(rr)
    result &= Item(
      name: uti["LocalizedName", GffCExoLocString].getStr(dlg, cTlk),
      resref: rr.resRef,
      tag: uti["Tag", GffCExoString],
    )
