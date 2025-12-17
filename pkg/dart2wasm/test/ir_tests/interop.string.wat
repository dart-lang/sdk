(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSStringImpl (sub final $#Top (struct
    (field $field0 i32)
    (field $_ref externref))))
  (func $"dart2wasm._292 (import)" (import "dart2wasm" "_292") (param externref) (result externref))
  (func $"dart2wasm._293 (import)" (import "dart2wasm" "_293") (param externref) (result externref))
  (global $.a (import "" "a") (ref extern))
  (global $"stringValueNullable initialized" (mut i32) <...>)
  (global $stringValueNullable (mut (ref null $JSStringImpl)) <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $new JSStringImpl.fromRef (param $var0 externref) (result (ref $JSStringImpl)) <...>)
  (func $sinkString <noInline> (param $var0 (ref $JSStringImpl)) <...>)
  (func $sinkStringNullable <noInline> (param $var0 (ref null $JSStringImpl)) <...>)
  (func $stringValue implicit getter (result (ref $JSStringImpl)) <...>)
  (func $"testStringConstant <noInline>"
    (local $var0 externref)
    global.get $.a
    call $"dart2wasm._292 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref $JSStringImpl))
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"new JSStringImpl.fromRef"
    end
    call $"sinkString <noInline>"
  )
  (func $"testStringConstantNullable <noInline>"
    (local $var0 externref)
    ref.null noextern
    call $"dart2wasm._293 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref null $JSStringImpl))
      ref.null none
    else
      local.get $var0
      call $"new JSStringImpl.fromRef"
    end
    call $"sinkStringNullable <noInline>"
  )
  (func $"testStringValue <noInline>"
    (local $var0 externref)
    call $"stringValue implicit getter"
    struct.get $JSStringImpl $_ref
    call $"dart2wasm._292 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref $JSStringImpl))
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"new JSStringImpl.fromRef"
    end
    call $"sinkString <noInline>"
  )
  (func $"testStringValueNullable <noInline>"
    (local $var0 (ref null $JSStringImpl))
    (local $var1 externref)
    global.get $"stringValueNullable initialized"
    i32.eqz
    if
      call $"ktrue implicit getter"
      if (result (ref null $JSStringImpl))
        call $"stringValue implicit getter"
      else
        ref.null none
      end
      global.set $stringValueNullable
      i32.const 1
      global.set $"stringValueNullable initialized"
    end
    global.get $stringValueNullable
    local.tee $var0
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      local.get $var0
      call $jsifyRaw
    end
    call $"dart2wasm._293 (import)"
    local.tee $var1
    call $isDartNull
    if (result (ref null $JSStringImpl))
      ref.null none
    else
      local.get $var1
      call $"new JSStringImpl.fromRef"
    end
    call $"sinkStringNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
)