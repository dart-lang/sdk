(module $M
  (memory $host.memory (import "host" "memory") 1 2 shared)
  (memory $memory0 1 2 shared)
  (memory $memory2 1 2)
  (@binaryen.inline 0)
  (func $main
    memory.size $host.memory
    i32.const 42
    i32.store offset=258
    memory.size $memory0
    f64.const 42.5
    f64.store$memory0 offset=258
    memory.size $memory2
    i32.const 1
    i32.store$memory2 offset=258
  )
)