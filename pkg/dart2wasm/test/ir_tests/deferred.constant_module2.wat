(module $module2
  (type $"dummy struct" <...>)
  (type $#Closure-0-1 <...>)
  (type $#Top <...>)
  (type $#Vtable-0-1 <...>)
  (type $Array<_NamedParameter> <...>)
  (type $Array<_Type> <...>)
  (type $BoxedInt <...>)
  (type $H0 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (type $_FunctionType <...>)
  (type $_TopType <...>)
  (global $"WasmArray<_NamedParameter>[0]" (import "module0" "global4") (ref $Array<_NamedParameter>))
  (global $"WasmArray<_Type>[0]" (import "module0" "global1") (ref $Array<_Type>))
  (global $"WasmArray<_Type>[1]" (import "module0" "global3") (ref $Array<_Type>))
  (global $.globalH0Foo (import "" "globalH0Foo") (ref extern))
  (global $_TopType (import "module0" "global2") (ref $_TopType))
  (table $module0.constant-table0 (import "module0" "constant-table0") 1 (ref null $_FunctionType))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 9 funcref)
  (global $"\"globalH0Foo\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $.globalH0Foo)
    (struct.new $JSStringImpl))
  (global $"globalH0Foo tear-off" (mut (ref null $#Closure-0-1))
    (ref.null none))
  (global $H0 (mut (ref null $H0))
    (ref.null none))
  (global $global0 (ref $"dummy struct") <...>)
  (global $global2 (ref $#Vtable-0-1) <...>)
  (elem $module0.cross-module-funcs-0
    (set 6 (ref.func $globalH0Foo))
    (set 7 (ref.func $0))
    (set 8 (ref.func $"H0 (lazy initializer)")))
  (func $"H0 (lazy initializer)" (result (ref $H0))
    (local $var0 (ref $_FunctionType))
    (local $var1 (ref $#Closure-0-1))
    (local $var2 (ref $H0))
    i32.const 120
    i32.const 0
    block $label0 (result (ref $#Closure-0-1))
      global.get $"globalH0Foo tear-off"
      br_on_non_null $label0
      i32.const 33
      i32.const 0
      global.get $global0
      global.get $global2
      block $label1 (result (ref $_FunctionType))
        i32.const 0
        table.get $module0.constant-table0
        br_on_non_null $label1
        i32.const 0
        i32.const 12
        i32.const 0
        i32.const 0
        i64.const 0
        global.get $"WasmArray<_Type>[0]"
        global.get $"WasmArray<_Type>[0]"
        global.get $_TopType
        global.get $"WasmArray<_Type>[1]"
        i64.const 1
        global.get $"WasmArray<_NamedParameter>[0]"
        struct.new $_FunctionType
        local.tee $var0
        table.set $module0.constant-table0
        local.get $var0
      end $label1
      struct.new $#Closure-0-1
      local.tee $var1
      global.set $"globalH0Foo tear-off"
      local.get $var1
    end $label0
    struct.new $H0
    local.tee $var2
    global.set $H0
    local.get $var2
  )
  (func $"globalH0Foo tear-off trampoline" (param $var0 (ref struct)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    local.get $var1
    ref.cast $BoxedInt
    struct.get $BoxedInt $value
    call $globalH0Foo
  )
  (func $null (result (ref null $H0)) <...>)
  (func $globalH0Foo (param $var0 i64) (result (ref null $#Top))
    global.get $"\"globalH0Foo\""
    i32.const 4
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
  )
)