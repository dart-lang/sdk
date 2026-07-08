(module $M
  (type $#Top <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $"\"fooAlwaysThrows\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo\"" (ref $JSExternWrapper) <...>)
  (func $Error._throwWithCurrentStackTrace (param $object (ref $#Top)) <...>)
  (func $Object (result (ref $Object)) <...>)
  (func $foo (result (ref null $#Top))
    global.get $"\"foo\""
    call $print
    ref.null none
    drop
    call $fooAlwaysThrows
    unreachable
  )
  (func $fooAlwaysThrows
    global.get $"\"fooAlwaysThrows\""
    call $print
    ref.null none
    drop
    call $Object
    call $Error._throwWithCurrentStackTrace
    unreachable
  )
  (func $print (param $object (ref null $#Top)) <...>)
)