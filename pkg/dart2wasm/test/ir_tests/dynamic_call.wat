(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $Array<Object?> (array (field (mut (ref null $#Top)))))
  (type $BoxedBool (sub final $#Top (struct
    (field $field0 i32)
    (field $value (mut i32)))))
  (type $BoxedInt (sub final $#Top (struct
    (field $field0 i32)
    (field $value i64))))
  (type $JSExternWrapper (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_externRef externref))))
  (type $ListBase (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $field2 (ref $_Type)))))
  (type $Object (sub $#Top (struct
    (field $field0 i32)
    (field $field1 (mut i32)))))
  (type $Symbol (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_name (ref $JSExternWrapper)))))
  (type $WasmListBase (sub final $ListBase (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $field2 (ref $_Type))
    (field $_length (mut i64))
    (field $_data (mut (ref $Array<Object?>))))))
  (type $_Invocation (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $memberName (ref $Symbol))
    (field $_positional (ref null $WasmListBase))
    (field $_named (ref null $Object)))))
  (type $_Type (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $isDeclaredNullable i32))))
  (type $type0 (func 
    (param $var0 (ref $#Top))
    (param $var1 (ref null $#Top))
    (result (ref null $#Top))))
  (table $dtable0 3 i31ref)
  (table $dtable2 3 funcref)
  (global $1 (ref $BoxedInt)
    (i32.const 63)
    (i64.const 1)
    (struct.new $BoxedInt))
  (global $true (ref $BoxedBool)
    (i32.const 3)
    (i32.const 1)
    (struct.new $BoxedBool))
  (elem $dtable0
    (set 0 (i32.const 105) (i31.new) (end))
    (set 1 (i32.const 106) (i31.new) (end)))
  (elem $dtable2
    (set 0 (ref.func $"Bar.toString (MethodCallShape(toString names:a))"))
    (set 1 (ref.func $"Foo.toString (MethodCallShape(toString names:a))")))
  (func $Bar.toString (MethodCallShape(toString names:a)) (param $this (ref $#Top)) (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $"Dynamic dispatcher for MethodCallShape(toString names:a)" (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $#Top))
    (local $var3 i32)
    (local $var4 i32)
    block $label0
      local.get $var0
      br_on_null $label0
      local.set $var2
      local.get $var2
      struct.get $#Top $field0
      local.set $var3
      block $label1
        local.get $var3
        i32.const -105
        i32.add
        local.tee $var4
        table.size $dtable0
        i32.ge_u
        br_if $label1
        local.get $var4
        table.get $dtable0
        br_on_null $label1
        i31.get_u
        local.get $var3
        i32.eq
        if
          local.get $var2
          local.get $var1
          local.get $var4
          table.get $dtable2
          br_on_null $label0
          ref.cast $type0
          call_ref $type0
          return
        end
      end $label1
    end $label0
    local.get $var0
    local.get $var1
    call $"Invocation creator (MethodCallShape(toString names:a))"
    call $Object._invokeNoSuchMethod
    return
  )
  (func $Foo.toString (MethodCallShape(toString names:a)) (param $this (ref $#Top)) (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $Invocation creator (MethodCallShape(toString names:a)) (param $var0 (ref null $#Top)) (result (ref $_Invocation)) <...>)
  (func $Bar (result (ref $Object)) <...>)
  (func $Foo (result (ref $Object)) <...>)
  (func $Object._invokeNoSuchMethod (param $receiver (ref null $#Top)) (param $invocation (ref $_Invocation)) (result (ref null $#Top)) <...>)
  (func $confuse (param $a (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $main
    (local $var0 (ref null $#Top))
    (local $var1 (ref null $#Top))
    call $Foo
    call $confuse
    global.get $true
    local.set $var0
    local.get $var0
    call $"Dynamic dispatcher for MethodCallShape(toString names:a)"
    call $print
    ref.null none
    drop
    call $Bar
    call $confuse
    global.get $1
    local.set $var1
    local.get $var1
    call $"Dynamic dispatcher for MethodCallShape(toString names:a)"
    call $print
    ref.null none
    drop
  )
  (func $print (param $object (ref null $#Top)) <...>)
)