(module $M
  (type $#Top (struct
    (field $#classId i32)))
  (type $BoxedInt (sub final $#Top (struct
    (field $#classId i32)
    (field $value i64))))
  (type $JSExternWrapper (sub $#Top (struct
    (field $#classId i32)
    (field $_externRef (ref extern)))))
  (global $.a (import "" "a") (ref extern))
  (table $foo.tbl (import "foo" "tbl") 1 10 funcref)
  (global $"\"a\"" (ref $JSExternWrapper)
    (i32.const 65)
    (global.get $.a)
    (struct.new $JSExternWrapper))
  (func $Error._throwWithCurrentStackTrace (param $var0 (ref $#Top)) <...>)
  (func $f (param $var0 i32) (result i32) <...>)
  (@binaryen.inline 0)
  (func $main
    i32.const 108
    table.size $foo.tbl
    i64.extend_i32_u
    struct.new $BoxedInt
    call $print
    i32.const 108
    ref.func $f
    i32.const 1
    table.grow $foo.tbl
    i64.extend_i32_s
    struct.new $BoxedInt
    call $print
    i32.const 0
    ref.func $f
    i32.const 2
    table.fill $foo.tbl
    i32.const 0
    ref.func $f
    table.set $foo.tbl
    i32.const 108
    i32.const 42
    i32.const 0
    call_indirect $foo.tbl (param i32) (result i32)
    i64.extend_i32_s
    struct.new $BoxedInt
    call $print
    global.get $"\"a\""
    call $Error._throwWithCurrentStackTrace
    unreachable
  )
  (func $print (param $var0 (ref $#Top)) <...>)
)