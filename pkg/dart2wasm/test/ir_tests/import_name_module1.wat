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
  (global $".hello world" (import "" "hello world") (ref extern))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 2 funcref)
  (global $"C468 \"hello world\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".hello world")
    (struct.new $JSStringImpl))
  (elem $module0.cross-module-funcs-0
    (set 0 (ref.func $"deferredFoo <noInline>")))
  (func $"deferredFoo <noInline>" (result (ref null $#Top))
    call $"mainFoo <noInline>"
    ref.null none
  )
  (func $"mainFoo <noInline>"
    global.get $"C468 \"hello world\""
    i32.const 1
    call_indirect (param (ref null $#Top)) (result (ref null $#Top))
    drop
  )
)