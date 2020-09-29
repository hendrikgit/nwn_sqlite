import sequtils, strutils, tables
import neverwinter/[gff, resman, tlk, twoda]
import db, helper

const gitEncounterFields: array[23, Field] = [
  ("id", ftId),
  ("area_id", ftId),
  ("Difficulty", ftInt),
  ("DifficultyIndex", ftInt),
  ("Faction", ftDword),
  ("LocalizedName", ftCExoLocString),
  ("MaxCreatures", ftInt),
  ("OnEntered", ftResRef),
  ("OnExhausted", ftResRef),
  ("OnExit", ftResRef),
  ("OnHeartbeat", ftResRef),
  ("OnUserDefined", ftResRef),
  ("PlayerOnly", ftByte),
  ("RecCreatures", ftInt),
  ("Reset", ftByte),
  ("ResetTime", ftInt),
  ("Respawns", ftInt),
  ("SpawnOption", ftInt),
  ("Tag", ftCExoString),
  ("TemplateResRef", ftResRef),
  ("XPosition", ftFloat),
  ("YPosition", ftFloat),
  ("ZPosition", ftFloat),
]

type
  Area = object
    id: int
    name, xNameLowercase, resRef, tag: string
    height, width: int
    flags: int
    xFlagInterior, xFlagUnderground, xFlagNatural: bool
    noRest: bool
    playerVsPlayer: int
    tileset, xTilesetName: string
    onEnter, onExit, onHeartbeat, onUserDefined: string
    loadScreenID: int
    isNight: bool
    dayNightCycle: int
    chanceLightning, chanceRain, chanceSnow: int
    windPower: int
    fogClipDist: float
    modListenCheck, modSpotCheck: int
    comments: string
    ambientSndDay, ambientSndDayVol, ambientSndNight, ambientSndNitVol: int
    envAudio, musicBattle, musicDay, musicDelay, musicNight: int
    xAmbientSndDayResource, xAmbientSndNightResource: string
    xMusicBattleResource, xMusicDayResource, xMusicDelayResource, xMusicNightResource: string

  AreaFlag {.size: 4.} = enum
    areaInterior = "interior" # exterior if unset
    areaUnderground = "underground" # aboveground if unset
    areaNatural = "natural" # urban if unset

  AreaFlags = set[AreaFlag]

proc toFlags(v: int): AreaFlags =
  cast[AreaFlags](v)

proc writeAreaTables*(list: seq[ResRef], rm: ResMan, dlg, tlk: Option[SingleTlk], dbName: string) =
  let sound2da = rm.get2da("ambientsound")
  let music2da = rm.get2da("ambientmusic")
  var
    areas = newSeq[Area]()
    tilesetNames = initTable[string, string]()
    encounters = newSeq[seq[string]]()
    encounterId = 1
    encounterCreatures = newSeq[seq[string]]()
  for idxArea, rr in list:
    let
      are = rm.getGffRoot(rr)
      gitrr = newResRef(rr.resRef, "git".getResType)
      name = are["Name", GffCExoLocString].getStr(dlg, tlk)
      flag = are["Flags", 0.GffDword].int
      flags = flag.toFlags
    var gitAreaProps = newTable[string, GffField]()
    if rm.contains(gitrr):
      let git = rm.getGffRoot(gitrr)
      gitAreaProps = git["AreaProperties", GffStruct].fields
      for e in git["Encounter List", GffList]:
        encounters &= gitEncounterFields.map proc (f: Field): string =
          if f.name == "id": $encounterId
          elif f.name == "area_id": $(idxArea + 1)
          else: e.getStringValue(f, dlg, tlk)
        for c in e["CreatureList", GffList]:
          encounterCreatures &= @[$encounterId, $c["ResRef", "".GffResRef], $c["SingleSpawn", 0.GffByte]]
        inc encounterId
    var area = Area(
      id: idxArea + 1,
      name: name,
      xNameLowercase: name.toLower,
      resref: rr.resRef,
      tag: are["Tag", "".GffCExoString],
      flags: flag,
      xFlagInterior: flags.contains(areaInterior),
      xFlagUnderground: flags.contains(areaUnderground),
      xFlagNatural: flags.contains(areaNatural),
      comments: are["Comments", "".GffCExoString],
      loadScreenID: are["LoadScreenID", 0.GffWord].int,
      fogClipDist: are["FogClipDist", 0.GffFloat],
    )
    for k, v in area.fieldPairs:
      let label {.used.} = k.capitalizeAscii
      when v is int:
        case label
        of "NoRest", "PlayerVsPlayer", "IsNight", "DayNightCycle":
          v = are[label, 0.GffByte].int
        of "Height", "Width", "ChanceLightning", "ChanceRain", "ChanceSnow",
            "WindPower", "ModListenCheck", "ModSpotCheck":
          v = are[label, -1.GffInt]
        of "AmbientSndDay", "AmbientSndDayVol", "AmbientSndNight", "AmbientSndNitVol",
            "EnvAudio", "MusicBattle", "MusicDay", "MusicDelay", "MusicNight":
          if gitAreaProps.hasKey(label): v = gitAreaProps[label].getValue(GffInt)
      when v is string:
        case label
        of "Tileset", "OnEnter", "OnExit", "OnHeartbeat", "OnUserDefined":
          v = $are[label, "".GffResRef]
    if sound2da.isSome:
      area.xAmbientSndDayResource = sound2da.get(TwoDA())[area.ambientSndDay, "Resource", ""]
      area.xAmbientSndNightResource = sound2da.get[area.ambientSndNight, "Resource", ""]
    if music2da.isSome:
      area.xMusicBattleResource = music2da.get[area.musicBattle, "Resource", ""]
      area.xMusicDayResource = music2da.get[area.musicDay, "Resource", ""]
      area.xMusicDelayResource = music2da.get[area.musicDelay, "Resource", ""]
      area.xMusicNightResource = music2da.get[area.musicNight, "Resource", ""]
    if area.tileset in tilesetNames:
      area.xTilesetName = tilesetNames[area.tileset]
    elif rm.contains(newResRef(area.tileset, "set".getResType)):
      let name = rm.demand(newResRef(area.tileset, "set".getResType))
        .readAll.getTilesetName(dlg, tlk)
      tilesetNames[area.tileset] = name
      area.xTilesetName = name
    areas &= area
  areas.writeTable(dbName, "areas")
  encounters.writeTable(gitEncounterFields.toColumns, dbName, "area_encounters")
  encounterCreatures.writeTable(
    [("area_encounter_id", sqliteInteger), ("ResRef", sqliteText), ("SingleSpawn", sqliteText)],
    dbName,
    "area_encounters_creatures"
  )
