(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSExternWrapper (sub $#Top (struct
    (field $field0 i32)
    (field $_externRef externref))))
  (global $"\"Hello world\"" (mut (ref null $JSExternWrapper))
    (ref.null none))
)