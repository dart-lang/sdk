(module $M
  (type $#Top <...>)
  (type $JSExternWrapper <...>)
  (global $"\"strongExport\"" (ref $JSExternWrapper) <...>)
  (global $"\"usedWeakExport\"" (ref $JSExternWrapper) <...>)
  (func $print (param $var0 (ref $#Top)) <...>)
  (@binaryen.js.called)
  (func $strongExport (export "strongExport") (result i32)
    global.get $"\"strongExport\""
    call $print
    i32.const 1
  )
  (@binaryen.js.called)
  (func $usedWeakExport (export "usedWeakExport") (result i32)
    global.get $"\"usedWeakExport\""
    call $print
    i32.const 1
  )
)