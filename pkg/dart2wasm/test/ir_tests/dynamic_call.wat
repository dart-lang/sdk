(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $Array<Object?> (array (field (mut (ref null $#Top)))))
  (type $Array<WasmI32> (array (field (mut i32))))
  (type $Array<_Type> (array (field (mut (ref $_Type)))))
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
  (type $_DefaultMap&_HashFieldBase&MapMixin (sub final $_HashFieldBase (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_index (mut (ref $Array<WasmI32>)))
    (field $_hashMask (mut i64))
    (field $_data (mut (ref $Array<Object?>)))
    (field $_usedData (mut i64))
    (field $_deletedKeys (mut i64))
    (field $field7 (ref $_Type))
    (field $field8 (ref $_Type)))))
  (type $_HashFieldBase (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_index (mut (ref $Array<WasmI32>)))
    (field $_hashMask (mut i64))
    (field $_data (mut (ref $Array<Object?>)))
    (field $_usedData (mut i64))
    (field $_deletedKeys (mut i64)))))
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
  (global $.a (import "" "a") (ref extern))
  (global $.toString (import "" "toString") (ref extern))
  (global $"SymbolConstant(#a)" (ref $Symbol)
    (i32.const 70)
    (i32.const 0)
    (global.get $"\"a\"")
    (struct.new $Symbol))
  (global $"SymbolConstant(#toString)" (ref $Symbol)
    (i32.const 70)
    (i32.const 0)
    (global.get $"\"toString\"")
    (struct.new $Symbol))
  (global $"WasmArray<Object>[0]" (ref $Array<Object?>)
    (array.new_fixed $Array<Object?> 0))
  (global $"WasmArray<Type>[0]" (ref $Array<_Type>)
    (array.new_fixed $Array<_Type> 0))
  (global $"\"a\"" (ref $JSExternWrapper)
    (i32.const 106)
    (i32.const 0)
    (global.get $.a)
    (struct.new $JSExternWrapper))
  (global $"\"toString\"" (ref $JSExternWrapper)
    (i32.const 106)
    (i32.const 0)
    (global.get $.toString)
    (struct.new $JSExternWrapper))
  (global $1 (ref $BoxedInt)
    (i32.const 66)
    (i64.const 1)
    (struct.new $BoxedInt))
  (global $true (ref $BoxedBool)
    (i32.const 3)
    (i32.const 1)
    (struct.new $BoxedBool))
  (func $Bar.toString invocation type checker (param $this (ref $#Top)) (param $var0 (ref $Array<_Type>)) (param $var1 (ref $Array<Object?>)) (param $var2 (ref $Array<Object?>)) (result (ref null $#Top)) <...>)
  (func $"Dynamic method forwarder for \"CallShape(toString, 0, 0, a)\"" (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $Array<_Type>))
    (local $var3 (ref $Array<Object?>))
    (local $var4 (ref $Array<Object?>))
    (local $var5 (ref $#Top))
    (local $var6 i32)
    (local $var7 (ref null $#Top))
    global.get $"WasmArray<Type>[0]"
    local.set $var2
    global.get $"WasmArray<Object>[0]"
    local.set $var3
    global.get $"SymbolConstant(#a)"
    local.get $var1
    array.new_fixed $Array<Object?> 2
    local.set $var4
    block $label0 (result (ref $#Top))
      local.get $var0
      br_on_non_null $label0
      local.get $var0
      global.get $"SymbolConstant(#toString)"
      local.get $var2
      call $_typeArgumentsToList
      local.get $var3
      call $_positionalParametersToList
      local.get $var4
      call $_namedParametersToMap
      call $"new Invocation.genericMethod"
      call $NoSuchMethodError._throwWithInvocation
      unreachable
    end $label0
    local.set $var5
    local.get $var5
    struct.get $#Top $field0
    local.set $var6
    block $label1
      block $label2
        block $label3
          local.get $var6
          i32.const 108
          i32.eq
          br_if $label3
          br $label2
        end $label3
        local.get $var5
        local.get $var2
        local.get $var3
        local.get $var1
        array.new_fixed $Array<Object?> 1
        call $"Bar.toString invocation type checker"
        return
      end $label2
      block $label4
        block $label5
          local.get $var6
          i32.const 109
          i32.eq
          br_if $label5
          br $label4
        end $label5
        local.get $var5
        local.get $var2
        local.get $var3
        local.get $var1
        array.new_fixed $Array<Object?> 1
        call $"Foo.toString invocation type checker"
        return
      end $label4
    end
    local.get $var5
    global.get $"SymbolConstant(#toString)"
    local.get $var2
    call $_typeArgumentsToList
    local.get $var3
    call $_positionalParametersToList
    local.get $var4
    call $_namedParametersToMap
    call $"new Invocation.genericMethod"
    call $Object.noSuchMethod
  )
  (func $Foo.toString invocation type checker (param $this (ref $#Top)) (param $var0 (ref $Array<_Type>)) (param $var1 (ref $Array<Object?>)) (param $var2 (ref $Array<Object?>)) (result (ref null $#Top)) <...>)
  (func $new Invocation.genericMethod (param $memberName (ref $Symbol)) (param $typeArguments (ref null $Object)) (param $positionalArguments (ref null $Object)) (param $namedArguments (ref null $Object)) (result (ref $_Invocation)) <...>)
  (func $Bar (result (ref $Object)) <...>)
  (func $Foo (result (ref $Object)) <...>)
  (func $NoSuchMethodError._throwWithInvocation (param $receiver (ref null $#Top)) (param $invocation (ref $_Invocation)) (result (ref none)) <...>)
  (func $Object.noSuchMethod (param $this (ref $#Top)) (param $invocation (ref $_Invocation)) (result (ref null $#Top)) <...>)
  (func $_namedParametersToMap (param $namedArguments (ref $Array<Object?>)) (result (ref $_DefaultMap&_HashFieldBase&MapMixin)) <...>)
  (func $_positionalParametersToList (param $positional (ref $Array<Object?>)) (result (ref $WasmListBase)) <...>)
  (func $_typeArgumentsToList (param $typeArgs (ref $Array<_Type>)) (result (ref $WasmListBase)) <...>)
  (func $confuse (param $a (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $main (result (ref null $#Top))
    (local $var0 (ref null $#Top))
    (local $var1 (ref null $#Top))
    call $Foo
    call $confuse
    global.get $true
    local.set $var0
    local.get $var0
    call $"Dynamic method forwarder for \"CallShape(toString, 0, 0, a)\""
    call $print
    drop
    call $Bar
    call $confuse
    global.get $1
    local.set $var1
    local.get $var1
    call $"Dynamic method forwarder for \"CallShape(toString, 0, 0, a)\""
    call $print
    drop
    ref.null none
  )
  (func $print (param $object (ref null $#Top)) (result (ref null $#Top)) <...>)
)