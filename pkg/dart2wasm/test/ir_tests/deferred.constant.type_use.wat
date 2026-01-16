(module $module0
  (type $#Top <...>)
  (type $DeferredLoadIdNotLoadedError <...>)
  (type $_DefaultSet&_HashFieldBase&SetMixin <...>)
  (type $_InterfaceType <...>)
  (type $type0 <...>)
  (table $static0-0 (export "static0-0") 1 (ref null $type0))
  (global $"C420 _InterfaceType" (ref $_InterfaceType) <...>)
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
      call $Error._throwWithCurrentStackTrace
      unreachable
    end
    i32.const 0
    call_indirect $static0-0 (result (ref null $#Top))
    drop
  )
  (func $"useFooAsType <noInline>"
    global.get $"C420 _InterfaceType"
    call $print
    drop
  )
  (func $Error._throwWithCurrentStackTrace (param $var0 (ref $#Top)) <...>)
  (func $_DefaultSet&_HashFieldBase&SetMixin&_HashBase&_OperatorEqualsAndHashCode&_LinkedHashSetMixin.contains (param $var0 (ref $_DefaultSet&_HashFieldBase&SetMixin)) (result i32) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)