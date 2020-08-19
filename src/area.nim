import neverwinter/[gff, resman, tlk]
import helper

type
  Area = object
    name, resref, tag: string
    height, width: int
    flags: int
    flags_interior, flags_underground, flags_natural: bool
    no_rest: bool
    player_vs_player: int
    tileset: string
    on_enter, on_exit: string
    load_screen_id: int
    is_night: bool
    day_night_cycle: int
    chance_lightning, chance_rain, chance_snow: int
    wind_power: int
    fog_clip_dist: float
    mod_listen_check, mod_spot_check: int
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
      noRest: are["NoRest", 0.GffByte].bool,
      playerVsPlayer: are["PlayerVsPlayer", 0.GffByte].int,
      tileset: $are["Tileset", GffResRef],
      onEnter: $are["OnEnter", GffResRef],
      onExit: $are["OnExit", GffResRef],
      comments: are["Comments", ""],
      loadScreenID: are["LoadScreenID", 0.GffWord].int,
      isNight: are["IsNight", 0.GffByte].bool,
      dayNightCycle: are["DayNightCycle", 0.GffByte].int,
      chanceLightning: are["ChanceLightning", GffInt],
      chanceRain: are["ChanceRain", 0.GffInt],
      chanceSnow: are["ChanceSnow", 0.GffInt],
      windPower: are["WindPower", 0.GffInt],
      fogClipDist: are["FogClipDist", 0.GffFloat],
      modListenCheck: are["ModListenCheck", 0.GffInt],
      modSpotCheck: are["ModSpotCheck", 0.GffInt],
    )
