(module $module1
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSStringImpl (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_ref externref))))
  (type $Object (sub $#Top (struct
    (field $field0 i32)
    (field $field1 (mut i32)))))
  (func $print (import "module0" "func0") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".hello world" (import "" "hello world") (ref extern))
  (global $"C468 \"hello world\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".hello world")
    (struct.new $JSStringImpl))
  (func $"deferredFoo <noInline>" (result (ref null $#Top))
    call $"mainFoo <noInline>"
    ref.null none
  )
  (func $"mainFoo <noInline>"
    global.get $"C468 \"hello world\""
    call $print
    drop
  )
)