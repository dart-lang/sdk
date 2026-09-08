(module $M
  (type $#Top (struct
    (field $#classId i32)))
  (type $EmbedderStringImpl (sub final $#Top (struct
    (field $#classId i32)
    (field $_ref (ref extern)))))
  (global $"\"Hello world\"" (mut (ref null $EmbedderStringImpl))
    (ref.null none))
)