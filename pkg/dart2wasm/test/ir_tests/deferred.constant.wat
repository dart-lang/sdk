(module $module0
  (type $#Top <...>)
  (type $Object <...>)
  (type $JSStringImpl <...>)
  (type $Array<Object?> <...>)
  (type $BoxedInt <...>)
  (type $_Type <...>)
  (type $Array<_Type> <...>)
  (type $_InterfaceType <...>)
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
  (type $type253 <...>)
  (type $H0 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $type256 <...>)
  (type $#DummyStruct <...>)
  (global $S.globalH1Bar< (import "S" "globalH1Bar<") externref)
  (global $S.globalH0Foo (import "S" "globalH0Foo") externref)
  (global $global29 (ref $#DummyStruct) <...>)
  (global $"C28 _InterfaceType" (ref $_InterfaceType) <...>)
  (global $"C333 \"h0\"" (ref $JSStringImpl) <...>)
  (global $"C372 _FunctionType" (ref $_FunctionType) <...>)
  (global $global32 (ref $#Vtable-1-1) <...>)
  (global $"C376 _FunctionType" (ref $_FunctionType) <...>)
  (global $"C377 globalH1Foo tear-off" (mut (ref null $#Closure-1-1))
    (ref.null none))
  (global $"C378 InstantiationConstant(globalH1Foo<int>)" (mut (ref null $#Closure-0-1))
    (ref.null none))
  (global $"C379 H1" (mut (ref null $H1))
    (ref.null none))
  (global $"C386 \"globalH1Bar<\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $S.globalH1Bar<)
    (struct.new $JSStringImpl))
  (global $global35 (ref $#Vtable-0-1) <...>)
  (global $"C397 globalH0Foo tear-off" (mut (ref null $#Closure-0-1))
    (ref.null none))
  (global $"C398 H0" (mut (ref null $H0))
    (ref.null none))
  (global $"C399 \"globalH0Foo\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $S.globalH0Foo)
    (struct.new $JSStringImpl))
  (table $static1-0 (export "static1-0") 1 (ref null $type256))
  (table $static2-0 (export "static2-0") 1 (ref null $type253))
  (func $#dummy function (ref struct) -> (ref null #Top) (param $var0 (ref struct)) (result (ref null $#Top)) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $"modMainUseH0 <noInline>"
    global.get $"C333 \"h0\""
    call $checkLibraryIsLoaded
    block $label0 (result (ref $H0))
      global.get $"C398 H0"
      br_on_non_null $label0
      call $"C398 H0 (lazy initializer)}"
    end $label0
    call $print
    drop
    global.get $"C333 \"h0\""
    call $checkLibraryIsLoaded
    block $label1 (result (ref $H0))
      global.get $"C398 H0"
      br_on_non_null $label1
      call $"C398 H0 (lazy initializer)}"
    end $label1
    drop
    i64.const 1
    i32.const 0
    call_indirect $static2-0 (param i64) (result (ref null $#Top))
    drop
  )
  (func $checkLibraryIsLoaded (param $var0 (ref $JSStringImpl)) <...>)
  (func $"globalH1Foo tear-off dynamic call entry" (param $var0 (ref $#ClosureBase)) (param $var1 (ref $Array<_Type>)) (param $var2 (ref $Array<Object?>)) (param $var3 (ref $Array<Object?>)) (result (ref null $#Top))
    local.get $var1
    i32.const 0
    array.get $Array<_Type>
    local.get $var2
    i32.const 0
    array.get $Array<Object?>
    i32.const 0
    call_indirect $static1-0 (param (ref $_Type) (ref null $#Top)) (result (ref null $#Top))
  )
  (func $"globalH1Foo tear-off trampoline" (param $var0 (ref struct)) (param $var1 (ref $_Type)) (param $var2 (ref null $#Top)) (result (ref null $#Top))
    local.get $var1
    local.get $var2
    i32.const 0
    call_indirect $static1-0 (param (ref $_Type) (ref null $#Top)) (result (ref null $#Top))
  )
  (func $dynamic call entry (param $var0 (ref $#ClosureBase)) (param $var1 (ref $Array<_Type>)) (param $var2 (ref $Array<Object?>)) (param $var3 (ref $Array<Object?>)) (result (ref null $#Top)) <...>)
  (func $instantiation constant trampoline (param $var0 (ref struct)) (param $var1 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $"C379 H1 (lazy initializer)}" (export "func0") (result (ref $H1))
    (local $var0 (ref $#Closure-1-1))
    (local $var1 (ref $#Closure-0-1))
    (local $var2 (ref $H1))
    i32.const 106
    i32.const 0
    block $label0 (result (ref $#Closure-0-1))
      global.get $"C378 InstantiationConstant(globalH1Foo<int>)"
      br_on_non_null $label0
      i32.const 37
      i32.const 0
      block $label1 (result (ref $#Closure-1-1))
        global.get $"C377 globalH1Foo tear-off"
        br_on_non_null $label1
        i32.const 37
        i32.const 0
        global.get $global29
        global.get $global32
        global.get $"C376 _FunctionType"
        struct.new $#Closure-1-1
        local.tee $var0
        global.set $"C377 globalH1Foo tear-off"
        local.get $var0
      end $label1
      global.get $"C28 _InterfaceType"
      struct.new $#InstantiationContext-1-1
      ref.func $"dynamic call entry"
      ref.func $"#dummy function (ref struct) -> (ref null #Top)"
      ref.func $"instantiation constant trampoline"
      struct.new $#Vtable-0-1
      global.get $"C372 _FunctionType"
      struct.new $#Closure-0-1
      local.tee $var1
      global.set $"C378 InstantiationConstant(globalH1Foo<int>)"
      local.get $var1
    end $label0
    struct.new $H1
    local.tee $var2
    global.set $"C379 H1"
    local.get $var2
  )
  (func $"globalH0Foo tear-off dynamic call entry" (param $var0 (ref $#ClosureBase)) (param $var1 (ref $Array<_Type>)) (param $var2 (ref $Array<Object?>)) (param $var3 (ref $Array<Object?>)) (result (ref null $#Top))
    local.get $var2
    i32.const 0
    array.get $Array<Object?>
    ref.cast $BoxedInt
    struct.get $BoxedInt $value
    i32.const 0
    call_indirect $static2-0 (param i64) (result (ref null $#Top))
  )
  (func $"globalH0Foo tear-off trampoline" (param $var0 (ref struct)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    local.get $var1
    ref.cast $BoxedInt
    struct.get $BoxedInt $value
    i32.const 0
    call_indirect $static2-0 (param i64) (result (ref null $#Top))
  )
  (func $"C398 H0 (lazy initializer)}" (result (ref $H0))
    (local $var0 (ref $#Closure-0-1))
    (local $var1 (ref $H0))
    i32.const 107
    i32.const 0
    block $label0 (result (ref $#Closure-0-1))
      global.get $"C397 globalH0Foo tear-off"
      br_on_non_null $label0
      i32.const 37
      i32.const 0
      global.get $global29
      global.get $global35
      global.get $"C372 _FunctionType"
      struct.new $#Closure-0-1
      local.tee $var0
      global.set $"C397 globalH0Foo tear-off"
      local.get $var0
    end $label0
    struct.new $H0
    local.tee $var1
    global.set $"C398 H0"
    local.get $var1
  )
)