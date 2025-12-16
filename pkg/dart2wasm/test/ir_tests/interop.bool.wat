(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (func $"dart2wasm._149 (import)" (import "dart2wasm" "_149") (param externref) (result i32))
  (func $"dart2wasm._150 (import)" (import "dart2wasm" "_150") (param i32) (result externref))
  (func $"dart2wasm._274 (import)" (import "dart2wasm" "_274") (param externref) (result externref))
  (func $"dart2wasm._275 (import)" (import "dart2wasm" "_275") (param externref) (result externref))
  (global $"C2 false" (ref $#Top) <...>)
  (global $"C40 true" (ref $#Top) <...>)
  (global $"boolValueNullable initialized" (mut i32) <...>)
  (global $boolValueNullable (mut (ref null $#Top)) <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $boolValue implicit getter (result i32) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $sinkBool <noInline> (param $var0 i32) <...>)
  (func $sinkBoolNullable <noInline> (param $var0 (ref null $#Top)) <...>)
  (func $"testBoolConstant <noInline>"
    (local $var0 externref)
    i32.const 1
    call $"dart2wasm._150 (import)"
    call $"dart2wasm._274 (import)"
    local.tee $var0
    call $isDartNull
    if (result i32)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._149 (import)"
    end
    call $"sinkBool <noInline>"
  )
  (func $"testBoolConstantNullable <noInline>"
    (local $var0 externref)
    ref.null noextern
    call $"dart2wasm._275 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref null $#Top))
      ref.null none
    else
      global.get $"C40 true"
      global.get $"C2 false"
      local.get $var0
      call $"dart2wasm._149 (import)"
      select (ref $#Top)
    end
    call $"sinkBoolNullable <noInline>"
  )
  (func $"testBoolValue <noInline>"
    (local $var0 externref)
    call $"boolValue implicit getter"
    call $"dart2wasm._150 (import)"
    call $"dart2wasm._274 (import)"
    local.tee $var0
    call $isDartNull
    if (result i32)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._149 (import)"
    end
    call $"sinkBool <noInline>"
  )
  (func $"testBoolValueNullable <noInline>"
    (local $var0 (ref null $#Top))
    (local $var1 externref)
    global.get $"boolValueNullable initialized"
    i32.eqz
    if
      call $"ktrue implicit getter"
      if (result (ref null $#Top))
        global.get $"C40 true"
        global.get $"C2 false"
        call $"boolValue implicit getter"
        select (ref $#Top)
      else
        ref.null none
      end
      global.set $boolValueNullable
      i32.const 1
      global.set $"boolValueNullable initialized"
    end
    global.get $boolValueNullable
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
    if (result (ref null $#Top))
      ref.null none
    else
      global.get $"C40 true"
      global.get $"C2 false"
      local.get $var1
      call $"dart2wasm._149 (import)"
      select (ref $#Top)
    end
    call $"sinkBoolNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
)