import neverwinter/[gff, resman, tlk]
import helper

type
  Area = object
    name, resref, tag: string
    height, width: int
    comments: string

proc areaList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Area] =
  for rr in list:
    let are = rm.getGffRoot(rr)
    result &= Area(
      name: are["Name", GffCExoLocString].getStr(dlg, tlk),
      resref: rr.resRef,
      tag: are["Tag", ""],
      height: are["Height", 0.GffInt],
      width: are["Width", 0.GffInt],
      comments: are["Comments", ""],
    )
