(module $module1
  (type $#Top <...>)
  (type $Object <...>)
  (type $Array<Object?> <...>)
  (type $_Type <...>)
  (type $Array<_Type> <...>)
  (type $JSStringImpl <...>)
  (type $type20 <...>)
  (type $_FunctionType <...>)
  (type $#ClosureBase <...>)
  (type $#Vtable-0-1 <...>)
  (type $#Closure-0-1 <...>)
  (type $H1 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $#Vtable-1-1 <...>)
  (type $#Closure-1-1 <...>)
  (type $#InstantiationContext-1-1 <...>)
  (type $#DummyStruct <...>)
  (type $_InterfaceType <...>)
  (type $BoxedInt <...>)
  (func $print (import "module0" "func5") (param (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate (import "module0" "func6") (param (ref $Array<Object?>)) (result (ref $JSStringImpl)))
  (global $"C21 \")\"" (import "module0" "global0") (ref $JSStringImpl))
  (global $"C28 _InterfaceType" (import "module0" "global5") (ref $_InterfaceType))
  (global $"C455 _FunctionType" (import "module0" "global7") (ref $_FunctionType))
  (global $S.globalH1Bar< (import "S" "globalH1Bar<") (ref extern))
  (global $global7 (ref $#Vtable-1-1) <...>)
  (global $global4 (ref $#DummyStruct) <...>)
  (global $"C459 _FunctionType" (ref $_FunctionType) <...>)
  (global $"C460 globalH1Foo tear-off" (mut (ref null $#Closure-1-1))
    (ref.null none))
  (global $"C461 InstantiationConstant(globalH1Foo<int>)" (mut (ref null $#Closure-0-1))
    (ref.null none))
  (global $"C462 H1" (mut (ref null $H1))
    (ref.null none))
  (global $"C463 \"globalH1Bar<\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $S.globalH1Bar<)
    (struct.new $JSStringImpl))
  (global $"C464 \">(\"" (ref $JSStringImpl) <...>)
  (func $"modH1UseH1 <noInline>" (result (ref null $#Top))
    (local $var0 (ref $#Closure-0-1))
    block $label0 (result (ref $H1))
      global.get $"C462 H1"
      br_on_non_null $label0
      call $"C462 H1 (lazy initializer)}"
    end $label0
    call $print
    drop
    block $label1 (result (ref $H1))
      global.get $"C462 H1"
      br_on_non_null $label1
      call $"C462 H1 (lazy initializer)}"
    end $label1
    struct.get $H1 $fun
    local.tee $var0
    struct.get $#Closure-0-1 $context
    i32.const 84
    i64.const 1
    struct.new $BoxedInt
    local.get $var0
    struct.get $#Closure-0-1 $vtable
    struct.get $#Vtable-0-1 $closureCallEntry-0-1
    call_ref $type20
    drop
    ref.null none
  )
  (func $globalH1Foo (param $var0 (ref $_Type)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C463 \"globalH1Bar<\""
    local.get $var0
    global.get $"C464 \">(\""
    local.get $var1
    global.get $"C21 \")\""
    array.new_fixed $Array<Object?> 5
    call $JSStringImpl._interpolate
    call $print
  )
  (func $"globalH1Foo tear-off dynamic call entry" (param $var0 (ref $#ClosureBase)) (param $var1 (ref $Array<_Type>)) (param $var2 (ref $Array<Object?>)) (param $var3 (ref $Array<Object?>)) (result (ref null $#Top))
    local.get $var1
    i32.const 0
    array.get $Array<_Type>
    local.get $var2
    i32.const 0
    array.get $Array<Object?>
    call $globalH1Foo
  )
  (func $"globalH1Foo tear-off trampoline" (param $var0 (ref struct)) (param $var1 (ref $_Type)) (param $var2 (ref null $#Top)) (result (ref null $#Top))
    local.get $var1
    local.get $var2
    call $globalH1Foo
  )
  (func $dynamic call entry (param $var0 (ref $#ClosureBase)) (param $var1 (ref $Array<_Type>)) (param $var2 (ref $Array<Object?>)) (param $var3 (ref $Array<Object?>)) (result (ref null $#Top)) <...>)
  (func $#dummy function (ref struct) -> (ref null #Top) (param $var0 (ref struct)) (result (ref null $#Top)) <...>)
  (func $instantiation constant trampoline (param $var0 (ref struct)) (param $var1 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $"C462 H1 (lazy initializer)}" (result (ref $H1))
    (local $var0 (ref $#Closure-1-1))
    (local $var1 (ref $#Closure-0-1))
    (local $var2 (ref $H1))
    i32.const 105
    i32.const 0
    block $label0 (result (ref $#Closure-0-1))
      global.get $"C461 InstantiationConstant(globalH1Foo<int>)"
      br_on_non_null $label0
      i32.const 37
      i32.const 0
      block $label1 (result (ref $#Closure-1-1))
        global.get $"C460 globalH1Foo tear-off"
        br_on_non_null $label1
        i32.const 37
        i32.const 0
        global.get $global4
        global.get $global7
        global.get $"C459 _FunctionType"
        struct.new $#Closure-1-1
        local.tee $var0
        global.set $"C460 globalH1Foo tear-off"
        local.get $var0
      end $label1
      global.get $"C28 _InterfaceType"
      struct.new $#InstantiationContext-1-1
      ref.func $"dynamic call entry"
      ref.func $"#dummy function (ref struct) -> (ref null #Top)"
      ref.func $"instantiation constant trampoline"
      struct.new $#Vtable-0-1
      global.get $"C455 _FunctionType"
      struct.new $#Closure-0-1
      local.tee $var1
      global.set $"C461 InstantiationConstant(globalH1Foo<int>)"
      local.get $var1
    end $label0
    struct.new $H1
    local.tee $var2
    global.set $"C462 H1"
    local.get $var2
  )
)