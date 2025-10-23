(module $module2
  (type $#Top <...>)
  (type $JSStringImpl <...>)
  (func $print (import "module0" "func1") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $module0.global4 (import "module0" "global4") (ref $JSStringImpl))
  (func $globalH0Foo (param $var0 i64) (result (ref null $#Top))
    global.get $module0.global4
    call $print
  )
)