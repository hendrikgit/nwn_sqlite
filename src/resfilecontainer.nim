import os, tables
import neverwinter/resman

type
  ResFileContainer* = ref object of ResContainer
    files: Table[ResRef, string]

proc newResFileContainer*(files: seq[string]): ResFileContainer =
  new(result)
  for file in files:
    let (_, fn, ext) = file.splitFile
    let rr = newResRef(fn, ext[1 .. ^1].getResType)
    result.files[rr] = file

method contains*(self: ResFileContainer, rr: ResRef): bool =
  self.files.hasKey(rr)

method demand*(self: ResFileContainer, rr: ResRef): Res =
  let f = self.files[rr]
  newRes(self.newResOrigin, rr, f.getLastModificationTime, f.openFileStream, f.getFileSize.int, ioOwned = true)

method count*(self: ResFileContainer): int =
  self.files.len

method contents*(self: ResFileContainer): OrderedSet[ResRef] =
  for rr in self.files.keys:
    result.incl rr

method `$`*(self: ResFileContainer): string =
  "ResFileContainer: " & $self.files.len & " files"
