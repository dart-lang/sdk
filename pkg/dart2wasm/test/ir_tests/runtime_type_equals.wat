(module $M
  (type $#Top (struct
    (field $field0 i32)))
  (type $Array<_Type> (array (field (mut (ref $#Top)))))
  (type $GenericClass (sub final $#Top (struct
    (field $field0 i32)
    (field $field1 (ref $_InterfaceType)))))
  (type $_InterfaceType (sub final $#Top (struct
    (field $field0 i32)
    (field $classId i32)
    (field $typeArguments (ref $Array<_Type>)))))
  (table $dtable0 741 funcref)
  (elem $dtable0 <...>)
  (func $_getMasqueradedRuntimeType (param $var0 (ref $#Top)) (result (ref $#Top)) <...>)
  (func $sink (param $var0 i32) <...>)
  (@binaryen.inline 0)
  (func $testBothNullable (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (result i32)
    i32.const 1
    call $sink
    block $label0 (result i32)
      block $label1 (result (ref $#Top))
        local.get $var0
        br_on_non_null $label1
        i32.const 0
        br $label0
      end $label1
      struct.get $#Top $field0
    end $label0
    block $label2 (result i32)
      block $label3 (result (ref $#Top))
        local.get $var1
        br_on_non_null $label3
        i32.const 0
        br $label2
      end $label3
      struct.get $#Top $field0
    end $label2
    i32.eq
  )
  (@binaryen.inline 0)
  (func $testGenericClass (param $var0 (ref $GenericClass)) (param $var1 (ref $GenericClass)) (result i32)
    (local $var2 (ref $#Top))
    local.get $var0
    call $_getMasqueradedRuntimeType
    local.tee $var2
    local.get $var1
    call $_getMasqueradedRuntimeType
    local.get $var2
    struct.get $#Top $field0
    i32.const 119
    i32.add
    call_indirect (param (ref $#Top) (ref $#Top)) (result i32)
  )
  (@binaryen.inline 0)
  (func $testHierarchy (param $var0 (ref $#Top)) (param $var1 (ref $#Top)) (result i32)
    i32.const 1
    call $sink
    local.get $var0
    struct.get $#Top $field0
    local.get $var1
    struct.get $#Top $field0
    i32.eq
  )
  (@binaryen.inline 0)
  (func $testInterface (param $var0 (ref $#Top)) (param $var1 (ref $#Top)) (result i32)
    i32.const 0
    call $sink
    local.get $var0
    struct.get $#Top $field0
    local.get $var1
    struct.get $#Top $field0
    i32.eq
  )
  (@binaryen.inline 0)
  (func $testLeftNullable (param $var0 (ref null $#Top)) (param $var1 (ref $#Top)) (result i32)
    i32.const 1
    call $sink
    block $label0 (result i32)
      block $label1 (result (ref $#Top))
        local.get $var0
        br_on_non_null $label1
        i32.const 0
        br $label0
      end $label1
      struct.get $#Top $field0
    end $label0
    local.get $var1
    struct.get $#Top $field0
    i32.eq
  )
  (@binaryen.inline 0)
  (func $testNonGenericNonNullable (param $var0 (ref $#Top)) (param $var1 (ref $#Top)) (result i32)
    local.get $var0
    struct.get $#Top $field0
    local.get $var1
    struct.get $#Top $field0
    i32.eq
  )
  (@binaryen.inline 0)
  (func $testRightNullable (param $var0 (ref $#Top)) (param $var1 (ref null $#Top)) (result i32)
    i32.const 0
    call $sink
    block $label0 (result i32)
      block $label1 (result (ref $#Top))
        local.get $var1
        br_on_non_null $label1
        i32.const 0
        br $label0
      end $label1
      struct.get $#Top $field0
    end $label0
    local.get $var0
    struct.get $#Top $field0
    i32.eq
  )
)