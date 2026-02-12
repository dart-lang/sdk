(module $module8
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (global $".FooConst4(" (import "" "FooConst4(") (ref extern))
  (global $"\")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $4 (import "module0" "global10") (ref $BoxedInt))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 34 funcref)
  (global $"\"FooConst4(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst4(")
    (struct.new $JSStringImpl))
  (global $"\"foo4Code(\"" (ref $JSStringImpl) <...>)
  (global $FooConst4 (ref $Object)
    (i32.const 125)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal4 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 16 (ref.func $"foo4Code <noInline>"))
    (set 25 (ref.func $"fooGlobal4 implicit getter"))
    (set 33 (ref.func $0)))
  (func $"foo4Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $FooConst4
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"\"foo4Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 19
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $4
    global.set $fooGlobal4
    ref.null none
  )
  (func $fooGlobal4 implicit getter (result (ref $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
  (func $FooConst4.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"FooConst4(\""
    local.get $var1
    global.get $"\")\""
    i32.const 19
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    local.get $var0
    local.get $var1
    i32.const 27
    call_indirect $module0.cross-module-funcs-0 (param (ref $Object) (ref null $#Top)) (result (ref null $#Top))
    drop
    ref.null none
  )
)