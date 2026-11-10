(module $M
  (@binaryen.inline 0)
  (func $addTwo (param $x i64) (result i64)
    (local $result i64)
    (local $x i64)
    ;;   final result = addOne(🎯x) + 1;      file:///.../source_positions.dart:18
    local.get $x
    ;;   final result = 🎯addOne(x) + 1;
    local.set $x
    block $label0 (result i64)
      ;; int addOne(int x) => 🎯x + 1;        file:///.../source_positions.dart:23
      local.get $x
      ;; int addOne(int x) => x + 🎯1;
      i64.const 1
      ;; int addOne(int x) => x 🎯+ 1;
      i64.add
      ;; int addOne(int x) => 🎯x + 1;
      br $label0
      ;; int 🎯addOne(int x) => x + 1;
    end $label0
    ;;   final result = addOne(x) + 🎯1;      file:///.../source_positions.dart:18
    i64.const 1
    ;;   final result = addOne(x) 🎯+ 1;
    i64.add
    ;;   final 🎯result = addOne(x) + 1;
    local.set $result
    ;;   return 🎯result;                     file:///.../source_positions.dart:19
    local.get $result
    ;;   🎯return result;
    return
    ;; int 🎯addTwo(int x) {                  file:///.../source_positions.dart:17
  )
)