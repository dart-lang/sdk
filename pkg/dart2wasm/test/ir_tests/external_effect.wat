(module $M
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedInt (sub final $#Top (struct
    (field $field0 i32)
    (field $value i64))))
  (global $1 (ref $BoxedInt)
    (i32.const 58)
    (i64.const 1)
    (struct.new $BoxedInt))
  (@binaryen.inline 0)
  (func $main
    global.get $1
    call $print
    i32.const 58
    i64.const 2
    struct.new $BoxedInt
    call $print
  )
  (func $print (param $var0 (ref $#Top)) <...>)
)