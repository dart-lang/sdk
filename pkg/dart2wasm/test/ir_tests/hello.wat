(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSStringImpl (sub final $#Top (struct
    (field $field0 i32)
    (field $_ref externref))))
  (global $".hello world" (import "" "hello world") (ref extern))
  (global $"C338 \"hello world\"" (ref $JSStringImpl)
    (i32.const 4)
    (global.get $".hello world")
    (struct.new $JSStringImpl))
  (func $"main <noInline>"
    global.get $"C338 \"hello world\""
    call $print
  )
  (func $print (param $var0 (ref $#Top)) <...>)
)