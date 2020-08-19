import neverwinter/[gff, resman, tlk]
import helper

type
  Area = object
    name, resref, tag: string
    comments: string

proc areaList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Area] =
  for rr in list:
    let are = rm.getGffRoot(rr)
    result &= Area(
      name: are["Name", GffCExoLocString].getStr(dlg, tlk),
      resref: rr.resRef,
      tag: are["Tag", ""],
      comments: are["Comments", ""],
    )
