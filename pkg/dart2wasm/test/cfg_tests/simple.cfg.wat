(module $M
  (func $loopSum (param $var0 i64) (result i64)
    (local $var1 i64)
    (local $var2 i64)
    (local $var3 i64)
    (local $var4 i32)
    ;;   v2 = 🎯Constant(0)
    i64.const 0
    local.set $var1
    ;;   v18 = 🎯Constant(1)
    i64.const 1
    local.set $var2
    ;;   v1 = 🎯Parameter(n)
    block $label0
      ;;   v25 = Phi(🎯v2, v19)
      local.get $var1
      ;;   v24 = Phi(🎯v2, v15)
      local.get $var1
      local.set $var3
      ;;   v25 = Phi(🎯v2, v19)
      local.set $var1
      ;;   🎯Goto(B5)
      br $label0
    end $label0
    ;; 🎯B5 = JoinBlock(B0, B10)
    loop $label1
      ;;   v9 = 🎯Comparison int <(v25, v1)
      local.get $var1
      local.get $var0
      i64.lt_s
      local.set $var4
      block $label2
        block $label3
          ;;   🎯Branch(v9, true: B10, false: B11)
          local.get $var4
          br_if $label3
          br $label2
        end $label3
        ;;   v15 = 🎯BinaryIntOp +(v24, v25)
        local.get $var3
        local.get $var1
        i64.add
        local.set $var3
        ;;   v19 = 🎯BinaryIntOp +(v25, v18)
        local.get $var1
        local.get $var2
        i64.add
        local.set $var1
        ;;   v25 = Phi(v2, 🎯v19)
        local.get $var1
        ;;   v24 = Phi(v2, 🎯v15)
        local.get $var3
        local.set $var3
        ;;   v25 = Phi(v2, 🎯v19)
        local.set $var1
        ;;   🎯Goto(B5)
        br $label1
      end $label2
      ;;   🎯Return(v24)
      local.get $var3
      return
    end $label1
    unreachable
  )
  (func $testAdd (param $var0 i64) (result i64)
    (local $var1 i64)
    ;;   v3 = 🎯Constant(42)
    i64.const 42
    local.set $var1
    ;;   v4 = 🎯BinaryIntOp +(v1, v3)
    local.get $var0
    local.get $var1
    i64.add
    local.set $var1
    ;;   🎯Return(v4)
    local.get $var1
    return
  )
)