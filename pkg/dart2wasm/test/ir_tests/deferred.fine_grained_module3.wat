(module $module3
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (type $_Future <...>)
  (global $".FooConst3(" (import "" "FooConst3(") (ref extern))
  (global $"\")\"" (import "module0" "global4") (ref $JSExternWrapper))
  (global $3 (import "module0" "global11") (ref $BoxedInt))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 34 funcref)
  (global $"\"FooConst3(\"" (ref $JSExternWrapper)
    (i32.const 104)
    (i32.const 0)
    (global.get $".FooConst3(")
    (struct.new $JSExternWrapper))
  (global $"\"foo3Code(\"" (ref $JSExternWrapper) <...>)
  (global $FooConst3 (ref $Object)
    (i32.const 125)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal3 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 11 (ref.func $foo3))
    (set 22 (ref.func $"fooGlobal3 implicit getter"))
    (set 23 (ref.func $"foo3Code <noInline>"))
    (set 32 (ref.func $0)))
  (func $"foo3Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $FooConst3
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"\"foo3Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 15
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $3
    global.set $fooGlobal3
    ref.null none
  )
  (func $fooGlobal3 implicit getter (result (ref $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
  (func $FooConst3.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"FooConst3(\""
    local.get $var1
    global.get $"\")\""
    i32.const 15
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
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
  (func $foo3 (result (ref $_Future)) <...>)
)