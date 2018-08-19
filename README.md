# `sml-sqlite3`

SQLite3 bindings for MLton. This is a minimal library: there are no fancy types
or type-safe SQL.

## Example

~~~sml
open SQLite3

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

## Building

Run `make` to build the library, and `make test` to build and run the tests.

## Usage

To use this library in your project, add this to your `.mlb` file:

~~~
path/to/sml-sqlite3/sml-sqlite3.mlb
~~~

And add the following command line flags to your MLton command:

~~~
-default-ann 'allowFFI true' -link-opt '-lsqlite3'
~~~

See the `Makefile` for an example.

# License

Copyright (c) 2018 Fernando Borretti

Licensed under the MIT License.
