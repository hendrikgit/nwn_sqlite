import db_sqlite, sequtils, strutils

proc createTable(db: DbConn, tablename: string, cols: seq[tuple[name, coltype: string]]) =
  let create = "create table " & tablename &
    " (id integer primary key," &
    cols.mapIt(it.name & " " & it.coltype).join(",") & ")"
  db.exec(create.sql)

proc writeTable*[T](s: seq[T], filename, tablename: string) =
  if s.len == 0: return
  var cols = newSeq[tuple[name, coltype: string]]()
  for k, v in s[0].fieldPairs:
    if v is int:
      cols &= (k, "integer")
    elif v is string:
      cols &= (k, "text")
    when v isnot int | string:
      {.fatal: "Handling of this type not implemented.".}
  let db = open(filename, "", "", "")
  db.exec(sql("drop table if exists " & tablename))
  createTable(db, tablename, cols)
  db.exec(sql"begin transaction")
  let insertcols = "insert into " & tablename & " (" & cols.mapIt(it.name).join(",") & ")"
  for el in s:
    var values = newSeq[string]()
    for _, v in el.fieldPairs:
      values &= $v
    db.exec(sql(insertcols & " values (" & newSeqWith(values.len, "?").join(",") & ")"), values)
  db.exec(sql"commit")
  db.close
