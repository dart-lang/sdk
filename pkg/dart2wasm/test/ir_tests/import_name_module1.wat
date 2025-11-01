(module $module1
  (type $#Top (struct
    (field $field0 i32)))
  (func $"mainFoo <noInline>" (import "module0" "func0") (result (ref null $#Top)))
  (func $"deferredFoo <noInline>" (result (ref null $#Top))
    call $"mainFoo <noInline>"
    drop
    ref.null none
  )
)