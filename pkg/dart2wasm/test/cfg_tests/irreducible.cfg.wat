(module $M
  (func $irreducible (param $var0 i64) (param $var1 i64) (result i64)
    (local $var2 i64)
    (local $var3 i64)
    (local $var4 i64)
    (local $var5 i64)
    (local $var6 i32)
    (local $var7 i64)
    (local $var8 i64)
    (local $var9 i64)
    (local $var10 i32)
    (local $var11 i32)
    (local $var12 i64)
    ;;   v3 = 🎯Constant(1)
    i64.const 1
    local.set $var2
    ;;   v15 = 🎯Constant(0)
    i64.const 0
    local.set $var3
    ;;   v28 = 🎯Constant(2)
    i64.const 2
    local.set $var4
    ;;   v34 = 🎯Constant(-1)
    i64.const -1
    local.set $var5
    ;;   v6 = 🎯Comparison int ==(v1, v3)
    local.get $var0
    local.get $var2
    i64.eq
    local.set $var6
    block $label0
      block $label1
        block $label2
          ;;   🎯Branch(v6, true: B7, false: B8)
          local.get $var6
          br_if $label2
          br $label1
        end $label2
        ;;   v37 = Phi(v3, v15, v3, 🎯v15)
        local.get $var3
        ;;   v38 = Phi(v39, v28, v39, 🎯v3)
        local.get $var2
        ;;   v40 = Phi(v2, v40, v35, 🎯v2)
        local.get $var1
        local.set $var9
        ;;   v38 = Phi(v39, v28, v39, 🎯v3)
        local.set $var8
        ;;   v37 = Phi(v3, v15, v3, 🎯v15)
        local.set $var7
        ;;   🎯Goto(B36)
        br $label0
      end $label1
      ;;   v37 = Phi(🎯v3, v15, v3, v15)
      local.get $var2
      ;;   v38 = Phi(🎯v39, v28, v39, v3)
      i64.const 0
      ;;   v40 = Phi(🎯v2, v40, v35, v2)
      local.get $var1
      local.set $var9
      ;;   v38 = Phi(🎯v39, v28, v39, v3)
      local.set $var8
      ;;   v37 = Phi(🎯v3, v15, v3, v15)
      local.set $var7
      ;;   🎯Goto(B36)
      br $label0
    end $label0
    ;; 🎯B36 = JoinBlock(B8, B42, B18, B7)
    loop $label3
      ;;   v43 = 🎯Comparison int <(v37, v3)
      local.get $var7
      local.get $var2
      i64.lt_s
      local.set $var10
      block $label4
        block $label5
          ;;   🎯Branch(v43, true: B41, false: B42)
          local.get $var10
          br_if $label5
          br $label4
        end $label5
        ;;   v16 = 🎯Comparison int <=(v40, v15)
        local.get $var9
        local.get $var3
        i64.le_s
        local.set $var11
        block $label6
          block $label7
            ;;   🎯Branch(v16, true: B17, false: B18)
            local.get $var11
            br_if $label7
            br $label6
          end $label7
          ;;   🎯Return(v38)
          local.get $var8
          return
        end $label6
        ;;   v35 = 🎯BinaryIntOp +(v40, v34)
        local.get $var9
        local.get $var5
        i64.add
        local.set $var12
        ;;   v37 = Phi(v3, v15, 🎯v3, v15)
        local.get $var2
        ;;   v38 = Phi(v39, v28, 🎯v39, v3)
        i64.const 0
        ;;   v40 = Phi(v2, v40, 🎯v35, v2)
        local.get $var12
        local.set $var9
        ;;   v38 = Phi(v39, v28, 🎯v39, v3)
        local.set $var8
        ;;   v37 = Phi(v3, v15, 🎯v3, v15)
        local.set $var7
        ;;   🎯Goto(B36)
        br $label3
      end $label4
      ;;   v37 = Phi(v3, 🎯v15, v3, v15)
      local.get $var3
      ;;   v38 = Phi(v39, 🎯v28, v39, v3)
      local.get $var4
      ;;   v40 = Phi(v2, 🎯v40, v35, v2)
      local.get $var9
      local.set $var9
      ;;   v38 = Phi(v39, 🎯v28, v39, v3)
      local.set $var8
      ;;   v37 = Phi(v3, 🎯v15, v3, v15)
      local.set $var7
      ;;   🎯Goto(B36)
      br $label3
    end $label3
    unreachable
  )
)