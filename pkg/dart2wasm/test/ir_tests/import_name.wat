(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $Object (sub $#Top (struct
    (field $field0 i32)
    (field $field1 (mut i32)))))
  (type $JSStringImpl (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_ref externref))))
  (global $".hello world" (import "" "hello world") (ref extern))
  (global $"C375 \"hello world\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".hello world")
    (struct.new $JSStringImpl))
  (func $print (param $var0 (ref $#Top)) <...>)
  (func $"mainFoo <noInline>" (export "func0") (result (ref null $#Top))
    global.get $"C375 \"hello world\""
    call $print
    ref.null none
  )
)