(module $module0
  (type $"dummy struct" (struct))
  (type $#Closure-0-0 (sub $#ClosureBase (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $context (ref struct))
    (field $vtable (ref $#Vtable-0-0))
    (field $functionType (ref $_FunctionType)))))
  (type $#ClosureBase (sub $_Closure (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $context (ref struct))
    (field $vtable (ref $#VtableBase))
    (field $functionType (ref $_FunctionType)))))
  (type $#NonGenericVtableBase (sub $#VtableBase (struct)))
  (type $#Top (struct
    (field $field0 i32)))
  (type $#Vtable-0-0 (sub $#NonGenericVtableBase (struct
    (field $closureCallEntry-0-0 (ref $type0)))))
  (type $#VtableBase (struct))
  (type $Array<Object?> (array (field (mut (ref null $#Top)))))
  (type $Array<WasmI32> (array (field (mut i32))))
  (type $Array<_NamedParameter> (array (field (mut (ref $_NamedParameter)))))
  (type $Array<_Type> (array (field (mut (ref $_Type)))))
  (type $BoxedBool (sub final $#Top (struct
    (field $field0 i32)
    (field $value (mut i32)))))
  (type $BoxedInt (sub final $#Top (struct
    (field $field0 i32)
    (field $value i64))))
  (type $JSStringImpl (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_ref externref))))
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
    (field $_name (ref $JSStringImpl)))))
  (type $WasmListBase (sub final $ListBase (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $field2 (ref $_Type))
    (field $_length (mut i64))
    (field $_data (mut (ref $Array<Object?>))))))
  (type $_Closure (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $context (ref struct)))))
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
  (type $_FunctionType (sub final $_Type (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $isDeclaredNullable i32)
    (field $typeParameterOffset i64)
    (field $typeParameterBounds (ref $Array<_Type>))
    (field $typeParameterDefaults (ref $Array<_Type>))
    (field $returnType (ref $_Type))
    (field $positionalParameters (ref $Array<_Type>))
    (field $requiredParameterCount i64)
    (field $namedParameters (ref $Array<_NamedParameter>)))))
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
  (type $_NamedParameter (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $name (ref $Symbol))
    (field $type (ref $_Type))
    (field $isRequired i32))))
  (type $_TopType (sub final $_Type (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $isDeclaredNullable i32)
    (field $_kind i64))))
  (type $_Type (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $isDeclaredNullable i32))))
  (type $type0 (func 
    (param $var0 (ref struct))
    (result (ref null $#Top))))
  (global $.a (import "" "a") (ref extern))
  (global $.toString (import "" "toString") (ref extern))
  (global $"SymbolConstant(#a)" (ref $Symbol)
    (i32.const 112)
    (i32.const 0)
    (global.get $"\"a\"")
    (struct.new $Symbol))
  (global $"SymbolConstant(#toString)" (ref $Symbol)
    (i32.const 112)
    (i32.const 0)
    (global.get $"\"toString\"")
    (struct.new $Symbol))
  (global $"WasmArray<Object>[0]" (ref $Array<Object?>)
    (array.new_fixed $Array<Object?> 0))
  (global $"WasmArray<Type>[0]" (ref $Array<_Type>)
    (array.new_fixed $Array<_Type> 0))
  (global $"WasmArray<_NamedParameter>[0]" (ref $Array<_NamedParameter>)
    (array.new_fixed $Array<_NamedParameter> 0))
  (global $"WasmArray<_Type>[0]" (ref $Array<_Type>)
    (array.new_fixed $Array<_Type> 0))
  (global $"\"a\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $.a)
    (struct.new $JSStringImpl))
  (global $"\"toString\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $.toString)
    (struct.new $JSStringImpl))
  (global $"main tear-off" (ref $#Closure-0-0)
    (i32.const 32)
    (i32.const 0)
    (global.get $global0)
    (global.get $global2)
    (global.get $_FunctionType)
    (struct.new $#Closure-0-0))
  (global $1 (ref $BoxedInt)
    (i32.const 68)
    (i64.const 1)
    (struct.new $BoxedInt))
  (global $_FunctionType (ref $_FunctionType)
    (i32.const 12)
    (i32.const 0)
    (i32.const 0)
    (i64.const 0)
    (global.get $"WasmArray<_Type>[0]")
    (global.get $"WasmArray<_Type>[0]")
    (global.get $_TopType)
    (global.get $"WasmArray<_Type>[0]")
    (i64.const 0)
    (global.get $"WasmArray<_NamedParameter>[0]")
    (struct.new $_FunctionType))
  (global $_TopType (ref $_TopType)
    (i32.const 6)
    (i32.const 0)
    (i32.const 1)
    (i64.const 2)
    (struct.new $_TopType))
  (global $global0 (ref struct)
    (struct.new $"dummy struct"))
  (global $global2 (ref $#Vtable-0-0)
    (ref.func $"main tear-off trampoline")
    (struct.new $#Vtable-0-0))
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
          i32.const 118
          i32.eq
          br_if $label3
          br $label2
        end $label3
        local.get $var5
        local.get $var2
        local.get $var3
        local.get $var1
        array.new_fixed $Array<Object?> 1
        call $"Foo.toString invocation type checker"
        return
      end $label2
      block $label4
        block $label5
          local.get $var6
          i32.const 119
          i32.eq
          br_if $label5
          br $label4
        end $label5
        local.get $var5
        local.get $var2
        local.get $var3
        local.get $var1
        array.new_fixed $Array<Object?> 1
        call $"Bar.toString invocation type checker"
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
  (func $main tear-off trampoline (param $var0 (ref struct)) (result (ref null $#Top)) <...>)
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
  (func $mainTearOffArg0 (result (ref null $#Closure-0-0))
    global.get $"main tear-off"
    return
  )
  (func $print (param $object (ref null $#Top)) (result (ref null $#Top)) <...>)
)