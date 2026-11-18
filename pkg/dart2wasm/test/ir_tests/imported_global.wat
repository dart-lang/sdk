(module $M
  (global $bar (import "app" "bar") (mut i32))
  (global $foo (import "app" "foo") i32)
  (@binaryen.inline 0)
  (func $testGlobals
    global.get $foo
    global.get $bar
    i32.add
    i32.const 42
    i32.add
    global.set $bar
  )
)