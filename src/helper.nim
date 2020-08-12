import os, options, streams, strutils
import neverwinter/[erf, tlk]

template findIt*(s, pred: untyped): untyped =
  var result: Option[type(s[0])]
  for it {.inject.} in s.items:
    if result.isNone and pred:
      result = some it
  result

proc getDataFiles*(dataDirs: seq[string]): seq[string] =
  for dir in dataDirs:
    if not dir.dirExists:
      echo "Directory not found: " & dir
      quit(QuitFailure)
    for file in dir.joinPath("*").walkFiles:
      if file.splitFile.ext in [".bif", ".hak", ".key", ".tlk"]:
        result &= file

proc getErf*(file, erfType: string): Erf =
  try:
    result = file.openFileStream.readErf
  except:
    echo "Could not read file. Is it a valid ERF/" & erfType.strip & " file?"
    quit(QuitFailure)
  if result.fileType != erfType:
    echo "Not a " & erfType & " file: " & result.fileType
    quit(QuitFailure)

proc tlkText*(strref: StrRef, dlg: SingleTlk, tlk: Option[SingleTlk]): string =
  if strref < 0x01_000_000:
    if dlg[strref].isSome:
      return dlg[strref].get.text
  elif tlk.isSome:
    let entry = tlk.get[strref - 0x01_000_000]
    if entry.isSome:
      return entry.get.text
