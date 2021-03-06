import json
import ../connection

type
  RDB* = ref object of RootObj
    db*: DbConn
    isInTransaction*: bool
    query*: JsonNode
    sqlString*: string
    placeHolder*: seq[string]
