(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSStringImpl (sub final $#Top (struct
    (field $field0 i32)
    (field $_ref (ref extern)))))
  (global $"\"Hello world\"" (mut (ref null $JSStringImpl))
    (ref.null none))
)