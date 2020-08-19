import neverwinter/[gff, resman, tlk]
import helper

type
  Area = object
    name, resref, tag: string
    height, width: int
    flags: int
    flags_interior, flags_underground, flags_natural: bool
    comments: string

  AreaFlag {.size: 4.} = enum
    areaInterior = "interior" # exterior if unset
    areaUnderground = "underground" # aboveground if unset
    areaNatural = "natural" # urban if unset

  AreaFlags = set[AreaFlag]

proc toFlags(v: int): AreaFlags =
  cast[AreaFlags](v)

proc areaList*(list: seq[ResRef], rm: ResMan, dlg: SingleTlk, tlk: Option[SingleTlk]): seq[Area] =
  for rr in list:
    let
      are = rm.getGffRoot(rr)
      flag = are["Flags", 0.GffDword].int
      flags = flag.toFlags
    result &= Area(
      name: are["Name", GffCExoLocString].getStr(dlg, tlk),
      resref: rr.resRef,
      tag: are["Tag", ""],
      height: are["Height", 0.GffInt],
      width: are["Width", 0.GffInt],
      flags: flag,
      flagsInterior: flags.contains(areaInterior),
      flagsUnderground: flags.contains(areaUnderground),
      flagsNatural: flags.contains(areaNatural),
      comments: are["Comments", ""],
    )
