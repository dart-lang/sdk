(module $M
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $_Type <...>)
  (func $<obj> is int (param $var0 (ref null $#Top)) (result i32) <...>)
  (func $_isNullabilityCheck (param $o (ref null $#Top)) (param $isDeclaredNullable i32) (result i32) <...>)
  (func $_isSubtype (param $o (ref null $#Top)) (param $t (ref $_Type)) (result i32) <...>)
  (func $testNullabilityOnly (param $var0 (ref null $BoxedInt)) (result i32)
    (local $var1 i32)
    ;;   v3 = 🎯TypeTest(v1, int)
    local.get $var0
    i32.const 0
    call $_isNullabilityCheck
    local.set $var1
    ;;   🎯Return(v3)
    local.get $var1
    return
  )
  (func $testSimple (param $var0 (ref null $#Top)) (result i32)
    (local $var1 i32)
    ;;   v3 = 🎯TypeTest(v1, int)
    local.get $var0
    call $"<obj> is int"
    local.set $var1
    ;;   🎯Return(v3)
    local.get $var1
    return
  )
  (func $testTypeParam (param $var0 (ref $_Type)) (param $var1 (ref null $#Top)) (result i32)
    (local $var2 nullref)
    (local $var3 i32)
    ;;   v6 = 🎯Constant(null)
    ref.null none
    local.set $var2
    ;;   v7 = 🎯TypeTest(v2, v6, v4, testTypeParam.T%)
    local.get $var1
    local.get $var0
    call $_isSubtype
    local.set $var3
    ;;   🎯Return(v7)
    local.get $var3
    return
  )
)