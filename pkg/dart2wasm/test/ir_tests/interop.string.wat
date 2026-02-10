(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSStringImpl (sub final $#Top (struct
    (field $field0 i32)
    (field $_ref externref))))
  (func $"dart2wasm._297 (import)" (import "dart2wasm" "_297") (param externref) (result externref))
  (func $"dart2wasm._298 (import)" (import "dart2wasm" "_298") (param externref) (result externref))
  (global $.a (import "" "a") (ref extern))
  (global $"stringValueNullable initialized" (mut i32) <...>)
  (global $stringValueNullable (mut (ref null $JSStringImpl)) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $new JSStringImpl.fromRef (param $var0 externref) (result (ref $JSStringImpl)) <...>)
  (func $sinkString <noInline> (param $var0 (ref $JSStringImpl)) <...>)
  (func $sinkStringNullable <noInline> (param $var0 (ref null $JSStringImpl)) <...>)
  (func $stringValue implicit getter (result (ref $JSStringImpl)) <...>)
  (func $"testStringConstant <noInline>"
    global.get $.a
    call $"dart2wasm._297 (import)"
    call $"new JSStringImpl.fromRef"
    call $"sinkString <noInline>"
  )
  (func $"testStringConstantNullable <noInline>"
    ref.null noextern
    call $"dart2wasm._298 (import)"
    call $JSStringImpl.fromRefNullable
    call $"sinkStringNullable <noInline>"
  )
  (func $"testStringValue <noInline>"
    call $"stringValue implicit getter"
    struct.get $JSStringImpl $_ref
    call $"dart2wasm._297 (import)"
    call $"new JSStringImpl.fromRef"
    call $"sinkString <noInline>"
  )
  (func $"testStringValueNullable <noInline>"
    (local $var0 (ref null $JSStringImpl))
    (local $var1 (ref null $JSStringImpl))
    global.get $"stringValueNullable initialized"
    if (result (ref null $JSStringImpl))
      global.get $stringValueNullable
    else
      call $"ktrue implicit getter"
      if (result (ref null $JSStringImpl))
        call $"stringValue implicit getter"
      else
        ref.null none
      end
      local.tee $var0
      global.set $stringValueNullable
      i32.const 1
      global.set $"stringValueNullable initialized"
      local.get $var0
    end
    local.tee $var1
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      local.get $var1
      call $jsifyRaw
    end
    call $"dart2wasm._298 (import)"
    call $JSStringImpl.fromRefNullable
    call $"sinkStringNullable <noInline>"
  )
  (func $JSStringImpl.fromRefNullable (param $var0 externref) (result (ref null $JSStringImpl)) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
)