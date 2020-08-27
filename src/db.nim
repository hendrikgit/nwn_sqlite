import db_sqlite, sequtils, strutils

proc createTable(db: DbConn, tablename: string, cols: seq[tuple[name, coltype: string]]) =
  let create = "create table " & tablename &
    " (id integer primary key," &
    cols.filterIt(it.name != "id").mapIt(it.name & " " & it.coltype).join(",") & ")"
  db.exec(create.sql)

proc writeTable*[T](s: seq[T], filename, tablename: string) =
  let db = open(filename, "", "", "")
  db.exec(sql("drop table if exists " & tablename))
  if s.len == 0: return
  var cols = newSeq[tuple[name, coltype: string]]()
  for k, v in s[0].fieldPairs:
    let name = if k == "id": k
      elif k[0] == 'x': '_' & k[1 .. ^1]
      else: k.capitalizeAscii
    when v is bool | int:
      cols &= (name, "integer")
    when v is float:
      cols &= (name, "real")
    when v is string:
      cols &= (name, "text")
    when k == "id" and v isnot int:
      {.fatal: "Column \"id\" has to be of type int.".}
    when v isnot bool | float | int | string:
      {.fatal: "Handling of this type not implemented.".}
  createTable(db, tablename, cols)
  db.exec(sql"begin transaction")
  let insertcols = "insert into " & tablename & " (" & cols.mapIt(it.name).join(",") & ")"
  for el in s:
    var values = newSeq[string]()
    for _, v in el.fieldPairs:
      when v is bool:
        values &= $v.int
      else:
        values &= $v
    db.exec(sql(insertcols & " values (" & newSeqWith(values.len, "?").join(",") & ")"), values)
  db.exec(sql"commit")
  db.close
