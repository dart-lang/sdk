(function hello.dart::main
  (constants
    (def v2 "Hello, World!"))
  (normal-entry B1)
  (block B1
    (CheckStackOverflow)
    (PushArgument v2)
    (StaticCall dart:core::print { args_len 1, env (v0 arg[0]), })
    (Return v0)))
