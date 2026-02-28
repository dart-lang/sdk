(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (func $"dart2wasm._171 (import)" (import "dart2wasm" "_171") (param f64) (result externref))
  (func $"dart2wasm._299 (import)" (import "dart2wasm" "_299") (param externref) (result externref))
  (func $"dart2wasm._300 (import)" (import "dart2wasm" "_300") (param externref) (result externref))
  (global $"numValueNullable initialized" (mut i32) <...>)
  (global $numValueNullable (mut (ref null $#Top)) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $numValue implicit getter (result (ref $#Top)) <...>)
  (func $sinkNum <noInline> (param $var0 f64) <...>)
  (func $sinkNumNullable <noInline> (param $var0 (ref null $BoxedDouble)) <...>)
  (func $"testNumConstant <noInline>"
    i64.const 1
    call $jsifyInt
    call $"dart2wasm._299 (import)"
    call $toDartDouble
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantDouble <noInline>"
    f64.const 1.1
    call $"dart2wasm._171 (import)"
    call $"dart2wasm._299 (import)"
    call $toDartDouble
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantNullable <noInline>"
    ref.null noextern
    call $"dart2wasm._300 (import)"
    call $toDartNullableDouble
    call $"sinkNumNullable <noInline>"
  )
  (func $"testNumValue <noInline>"
    call $"numValue implicit getter"
    call $jsifyNum
    call $"dart2wasm._299 (import)"
    call $toDartDouble
    call $"sinkNum <noInline>"
  )
  (func $"testNumValueNullable <noInline>"
    (local $var0 (ref null $#Top))
    global.get $"numValueNullable initialized"
    if (result (ref null $#Top))
      global.get $numValueNullable
    else
      call $"ktrue implicit getter"
      if (result (ref null $#Top))
        call $"numValue implicit getter"
      else
        ref.null none
      end
      local.tee $var0
      global.set $numValueNullable
      i32.const 1
      global.set $"numValueNullable initialized"
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
    call $"dart2wasm._300 (import)"
    call $toDartNullableDouble
    call $"sinkNumNullable <noInline>"
  )
  (func $jsifyInt (param $var0 i64) (result externref) <...>)
  (func $jsifyNum (param $var0 (ref $#Top)) (result externref) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
  (func $toDartDouble (param $var0 externref) (result f64) <...>)
  (func $toDartNullableDouble (param $var0 externref) (result (ref null $BoxedDouble)) <...>)
)