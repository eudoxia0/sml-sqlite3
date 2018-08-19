open SQLite3

fun println s = print (s ^ "\n")

fun main () =
  let val db = opendb "testdb"
  in
      println "Opened database";
      if (tableExists db "pairs") then
          println "Table 'pairs' already exists"
      else
          let val q = query db "CREATE TABLE pairs (INTEGER i, TEXT S);" []
          in
              exec q;
              println "Create table"
          end;
      let val q = query db
                        "INSERT INTO pairs VALUES (?, ?);"
                        [Integer 10, Text "Hello, world!"]
      in
          exec q
      end;
      let val q = query db
                        "SELECT * FROM pairs;"
                        []
      in
          print (rowsToString (execlist q))
      end;
      close db
  end handle SqlError s => println s

val _ = main ()
