(module $M
  (func $loopSum (param $var0 i64) (result i64)
    (local $var1 i64)
    (local $var2 i64)
    (local $var3 i64)
    (local $var4 i64)
    (local $var5 i32)
    (local $var6 i64)
    (local $var7 i64)
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
      local.set $var4
      ;;   v25 = Phi(🎯v2, v19)
      local.set $var3
      ;;   🎯Goto(B5)
      br $label0
    end $label0
    ;; 🎯B5 = JoinBlock(B0, B10)
    loop $label1
      ;;   v9 = 🎯Comparison int <(v25, v1)
      local.get $var3
      local.get $var0
      i64.lt_s
      local.set $var5
      block $label2
        block $label3
          ;;   🎯Branch(v9, true: B10, false: B11)
          local.get $var5
          br_if $label3
          br $label2
        end $label3
        ;;   v15 = 🎯BinaryIntOp +(v24, v25)
        local.get $var4
        local.get $var3
        i64.add
        local.set $var6
        ;;   v19 = 🎯BinaryIntOp +(v25, v18)
        local.get $var3
        local.get $var2
        i64.add
        local.set $var7
        ;;   v25 = Phi(v2, 🎯v19)
        local.get $var7
        ;;   v24 = Phi(v2, 🎯v15)
        local.get $var6
        local.set $var4
        ;;   v25 = Phi(v2, 🎯v19)
        local.set $var3
        ;;   🎯Goto(B5)
        br $label1
      end $label2
      ;;   🎯Return(v24)
      local.get $var4
      return
    end $label1
    unreachable
  )
  (func $testAdd (param $var0 i64) (result i64)
    (local $var1 i64)
    (local $var2 i64)
    ;;   v3 = 🎯Constant(42)
    i64.const 42
    local.set $var1
    ;;   v4 = 🎯BinaryIntOp +(v1, v3)
    local.get $var0
    local.get $var1
    i64.add
    local.set $var2
    ;;   🎯Return(v4)
    local.get $var2
    return
  )
)