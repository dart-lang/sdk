(module $module0
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (global $".FooConst0(" (import "" "FooConst0(") (ref extern))
  (global $".FooConstBase(" (import "" "FooConstBase(") (ref extern))
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 17 funcref)
  (global $"C12 0" (ref $BoxedInt) <...>)
  (global $"C395 \"FooConstBase(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConstBase(")
    (struct.new $JSStringImpl))
  (global $"C396 FooConst0" (ref $Object)
    (i32.const 121)
    (i32.const 0)
    (struct.new $Object))
  (global $"C397 \"FooConst0(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst0(")
    (struct.new $JSStringImpl))
  (global $"C513 \"foo0Code(\"" (ref $JSStringImpl) <...>)
  (global $"C8 \")\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal0 (mut (ref null $#Top))
    (ref.null none))
  (func $"foo0Code <noInline>" (export "func12") (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C396 FooConst0"
    call $print
    drop
    global.get $"C513 \"foo0Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C12 0"
    global.set $fooGlobal0
    ref.null none
  )
  (func $FooConst0.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C397 \"FooConst0(\""
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
  (func $FooConstBase.doit (export "func14") (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C395 \"FooConstBase(\""
    local.get $var1
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    ref.null none
  )
  (func $JSStringImpl._interpolate3 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (param $var2 (ref null $#Top)) (result (ref $JSStringImpl)) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)