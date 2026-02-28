(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSExternWrapper (sub $#Top (struct
    (field $field0 i32)
    (field $_externRef externref))))
  (global $".hello world" (import "" "hello world") (ref extern))
  (global $"\"hello world\"" (ref $JSExternWrapper)
    (i32.const 105)
    (global.get $".hello world")
    (struct.new $JSExternWrapper))
  (func $"main <noInline>"
    global.get $"\"hello world\""
    call $print
  )
  (func $print (param $var0 (ref $#Top)) <...>)
)