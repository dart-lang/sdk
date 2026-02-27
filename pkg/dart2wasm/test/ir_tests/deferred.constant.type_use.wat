(module $module0
  (type $#Top <...>)
  (type $DeferredLoadIdNotLoadedError <...>)
  (type $JSStringImpl <...>)
  (type $_DefaultSet&_HashFieldBase&SetMixin <...>)
  (type $_InterfaceType <...>)
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 3 funcref)
  (global $_InterfaceType_444 (ref $_InterfaceType) <...>)
  (elem $cross-module-funcs-0
    (set 1 (ref.func $JSStringImpl._interpolate2))
    (set 2 (ref.func $print)))
  (func $Error._throwWithCurrentStackTrace <noInline> (param $var0 (ref $#Top)) <...>)
  (func $_loaded implicit getter (result (ref $_DefaultSet&_HashFieldBase&SetMixin)) <...>)
  (func $"useFoo <noInline>"
    call $"useFooAsType <noInline>"
    call $"_loaded implicit getter"
    call $_DefaultSet&_HashFieldBase&SetMixin&_HashBase&_OperatorEqualsAndHashCode&_LinkedHashSetMixin.contains
    i32.eqz
    if
      i32.const 51
      i32.const 0
      ref.null none
      i64.const 0
      struct.new $DeferredLoadIdNotLoadedError
      call $"Error._throwWithCurrentStackTrace <noInline>"
      unreachable
    end
    i32.const 0
    call_indirect $cross-module-funcs-0 (result (ref null $#Top))
    drop
  )
  (func $"useFooAsType <noInline>"
    global.get $_InterfaceType_444
    call $print
    drop
  )
  (func $JSStringImpl._interpolate2 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (result (ref $JSStringImpl)) <...>)
  (func $_DefaultSet&_HashFieldBase&SetMixin&_HashBase&_OperatorEqualsAndHashCode&_LinkedHashSetMixin.contains (param $var0 (ref $_DefaultSet&_HashFieldBase&SetMixin)) (result i32) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)