import db_common, strformat, strutils, json
import ../base
import ../generators/sqlite_generators

proc migrate*(this:Model):string =

  var columnString = ""
  var primaryColumn = ""
  for i, column in this.columns:
    # echo repr column
    if i > 0:
      columnString.add(", ")

    case column.typ:
      # int ===================================================================
      of rdbIncrements:
        primaryColumn = column.name
        columnString.add(
          serialGenerator(column.name)
        )
      of rdbInteger:
        columnString.add(
          intGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultInt,
            column.isUnsigned
          )
        )
      of rdbSmallInteger:
        columnString.add(
          intGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultInt,
            column.isUnsigned
          )
        )
      of rdbMediumInteger:
        columnString.add(
          intGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultInt,
            column.isUnsigned
          )
        )
      of rdbBigInteger:
        columnString.add(
          intGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultInt,
            column.isUnsigned
          )
        )
      # float =================================================================
      of rdbDecimal:
        columnString.add(
          decimalGenerator(
            column.name,
            parseInt($column.info["maximum"]),
            parseInt($column.info["digit"]),
            column.isNullable,
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
          )
        )
      of rdbDouble:
        columnString.add(
          decimalGenerator(
            column.name,
            parseInt($column.info["maximum"]),
            parseInt($column.info["digit"]),
            column.isNullable,
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
          )
        )
      of rdbFloat:
        columnString.add(
          floatGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
          )
        )
      # char ==================================================================
      of rdbChar:
        columnString.add(
          charGenerator(
            column.name,
            parseInt($column.info["maxLength"]),
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of rdbString:
        columnString.add(
          varcharGenerator(
            column.name,
            parseInt($column.info["maxLength"]),
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      # text ==================================================================
      of rdbText:
        columnString.add(
          textGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of rdbMediumText:
        columnString.add(
          textGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of rdbLongText:
        columnString.add(
          textGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      # date ==================================================================
      of rdbDate:
        columnString.add(
          dateGenerator(column.name, column.isNullable, column.isDefault)
        )
      of rdbDatetime:
        columnString.add(
          datetimeGenerator(column.name, column.isNullable, column.isDefault)
        )
      of rdbTime:
        columnString.add(
          timeGenerator(
            column.name,
            column.isNullable,
            column.isDefault
          )
        )
      of rdbTimestamp:
        columnString.add(
          timestampGenerator(
            column.name,
            column.isNullable,
            column.isDefault
          )
        )
      of rdbTimestamps:
        columnString.add(
          timestampsGenerator()
        )
      of rdbSoftDelete:
        columnString.add(
          softDeleteGenerator()
        )
      # others ================================================================
      of rdbBinary:
        columnString.add(
          blobGenerator(column.name, column.isNullable)
        )
      of rdbBoolean:
        columnString.add(
          boolGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultBool
          )
        )
      of rdbEnumField:
        columnString.add(
          enumGenerator(
            column.name,
            column.info["options"].getElems,
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of rdbJson:
        columnString.add(
          jsonGenerator(
            column.name,
            column.isNullable
          )
        )
      of rdbForeign:
        columnString.add(
          foreignGenerator(
            column.name,
            column.info["table"].getStr(),
            column.info["column"].getStr()
          )
        )

  # primary key
  var primaryString = ""
  if primaryColumn.len > 0:
    primaryString.add(
      &", PRIMARY KEY ({primaryColumn})"
    )

  var query = &"CREATE TABLE {this.name} ({columnString})"
  return query
