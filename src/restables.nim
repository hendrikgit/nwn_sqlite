import macros, sequtils, strutils, tables
import neverwinter/[resman, twoda]
import db

macro objectDef(cols: openArray[string]): untyped =
  # cols.getImpl.treeRepr:
  # IdentDefs
  #   Sym "cols"
  #   Empty
  #   Bracket
  #     StrLit "x"
  #     StrLit "y"
  #     ...
  let colStrings = toSeq(cols.getImpl[2].children).mapIt it.strVal
  parseStmt("type TwodaRow = object\n  id:int\n  " & colStrings.join(",") & ":string")

template write2daTable*(rm: ResMan, dbName, twodaName, tableName: string, cols: openArray[string]) =
  let resref = newResRef(twodaName, "2da".getResType)
  if rm.contains(resref):
    let twoda = rm[resref].get.readAll.newStringStream.readTwoDA
    var colIdxs = initTable[string, int]()
    for idx, c in twoda.columns:
      if cols.findIt(it == c).isSome:
        colIdxs[c] = idx
    let colsForMacro = cols # the macro needs symbols to work on and cols passed to this template might be an automatic variable
    objectDef(colsForMacro)
    var rows = newSeq[TwodaRow]()
    for rowIdx in 0 .. twoda.high:
      var add = false
      var row = TwodaRow()
      for col, v in row.fieldPairs:
        when col != "id":
          if twoda[rowIdx].get[colIdxs[col]].isSome:
            add = true
            v = twoda[rowIdx].get[colIdxs[col]].get
      if add:
        row.id = rowIdx
        rows &= row
    rows.writeTable(dbName, tableName)
