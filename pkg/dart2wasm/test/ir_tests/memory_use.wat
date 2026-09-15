(module $M
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (type $JSExternWrapper (sub $#Top (struct
    (field $#classId i32)
    (field $_externRef externref))))
  (memory $foo.mem (import "foo" "mem") 1)
  (memory $foo.second_mem (import "foo" "second_mem") 1)
  (func $"foo.mem (import)" (import "foo" "mem") (result anyref))
  (global $.a (import "" "a") (ref extern))
  (global $"\"a\"" (ref $JSExternWrapper)
    (i32.const 65)
    (global.get $.a)
    (struct.new $JSExternWrapper))
  (func $Error._throwWithCurrentStackTrace (param $var0 (ref $#Top)) <...>)
  (@binaryen.inline 0)
  (func $main
    i32.const 1
    memory.grow $foo.mem
    drop
    i32.const 98
    i32.const 0
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    i32.const 98
    i32.const 0
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    i32.const 98
    i32.const 0
    f64.load align=8
    struct.new $BoxedDouble
    call $print
    i32.const 98
    i32.const 1
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    i32.const 98
    i32.const 1
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    memory.size $foo.mem
    i32.const 32
    i32.store offset=10
    memory.size $foo.second_mem
    f64.const 42.5
    f64.store$foo.second_mem offset=258 align=8
    i32.const 98
    memory.size $foo.second_mem
    f64.load$foo.second_mem offset=258 align=8
    struct.new $BoxedDouble
    call $print
    call $"foo.mem (import)"
    drop
    global.get $"\"a\""
    call $Error._throwWithCurrentStackTrace
    unreachable
  )
  (func $print (param $var0 (ref $#Top)) <...>)
)