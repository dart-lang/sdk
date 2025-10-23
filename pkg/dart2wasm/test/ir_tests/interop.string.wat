(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSStringImpl (sub final $#Top (struct
    (field $field0 i32)
    (field $field1 externref))))
  (func $"dart2wasm._274 (import)" (import "dart2wasm" "_274") (param externref) (result externref))
  (func $"dart2wasm._275 (import)" (import "dart2wasm" "_275") (param externref) (result externref))
  (global $S.a (import "S" "a") externref)
  (global $"stringValueNullable initialized" (mut i32)
    (i32.const 0))
  (global $stringValueNullable (mut (ref null $JSStringImpl))
    (ref.null none))
  (global $"ktrue initialized" (mut i32)
    (i32.const 0))
  (global $ktrue (mut i32)
    (i32.const 0))
  (global $stringValue (mut (ref null $JSStringImpl))
    (ref.null none))
  (global $"C358 \"a\"" (ref $JSStringImpl)
    (i32.const 4)
    (global.get $S.a)
    (struct.new $JSStringImpl))
  (func $new JSStringImpl.fromRef (param $var0 externref) (result (ref $JSStringImpl)) <...>)
  (func $"testStringConstant <noInline>"
    (local $var0 externref)
    global.get $"C358 \"a\""
    struct.get $JSStringImpl $field1
    call $"dart2wasm._274 (import)"
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
    call $"dart2wasm._275 (import)"
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
    block $label0 (result (ref $JSStringImpl))
      global.get $stringValue
      br_on_non_null $label0
      call $"stringValue implicit getter"
    end $label0
    struct.get $JSStringImpl $field1
    call $"dart2wasm._274 (import)"
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
      global.get $"ktrue initialized"
      if (result i32)
        global.get $ktrue
      else
        call $"ktrue implicit getter"
      end
      if (result (ref null $JSStringImpl))
        block $label0 (result (ref $JSStringImpl))
          global.get $stringValue
          br_on_non_null $label0
          call $"stringValue implicit getter"
        end $label0
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
    call $"dart2wasm._275 (import)"
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
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $sinkStringNullable <noInline> (param $var0 (ref null $JSStringImpl)) <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $stringValue implicit getter (result (ref $JSStringImpl)) <...>)
  (func $sinkString <noInline> (param $var0 (ref $JSStringImpl)) <...>)
)