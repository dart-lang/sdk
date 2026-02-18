(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedInt (sub $#Top (struct
    (field $field0 i32)
    (field $value i64))))
  (func $"dart2wasm._297 (import)" (import "dart2wasm" "_297") (param externref) (result externref))
  (func $"dart2wasm._298 (import)" (import "dart2wasm" "_298") (param externref) (result externref))
  (global $"intValueNullable initialized" (mut i32) <...>)
  (global $intValueNullable (mut (ref null $BoxedInt)) <...>)
  (func $intValue implicit getter (result i64) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $sinkInt <noInline> (param $var0 i64) <...>)
  (func $sinkIntNullable <noInline> (param $var0 (ref null $BoxedInt)) <...>)
  (func $"testIntConstant <noInline>"
    i64.const 1
    call $jsifyInt
    call $"dart2wasm._297 (import)"
    call $toDartInt
    call $"sinkInt <noInline>"
  )
  (func $"testIntConstantNullable <noInline>"
    ref.null noextern
    call $"dart2wasm._298 (import)"
    call $toDartNullableInt
    call $"sinkIntNullable <noInline>"
  )
  (func $"testIntValue <noInline>"
    call $"intValue implicit getter"
    call $jsifyInt
    call $"dart2wasm._297 (import)"
    call $toDartInt
    call $"sinkInt <noInline>"
  )
  (func $"testIntValueNullable <noInline>"
    (local $var0 (ref null $BoxedInt))
    global.get $"intValueNullable initialized"
    if (result (ref null $BoxedInt))
      global.get $intValueNullable
    else
      call $"ktrue implicit getter"
      if (result (ref null $BoxedInt))
        i32.const 69
        call $"intValue implicit getter"
        struct.new $BoxedInt
      else
        ref.null none
      end
      local.tee $var0
      global.set $intValueNullable
      i32.const 1
      global.set $"intValueNullable initialized"
      local.get $var0
    end
    local.tee $var0
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      local.get $var0
      call $jsifyRaw
    end
    call $"dart2wasm._298 (import)"
    call $toDartNullableInt
    call $"sinkIntNullable <noInline>"
  )
  (func $jsifyInt (param $var0 i64) (result externref) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
  (func $toDartInt (param $var0 externref) (result i64) <...>)
  (func $toDartNullableInt (param $var0 externref) (result (ref null $BoxedInt)) <...>)
)