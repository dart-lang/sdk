(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (func $"dart2wasm._298 (import)" (import "dart2wasm" "_298") (param f64) (result externref))
  (func $"dart2wasm._299 (import)" (import "dart2wasm" "_299") (param externref) (result externref))
  (global $"doubleValueNullable initialized" (mut i32) <...>)
  (global $doubleValueNullable (mut (ref null $BoxedDouble)) <...>)
  (func $doubleValue implicit getter (result f64) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $sinkDouble <noInline> (param $var0 f64) <...>)
  (func $sinkDoubleNullable <noInline> (param $var0 (ref null $BoxedDouble)) <...>)
  (func $"testDoubleConstant <noInline>"
    f64.const 1.1
    call $"dart2wasm._298 (import)"
    call $toDartDouble
    call $"sinkDouble <noInline>"
  )
  (func $"testDoubleConstantNullable <noInline>"
    ref.null noextern
    call $"dart2wasm._299 (import)"
    call $toDartNullableDouble
    call $"sinkDoubleNullable <noInline>"
  )
  (func $"testDoubleValue <noInline>"
    call $"doubleValue implicit getter"
    call $"dart2wasm._298 (import)"
    call $toDartDouble
    call $"sinkDouble <noInline>"
  )
  (func $"testDoubleValueNullable <noInline>"
    (local $var0 (ref null $BoxedDouble))
    global.get $"doubleValueNullable initialized"
    if (result (ref null $BoxedDouble))
      global.get $doubleValueNullable
    else
      call $"ktrue implicit getter"
      if (result (ref null $BoxedDouble))
        i32.const 98
        call $"doubleValue implicit getter"
        struct.new $BoxedDouble
      else
        ref.null none
      end
      local.tee $var0
      global.set $doubleValueNullable
      i32.const 1
      global.set $"doubleValueNullable initialized"
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
    call $"dart2wasm._299 (import)"
    call $toDartNullableDouble
    call $"sinkDoubleNullable <noInline>"
  )
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
  (func $toDartDouble (param $var0 externref) (result f64) <...>)
  (func $toDartNullableDouble (param $var0 externref) (result (ref null $BoxedDouble)) <...>)
)