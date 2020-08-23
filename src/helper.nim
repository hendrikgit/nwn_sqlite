import os, options, sequtils, streams, strutils, tables
import neverwinter/[erf, gff, resman, tlk, twoda]
import resfilecontainer

const dataFileExtensions* = [
  ".2da",
  ".are",
  ".bif",
  ".fac",
  ".git",
  ".hak",
  ".itp",
  ".key",
  ".mod",
  ".tlk",
  ".utc",
  ".uti",
  ".utp"
]

type
  PalcusInfo* = Table[int, tuple[name: string, full: string]]

  FactionInfo* = object
    names*: Table[int, string]
    parents*: Table[int, int]

template findIt*(s, pred: untyped): untyped =
  var result: Option[type(s[0])]
  for it {.inject.} in s.items:
    if result.isNone and pred:
      result = some it
  result

proc addFiles*(rm: ResMan, files: seq[string], filterExtensions = newSeq[string]()) =
  let filesToAdd =
    if filterExtensions.len == 0:
      files
    else:
      files.filterIt filterExtensions.any do (ext: string) -> bool: it.endsWith(ext)
  if filesToAdd.len > 0:
    echo "Adding " & $filesToAdd.len & " files"
    for ext in filterExtensions:
      let extFiles = filesToAdd.filterIt it.endsWith(ext)
      if extFiles.len > 0: echo " " & ext[1 .. ^1] & ": " & $extFiles.len
      if extFiles.len <= 10:
        for f in extFiles:
          echo "  " & f
    rm.add filesToAdd.newResFileContainer

proc flatten*(list: GffList): GffList =
  for li in list:
    if li.hasField("LIST", GffList):
      result.insert li["LIST", GffList].flatten
    else:
      result &= li

proc get2da*(rm: ResMan, name: string): Option[TwoDA] =
  if rm.contains(newResRef(name, "2da".getResType)):
    return some rm[newResRef(name, "2da".getResType)].get.readAll.newStringStream.readTwoDA
  else:
    echo "Warning: 2da not found: " & name & ".2da"

proc getDataFiles*(paths: seq[string]): seq[string] =
  for path in paths:
    if path.existsFile:
      if path.splitFile.ext in dataFileExtensions:
        result &= path
    elif path.existsDir:
      for file in path.joinPath("*").walkFiles:
        if file.splitFile.ext in dataFileExtensions:
          result &= file
    else:
      echo "Not found: " & path
      quit(QuitFailure)

proc getErf*(file, erfType: string): Erf =
  try:
    result = file.openFileStream.readErf
  except:
    echo "Could not read file. Is it a valid ERF/" & erfType.strip & " file?"
    quit(QuitFailure)
  if result.fileType != erfType:
    echo "Not a " & erfType & " file: " & result.fileType
    quit(QuitFailure)

proc getGffRoot*(rm: ResMan, resref: ResRef): GffRoot =
  if rm[resref].isSome:
    try:
      let gffContent = rm[resref].get.readAll
      gffContent.newStringStream.readGffRoot
    except:
      echo "Error reading \"" & $resref & "\". Is it a valid gff file?"
      quit(QuitFailure)
  else:
    echo "Error: GFF " & $resref & " not found."
    quit(QuitFailure)

proc getGffRoot*(rm: ResMan, resref, restype: string): GffRoot =
  getGffRoot(rm, newResRef(resref, restype.getResType))

proc tlkText*(strref: StrRef, dlg, tlk: Option[SingleTlk]): string =
  if dlg.isSome and strref < 0x01_000_000:
    let entry = dlg.get[strref]
    if entry.isSome:
      return entry.get.text
  if tlk.isSome and strref >= 0x01_000_000:
    let entry = tlk.get[strref - 0x01_000_000]
    if entry.isSome:
      return entry.get.text

proc tlkText*(strref: string, dlg, tlk: Option[SingleTlk]): string =
  tlkText(strref.parseInt.StrRef , dlg, tlk)

proc getStr*(locstr: GffCExoLocString, dlg, tlk: Option[SingleTlk]): string =
  if dlg.isSome and locstr.entries.hasKey(dlg.get.language.ord):
    return locstr.entries[dlg.get.language.ord]
  if locstr.entries.hasKey(Language.English.ord):
    return locstr.entries[Language.English.ord]
  for value in locstr.entries.values:
    if value.len > 0: return value
  if locstr.strRef != BadStrRef:
    return locstr.strRef.tlkText(dlg, tlk)

proc toPalcusInfo*(list: GffList, dlg, tlk: Option[SingleTlk], parents = ""): PalcusInfo =
  for li in list:
    if li.hasField("LIST", GffList):
      var name = ""
      if li.hasField("NAME", GffCExoString):
        name = li["NAME", GffCExoString]
      if li.hasField("STRREF", GffDword):
        name = li["STRREF", GffDword].tlkText(dlg, tlk)
      let parentsNew = if parents.len > 0: parents & ">" & name else: name
      if li.hasField("ID", GffByte):
        result[li["ID", GffByte].int] = (name, parentsNew)
      for k, v in toPalcusInfo(li["LIST", GffList], dlg, tlk, parentsNew):
        result[k] = v

proc toFactionInfo*(repute: GffRoot): FactionInfo =
  for fac in repute["FactionList", GffList]:
    result.names[fac.id] = fac["FactionName", GffCExoString]
    let pId = fac["FactionParentID", GffDword]
    if pId == GffDword.high:
      result.parents[fac.id] = fac.id
    else:
      result.parents[fac.id] = pId.int
