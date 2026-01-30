(module $module1
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (type $WasmListBase <...>)
  (type $_Future <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (global $".FooConst5(" (import "" "FooConst5(") (ref extern))
  (global $"C318 \"[]\"" (import "module0" "global6") (ref $JSStringImpl))
  (global $"C394 5" (import "module0" "global5") (ref $BoxedInt))
  (global $"C396 FooConst0" (import "module0" "global7") (ref $Object))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 34 funcref)
  (table $module0.dispatch0 (import "module0" "dispatch0") 824 funcref)
  (global $"C515 FooConst5" (ref $Object)
    (i32.const 126)
    (i32.const 0)
    (struct.new $Object))
  (global $"C516 \"foo5Code(\"" (ref $JSStringImpl) <...>)
  (global $"C517 \"FooConst5(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst5(")
    (struct.new $JSStringImpl))
  (global $"C518 _InterfaceType" (ref $_InterfaceType) <...>)
  (global $allFooConstants (mut (ref null $WasmListBase))
    (ref.null none))
  (global $fooGlobal5 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 17 (ref.func $foo5)))
  (elem $module0.dispatch0 <...>)
  (func $"foo5Code <noInline>" (param $var0 (ref $#Top))
    (local $var1 (ref $WasmListBase))
    (local $var2 (ref $Object))
    (local $var3 i64)
    global.get $"C515 FooConst5"
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"C516 \"foo5Code(\""
    local.get $var0
    global.get $"C8 \")\""
    i32.const 19
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"C394 5"
    global.set $fooGlobal5
    i32.const 20
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 21
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 22
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 3
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 23
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 12
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 24
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 14
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 25
    call_indirect $module0.cross-module-funcs-0 (result (ref $#Top))
    i32.const 16
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    block $label0 (result (ref $WasmListBase))
      global.get $allFooConstants
      br_on_non_null $label0
      global.get $"C518 _InterfaceType"
      global.get $"C396 FooConst0"
      i32.const 30
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      i32.const 31
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      i32.const 32
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      i32.const 33
      call_indirect $module0.cross-module-funcs-0 (result (ref $Object))
      global.get $"C515 FooConst5"
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
      global.get $"C318 \"[]\""
      i32.const 26
      call_indirect $module0.cross-module-funcs-0 (param i64 i64 (ref null $JSStringImpl)) (result (ref none))
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
    i32.const 415
    i32.add
    call_indirect $module0.dispatch0 (param (ref $Object) (ref null $#Top)) (result (ref null $#Top))
    drop
  )
  (func $fooGlobal5 implicit getter (result (ref $#Top)) <...>)
  (func $FooConst5.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C517 \"FooConst5(\""
    local.get $var1
    global.get $"C8 \")\""
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
  (func $foo5 (result (ref $_Future)) <...>)
)