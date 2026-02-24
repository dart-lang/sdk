(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (memory $foo.mem (import "foo" "mem") 1)
  (func $"main <noInline>"
    memory.size $foo.mem
    drop
    i32.const 1
    memory.grow $foo.mem
    drop
    i32.const 99
    i32.const 0
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    i32.const 99
    i32.const 0
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    i32.const 99
    i32.const 0
    f64.load align=8
    struct.new $BoxedDouble
    call $print
    i32.const 99
    i32.const 1
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    i32.const 99
    i32.const 1
    f32.load align=4
    f64.promote_f32
    struct.new $BoxedDouble
    call $print
    memory.size $foo.mem
    i32.const 32
    i32.store offset=10
  )
  (func $print (param $var0 (ref $#Top)) <...>)
)