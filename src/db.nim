import db_sqlite, sequtils, strutils

type
  SqliteType* = enum
    sqliteInteger = "integer"
    sqliteReal = "real"
    sqliteText = "text"

  Column* = tuple
    name: string
    coltype: SqliteType

proc createTable(db: DbConn, tablename: string, cols: seq[Column]) =
  let create = "create table " & tablename &
    " (id integer primary key," &
    cols.filterIt(it.name != "id").mapIt(it.name & " " & $it.coltype).join(",") & ")"
  db.exec(create.sql)

proc insert(db: DbConn, tablename: string, cols: seq[Column], rows: seq[seq[string]]) =
  let insertcols = "insert into " & tablename & " (" & cols.mapIt(it.name).join(",") & ")"
  let rowLen = cols.len # all rows have to have the same length, it would be an error otherwise
  db.exec(sql"begin transaction")
  for row in rows:
    db.exec(sql(insertcols & " values (" & newSeqWith(rowLen, "?").join(",") & ")"), row)
  db.exec(sql"commit")

proc writeTable*(rows: seq[object | tuple], filename, tablename: string) =
  let db = open(filename, "", "", "")
  db.exec(sql("drop table if exists " & tablename))
  if rows.len == 0: return
  var cols = newSeq[Column]()
  for k, v in rows[0].fieldPairs:
    let name = if k == "id": k
      elif k[0] == 'x': '_' & k[1 .. ^1]
      else: k.capitalizeAscii
    when v is bool | int:
      cols &= (name, sqliteInteger)
    when v is float:
      cols &= (name, sqliteReal)
    when v is string:
      cols &= (name, sqliteText)
    when k == "id" and v isnot int:
      {.fatal: "Column \"id\" has to be of type int.".}
    when v isnot bool | float | int | string:
      {.fatal: "Handling of this type not implemented.".}
  db.createTable(tablename, cols)
  var stringRows = newSeq[seq[string]]()
  for row in rows:
    var stringRow = newSeq[string]()
    for _, v in row.fieldPairs:
      when v is bool:
        stringRow &= $v.int
      else:
        stringRow &= $v
    stringRows &= stringRow
  db.insert(tablename, cols, stringRows)
  db.close

proc writeTable*(rows: seq[seq[string]], cols: seq[Column], filename, tablename: string) =
  let db = open(filename, "", "", "")
  db.exec(sql("drop table if exists " & tablename))
  if rows.len == 0: return
  db.createTable(tablename, cols)
  db.insert(tablename, cols, rows)
  db.close
