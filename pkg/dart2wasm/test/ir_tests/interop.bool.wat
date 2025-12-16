(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (func $"dart2wasm._169 (import)" (import "dart2wasm" "_169") (param externref) (result i32))
  (func $"dart2wasm._170 (import)" (import "dart2wasm" "_170") (param i32) (result externref))
  (func $"dart2wasm._294 (import)" (import "dart2wasm" "_294") (param externref) (result externref))
  (func $"dart2wasm._295 (import)" (import "dart2wasm" "_295") (param externref) (result externref))
  (global $"C2 false" (ref $#Top) <...>)
  (global $"C40 true" (ref $#Top) <...>)
  (global $"boolValue initialized" (mut i32) <...>)
  (global $"boolValueNullable initialized" (mut i32) <...>)
  (global $"ktrue initialized" (mut i32) <...>)
  (global $boolValue (mut i32) <...>)
  (global $boolValueNullable (mut (ref null $#Top)) <...>)
  (global $ktrue (mut i32) <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $boolValue implicit getter (result i32) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $sinkBool <noInline> (param $var0 i32) <...>)
  (func $sinkBoolNullable <noInline> (param $var0 (ref null $#Top)) <...>)
  (func $"testBoolConstant <noInline>"
    (local $var0 externref)
    i32.const 1
    call $"dart2wasm._170 (import)"
    call $"dart2wasm._294 (import)"
    local.tee $var0
    call $isDartNull
    if (result i32)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._169 (import)"
    end
    call $"sinkBool <noInline>"
  )
  (func $"testBoolConstantNullable <noInline>"
    (local $var0 externref)
    ref.null noextern
    call $"dart2wasm._295 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref null $#Top))
      ref.null none
    else
      global.get $"C40 true"
      global.get $"C2 false"
      local.get $var0
      call $"dart2wasm._169 (import)"
      select (ref $#Top)
    end
    call $"sinkBoolNullable <noInline>"
  )
  (func $"testBoolValue <noInline>"
    (local $var0 externref)
    global.get $"boolValue initialized"
    if (result i32)
      global.get $boolValue
    else
      call $"boolValue implicit getter"
    end
    call $"dart2wasm._170 (import)"
    call $"dart2wasm._294 (import)"
    local.tee $var0
    call $isDartNull
    if (result i32)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._169 (import)"
    end
    call $"sinkBool <noInline>"
  )
  (func $"testBoolValueNullable <noInline>"
    (local $var0 (ref null $#Top))
    (local $var1 externref)
    global.get $"boolValueNullable initialized"
    i32.eqz
    if
      global.get $"ktrue initialized"
      if (result i32)
        global.get $ktrue
      else
        call $"ktrue implicit getter"
      end
      if (result (ref null $#Top))
        global.get $"C40 true"
        global.get $"C2 false"
        global.get $"boolValue initialized"
        if (result i32)
          global.get $boolValue
        else
          call $"boolValue implicit getter"
        end
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
    call $"dart2wasm._295 (import)"
    local.tee $var1
    call $isDartNull
    if (result (ref null $#Top))
      ref.null none
    else
      global.get $"C40 true"
      global.get $"C2 false"
      local.get $var1
      call $"dart2wasm._169 (import)"
      select (ref $#Top)
    end
    call $"sinkBoolNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
)