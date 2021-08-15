# `sml-sqlite3`

[![Build Status](https://travis-ci.org/eudoxia0/sml-sqlite3.svg?branch=master)](https://travis-ci.org/eudoxia0/sml-sqlite3)

SQLite3 bindings for MLton. This is a minimal library: there are no fancy types
or type-safe SQL.

## Example

~~~sml
open SQLite3

fun test () =
  let val db = opendb "path/to/database.db"
  in
    let val q = query db "SELECT ... WHERE x = ? AND y = ?"
                [Integer 10, Text "Hello!"]
    in
      print (rowsToString (execlist q));
      close db
    end
  end
~~~

## The `SQLITE3` Signature

~~~sml
signature SQLITE3 = sig
  type db
  type query

  type bytevec = Word8.word Vector.vector

  datatype value = Null
                 | Integer of int
                 | Real of real
                 | Text of string
                 | Blob of bytevec

  datatype row = Row of value list

  exception SqlError of string;

  val opendb : string -> db
  val close : db -> unit
  val query : db -> string -> value list -> query
  val exec : query -> unit
  val execlist : query -> row list

  val valueToString : value -> string
  val rowToString : row -> string
  val rowsToString : row list -> string

  val tableExists : db -> string -> bool
end
~~~

## Building

Run `make` to build the library, and `make test` to build and run the tests.

## Usage

To use this library in your project, add this to your `.mlb` file:

~~~
path/to/sml-sqlite3/sml-sqlite3.mlb
~~~

And add the following command line flags to your MLton command:

~~~
-link-opt '-lsqlite3'
~~~

See the `Makefile` for an example.

# License

Copyright (c) 2018 Fernando Borretti

Licensed under the MIT License.
