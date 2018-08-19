structure SQLiteCStr :> SQLITE_CSTR = struct
  type cstring = MLton.Pointer.t

  val strlen = _import "strlen": cstring -> int;

  fun readChar ptr idx =
      Byte.byteToChar (MLton.Pointer.getWord8 (ptr, idx))

  fun toString cstr =
      if cstr = MLton.Pointer.null then
          raise Fail "null pointer passed to SQLiteCStr.toString"
      else
          CharVector.tabulate (strlen cstr, readChar cstr)
end
