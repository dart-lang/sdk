(module $module0
  (type $#Top <...>)
  (type $Foo0 <...>)
  (type $Foo1 <...>)
  (type $FooBase <...>)
  (type $JSStringImpl <...>)
  (type $type0 <...>)
  (global $".Foo0.doitDispatch(" (import "" "Foo0.doitDispatch(") (ref extern))
  (global $".Foo1.doitDispatch(" (import "" "Foo1.doitDispatch(") (ref extern))
  (global $".FooBase(" (import "" "FooBase(") (ref extern))
  (table $static0-0 (export "static0-0") 1 (ref null $type0))
  (global $"C383 \"FooBase(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooBase(")
    (struct.new $JSStringImpl))
  (global $"C384 \"Foo1.doitDispatch(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".Foo1.doitDispatch(")
    (struct.new $JSStringImpl))
  (global $"C385 \"Foo0.doitDispatch(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".Foo0.doitDispatch(")
    (struct.new $JSStringImpl))
  (global $"C8 \")\"" (ref $JSStringImpl) <...>)
  (global $baseObj (mut (ref null $FooBase)) <...>)
  (global $foo1Obj (mut (ref null $Foo1)) <...>)
  (func $"foo0 <noInline>"
    call $"runtimeTrue implicit getter"
    if (result (ref $FooBase))
      i32.const 118
      i32.const 0
      struct.new $Foo0
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
    call_indirect $static0-0 (result (ref null $#Top))
    drop
  )
  (func $runtimeTrue implicit getter (result i32) <...>)
  (func $Foo0.doitDispatch (param $var0 (ref $FooBase)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $Foo0))
    local.get $var0
    ref.cast $Foo0
    local.set $var2
    global.get $"C385 \"Foo0.doitDispatch(\""
    local.get $var1
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var1
    call $FooBase.doitDispatch
    ref.null none
  )
  (func $Foo1 (result (ref $Foo1)) <...>)
  (func $Foo1.doitDispatch (export "func1") (param $var0 (ref $FooBase)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $Foo1))
    local.get $var0
    ref.cast $Foo1
    local.set $var2
    global.get $"C384 \"Foo1.doitDispatch(\""
    local.get $var1
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var1
    call $FooBase.doitDispatch
    ref.null none
  )
  (func $FooBase.doitDispatch (param $var0 (ref null $#Top))
    global.get $"C383 \"FooBase(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
  )
  (func $JSStringImpl._interpolate3 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (param $var2 (ref null $#Top)) (result (ref $JSStringImpl)) <...>)
  (func $checkLibraryIsLoadedFromLoadId  <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)