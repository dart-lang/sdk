(module $$
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (type $BoxedInt (sub final $#Top (struct
    (field $field0 i32)
    (field $value i64))))
  (func $doubleA implicit getter (result f64) <...>)
  (func $doubleB implicit getter (result f64) <...>)
  (func $intA implicit getter (result i64) <...>)
  (func $intB implicit getter (result i64) <...>)
  (func $numIntA implicit getter (result (ref $#Top)) <...>)
  (func $numIntB implicit getter (result (ref $#Top)) <...>)
  (func $"sinkDouble <noInline>" (param $var0 f64)
    i32.const 92
    local.get $var0
    struct.new $BoxedDouble
    call $print
  )
  (func $"sinkInt <noInline>" (param $var0 i64)
    i32.const 86
    local.get $var0
    struct.new $BoxedInt
    call $print
  )
  (func $"sinkNum <noInline>" (param $var0 (ref $#Top))
    local.get $var0
    call $print
  )
  (func $"testMaxDoubleDouble <noInline>"
    call $"doubleA implicit getter"
    call $"doubleB implicit getter"
    f64.max
    call $"sinkDouble <noInline>"
  )
  (func $"testMaxIntDouble <noInline>"
    i32.const 86
    call $"intA implicit getter"
    struct.new $BoxedInt
    i32.const 92
    call $"doubleA implicit getter"
    struct.new $BoxedDouble
    call $_maxSlow
    call $"sinkNum <noInline>"
  )
  (func $"testMaxIntInt <noInline>"
    (local $var0 i64)
    (local $var1 i64)
    call $"intA implicit getter"
    local.tee $var0
    call $"intB implicit getter"
    local.tee $var1
    local.get $var0
    local.get $var1
    i64.ge_s
    select
    call $"sinkInt <noInline>"
  )
  (func $"testMaxNumNum <noInline>"
    (local $var0 (ref $#Top))
    (local $var1 (ref $#Top))
    (local $var2 i64)
    (local $var3 i64)
    block $label0 (result (ref $#Top))
      call $"numIntA implicit getter"
      local.tee $var0
      struct.get $#Top $field0
      i32.const 86
      i32.ne
      call $"numIntB implicit getter"
      local.tee $var1
      struct.get $#Top $field0
      i32.const 86
      i32.ne
      i32.or
      i32.eqz
      if
        i32.const 86
        local.get $var0
        ref.cast $BoxedInt
        struct.get $BoxedInt $value
        local.tee $var2
        local.get $var1
        ref.cast $BoxedInt
        struct.get $BoxedInt $value
        local.tee $var3
        local.get $var2
        local.get $var3
        i64.ge_s
        select
        struct.new $BoxedInt
        br $label0
      end
      local.get $var0
      struct.get $#Top $field0
      i32.const 92
      i32.ne
      local.get $var1
      struct.get $#Top $field0
      i32.const 92
      i32.ne
      i32.or
      i32.eqz
      if
        i32.const 92
        local.get $var0
        ref.cast $BoxedDouble
        struct.get $BoxedDouble $value
        local.get $var1
        ref.cast $BoxedDouble
        struct.get $BoxedDouble $value
        f64.max
        struct.new $BoxedDouble
        br $label0
      end
      local.get $var0
      local.get $var1
      call $_maxSlow
    end $label0
    call $"sinkNum <noInline>"
  )
  (func $"testMinDoubleDouble <noInline>"
    call $"doubleA implicit getter"
    call $"doubleB implicit getter"
    f64.min
    call $"sinkDouble <noInline>"
  )
  (func $"testMinIntDouble <noInline>"
    i32.const 86
    call $"intA implicit getter"
    struct.new $BoxedInt
    i32.const 92
    call $"doubleA implicit getter"
    struct.new $BoxedDouble
    call $_minSlow
    call $"sinkNum <noInline>"
  )
  (func $"testMinIntInt <noInline>"
    (local $var0 i64)
    (local $var1 i64)
    call $"intA implicit getter"
    local.tee $var0
    call $"intB implicit getter"
    local.tee $var1
    local.get $var0
    local.get $var1
    i64.le_s
    select
    call $"sinkInt <noInline>"
  )
  (func $"testMinNumNum <noInline>"
    (local $var0 (ref $#Top))
    (local $var1 (ref $#Top))
    (local $var2 i64)
    (local $var3 i64)
    block $label0 (result (ref $#Top))
      call $"numIntA implicit getter"
      local.tee $var0
      struct.get $#Top $field0
      i32.const 86
      i32.ne
      call $"numIntB implicit getter"
      local.tee $var1
      struct.get $#Top $field0
      i32.const 86
      i32.ne
      i32.or
      i32.eqz
      if
        i32.const 86
        local.get $var0
        ref.cast $BoxedInt
        struct.get $BoxedInt $value
        local.tee $var2
        local.get $var1
        ref.cast $BoxedInt
        struct.get $BoxedInt $value
        local.tee $var3
        local.get $var2
        local.get $var3
        i64.le_s
        select
        struct.new $BoxedInt
        br $label0
      end
      local.get $var0
      struct.get $#Top $field0
      i32.const 92
      i32.ne
      local.get $var1
      struct.get $#Top $field0
      i32.const 92
      i32.ne
      i32.or
      i32.eqz
      if
        i32.const 92
        local.get $var0
        ref.cast $BoxedDouble
        struct.get $BoxedDouble $value
        local.get $var1
        ref.cast $BoxedDouble
        struct.get $BoxedDouble $value
        f64.min
        struct.new $BoxedDouble
        br $label0
      end
      local.get $var0
      local.get $var1
      call $_minSlow
    end $label0
    call $"sinkNum <noInline>"
  )
  (func $_maxSlow (param $var0 (ref $#Top)) (param $var1 (ref $#Top)) (result (ref $#Top)) <...>)
  (func $_minSlow (param $var0 (ref $#Top)) (param $var1 (ref $#Top)) (result (ref $#Top)) <...>)
  (func $print (param $var0 (ref $#Top)) <...>)
)