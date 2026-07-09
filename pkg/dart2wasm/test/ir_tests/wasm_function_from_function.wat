(module $M
  (type $#Top <...>)
  (type $JSExternWrapper <...>)
  (func $"outside.registerCallback (import)" (import "outside" "registerCallback") (param (ref func)))
  (global $"\"Hello\"" (ref $JSExternWrapper) <...>)
  (@binaryen.js.called)
  (func $dartFunction
    global.get $"\"Hello\""
    call $print
  )
  (func $print (param $var0 (ref $#Top)) <...>)
  (@binaryen.inline 0)
  (func $runTest
    ref.func $dartFunction
    call $"outside.registerCallback (import)"
  )
)