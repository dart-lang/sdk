(module $module1
  (type $#Top <...>)
  (type $Foo (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $i (mut i64)))))
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (global $".Foo called " (import "" "Foo called ") (ref extern))
  (global $"\"Foo called \"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".Foo called ")
    (struct.new $JSStringImpl))
  (func $"useFooAsObject <noInline>" (result (ref null $#Top))
    (local $var0 (ref $Foo))
    i32.const 120
    i32.const 0
    i64.const 0
    struct.new $Foo
    local.tee $var0
    call $Foo.printFoo
    local.get $var0
    call $Foo.printFoo
    ref.null none
  )
  (func $Foo.printFoo (param $var0 (ref $Foo)) <...>)
)