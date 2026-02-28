(module $module5
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (type $WasmListBase <...>)
  (type $_Future <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (global $".FooConst5(" (import "" "FooConst5(") (ref extern))
  (global $"\")\"" (import "module0" "global4") (ref $JSExternWrapper))
  (global $"\"[]\"" (import "module0" "global6") (ref $JSExternWrapper))
  (global $5 (import "module0" "global5") (ref $BoxedInt))
  (global $FooConst0 (import "module0" "global7") (ref $Object))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 34 funcref)
  (table $module0.dispatch0 (import "module0" "dispatch0") 797 funcref)
  (global $"\"FooConst5(\"" (ref $JSExternWrapper)
    (i32.const 104)
    (i32.const 0)
    (global.get $".FooConst5(")
    (struct.new $JSExternWrapper))
  (global $"\"foo5Code(\"" (ref $JSExternWrapper) <...>)
  (global $FooConst5 (ref $Object)
    (i32.const 127)
    (i32.const 0)
    (struct.new $Object))
  (global $_InterfaceType (ref $_InterfaceType) <...>)
  (global $allFooConstants (mut (ref null $WasmListBase))
    (ref.null none))
  (global $fooGlobal5 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 13 (ref.func $foo5)))
  (elem $module0.dispatch0 <...>)
  (func $"foo5Code <noInline>" (param $var0 (ref $#Top))
    (local $var1 (ref $WasmListBase))
    (local $var2 (ref $Object))
    (local $var3 i64)
    global.get $FooConst5
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"\"foo5Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 15
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $5
    global.set $fooGlobal5
    i32.const 16
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 17
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 19
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 20
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 21
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 22
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 23
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 24
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 25
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    block $label0 (result (ref $WasmListBase))
      global.get $allFooConstants
      br_on_non_null $label0
      global.get $_InterfaceType
      global.get $FooConst0
      i32.const 30
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      i32.const 31
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      i32.const 32
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      i32.const 33
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      global.get $FooConst5
      array.new_fixed $Array<Object?> 6
      i32.const 28
      call_indirect $module0.cross-module-funcs-0 (param (ref $_Type) (ref $Array<Object?>)) (result (ref $WasmListBase))
      local.tee $var1
      global.set $allFooConstants
      local.get $var1
    end $label0
    local.tee $var1
    struct.get $WasmListBase $_length
    local.tee $var3
    i64.eqz
    if
      i64.const 0
      local.get $var3
      global.get $"\"[]\""
      i32.const 26
      call_indirect $module0.cross-module-funcs-0 (param i64 i64 (ref null $JSExternWrapper)) (result (ref none))
      unreachable
    end
    local.get $var1
    struct.get $WasmListBase $_data
    i32.const 0
    array.get $Array<Object?>
    ref.cast $Object
    local.tee $var2
    call $"fooGlobal5 implicit getter"
    local.get $var2
    struct.get $Object $field0
    i32.const 427
    i32.add
    call_indirect $module0.dispatch0 (param (ref $Object) (ref null $#Top)) (result (ref null $#Top))
    drop
  )
  (func $fooGlobal5 implicit getter (result (ref $#Top)) <...>)
  (func $FooConst5.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"FooConst5(\""
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
  (func $foo5 (result (ref $_Future)) <...>)
)