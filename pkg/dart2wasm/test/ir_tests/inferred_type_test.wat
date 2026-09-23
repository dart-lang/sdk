(module $M
  (type $#Top <...>)
  (type $BoxedBool <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $"\")\"" (ref $JSExternWrapper) <...>)
  (global $"\"Base.foo(x = \"" (ref $JSExternWrapper) <...>)
  (global $"\"Sub.bar(x: \"" (ref $JSExternWrapper) <...>)
  (global $"\"Sub.foo(x: \"" (ref $JSExternWrapper) <...>)
  (global $false (ref $BoxedBool) <...>)
  (global $true (ref $BoxedBool) <...>)
  (func $Base.foo (param $this (ref $Object)) (param $x i32)
    global.get $"\"Base.foo(x = \""
    local.get $x
    if (result (ref $BoxedBool))
      global.get $true
    else
      global.get $false
    end
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    ref.null none
    drop
  )
  (func $JSStringImpl._interpolate3 (param $value1 (ref null $#Top)) (param $value2 (ref null $#Top)) (param $value3 (ref null $#Top)) (result (ref $JSExternWrapper)) <...>)
  (func $Sub.bar (param $this (ref $Object)) (param $x i32)
    global.get $"\"Sub.bar(x: \""
    local.get $x
    if (result (ref $BoxedBool))
      global.get $true
    else
      global.get $false
    end
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    ref.null none
    drop
  )
  (func $Sub.foo (param $this (ref $Object)) (param $x i32)
    global.get $"\"Sub.foo(x: \""
    local.get $x
    if (result (ref $BoxedBool))
      global.get $true
    else
      global.get $false
    end
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    ref.null none
    drop
  )
  (func $print (param $object (ref null $#Top)) <...>)
)