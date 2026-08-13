(module $M1
  (type $#Top <...>)
  (type $Foo (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $i (mut i64)))))
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (type $_InterfaceType <...>)
  (global $".Foo called " (import "" "Foo called ") (ref extern))
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 4 funcref)
  (global $"\"Foo called \"" (ref $JSExternWrapper)
    (i32.const 65)
    (i32.const 0)
    (global.get $".Foo called ")
    (struct.new $JSExternWrapper))
  (global $_InterfaceType (ref $_InterfaceType) <...>)
  (elem $M.cross-module-funcs-0
    (set 0 (ref.func $useFoo)))
  (func $Foo.printFoo (param $var0 (ref $Foo)) <...>)
  (@binaryen.inline 0)
  (func $useFoo
    call $useFooAsType
    i64.const 1
    i32.const 1
    call_indirect (param i64) (result i32)
    drop
    call $useFooAsObject
  )
  (@binaryen.inline 0)
  (func $useFooAsObject
    (local $var0 (ref $Foo))
    i32.const 109
    i32.const 0
    i64.const 0
    struct.new $Foo
    local.tee $var0
    call $Foo.printFoo
    local.get $var0
    call $Foo.printFoo
  )
  (@binaryen.inline 0)
  (func $useFooAsType
    global.get $_InterfaceType
    i32.const 3
    call_indirect (param (ref null $#Top))
  )
)