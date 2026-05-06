(module $module0
  (type $JSExternWrapper (sub $Object (struct
    (field $field0 i32)
    (field $_externRef externref))))
  (type $Object (struct
    (field $field0 i32)))
  (global $"\"Hello world\"" (mut (ref null $JSExternWrapper))
    (ref.null none))
)