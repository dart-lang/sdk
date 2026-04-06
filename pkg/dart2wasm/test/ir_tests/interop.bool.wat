(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (func $"dart2wasm._197 (import)" (import "dart2wasm" "_197") (param i32) (result externref))
  (func $"dart2wasm._322 (import)" (import "dart2wasm" "_322") (param externref) (result externref))
  (func $"dart2wasm._323 (import)" (import "dart2wasm" "_323") (param externref) (result externref))
  (global $"boolValueNullable initialized" (mut i32) <...>)
  (global $boolValueNullable (mut (ref null $#Top)) <...>)
  (global $false (ref $#Top) <...>)
  (global $true (ref $#Top) <...>)
  (func $boolValue implicit getter (result i32) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $sinkBool <noInline> (param $var0 i32) <...>)
  (func $sinkBoolNullable <noInline> (param $var0 (ref null $#Top)) <...>)
  (func $"testBoolConstant <noInline>"
    i32.const 1
    call $"dart2wasm._197 (import)"
    call $"dart2wasm._322 (import)"
    call $toDartBool
    call $"sinkBool <noInline>"
  )
  (func $"testBoolConstantNullable <noInline>"
    ref.null noextern
    call $"dart2wasm._323 (import)"
    call $toDartNullableBool
    call $"sinkBoolNullable <noInline>"
  )
  (func $"testBoolValue <noInline>"
    call $"boolValue implicit getter"
    call $"dart2wasm._197 (import)"
    call $"dart2wasm._322 (import)"
    call $toDartBool
    call $"sinkBool <noInline>"
  )
  (func $"testBoolValueNullable <noInline>"
    (local $var0 (ref null $#Top))
    global.get $"boolValueNullable initialized"
    if (result (ref null $#Top))
      global.get $boolValueNullable
    else
      call $"ktrue implicit getter"
      if (result (ref null $#Top))
        global.get $true
        global.get $false
        call $"boolValue implicit getter"
        select (ref $#Top)
      else
        ref.null none
      end
      local.tee $var0
      global.set $boolValueNullable
      i32.const 1
      global.set $"boolValueNullable initialized"
      local.get $var0
    end
    local.tee $var0
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      local.get $var0
      global.get $false
      ref.eq
      i32.eqz
      call $"dart2wasm._197 (import)"
    end
    call $"dart2wasm._323 (import)"
    call $toDartNullableBool
    call $"sinkBoolNullable <noInline>"
  )
  (func $toDartBool (param $var0 externref) (result i32) <...>)
  (func $toDartNullableBool (param $var0 externref) (result (ref null $#Top)) <...>)
)