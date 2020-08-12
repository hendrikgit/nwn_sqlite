import streams, strutils
import neverwinter/erf

template findIt*(s, pred: untyped): untyped =
  var result: Option[type(s[0])]
  for it {.inject.} in s.items:
    if result.isNone and pred:
      result = some it
  result

proc getErf*(file, erfType: string): Erf =
  try:
    result = file.openFileStream.readErf
  except:
    echo "Could not read file. Is it a valid ERF/" & erfType.strip & " file?"
    quit(QuitFailure)
  if result.fileType != erfType:
    echo "Not a " & erfType & " file: " & result.fileType
    quit(QuitFailure)
