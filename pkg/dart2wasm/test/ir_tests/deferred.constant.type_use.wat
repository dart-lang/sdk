(module $module0
  (type $#Top <...>)
  (type $DefaultSet <...>)
  (type $DeferredLoadIdNotLoadedError <...>)
  (type $_InterfaceType <...>)
  (type $type0 <...>)
  (table $static0-0 (export "static0-0") 1 (ref null $type0))
  (global $"C414 _InterfaceType" (ref $_InterfaceType) <...>)
  (func $_loaded implicit getter (result (ref $DefaultSet)) <...>)
  (func $"useFoo <noInline>"
    call $"useFooAsType <noInline>"
    call $"_loaded implicit getter"
    call $_DefaultSet&_HashFieldBase&SetMixin&_HashBase&_OperatorEqualsAndHashCode&_LinkedHashSetMixin.contains
    i32.eqz
    if
      i32.const 49
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
    global.get $"C414 _InterfaceType"
    call $print
    drop
  )
  (func $Error._throwWithCurrentStackTrace (param $var0 (ref $#Top)) <...>)
  (func $_DefaultSet&_HashFieldBase&SetMixin&_HashBase&_OperatorEqualsAndHashCode&_LinkedHashSetMixin.contains (param $var0 (ref $DefaultSet)) (result i32) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)