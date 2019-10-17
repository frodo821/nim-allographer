import db_common, strformat, strutils, json
import util, generators
include ../modules/database

type 
  Model* = ref object
    name*: string
    columns*: seq[Column]

  Column* = ref object
    name*: string
    typ*: DbTypeKind
    isNullable*: bool
    isUnsigned*: bool
    isDefault*: bool
    defaultBool*: bool
    defaultInt*: int
    defaultFloat*: float
    defaultString*: string
    info*: JsonNode


proc new*(this:Model, name:string, columns:varargs[Column]): Model =
  Model(
    name: name,
    columns: @columns
  )

proc driverTypeError() =
  let driver = util.getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")

proc migrate*(this:Model) =
  driverTypeError()
  var columnString = ""
  var i = 0
  var primaryColumn = ""
  for column in this.columns:
    echo repr column
    if i > 0:
      columnString.add(", ")
    i += 1

    case column.typ:
      of dbSerial:
        primaryColumn = column.name
        columnString.add(
          serialGenerator(column.name)
        )
      of dbInt:
        columnString.add(
          intGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultInt
          )
        )
      of dbBlob:
        columnString.add(
          blobGenerator(column.name, column.isNullable)
        )
      of dbBool:
        columnString.add(
          boolGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultBool
          )
        )
      of dbFixedChar:
        columnString.add(
          charGenerator(
            column.name,
            parseInt($column.info["maxLength"]),
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of dbDate:
        columnString.add(
          dateGenerator(column.name, column.isNullable)
        )
      of dbDatetime:
        columnString.add(
          datetimeGenerator(column.name, column.isNullable)
        )
      of dbDecimal:
        columnString.add(
          decimalGenerator(
            column.name,
            parseInt($column.info["maximum"]),
            parseInt($column.info["digit"]),
            column.isNullable,
            column.isDefault,
            column.defaultFloat
          )
        )
      of dbFloat:
        columnString.add(
          floatGenerator(
            column.name,
            parseInt($column.info["maximum"]),
            parseInt($column.info["digit"]),
            column.isNullable,
            column.isDefault,
            column.defaultFloat
          )
        )
      of dbEnum:
        columnString.add(
          enumGenerator(
            column.name,
            column.info["options"],
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      else:
        echo ""
      

  # primary key
  var primaryString = ""
  if primaryColumn.len > 0:
    primaryString.add(
      &", PRIMARY KEY ({primaryColumn})"
    )

  let driver = util.getDriver()
  var query = ""

  # create table
  if driver == "sqlite":
    query.add(
      &"CREATE TABLE {this.name} ({columnString})"
    )
  elif driver == "mysql":
    query.add(
      ""
    )
  elif driver == "postgres":
    query.add(
      ""
    )

  var charset = getCharset()
  query.add(
    &"{charset}"
  )
  echo query
  let db = db()
  try:
    db.exec(sql"drop table table_name")
  except Exception:
    echo getCurrentExceptionMsg()

  db.exec(sql query)
  db.close()
