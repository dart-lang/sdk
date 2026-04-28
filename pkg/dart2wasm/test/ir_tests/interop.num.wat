(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (func $"dart2wasm.M (import)" (import "dart2wasm" "M") (param externref) (result externref))
  (func $"dart2wasm.P (import)" (import "dart2wasm" "P") (param f64) (result externref))
  (func $"dart2wasm.R (import)" (import "dart2wasm" "R") (param externref) (result externref))
  (global $"numValueNullable initialized" (mut i32) <...>)
  (global $numValueNullable (mut (ref null $#Top)) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $numValue implicit getter (result (ref $#Top)) <...>)
  (func $sinkNum <noInline> (param $var0 f64) <...>)
  (func $sinkNumNullable <noInline> (param $var0 (ref null $BoxedDouble)) <...>)
  (func $"testNumConstant <noInline>"
    call $jsifyInt
    call $"dart2wasm.R (import)"
    call $toDartDouble
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantDouble <noInline>"
    f64.const 1.1
    call $"dart2wasm.P (import)"
    call $"dart2wasm.R (import)"
    call $toDartDouble
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantNullable <noInline>"
    ref.null noextern
    call $"dart2wasm.M (import)"
    call $toDartNullableDouble
    call $"sinkNumNullable <noInline>"
  )
  (func $"testNumValue <noInline>"
    call $"numValue implicit getter"
    call $jsifyNum
    call $"dart2wasm.R (import)"
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
      ref.as_non_null
      call $jsifyNum
    end
    call $"dart2wasm.M (import)"
    call $toDartNullableDouble
    call $"sinkNumNullable <noInline>"
  )
  (func $jsifyInt (result (ref extern)) <...>)
  (func $jsifyNum (param $var0 (ref $#Top)) (result externref) <...>)
  (func $toDartDouble (param $var0 externref) (result f64) <...>)
  (func $toDartNullableDouble (param $var0 externref) (result (ref null $BoxedDouble)) <...>)
)