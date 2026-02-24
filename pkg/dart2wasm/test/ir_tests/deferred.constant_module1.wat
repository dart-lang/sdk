(module $module1
  (type $"dummy struct" <...>)
  (type $#Closure-0-1 <...>)
  (type $#Closure-1-1 <...>)
  (type $#InstantiationContext-1-1 <...>)
  (type $#Top <...>)
  (type $#Vtable-0-1 <...>)
  (type $#Vtable-1-1 <...>)
  (type $Array<Object?> <...>)
  (type $Array<_NamedParameter> <...>)
  (type $Array<_Type> <...>)
  (type $BoxedInt <...>)
  (type $H1 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (type $_FunctionType <...>)
  (type $_InterfaceType <...>)
  (type $_TopType <...>)
  (type $_Type <...>)
  (type $type0 <...>)
  (global $"WasmArray<_NamedParameter>[0]" (import "module0" "global4") (ref $Array<_NamedParameter>))
  (global $"WasmArray<_Type>[0]" (import "module0" "global1") (ref $Array<_Type>))
  (global $"WasmArray<_Type>[1]" (import "module0" "global3") (ref $Array<_Type>))
  (global $"\")\"" (import "module0" "global0") (ref $JSStringImpl))
  (global $.globalH1Bar< (import "" "globalH1Bar<") (ref extern))
  (global $_InterfaceType (import "module0" "global7") (ref $_InterfaceType))
  (global $_TopType (import "module0" "global2") (ref $_TopType))
  (table $module0.constant-table0 (import "module0" "constant-table0") 1 (ref null $_FunctionType))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 9 funcref)
  (global $"InstantiationConstant(globalH1Foo<int>)" (mut (ref null $#Closure-0-1))
    (ref.null none))
  (global $"\">(\"" (ref $JSStringImpl) <...>)
  (global $"\"globalH1Bar<\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $.globalH1Bar<)
    (struct.new $JSStringImpl))
  (global $"globalH1Foo tear-off" (mut (ref null $#Closure-1-1))
    (ref.null none))
  (global $H1 (mut (ref null $H1))
    (ref.null none))
  (global $_FunctionType (ref $_FunctionType) <...>)
  (global $global0 (ref $"dummy struct") <...>)
  (global $global2 (ref $#Vtable-1-1) <...>)
  (elem $module0.cross-module-funcs-0
    (set 0 (ref.func $"modH1UseH1 <noInline>")))
  (func $#dummy function (ref struct) -> (ref null #Top) (param $var0 (ref struct)) (result (ref null $#Top)) <...>)
  (func $"H1 (lazy initializer)" (result (ref $H1))
    (local $var0 (ref $#Closure-1-1))
    (local $var1 (ref $_FunctionType))
    (local $var2 (ref $#Closure-0-1))
    (local $var3 (ref $H1))
    i32.const 120
    i32.const 0
    block $label0 (result (ref $#Closure-0-1))
      global.get $"InstantiationConstant(globalH1Foo<int>)"
      br_on_non_null $label0
      i32.const 32
      i32.const 0
      block $label1 (result (ref $#Closure-1-1))
        global.get $"globalH1Foo tear-off"
        br_on_non_null $label1
        i32.const 32
        i32.const 0
        global.get $global0
        global.get $global2
        global.get $_FunctionType
        struct.new $#Closure-1-1
        local.tee $var0
        global.set $"globalH1Foo tear-off"
        local.get $var0
      end $label1
      global.get $_InterfaceType
      struct.new $#InstantiationContext-1-1
      ref.func $"#dummy function (ref struct) -> (ref null #Top)"
      ref.func $"instantiation constant trampoline"
      struct.new $#Vtable-0-1
      block $label2 (result (ref $_FunctionType))
        i32.const 0
        table.get $module0.constant-table0
        br_on_non_null $label2
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
        local.tee $var1
        table.set $module0.constant-table0
        local.get $var1
      end $label2
      struct.new $#Closure-0-1
      local.tee $var2
      global.set $"InstantiationConstant(globalH1Foo<int>)"
      local.get $var2
    end $label0
    struct.new $H1
    local.tee $var3
    global.set $H1
    local.get $var3
  )
  (func $"globalH1Foo tear-off trampoline" (param $var0 (ref struct)) (param $var1 (ref $_Type)) (param $var2 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"globalH1Bar<\""
    local.get $var1
    global.get $"\">(\""
    local.get $var2
    global.get $"\")\""
    array.new_fixed $Array<Object?> 5
    i32.const 5
    call_indirect $module0.cross-module-funcs-0 (param (ref $Array<Object?>)) (result (ref $JSStringImpl))
    i32.const 4
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
  )
  (func $instantiation constant trampoline (param $var0 (ref struct)) (param $var1 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $"modH1UseH1 <noInline>" (result (ref null $#Top))
    (local $var0 (ref $#Closure-0-1))
    block $label0 (result (ref $H1))
      global.get $H1
      br_on_non_null $label0
      call $"H1 (lazy initializer)"
    end $label0
    i32.const 4
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    block $label1 (result (ref $H1))
      global.get $H1
      br_on_non_null $label1
      call $"H1 (lazy initializer)"
    end $label1
    struct.get $H1 $fun
    local.tee $var0
    struct.get $#Closure-0-1 $context
    i32.const 118
    i64.const 1
    struct.new $BoxedInt
    local.get $var0
    struct.get $#Closure-0-1 $vtable
    struct.get $#Vtable-0-1 $closureCallEntry-0-1
    call_ref $type0
    drop
    ref.null none
  )
)