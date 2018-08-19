structure SQLite3 :> SQLITE3 = struct
  type pointer = MLton.Pointer.t
  type db_pointer = pointer
  type stmt_pointer = pointer
  val null = MLton.Pointer.null

  datatype db = Database of pointer

  datatype query = Query of stmt_pointer

  type bytevec = Word8.word Vector.vector

  datatype value = Null
                 | Integer of int
                 | Real of real
                 | Text of string
                 | Blob of bytevec

  datatype row = Row of value list

  exception SqlError of string;

  (* Errors *)

  fun ec 0 = "SQLITE_OK"
    | ec 1 = "SQLITE_ERROR"
    | ec 2 = "SQLITE_INTERNAL"
    | ec 3 = "SQLITE_PERM"
    | ec 4 = "SQLITE_ABORT"
    | ec 5 = "SQLITE_BUSY"
    | ec 6 = "SQLITE_LOCKED"
    | ec 7 = "SQLITE_NOMEM"
    | ec 8 = "SQLITE_READONLY"
    | ec 9 = "SQLITE_INTERRUPT"
    | ec 10 = "SQLITE_IOERR"
    | ec 11 = "SQLITE_CORRUPT"
    | ec 12 = "SQLITE_NOTFOUND"
    | ec 13 = "SQLITE_FULL"
    | ec 14 = "SQLITE_CANTOPEN"
    | ec 15 = "SQLITE_PROTOCOL"
    | ec 16 = "SQLITE_EMPTY"
    | ec 17 = "SQLITE_SCHEMA"
    | ec 18 = "SQLITE_TOOBIG"
    | ec 19 = "SQLITE_CONSTRAINT"
    | ec 20 = "SQLITE_MISMATCH"
    | ec 21 = "SQLITE_MISUSE"
    | ec 22 = "SQLITE_NOLFS"
    | ec 23 = "SQLITE_AUTH"
    | ec 24 = "SQLITE_FORMAT"
    | ec 25 = "SQLITE_RANGE"
    | ec 26 = "SQLITE_NOTADB"
    | ec 27 = "SQLITE_NOTICE"
    | ec 28 = "SQLITE_WARNING"
    | ec 100 = "SQLITE_ROW"
    | ec 101 = "SQLITE_DONE"
    | ec c = "Unknown result code (" ^ (Int.toString c) ^ ")"

  val sqlite3_errstr = _import "sqlite3_errstr" : int -> pointer;

  val sqlite3_errmsg = _import "sqlite3_errmsg" : db_pointer -> pointer;

  fun errstr c =
    let val p = sqlite3_errstr c
    in
        if p = null then
            "[Error string is NULL]"
        else
            SQLiteCStr.toString p
    end

  fun errmsg (Database db) =
    if db = null then
        "[Database is NULL]"
    else
        let val p = sqlite3_errmsg db
        in
            if p = null then
                "[Error string is NULL]"
            else
                SQLiteCStr.toString p
        end

  fun sqlError (msg, code, db) =
    let val s = msg
                ^ (case code of
                       SOME c => "\n  Return code: " ^ (Int.toString c) ^ " (" ^ (ec c) ^ "), code message: \"" ^ (errstr c) ^ "\""
                     | NONE => "")
                ^ (case db of
                       SOME db => "\n  Database error message: \"" ^ (errmsg db) ^ "\""
                     | NONE => "")
    in
        raise SqlError s
    end

  (* Opening database *)

  val sqlite3_open = _import "sqlite3_open" : string * db_pointer ref -> int;

  fun opendb name =
    let val p = ref null
    in
        let val rc = sqlite3_open (name, p)
        in
            if rc <> 0 then
                sqlError ("Error opening database", SOME rc, NONE)
            else
                if !p = null then
                    sqlError ("Database is NULL", NONE, NONE)
                else
                    Database (!p)
        end
    end

  (* Closing database *)

  val sqlite3_close = _import "sqlite3_close" : pointer -> int;

  fun close (Database p) =
    let in
        let val rc = sqlite3_close p
        in
            if rc <> 0 then
                sqlError ("Error closing database", SOME rc, SOME (Database p))
            else
                ()
        end
    end

  (* Preparing statements *)

  val sqlite3_prepare_v2 = _import "sqlite3_prepare_v2" : db_pointer * string * int * stmt_pointer ref * pointer -> int;

  fun prepare (Database p) s =
    let val stmt = ref null
    in
        let val rc = sqlite3_prepare_v2 (p, s, ~1, stmt, null)
        in
            if rc <> 0 then
                sqlError ("Error while preparing statement", SOME rc, SOME (Database p))
            else
                if !stmt = null then
                    sqlError ("Statement is NULL", NONE, NONE)
                else
                    !stmt
        end
    end

  (* Binding parameters in statements *)

  type param_index = int

  val sqlite3_bind_null = _import "sqlite3_bind_null" : stmt_pointer * param_index -> int;
  val sqlite3_bind_int = _import "sqlite3_bind_int" : stmt_pointer * param_index * int -> int;
  val sqlite3_bind_double = _import "sqlite3_bind_double" : stmt_pointer * param_index * real -> int;
  val sqlite3_bind_text = _import "sqlite3_bind_text" : stmt_pointer * param_index * string * int * pointer -> int;
  val sqlite3_bind_blob = _import "sqlite3_bind_blob" : stmt_pointer * param_index * bytevec * int * pointer -> int;

  fun ensureRC i =
    if i <> 0 then
        sqlError ("Bad result code", SOME i, NONE)
    else
        ()

  fun bindValue s idx (v: value) =
    ensureRC (case v of
                  Null => sqlite3_bind_null (s, idx)
                | (Integer i) => sqlite3_bind_int (s, idx, i)
                | (Real r) => sqlite3_bind_double (s, idx, r)
                | (Text text) => sqlite3_bind_text (s, idx, text, ~1, null)
                | (Blob vec) => sqlite3_bind_blob (s, idx, vec, Vector.length vec, null))

  (* Stepping statements *)

  val sqlite3_step = _import "sqlite3_step" : stmt_pointer -> int;

  datatype step = RowStep | Done

  fun step s =
    let val rc = sqlite3_step s
    in
        case rc of
            101 => Done
          | 100 => RowStep
          | c => sqlError ("Bad step", SOME rc, NONE)
    end

  (* Finalizing statements *)

  val sqlite3_finalize = _import "sqlite3_finalize" : stmt_pointer -> int;

  fun finalize s = ensureRC (sqlite3_finalize s)

  (* Result column counts *)

  val sqlite3_column_count = _import "sqlite3_column_count" : stmt_pointer -> int;

  fun columnCount s = sqlite3_column_count s

  (* Result column types *)

  type col_index = int;

  val sqlite3_column_type = _import "sqlite3_column_type" : stmt_pointer * col_index -> int;

  datatype sql_type = NullType
                    | IntegerType
                    | RealType
                    | TextType
                    | BlobType

  fun codeToType 1 = IntegerType
    | codeToType 2 = RealType
    | codeToType 3 = TextType
    | codeToType 4 = BlobType
    | codeToType 5 = NullType
    | codeToType i = sqlError ("Invalid type code: " ^ (Int.toString i), NONE, NONE)

  fun columnType s i = codeToType (sqlite3_column_type (s, i))

  (* Result column values *)

  val sqlite3_column_int = _import "sqlite3_column_int" : stmt_pointer * col_index -> int;
  val sqlite3_column_double = _import "sqlite3_column_double" : stmt_pointer * col_index -> real;
  val sqlite3_column_text = _import "sqlite3_column_text" : stmt_pointer * col_index -> pointer;
  val sqlite3_column_blob = _import "sqlite3_column_blob" : stmt_pointer * col_index -> pointer;
  val sqlite3_column_bytes = _import "sqlite3_column_bytes" : stmt_pointer * col_index -> int;

  (* Loading column values into the ML environment *)

  fun loadColumn s i =
    case (columnType s i) of
        NullType => Null
      | IntegerType => Integer (sqlite3_column_int (s, i))
      | RealType => Real (sqlite3_column_double (s, i))
      | TextType => Text (loadString (sqlite3_column_text (s, i)))
      | BlobType => let val ptr = sqlite3_column_blob (s, i)
                        and len = sqlite3_column_bytes (s, i)
                    in
                        Blob (loadVec ptr len)
                    end
  and loadString ptr =
      if ptr = null then
          sqlError ("String is NULL", NONE, NONE)
      else
          SQLiteCStr.toString ptr
  and loadVec ptr len =
      Vector.tabulate (len, fn idx => MLton.Pointer.getWord8 (ptr, idx))

  (* High-level interface *)

  fun query db str vals =
    let val stmt = prepare db str
    in
        let fun bind_list [] _ = ()
              | bind_list (head::tail) idx = let in
                                                 bindValue stmt idx head;
                                                 bind_list tail (idx+1)
                                             end
        in
            bind_list vals 1;
            Query stmt
        end
    end

  fun loadRow stmt =
    let val cols = columnCount stmt
    in
        let fun loadC i =
              if i = cols then
                  nil
              else
                  let val head = loadColumn stmt i
                  in
                      let val tail = loadC (i+1)
                      in
                          head :: tail
                      end
                  end
        in
            Row (loadC 0)
        end
    end

  fun exec (Query stmt) =
    let in step stmt; finalize stmt; () end

  fun execlist (Query stmt) =
    let val l = execlist_ stmt
    in
        finalize stmt;
        l
    end
  and execlist_ stmt =
    case step stmt of
        Done => nil
      | RowStep => let val row = loadRow stmt
                   in
                       let val tail = execlist_ stmt
                       in
                           row :: tail
                       end
                   end

  (* Printing *)

  fun valueToString Null = "NULL"
    | valueToString (Integer i) = Int.toString i
    | valueToString (Real r) = Real.toString r
    | valueToString (Text t) = "\"" ^ t ^ "\"" (*TODO: escape quotes *)
    | valueToString (Blob v) = "BLOB (" ^ (Int.toString (Vector.length v)) ^ " bytes)"

  fun rowToString (Row l) = "(" ^ (String.concatWith ", " (map valueToString l)) ^ ")"

  fun rowsToString l = String.concatWith "\n" (map rowToString l)

  fun tableExists db table =
    let val q = query db
                  "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
                  [Text table]
    in
        length (execlist q) > 0
    end
end
