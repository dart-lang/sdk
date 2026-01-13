(module $module3
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (func $FooConstBase.doit (import "module0" "func14") (param (ref $Object) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func10") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func9") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".FooConst2(" (import "" "FooConst2(") (ref extern))
  (global $"C348 2" (import "module0" "global12") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $"C515 FooConst2" (ref $Object)
    (i32.const 120)
    (i32.const 0)
    (struct.new $Object))
  (global $"C520 \"FooConst2(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst2(")
    (struct.new $JSStringImpl))
  (global $"C528 \"foo2Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal2 (mut (ref null $#Top))
    (ref.null none))
  (func $"foo2Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C515 FooConst2"
    call $print
    drop
    global.get $"C528 \"foo2Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C348 2"
    global.set $fooGlobal2
    ref.null none
  )
  (func $FooConst2.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C520 \"FooConst2(\""
    local.get $var1
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var0
    local.get $var1
    call $FooConstBase.doit
    drop
    ref.null none
  )
)