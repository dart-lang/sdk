(module $module2
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (type $_Future <...>)
  (global $".FooConst2(" (import "" "FooConst2(") (ref extern))
  (global $"\")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $2 (import "module0" "global12") (ref $BoxedInt))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 34 funcref)
  (global $"\"FooConst2(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst2(")
    (struct.new $JSStringImpl))
  (global $"\"foo2Code(\"" (ref $JSStringImpl) <...>)
  (global $FooConst2 (ref $Object)
    (i32.const 124)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal2 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 6 (ref.func $foo2))
    (set 20 (ref.func $"fooGlobal2 implicit getter"))
    (set 21 (ref.func $"foo2Code <noInline>"))
    (set 31 (ref.func $0)))
  (func $"foo2Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $FooConst2
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"\"foo2Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 15
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $2
    global.set $fooGlobal2
    ref.null none
  )
  (func $fooGlobal2 implicit getter (result (ref $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
  (func $FooConst2.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"FooConst2(\""
    local.get $var1
    global.get $"\")\""
    i32.const 15
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    local.get $var0
    local.get $var1
    i32.const 27
    call_indirect $module0.cross-module-funcs-0 (param (ref $Object) (ref null $#Top)) (result (ref null $#Top))
    drop
    ref.null none
  )
  (func $foo2 (result (ref $_Future)) <...>)
)