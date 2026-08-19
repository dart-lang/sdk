(module $M
  (type $#Top (struct
    (field $field0 i32)))
  (type $Array<_Type> (array (field (mut (ref $_Type)))))
  (type $GenericClass (sub final $#Top (struct
    (field $field0 i32)
    (field $field1 (ref $_InterfaceType)))))
  (type $_InterfaceType (sub final $_Type (struct
    (field $field0 i32)
    (field $isDeclaredNullable i32)
    (field $classId i32)
    (field $typeArguments (ref $Array<_Type>)))))
  (type $_Type (sub $#Top (struct
    (field $field0 i32)
    (field $isDeclaredNullable i32))))
  (table $dtable0 741 funcref)
  (global $_BottomType (ref $_Type) <...>)
  (elem $dtable0 <...>)
  (func $_getMasqueradedRuntimeType (param $var0 (ref $#Top)) (result (ref $_Type)) <...>)
  (func $sink (param $var0 i32) <...>)
  (@binaryen.inline 0)
  (func $testBothNullable (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (result i32)
    (local $var2 (ref $_Type))
    i32.const 1
    call $sink
    block $label0 (result (ref $_Type))
      block $label1
        local.get $var0
        br_on_null $label1
        call $_getMasqueradedRuntimeType
        br $label0
      end $label1
      global.get $_BottomType
    end $label0
    local.tee $var2
    block $label2 (result (ref $_Type))
      block $label3
        local.get $var1
        br_on_null $label3
        call $_getMasqueradedRuntimeType
        br $label2
      end $label3
      global.get $_BottomType
    end $label2
    local.get $var2
    struct.get $_Type $field0
    i32.const 119
    i32.add
    call_indirect (param (ref $#Top) (ref $#Top)) (result i32)
  )
  (@binaryen.inline 0)
  (func $testGenericClass (param $var0 (ref $GenericClass)) (param $var1 (ref $GenericClass)) (result i32)
    (local $var2 (ref $_Type))
    local.get $var0
    call $_getMasqueradedRuntimeType
    local.tee $var2
    local.get $var1
    call $_getMasqueradedRuntimeType
    local.get $var2
    struct.get $_Type $field0
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
    (local $var2 (ref $_Type))
    i32.const 1
    call $sink
    block $label0 (result (ref $_Type))
      block $label1
        local.get $var0
        br_on_null $label1
        call $_getMasqueradedRuntimeType
        br $label0
      end $label1
      global.get $_BottomType
    end $label0
    local.tee $var2
    local.get $var1
    call $_getMasqueradedRuntimeType
    local.get $var2
    struct.get $_Type $field0
    i32.const 119
    i32.add
    call_indirect (param (ref $#Top) (ref $#Top)) (result i32)
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
    (local $var2 (ref $_Type))
    i32.const 0
    call $sink
    local.get $var0
    call $_getMasqueradedRuntimeType
    local.tee $var2
    block $label0 (result (ref $_Type))
      block $label1
        local.get $var1
        br_on_null $label1
        call $_getMasqueradedRuntimeType
        br $label0
      end $label1
      global.get $_BottomType
    end $label0
    local.get $var2
    struct.get $_Type $field0
    i32.const 119
    i32.add
    call_indirect (param (ref $#Top) (ref $#Top)) (result i32)
  )
)