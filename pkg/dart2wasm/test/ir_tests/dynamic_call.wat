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
  (global $1 (ref $BoxedInt)
    (i32.const 65)
    (i64.const 1)
    (struct.new $BoxedInt))
  (global $true (ref $BoxedBool)
    (i32.const 3)
    (i32.const 1)
    (struct.new $BoxedBool))
  (func $Bar.toString (CallShape(toString names:a)) (param $this (ref $#Top)) (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $"Dynamic method forwarder for \"CallShape(toString names:a)\"" (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $#Top))
    (local $var3 i32)
    block $label0 (result (ref $#Top))
      local.get $var0
      br_on_non_null $label0
      local.get $var0
      local.get $var1
      call $"Invocation creator (CallShape(toString names:a))"
      call $Object._invokeNoSuchMethod
      unreachable
    end $label0
    local.set $var2
    local.get $var2
    struct.get $#Top $field0
    local.set $var3
    block $label1
      block $label2
        block $label3
          local.get $var3
          i32.const 108
          i32.eq
          br_if $label3
          br $label2
        end $label3
        local.get $var2
        local.get $var1
        call $"Bar.toString (CallShape(toString names:a))"
        return
      end $label2
      block $label4
        block $label5
          local.get $var3
          i32.const 109
          i32.eq
          br_if $label5
          br $label4
        end $label5
        local.get $var2
        local.get $var1
        call $"Foo.toString (CallShape(toString names:a))"
        return
      end $label4
    end
    local.get $var2
    local.get $var1
    call $"Invocation creator (CallShape(toString names:a))"
    call $Object._invokeNoSuchMethod
  )
  (func $Foo.toString (CallShape(toString names:a)) (param $this (ref $#Top)) (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $Invocation creator (CallShape(toString names:a)) (param $var0 (ref null $#Top)) (result (ref $_Invocation)) <...>)
  (func $Bar (result (ref $Object)) <...>)
  (func $Foo (result (ref $Object)) <...>)
  (func $Object._invokeNoSuchMethod (param $receiver (ref null $#Top)) (param $invocation (ref $_Invocation)) (result (ref null $#Top)) <...>)
  (func $confuse (param $a (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $main (result (ref null $#Top))
    (local $var0 (ref null $#Top))
    (local $var1 (ref null $#Top))
    call $Foo
    call $confuse
    global.get $true
    local.set $var0
    local.get $var0
    call $"Dynamic method forwarder for \"CallShape(toString names:a)\""
    call $print
    drop
    call $Bar
    call $confuse
    global.get $1
    local.set $var1
    local.get $var1
    call $"Dynamic method forwarder for \"CallShape(toString names:a)\""
    call $print
    drop
    ref.null none
  )
  (func $print (param $object (ref null $#Top)) (result (ref null $#Top)) <...>)
)