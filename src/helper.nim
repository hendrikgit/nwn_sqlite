import os, options, sequtils, streams, strutils, tables
import neverwinter/[erf, gff, resfile, resman, tlk, twoda]

const dataFileExtensions = [".2da", ".bif", ".hak", ".key", ".mod", ".tlk", ".utc", ".uti"]

type
  PalcusInfo* = Table[int, tuple[name: string, full: string]]

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
      let count = filesToAdd.countIt it.endsWith(ext)
      if count > 0: echo " " & ext & ": " & $count
    for f in filesToAdd:
      if filesToAdd.len <= 10: echo "  " & f
      rm.add f.newResFile

proc flatten*(list: GffList): GffList =
  for li in list:
    if li.hasField("LIST", GffList):
      result.insert li["LIST", GffList].flatten
    else:
      result &= li

proc get2da*(rm: ResMan, name: string): TwoDA =
  if rm.contains(newResRef(name, "2da".getResType)):
    result = rm[newResRef(name, "2da".getResType)].get.readAll.newStringStream.readTwoDA
  else:
    echo name & ".2da not found"
    quit(QuitFailure)

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

proc tlkText*(strref: StrRef, dlg: SingleTlk, tlk: Option[SingleTlk]): string =
  if strref < 0x01_000_000:
    if dlg[strref].isSome:
      return dlg[strref].get.text
  elif tlk.isSome:
    let entry = tlk.get[strref - 0x01_000_000]
    if entry.isSome:
      return entry.get.text

proc tlkText*(strref: string, dlg: SingleTlk, tlk: Option[SingleTlk]): string =
  tlkText(strref.parseInt.StrRef , dlg, tlk)

proc getStr*(locstr: GffCExoLocString, dlg: SingleTlk, tlk: Option[SingleTlk]): string =
  if locstr.strRef != BadStrRef:
    return locstr.strRef.tlkText(dlg, tlk)
  if locstr.entries.hasKey(dlg.language.ord):
    return locstr.entries[dlg.language.ord]
  if locstr.entries.hasKey(Language.English.ord):
    return locstr.entries[Language.English.ord]
  for value in locstr.entries.values:
    if value.len > 0: return value

proc toPalcusInfo*(list: GffList, dlg: SingleTlk, tlk: Option[SingleTlk], parents = ""): PalcusInfo =
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
