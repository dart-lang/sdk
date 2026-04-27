(module $module0
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $Array<_Type> <...>)
  (type $Base <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $SubNamed <...>)
  (type $SubOptionalNamed <...>)
  (type $SubOptionalPos <...>)
  (type $SubPos1 <...>)
  (type $SubPos2 <...>)
  (type $WasmListBase <...>)
  (type $_InterfaceType <...>)
  (type $_MixinApplication0&Base&SubMixin <...>)
  (type $_MixinApplication2&Base&SubMixin <...>)
  (type $_MixinApplication3&Base&SubMixin <...>)
  (type $_Type <...>)
  (global $"\", \"" (ref $JSExternWrapper) <...>)
  (global $"\">: \"" (ref $JSExternWrapper) <...>)
  (global $"\"SubNamed<\"" (ref $JSExternWrapper) <...>)
  (global $"\"SubOptionalNamed<\"" (ref $JSExternWrapper) <...>)
  (global $"\"SubOptionalPos<\"" (ref $JSExternWrapper) <...>)
  (global $"\"SubPos1<\"" (ref $JSExternWrapper) <...>)
  (global $"\"SubPos2<\"" (ref $JSExternWrapper) <...>)
  (func $"SubNamed.onlyUsedInSubField implicit getter" (param $var0 (ref $Base)) (result i64)
    local.get $var0
    ref.cast $SubNamed
    struct.get $SubNamed $onlyUsedInSubField
  )
  (func $"SubNamed.subInitializerField implicit getter" (param $var0 (ref $Base)) (result (ref null $#Top))
    local.get $var0
    ref.cast $SubNamed
    struct.get $SubNamed $subInitializerField
  )
  (func $"SubOptionalNamed.onlyUsedInSubField implicit getter" (param $var0 (ref $Base)) (result i64)
    local.get $var0
    ref.cast $SubOptionalNamed
    struct.get $SubOptionalNamed $onlyUsedInSubField
  )
  (func $"SubOptionalNamed.subInitializerField implicit getter" (param $var0 (ref $Base)) (result (ref null $#Top))
    local.get $var0
    ref.cast $SubOptionalNamed
    struct.get $SubOptionalNamed $subInitializerField
  )
  (func $"SubOptionalPos.onlyUsedInSubField implicit getter" (param $var0 (ref $Base)) (result i64)
    local.get $var0
    ref.cast $SubOptionalPos
    struct.get $SubOptionalPos $onlyUsedInSubField
  )
  (func $"SubOptionalPos.subInitializerField implicit getter" (param $var0 (ref $Base)) (result (ref null $#Top))
    local.get $var0
    ref.cast $SubOptionalPos
    struct.get $SubOptionalPos $subInitializerField
  )
  (func $"SubPos1.onlyUsedInSubField implicit getter" (param $var0 (ref $Base)) (result i64)
    local.get $var0
    ref.cast $SubPos1
    struct.get $SubPos1 $onlyUsedInSubField
  )
  (func $"SubPos1.subInitializerField implicit getter" (param $var0 (ref $Base)) (result (ref null $#Top))
    local.get $var0
    ref.cast $SubPos1
    struct.get $SubPos1 $subInitializerField
  )
  (func $"SubPos2.onlyUsedInSubField implicit getter" (param $var0 (ref $Base)) (result i64)
    local.get $var0
    ref.cast $SubPos2
    struct.get $SubPos2 $onlyUsedInSubField
  )
  (func $"SubPos2.subInitializerField implicit getter" (param $var0 (ref $Base)) (result (ref null $#Top))
    local.get $var0
    ref.cast $SubPos2
    struct.get $SubPos2 $subInitializerField
  )
  (func $createEmptyList<DynamicType(dynamic)> (result (ref $WasmListBase)) <...>)
  (func $new Base.named (constructor body) (param $this (ref $Base)) <...>)
  (func $new Base.named (initializer) (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) <...>)
  (func $new Base.sub1 (constructor body) (param $this (ref $Base)) (param $onlyUsedInBaseBody i64) <...>)
  (func $new Base.sub1 (initializer) (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (param $onlyUsedInBaseBody i64) (result i64) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) <...>)
  (func $new Base.sub2 (constructor body) (param $this (ref $Base)) <...>)
  (func $new Base.sub2 (initializer) (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) <...>)
  (func $"new SubNamed (constructor body)" (param $this (ref $SubNamed))
    (local $var0 (ref $_Type))
    (local $var1 i64)
    (local $var2 (ref null $#Top))
    local.get $this
    struct.get $SubNamed $field2
    local.set $var0
    local.get $this
    struct.get $SubNamed $onlyUsedInSubField
    local.set $var1
    local.get $this
    struct.get $SubNamed $onlyUsedInBaseField
    local.set $var2
    local.get $this
    call $"new _MixinApplication1&Base&SubMixin.named (constructor body)"
    global.get $"\"SubNamed<\""
    local.get $var0
    global.get $"\">: \""
    local.get $this
    struct.get $SubNamed $subInitializerField
    call $JSStringImpl._interpolate4
    call $print
    drop
  )
  (func $"new SubNamed (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInSubField i64) (param $onlyUsedInSuper i64) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref null $#Top)) (result i64)
    (local $var1 (ref null $#Top))
    (local $var2 i64)
    (local $var3 i64)
    call $"createEmptyList<DynamicType(dynamic)>"
    local.set $var1
    local.get $onlyUsedInSubField
    local.set $var2
    local.get $var0
    local.get $onlyUsedInSuper
    local.set $var3
    i32.const 63
    local.get $var3
    struct.new $BoxedInt
    call $"new _MixinApplication1&Base&SubMixin.named (initializer)"
    local.get $var1
    local.get $var2
  )
  (func $"new SubOptionalNamed (constructor body)" (param $this (ref $SubOptionalNamed))
    (local $var0 (ref $_Type))
    (local $var1 i64)
    (local $var2 (ref null $#Top))
    local.get $this
    struct.get $SubOptionalNamed $field5
    local.set $var0
    local.get $this
    struct.get $SubOptionalNamed $onlyUsedInSubField
    local.set $var1
    local.get $this
    struct.get $SubOptionalNamed $onlyUsedInBaseField
    local.set $var2
    local.get $this
    call $"new _MixinApplication3&Base&SubMixin.named (constructor body)"
    global.get $"\"SubOptionalNamed<\""
    local.get $var0
    global.get $"\">: \""
    local.get $this
    struct.get $SubOptionalNamed $subInitializerField
    call $JSStringImpl._interpolate4
    call $print
    drop
  )
  (func $"new SubOptionalNamed (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInSubField (ref null $BoxedInt)) (param $onlyUsedInSuper (ref null $BoxedInt)) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref $_Type)) (result (ref null $#Top)) (result i64)
    (local $var1 (ref null $#Top))
    (local $var2 i64)
    call $"createEmptyList<DynamicType(dynamic)>"
    local.set $var1
    local.get $onlyUsedInSubField
    struct.get $BoxedInt $value
    local.set $var2
    local.get $var0
    local.get $onlyUsedInSuper
    call $"new _MixinApplication3&Base&SubMixin.named (initializer)"
    local.get $var1
    local.get $var2
  )
  (func $"new SubOptionalPos (constructor body)" (param $this (ref $SubOptionalPos)) (param $onlyUsedInSubBody (ref null $BoxedInt)) (param $var0 i64)
    (local $var1 (ref $_Type))
    (local $var2 i64)
    (local $var3 (ref null $#Top))
    local.get $this
    struct.get $SubOptionalPos $field5
    local.set $var1
    local.get $this
    struct.get $SubOptionalPos $onlyUsedInSubField
    local.set $var2
    local.get $this
    struct.get $SubOptionalPos $onlyUsedInBaseField
    local.set $var3
    local.get $this
    local.get $var0
    call $"new _MixinApplication2&Base&SubMixin.sub1 (constructor body)"
    global.get $"\"SubOptionalPos<\""
    local.get $var1
    global.get $"\">: \""
    local.get $this
    struct.get $SubOptionalPos $subInitializerField
    global.get $"\", \""
    local.get $onlyUsedInSubBody
    array.new_fixed $Array<Object?> 6
    call $JSStringImpl._interpolate
    call $print
    drop
  )
  (func $"new SubOptionalPos (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInSubField (ref null $BoxedInt)) (param $onlyUsedInSubBody (ref null $BoxedInt)) (param $onlyUsedInSuper1 (ref null $BoxedInt)) (param $onlyUsedInSuper2 (ref null $BoxedInt)) (result (ref null $BoxedInt)) (result i64) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref $_Type)) (result (ref null $#Top)) (result i64)
    (local $var1 (ref null $#Top))
    (local $var2 i64)
    (local $var3 (ref $_Type))
    (local $var4 (ref null $#Top))
    (local $var5 (ref $WasmListBase))
    (local $var6 (ref $_Type))
    (local $var7 i64)
    call $"createEmptyList<DynamicType(dynamic)>"
    local.set $var1
    local.get $onlyUsedInSubField
    struct.get $BoxedInt $value
    local.set $var2
    local.get $var0
    local.get $onlyUsedInSuper1
    local.get $onlyUsedInSuper2
    struct.get $BoxedInt $value
    call $"new _MixinApplication2&Base&SubMixin.sub1 (initializer)"
    local.set $var3
    local.set $var4
    local.set $var5
    local.set $var6
    local.set $var7
    local.get $onlyUsedInSubBody
    local.get $var7
    local.get $var6
    local.get $var5
    local.get $var4
    local.get $var3
    local.get $var1
    local.get $var2
  )
  (func $"new SubPos1 (constructor body)" (param $this (ref $SubPos1)) (param $onlyUsedInSubBody i64) (param $var0 i64)
    (local $var1 (ref $_Type))
    (local $var2 i64)
    (local $var3 (ref null $#Top))
    (local $var4 i64)
    local.get $this
    struct.get $SubPos1 $field5
    local.set $var1
    local.get $this
    struct.get $SubPos1 $onlyUsedInSubField
    local.set $var2
    local.get $this
    struct.get $SubPos1 $onlyUsedInBaseField
    local.set $var3
    local.get $this
    local.get $var0
    call $"new _MixinApplication0&Base&SubMixin.sub1 (constructor body)"
    global.get $"\"SubPos1<\""
    local.get $var1
    global.get $"\">: \""
    local.get $this
    struct.get $SubPos1 $subInitializerField
    global.get $"\", \""
    local.get $onlyUsedInSubBody
    local.set $var4
    i32.const 63
    local.get $var4
    struct.new $BoxedInt
    array.new_fixed $Array<Object?> 6
    call $JSStringImpl._interpolate
    call $print
    drop
  )
  (func $"new SubPos1 (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInSubField i64) (param $onlyUsedInSubBody i64) (param $onlyUsedInSuper1 i64) (param $onlyUsedInSuper2 i64) (result i64) (result i64) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref $_Type)) (result (ref null $#Top)) (result i64)
    (local $var1 (ref null $#Top))
    (local $var2 i64)
    (local $var3 i64)
    (local $var4 (ref $_Type))
    (local $var5 (ref null $#Top))
    (local $var6 (ref $WasmListBase))
    (local $var7 (ref $_Type))
    (local $var8 i64)
    call $"createEmptyList<DynamicType(dynamic)>"
    local.set $var1
    local.get $onlyUsedInSubField
    local.set $var2
    local.get $var0
    local.get $onlyUsedInSuper1
    local.set $var3
    i32.const 63
    local.get $var3
    struct.new $BoxedInt
    local.get $onlyUsedInSuper2
    call $"new _MixinApplication0&Base&SubMixin.sub1 (initializer)"
    local.set $var4
    local.set $var5
    local.set $var6
    local.set $var7
    local.set $var8
    local.get $onlyUsedInSubBody
    local.get $var8
    local.get $var7
    local.get $var6
    local.get $var5
    local.get $var4
    local.get $var1
    local.get $var2
  )
  (func $"new SubPos2 (constructor body)" (param $this (ref $SubPos2))
    (local $var0 (ref $_Type))
    (local $var1 i64)
    (local $var2 (ref null $#Top))
    local.get $this
    struct.get $SubPos2 $field2
    local.set $var0
    local.get $this
    struct.get $SubPos2 $onlyUsedInSubField
    local.set $var1
    local.get $this
    struct.get $SubPos2 $onlyUsedInBaseField
    local.set $var2
    local.get $this
    call $"new _MixinApplication1&Base&SubMixin.sub2 (constructor body)"
    global.get $"\"SubPos2<\""
    local.get $var0
    global.get $"\">: \""
    local.get $this
    struct.get $SubPos2 $subInitializerField
    call $JSStringImpl._interpolate4
    call $print
    drop
  )
  (func $"new SubPos2 (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInSubField i64) (param $onlyUsedInSuper1 i64) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref null $#Top)) (result i64)
    (local $var1 (ref null $#Top))
    (local $var2 i64)
    (local $var3 i64)
    call $"createEmptyList<DynamicType(dynamic)>"
    local.set $var1
    local.get $onlyUsedInSubField
    local.set $var2
    local.get $var0
    local.get $onlyUsedInSuper1
    local.set $var3
    i32.const 63
    local.get $var3
    struct.new $BoxedInt
    call $"new _MixinApplication1&Base&SubMixin.sub2 (initializer)"
    local.get $var1
    local.get $var2
  )
  (func $"new _MixinApplication0&Base&SubMixin.sub1 (constructor body)" (param $this (ref $_MixinApplication0&Base&SubMixin)) (param $var0 i64)
    (local $preciseThis (ref $SubPos1))
    (local $var1 (ref $_Type))
    (local $var2 (ref null $#Top))
    local.get $this
    ref.cast $SubPos1
    local.set $preciseThis
    local.get $preciseThis
    struct.get $_MixinApplication0&Base&SubMixin $field5
    local.set $var1
    local.get $preciseThis
    struct.get $_MixinApplication0&Base&SubMixin $onlyUsedInBaseField
    local.set $var2
    local.get $this
    local.get $var0
    call $"new Base.sub1 (constructor body)"
  )
  (func $"new _MixinApplication0&Base&SubMixin.sub1 (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (param $onlyUsedInBaseBody i64) (result i64) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref $_Type))
    i32.const 9
    i32.const 0
    i32.const 0
    i32.const 170
    local.get $var0
    array.new_fixed $Array<_Type> 1
    struct.new $_InterfaceType
    local.get $onlyUsedInBaseField
    local.get $onlyUsedInBaseBody
    call $"new Base.sub1 (initializer)"
    local.get $var0
  )
  (func $"new _MixinApplication1&Base&SubMixin.named (constructor body)" (param $this (ref $Base))
    (local $var0 (ref $_Type))
    (local $var1 (ref null $#Top))
    local.get $this
    struct.get $Base $field2
    local.set $var0
    local.get $this
    struct.get $Base $onlyUsedInBaseField
    local.set $var1
    local.get $this
    call $"new Base.named (constructor body)"
  )
  (func $"new _MixinApplication1&Base&SubMixin.named (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top))
    local.get $var0
    local.get $onlyUsedInBaseField
    call $"new Base.named (initializer)"
  )
  (func $"new _MixinApplication1&Base&SubMixin.sub2 (constructor body)" (param $this (ref $Base))
    (local $var0 (ref $_Type))
    (local $var1 (ref null $#Top))
    local.get $this
    struct.get $Base $field2
    local.set $var0
    local.get $this
    struct.get $Base $onlyUsedInBaseField
    local.set $var1
    local.get $this
    call $"new Base.sub2 (constructor body)"
  )
  (func $"new _MixinApplication1&Base&SubMixin.sub2 (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top))
    local.get $var0
    local.get $onlyUsedInBaseField
    call $"new Base.sub2 (initializer)"
  )
  (func $"new _MixinApplication2&Base&SubMixin.sub1 (constructor body)" (param $this (ref $_MixinApplication2&Base&SubMixin)) (param $var0 i64)
    (local $preciseThis (ref $SubOptionalPos))
    (local $var1 (ref $_Type))
    (local $var2 (ref null $#Top))
    local.get $this
    ref.cast $SubOptionalPos
    local.set $preciseThis
    local.get $preciseThis
    struct.get $_MixinApplication2&Base&SubMixin $field5
    local.set $var1
    local.get $preciseThis
    struct.get $_MixinApplication2&Base&SubMixin $onlyUsedInBaseField
    local.set $var2
    local.get $this
    local.get $var0
    call $"new Base.sub1 (constructor body)"
  )
  (func $"new _MixinApplication2&Base&SubMixin.sub1 (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (param $onlyUsedInBaseBody i64) (result i64) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref $_Type))
    i32.const 9
    i32.const 0
    i32.const 0
    i32.const 174
    local.get $var0
    array.new_fixed $Array<_Type> 1
    struct.new $_InterfaceType
    local.get $onlyUsedInBaseField
    local.get $onlyUsedInBaseBody
    call $"new Base.sub1 (initializer)"
    local.get $var0
  )
  (func $"new _MixinApplication3&Base&SubMixin.named (constructor body)" (param $this (ref $_MixinApplication3&Base&SubMixin))
    (local $preciseThis (ref $SubOptionalNamed))
    (local $var0 (ref $_Type))
    (local $var1 (ref null $#Top))
    local.get $this
    ref.cast $SubOptionalNamed
    local.set $preciseThis
    local.get $preciseThis
    struct.get $_MixinApplication3&Base&SubMixin $field5
    local.set $var0
    local.get $preciseThis
    struct.get $_MixinApplication3&Base&SubMixin $onlyUsedInBaseField
    local.set $var1
    local.get $this
    call $"new Base.named (constructor body)"
  )
  (func $"new _MixinApplication3&Base&SubMixin.named (initializer)" (param $var0 (ref $_Type)) (param $onlyUsedInBaseField (ref null $#Top)) (result (ref $_Type)) (result (ref $WasmListBase)) (result (ref null $#Top)) (result (ref $_Type))
    i32.const 9
    i32.const 0
    i32.const 0
    i32.const 162
    local.get $var0
    array.new_fixed $Array<_Type> 1
    struct.new $_InterfaceType
    local.get $onlyUsedInBaseField
    call $"new Base.named (initializer)"
    local.get $var0
  )
  (func $JSStringImpl._interpolate (param $values (ref $Array<Object?>)) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl._interpolate4 (param $value1 (ref null $#Top)) (param $value2 (ref null $#Top)) (param $value3 (ref null $#Top)) (param $value4 (ref null $#Top)) (result (ref $JSExternWrapper)) <...>)
  (func $SubNamed (param $var0 (ref $_Type)) (param $onlyUsedInSubField i64) (param $onlyUsedInSuper i64) (result (ref $SubNamed))
    (local $var1 (ref $SubNamed))
    i32.const 107
    i32.const 0
    local.get $var0
    local.get $onlyUsedInSubField
    local.get $onlyUsedInSuper
    call $"new SubNamed (initializer)"
    struct.new $SubNamed
    local.tee $var1
    call $"new SubNamed (constructor body)"
    local.get $var1
  )
  (func $SubNamed._typeArguments (param $var0 (ref $#Top)) (result (ref $Array<_Type>))
    (local $this (ref $SubNamed))
    local.get $var0
    ref.cast $SubNamed
    local.set $this
    local.get $this
    struct.get $SubNamed $field2
    array.new_fixed $Array<_Type> 1
  )
  (func $SubOptionalNamed (param $var0 (ref $_Type)) (param $onlyUsedInSubField (ref null $BoxedInt)) (param $onlyUsedInSuper (ref null $BoxedInt)) (result (ref $SubOptionalNamed))
    (local $var1 (ref $SubOptionalNamed))
    i32.const 109
    i32.const 0
    local.get $var0
    local.get $onlyUsedInSubField
    local.get $onlyUsedInSuper
    call $"new SubOptionalNamed (initializer)"
    struct.new $SubOptionalNamed
    local.tee $var1
    call $"new SubOptionalNamed (constructor body)"
    local.get $var1
  )
  (func $SubOptionalNamed._typeArguments (param $var0 (ref $#Top)) (result (ref $Array<_Type>))
    (local $this (ref $SubOptionalNamed))
    local.get $var0
    ref.cast $SubOptionalNamed
    local.set $this
    local.get $this
    struct.get $SubOptionalNamed $field5
    array.new_fixed $Array<_Type> 1
  )
  (func $SubOptionalPos (param $var0 (ref $_Type)) (param $onlyUsedInSubField (ref null $BoxedInt)) (param $onlyUsedInSubBody (ref null $BoxedInt)) (param $onlyUsedInSuper1 (ref null $BoxedInt)) (param $onlyUsedInSuper2 (ref null $BoxedInt)) (result (ref $SubOptionalPos))
    (local $var1 i64)
    (local $var2 (ref null $#Top))
    (local $var3 (ref $_Type))
    (local $var4 (ref null $#Top))
    (local $var5 (ref $WasmListBase))
    (local $var6 (ref $_Type))
    (local $var7 i64)
    (local $var8 (ref null $BoxedInt))
    (local $var9 (ref $SubOptionalPos))
    local.get $var0
    local.get $onlyUsedInSubField
    local.get $onlyUsedInSubBody
    local.get $onlyUsedInSuper1
    local.get $onlyUsedInSuper2
    call $"new SubOptionalPos (initializer)"
    local.set $var1
    local.set $var2
    local.set $var3
    local.set $var4
    local.set $var5
    local.set $var6
    local.set $var7
    local.set $var8
    i32.const 108
    i32.const 0
    local.get $var6
    local.get $var5
    local.get $var4
    local.get $var3
    local.get $var2
    local.get $var1
    struct.new $SubOptionalPos
    local.tee $var9
    local.get $var8
    local.get $var7
    call $"new SubOptionalPos (constructor body)"
    local.get $var9
  )
  (func $SubOptionalPos._typeArguments (param $var0 (ref $#Top)) (result (ref $Array<_Type>))
    (local $this (ref $SubOptionalPos))
    local.get $var0
    ref.cast $SubOptionalPos
    local.set $this
    local.get $this
    struct.get $SubOptionalPos $field5
    array.new_fixed $Array<_Type> 1
  )
  (func $SubPos1 (param $var0 (ref $_Type)) (param $onlyUsedInSubField i64) (param $onlyUsedInSubBody i64) (param $onlyUsedInSuper1 i64) (param $onlyUsedInSuper2 i64) (result (ref $SubPos1))
    (local $var1 i64)
    (local $var2 (ref null $#Top))
    (local $var3 (ref $_Type))
    (local $var4 (ref null $#Top))
    (local $var5 (ref $WasmListBase))
    (local $var6 (ref $_Type))
    (local $var7 i64)
    (local $var8 i64)
    (local $var9 (ref $SubPos1))
    local.get $var0
    local.get $onlyUsedInSubField
    local.get $onlyUsedInSubBody
    local.get $onlyUsedInSuper1
    local.get $onlyUsedInSuper2
    call $"new SubPos1 (initializer)"
    local.set $var1
    local.set $var2
    local.set $var3
    local.set $var4
    local.set $var5
    local.set $var6
    local.set $var7
    local.set $var8
    i32.const 105
    i32.const 0
    local.get $var6
    local.get $var5
    local.get $var4
    local.get $var3
    local.get $var2
    local.get $var1
    struct.new $SubPos1
    local.tee $var9
    local.get $var8
    local.get $var7
    call $"new SubPos1 (constructor body)"
    local.get $var9
  )
  (func $SubPos1._typeArguments (param $var0 (ref $#Top)) (result (ref $Array<_Type>))
    (local $this (ref $SubPos1))
    local.get $var0
    ref.cast $SubPos1
    local.set $this
    local.get $this
    struct.get $SubPos1 $field5
    array.new_fixed $Array<_Type> 1
  )
  (func $SubPos2 (param $var0 (ref $_Type)) (param $onlyUsedInSubField i64) (param $onlyUsedInSuper1 i64) (result (ref $SubPos2))
    (local $var1 (ref $SubPos2))
    i32.const 106
    i32.const 0
    local.get $var0
    local.get $onlyUsedInSubField
    local.get $onlyUsedInSuper1
    call $"new SubPos2 (initializer)"
    struct.new $SubPos2
    local.tee $var1
    call $"new SubPos2 (constructor body)"
    local.get $var1
  )
  (func $SubPos2._typeArguments (param $var0 (ref $#Top)) (result (ref $Array<_Type>))
    (local $this (ref $SubPos2))
    local.get $var0
    ref.cast $SubPos2
    local.set $this
    local.get $this
    struct.get $SubPos2 $field2
    array.new_fixed $Array<_Type> 1
  )
  (func $print (param $object (ref null $#Top)) (result (ref null $#Top)) <...>)
)