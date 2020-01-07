import unittest, json, strformat

import ../src/allographer/schema_builder
import ../src/allographer/query_builder
from ../src/allographer/connection import getDriver


Schema().create([
  Table().create("auth",[
    Column().increments("id"),
    Column().string("auth")
  ], reset=true),
  Table().create("users",[
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().string("email").nullable(),
    Column().string("address").nullable(),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])

# seeder
RDB().table("auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])

var insertData: seq[JsonNode]
for i in 1..20:
  let authId = if i mod 2 == 0: 2 else: 1
  insertData.add(
    %*{
      "name": &"user{i}",
      "email": &"user{i}@gmail.com",
      "auth_id": authId
    }
  )

RDB().table("users").insert(insertData)
RDB().table("users").delete(2)

suite "query pagination":
  test "count":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    echo t
    check t["count"].getInt() == 3
    
  test "currentPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["currentPage"][0]["id"].getInt() == 5

  test "hasMorePages":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["hasMorePages"].getBool() == true

  test "lastPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["lastPage"].getInt() == 6

  test "nextPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 3)
    check t["nextPage"].getInt() == 4

  test "perPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["perPage"].getInt() == 3

  test "previousPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 1)
    check t["previousPage"].getInt() == 1

  test "total":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["total"].getInt() == 19
  
suite "query fast paginate":
  test "fastPaginate":
    var t = RDB().table("users").select("id", "name").fastPaginate(3)
    echo t
    check t["previousPage"].getInt == 0
    check t["currentPage"][0]["id"].getInt == 1
    check t["nextPage"].getInt == 5

  test "fastPaginate Desc":
    var t = RDB().table("users").select("id", "name").fastPaginate(3, order=Desc)
    echo t
    check t["previousPage"].getInt == 0
    check t["currentPage"][0]["id"].getInt == 20
    check t["nextPage"].getInt == 17

  test "fastPaginateNext":
    var t = RDB().table("users").select("id", "name").fastPaginateNext(3, 5)
    echo t
    check t["previousPage"].getInt == 4
    check t["currentPage"][0]["id"].getInt == 5
    check t["nextPage"].getInt == 8

  test "fastPaginateNext Desc":
    var t = RDB().table("users").select("id", "name").fastPaginateNext(3, 5, order=Desc)
    echo t
    check t["previousPage"].getInt == 6
    check t["currentPage"][0]["id"].getInt == 5
    check t["nextPage"].getInt == 1

  test "fastPaginateBack":
    var t = RDB().table("users").select("id", "name").fastPaginateBack(3, 5)
    echo t
    check t["previousPage"].getInt == 1
    check t["currentPage"][0]["id"].getInt == 3
    check t["nextPage"].getInt == 6

  test "fastPaginateBack Desc":
    var t = RDB().table("users").select("id", "name").fastPaginateBack(3, 5, order=Desc)
    echo t
    check t["previousPage"].getInt == 8
    check t["currentPage"][0]["id"].getInt == 7
    check t["nextPage"].getInt == 4

  test "fastPaninate with WHERE":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginate(3, key="users.id")
    echo t
    check t["hasPreviousPage"].getBool == false
    check t["currentPage"][0]["id"].getInt == 4
    check t["nextPage"].getInt == 10

  test "fastPaninateNext with WHERE":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginate(3, key="users.id")

    t = RDB().table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginateNext(3, t["nextPage"].getInt, key="users.id")
    echo t
    check t["previousPage"].getInt == 8
    check t["currentPage"][0]["id"].getInt == 10
    check t["nextPage"].getInt == 16

  test "fastPaninateBack with WHERE":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginateNext(3, 10, key="users.id")

    t = RDB().table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginateBack(3, t["previousPage"].getInt, key="users.id")
    echo t
    check t["hasPreviousPage"].getBool == false
    check t["currentPage"][0]["id"].getInt == 4
    check t["nextPage"].getInt == 10

suite "fastpaginate result items":
  test "fastPaginate result 1":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", "<", "2")
            .fastPaginate(2, key="users.id")
    echo t
    check t["currentPage"].len == 1
    check t["hasNextPage"].getBool == false

  test "fastPaginate result 2":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", "<", "4")
            .fastPaginate(2, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextPage"].getBool == false

  test "fastPaginate result 3":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", "<", "5")
            .fastPaginate(2, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextPage"].getBool == true


  test "fastPaginateNext result 1":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", "<", "2")
            .fastPaginateNext(2, 1, key="users.id")
    echo t
    check t["currentPage"].len == 1
    check t["hasNextPage"].getBool == false

  test "fastPaginateNext result 2":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", "<", "4")
            .fastPaginateNext(2, 1, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextPage"].getBool == false

  test "fastPaginateNext result 3":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", "<", "5")
            .fastPaginateNext(2, 1, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextPage"].getBool == true


  test "fastPaginateBack result 1":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", ">=", 20)
            .fastPaginateBack(2, 20, key="users.id")
    echo t
    check t["currentPage"].len == 1
    check t["hasPreviousPage"].getBool == false

  test "fastPaginateBack result 2":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", ">=", 19)
            .fastPaginateBack(2, 20, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasPreviousPage"].getBool == false

  test "fastPaginateBack result 3":
    var t = RDB().table("users")
            .select("users.id", "users.name")
            .where("id", ">=", 18)
            .fastPaginateBack(2, 20, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasPreviousPage"].getBool == true
