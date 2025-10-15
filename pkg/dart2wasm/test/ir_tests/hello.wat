(module $module0
  (type $#Top (struct (field $field0 i32)))
  (type $JSStringImpl (sub final $#Top (struct (field $field0 i32) (field $field1 externref))))
  (global $"S.hello world" (import "S" "hello world") externref)
  (global $"C327 \"hello world\"" (ref $JSStringImpl) (i32.const 4) (global.get $"S.hello world") (struct.new $JSStringImpl))
  (func $"main <noInline>"
    global.get $"C327 \"hello world\""
    call $print
  )
  (func $print (param $var0 (ref $#Top)))
)