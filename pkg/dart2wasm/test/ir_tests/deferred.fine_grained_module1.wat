(module $module1
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $BoxedInt <...>)
  (type $FooConst0 <...>)
  (type $FooConst1 <...>)
  (type $FooConst2 <...>)
  (type $FooConst3 <...>)
  (type $FooConst4 <...>)
  (type $FooConst5 <...>)
  (type $FooConstBase <...>)
  (type $GrowableList <...>)
  (type $JSStringImpl <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (type $type0 <...>)
  (type $type10 <...>)
  (type $type2 <...>)
  (type $type4 <...>)
  (type $type6 <...>)
  (type $type8 <...>)
  (func $"_throwIndexError <noInline>" (import "module0" "func13") (param i64 i64 (ref null $JSStringImpl)) (result (ref none)))
  (func $"foo0Code <noInline>" (import "module0" "func12") (param (ref null $#Top)) (result (ref null $#Top)))
  (func $"fooGlobal0 implicit getter" (import "module0" "func11") (result (ref $#Top)))
  (func $FooConstBase.doit (import "module0" "func14") (param (ref $FooConstBase) (ref null $#Top)) (result (ref null $#Top)))
  (func $GrowableList._withData (import "module0" "func15") (param (ref $_Type) (ref $Array<Object?>)) (result (ref $GrowableList)))
  (func $JSStringImpl._interpolate3 (import "module0" "func10") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func9") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".FooConst5(" (import "" "FooConst5(") (ref extern))
  (global $"C313 \"[]\"" (import "module0" "global6") (ref $JSStringImpl))
  (global $"C389 5" (import "module0" "global5") (ref $BoxedInt))
  (global $"C391 FooConst0" (import "module0" "global7") (ref $FooConst0))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (table $module0.dispatch0 (import "module0" "dispatch0") 778 funcref)
  (table $module0.static1-0 (import "module0" "static1-0") 4 (ref null $type2))
  (table $module0.static2-0 (import "module0" "static2-0") 4 (ref null $type0))
  (table $module0.static3-0 (import "module0" "static3-0") 1 (ref null $type4))
  (table $module0.static4-0 (import "module0" "static4-0") 1 (ref null $type6))
  (table $module0.static5-0 (import "module0" "static5-0") 1 (ref null $type8))
  (table $module0.static6-0 (import "module0" "static6-0") 1 (ref null $type10))
  (global $"C510 FooConst5" (ref $FooConst5)
    (i32.const 123)
    (i32.const 0)
    (struct.new $FooConst5))
  (global $"C511 \"foo5Code(\"" (ref $JSStringImpl) <...>)
  (global $"C512 \"FooConst5(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst5(")
    (struct.new $JSStringImpl))
  (global $"C513 _InterfaceType" (ref $_InterfaceType) <...>)
  (global $allFooConstants (mut (ref null $GrowableList))
    (ref.null none))
  (global $fooGlobal5 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.dispatch0 <...>)
  (func $"foo5Code <noInline>" (param $var0 (ref $#Top))
    (local $var1 (ref $GrowableList))
    (local $var2 (ref $FooConstBase))
    (local $var3 i64)
    global.get $"C510 FooConst5"
    call $print
    drop
    global.get $"C511 \"foo5Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C389 5"
    global.set $fooGlobal5
    call $"fooGlobal0 implicit getter"
    call $"foo0Code <noInline>"
    drop
    i32.const 0
    call_indirect $module0.static2-0 (result (ref $#Top))
    i32.const 0
    call_indirect $module0.static1-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 1
    call_indirect $module0.static2-0 (result (ref $#Top))
    i32.const 1
    call_indirect $module0.static1-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 2
    call_indirect $module0.static2-0 (result (ref $#Top))
    i32.const 2
    call_indirect $module0.static1-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    i32.const 3
    call_indirect $module0.static2-0 (result (ref $#Top))
    i32.const 3
    call_indirect $module0.static1-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    block $label0 (result (ref $GrowableList))
      global.get $allFooConstants
      br_on_non_null $label0
      global.get $"C513 _InterfaceType"
      global.get $"C391 FooConst0"
      i32.const 0
      call_indirect $module0.static3-0 (result (ref $FooConst1))
      i32.const 0
      call_indirect $module0.static4-0 (result (ref $FooConst2))
      i32.const 0
      call_indirect $module0.static5-0 (result (ref $FooConst3))
      i32.const 0
      call_indirect $module0.static6-0 (result (ref $FooConst4))
      global.get $"C510 FooConst5"
      array.new_fixed $Array<Object?> 6
      call $GrowableList._withData
      global.set $allFooConstants
      global.get $allFooConstants
      ref.as_non_null
    end $label0
    local.tee $var1
    struct.get $GrowableList $_length
    local.tee $var3
    i64.eqz
    if
      i64.const 0
      local.get $var3
      global.get $"C313 \"[]\""
      call $"_throwIndexError <noInline>"
      unreachable
    end
    local.get $var1
    struct.get $GrowableList $_data
    i32.const 0
    array.get $Array<Object?>
    ref.cast $FooConstBase
    local.tee $var2
    call $"fooGlobal5 implicit getter"
    local.get $var2
    struct.get $FooConstBase $field0
    i32.const 400
    i32.add
    call_indirect $module0.dispatch0 (param (ref $FooConstBase) (ref null $#Top)) (result (ref null $#Top))
    drop
  )
  (func $fooGlobal5 implicit getter (result (ref $#Top)) <...>)
  (func $FooConst5.doit (param $var0 (ref $FooConstBase)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $FooConst5))
    local.get $var0
    ref.cast $FooConst5
    global.get $"C512 \"FooConst5(\""
    local.get $var1
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var1
    call $FooConstBase.doit
    drop
    ref.null none
  )
)