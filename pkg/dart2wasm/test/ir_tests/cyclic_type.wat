(module $M
  (type $#Closure-0-0 <...>)
  (type $#Top <...>)
  (type $#Vtable-0-0 <...>)
  (type $CyclicClass <...>)
  (type $JSExternWrapper <...>)
  (type $_FunctionType <...>)
  (global $"\"Attempt to execute code remove<...>\"" (ref $JSExternWrapper) <...>)
  (global $"\"CyclicClass.initGlobalBox(): i<...>\"" (ref $JSExternWrapper) <...>)
  (global $"\"fooStatic\"" (ref $JSExternWrapper) <...>)
  (global $_FunctionType (ref $_FunctionType) <...>)
  (global $_FunctionType (ref $_FunctionType) <...>)
  (global $global0 (ref struct) <...>)
  (global $global2 (ref $#Vtable-0-0) <...>)
  (global $global4 (ref $#Vtable-0-0) <...>)
  (func $"CyclicClass.fooStatic tear-off trampoline" (param $var0 (ref struct)) (result (ref null $#Top))
    call $CyclicClass.fooStatic
    ref.null none
  )
  (func $"CyclicClass.initGlobalBox closure at file:///.../cyclic_type.dart:47:16" (param $var0 (ref struct)) (result (ref $CyclicClass))
    i32.const 36
    i32.const 0
    global.get $global0
    global.get $global2
    global.get $_FunctionType
    struct.new $#Closure-0-0
    call $"constructorInitializeClosure= implicit setter"
    ref.null none
    drop
    call $"cyclic implicit getter"
    return
  )
  (func $"CyclicClass.initGlobalBox closure at file:///.../cyclic_type.dart:48:41" (param $var0 (ref struct)) (result (ref null $#Top))
    global.get $"\"CyclicClass.initGlobalBox(): i<...>\""
    call $print
    ref.null none
    drop
    ref.null none
  )
  (func $"CyclicClass.initGlobalBox closure at file:///.../cyclic_type.dart:55:37" (param $var0 (ref struct)) (result (ref null $#Top))
    unreachable
  )
  (func $constructorInitializeClosure= implicit setter (param $var0 (ref null $#Closure-0-0)) <...>)
  (func $cyclic implicit getter (result (ref $CyclicClass)) <...>)
  (func $"new CyclicClass.initGlobalBox (initializer)" (result (ref $CyclicClass))
    (local $var0 (ref null $#Top))
    i32.const 36
    i32.const 0
    global.get $global0
    global.get $global4
    global.get $_FunctionType
    struct.new $#Closure-0-0
    struct.get $#Closure-0-0 $context
    call $"CyclicClass.initGlobalBox closure at file:///.../cyclic_type.dart:47:16"
    drop
    global.get $"\"Attempt to execute code remove<...>\""
    call $Error._throwWithCurrentStackTrace
    unreachable
  )
  (func $CyclicClass.fooStatic
    global.get $"\"fooStatic\""
    call $print
    ref.null none
    drop
  )
  (func $CyclicClass.initGlobalBox (result (ref $CyclicClass))
    i32.const 120
    i32.const 0
    call $"new CyclicClass.initGlobalBox (initializer)"
    unreachable
  )
  (func $Error._throwWithCurrentStackTrace (param $object (ref $#Top)) <...>)
  (func $print (param $object (ref null $#Top)) <...>)
)