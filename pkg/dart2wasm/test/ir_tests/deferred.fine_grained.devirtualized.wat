(module $module0
  (type $#Top <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $".Foo0.doitDispatch(" (import "" "Foo0.doitDispatch(") (ref extern))
  (global $".Foo1.doitDispatch(" (import "" "Foo1.doitDispatch(") (ref extern))
  (global $".FooBase(" (import "" "FooBase(") (ref extern))
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 5 funcref)
  (global $"\")\"" (ref $JSExternWrapper) <...>)
  (global $"\"Foo0.doitDispatch(\"" (ref $JSExternWrapper)
    (i32.const 104)
    (i32.const 0)
    (global.get $".Foo0.doitDispatch(")
    (struct.new $JSExternWrapper))
  (global $"\"Foo1.doitDispatch(\"" (ref $JSExternWrapper)
    (i32.const 104)
    (i32.const 0)
    (global.get $".Foo1.doitDispatch(")
    (struct.new $JSExternWrapper))
  (global $"\"FooBase(\"" (ref $JSExternWrapper)
    (i32.const 104)
    (i32.const 0)
    (global.get $".FooBase(")
    (struct.new $JSExternWrapper))
  (global $baseObj (mut (ref null $Object)) <...>)
  (global $foo1Obj (mut (ref null $Object)) <...>)
  (elem $cross-module-funcs-0
    (set 1 (ref.func $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>"))
    (set 2 (ref.func $Foo1.doitDispatch))
    (set 3 (ref.func $JSStringImpl._interpolate3))
    (set 4 (ref.func $print)))
  (func $_TypeError._throwNullCheckErrorWithCurrentStack <noInline> (result (ref none)) <...>)
  (func $"foo0 <noInline>"
    call $"runtimeTrue implicit getter"
    if (result (ref $Object))
      i32.const 122
      i32.const 0
      struct.new $Object
    else
      call $Foo1
    end
    global.set $baseObj
    call $"runtimeTrue implicit getter"
    drop
    call $Foo1
    global.set $foo1Obj
    call $checkLibraryIsLoadedFromLoadId
    i32.const 0
    call_indirect $cross-module-funcs-0 (result (ref null $#Top))
    drop
  )
  (func $runtimeTrue implicit getter (result i32) <...>)
  (func $Foo0.doitDispatch (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"Foo0.doitDispatch(\""
    local.get $var1
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var1
    call $FooBase.doitDispatch
    ref.null none
  )
  (func $Foo1 (result (ref $Object)) <...>)
  (func $Foo1.doitDispatch (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"Foo1.doitDispatch(\""
    local.get $var1
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var1
    call $FooBase.doitDispatch
    ref.null none
  )
  (func $FooBase.doitDispatch (param $var0 (ref null $#Top))
    global.get $"\"FooBase(\""
    local.get $var0
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
  )
  (func $JSStringImpl._interpolate3 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (param $var2 (ref null $#Top)) (result (ref $JSExternWrapper)) <...>)
  (func $checkLibraryIsLoadedFromLoadId  <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)