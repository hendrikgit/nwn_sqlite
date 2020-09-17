import strutils, tables
import neverwinter/[resman, tlk, twoda]
import db

template write2daTable*(rm: ResMan, dlg, tlk: Option[SingleTlk], dbName, twodaName, tableName: string, cols: tuple) =
  let resref = newResRef(twodaName, "2da".getResType)
  if rm.contains(resref):
    let twoda = rm[resref].get.readAll.newStringStream.readTwoDA
    var colIdxs = initTable[string, int]()
    for k, _ in cols.fieldPairs:
      let col = if k.startsWith("x"): k[1 .. ^1] else: k
      let idx = twoda.columns.findItIdx it == col
      if idx != -1:
        colIdxs[k] = idx
    var rows = newSeq[cols.typeof]()
    for rowIdx in 0 .. twoda.high:
      var add = false
      var row = cols
      for col, v in row.fieldPairs:
        when col != "id":
          if twoda[rowIdx].get[colIdxs[col]].isSome:
            add = true
            if v == "strref":
              v = twoda[rowIdx].get[colIdxs[col]].get.tlkText(dlg, tlk)
            else:
              v = twoda[rowIdx].get[colIdxs[col]].get
      if add:
        row.id = rowIdx
        rows &= row
    rows.writeTable(dbName, tableName)
  else: # call with empty seq to drop existing table
    writeTable(newSeq[tuple[]](), dbName, tableName)
