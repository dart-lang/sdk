(module $module0
  (type $#Top <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 4 funcref)
  (global $baseObj (mut (ref null $Object)) <...>)
  (global $foo1Obj (mut (ref null $Object)) <...>)
  (elem $cross-module-funcs-0
    (set 1 (ref.func $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>"))
    (set 2 (ref.func $JSStringImpl._interpolate3))
    (set 3 (ref.func $print)))
  (func $_TypeError._throwNullCheckErrorWithCurrentStack <noInline> (result (ref none)) <...>)
  (func $"foo0 <noInline>"
    call $"runtimeTrue implicit getter"
    if (result (ref $Object))
      i32.const 111
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
  (func $Foo1 (result (ref $Object)) <...>)
  (func $JSStringImpl._interpolate3 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (param $var2 (ref null $#Top)) (result (ref $JSExternWrapper)) <...>)
  (func $checkLibraryIsLoadedFromLoadId  <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)