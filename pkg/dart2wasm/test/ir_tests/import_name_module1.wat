(module $M1
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSExternWrapper (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_externRef externref))))
  (type $Object (sub $#Top (struct
    (field $field0 i32)
    (field $field1 (mut i32)))))
  (global $".hello world" (import "" "hello world") (ref extern))
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 2 funcref)
  (global $"\"hello world\"" (ref $JSExternWrapper)
    (i32.const 65)
    (i32.const 0)
    (global.get $".hello world")
    (struct.new $JSExternWrapper))
  (elem $M.cross-module-funcs-0
    (set 0 (ref.func $deferredFoo)))
  (@binaryen.inline 0)
  (func $deferredFoo
    call $mainFoo
  )
  (@binaryen.inline 0)
  (func $mainFoo
    global.get $"\"hello world\""
    i32.const 1
    call_indirect (param (ref null $#Top))
  )
)