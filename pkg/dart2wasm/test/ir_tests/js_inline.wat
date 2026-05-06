(module $module0
  (type $#Top <...>)
  (func $"dart2wasm.M (import)" (import "dart2wasm" "M") (param i32 i32) (result i32))
  (func $"dart2wasm.N (import)" (import "dart2wasm" "N") (param i32))
  (func $"dart2wasm.O (import)" (import "dart2wasm" "O") (param i32))
  (func $"dart2wasm.P (import)" (import "dart2wasm" "P") (param i32 i32) (result i32))
  (func $consumeAny <noInline>  <...>)
  (func $consumeInt <noInline> (param $arg i64) <...>)
  (func $"runTest <noInline>"
    (local $#this i64)
    (local $#this i64)
    (local $a i32)
    (local $b i32)
    (local $#this i64)
    (local $#this i64)
    (local $a i32)
    (local $b i32)
    (local $var0 (ref null $#Top))
    (local $var1 (ref null $#Top))
    (local $var2 (ref null $#Top))
    (local $#this i64)
    (local $var3 (ref null $#Top))
    (local $#this i64)
    i64.const 1
    i64.const 2
    call $addInt
    call $"consumeInt <noInline>"
    ref.null none
    drop
    i64.const 3
    i64.const 4
    call $addInt
    call $"consumeInt <noInline>"
    ref.null none
    drop
    i64.const 1
    local.set $#this
    block $label0 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label0
    end $label0
    i64.const 2
    local.set $#this
    block $label1 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label1
    end $label1
    local.set $b
    local.set $a
    block $label2 (result i32)
      local.get $a
      local.get $b
      call $"dart2wasm.M (import)"
      br $label2
    end $label2
    i64.extend_i32_s
    call $"consumeInt <noInline>"
    ref.null none
    drop
    i64.const 3
    local.set $#this
    block $label3 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label3
    end $label3
    i64.const 4
    local.set $#this
    block $label4 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label4
    end $label4
    local.set $b
    local.set $a
    block $label5 (result i32)
      local.get $a
      local.get $b
      call $"dart2wasm.M (import)"
      br $label5
    end $label5
    i64.extend_i32_s
    call $"consumeInt <noInline>"
    ref.null none
    drop
    i64.const 1
    call $passIntToJS
    local.set $var0
    call $"consumeAny <noInline>"
    ref.null none
    drop
    i64.const 2
    call $passIntToJS
    local.set $var1
    call $"consumeAny <noInline>"
    ref.null none
    drop
    i64.const 1
    local.set $#this
    block $label6 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label6
    end $label6
    call $passWasmI32ToJS
    local.set $var2
    call $"consumeAny <noInline>"
    ref.null none
    drop
    i64.const 2
    local.set $#this
    block $label7 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label7
    end $label7
    call $passWasmI32ToJS
    local.set $var3
    call $"consumeAny <noInline>"
    ref.null none
    drop
  )
  (func $addInt (param $a i64) (param $b i64) (result i64)
    (local $#this i64)
    (local $#this i64)
    local.get $a
    local.set $#this
    block $label0 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label0
    end $label0
    local.get $b
    local.set $#this
    block $label1 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label1
    end $label1
    call $"dart2wasm.P (import)"
    i64.extend_i32_s
    return
  )
  (func $passIntToJS (param $a i64) (result (ref null $#Top))
    (local $#this i64)
    local.get $a
    local.set $#this
    block $label0 (result i32)
      local.get $#this
      i32.wrap_i64
      br $label0
    end $label0
    call $"dart2wasm.O (import)"
    ref.null none
    return
  )
  (func $passWasmI32ToJS (param $a i32) (result (ref null $#Top))
    local.get $a
    call $"dart2wasm.N (import)"
    ref.null none
    return
  )
)