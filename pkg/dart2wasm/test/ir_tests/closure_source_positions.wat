(module $M
  (type $"<context file:///.../closure_source_positions.dart:19:39>" <...>)
  (type $"<context file:///.../closure_source_positions.dart:20:10>" <...>)
  (type $#Closure-0-0 <...>)
  (type $#Vtable-0-0 <...>)
  (type $_FunctionType <...>)
  (global $_FunctionType (ref $_FunctionType) <...>)
  (global $global0 (ref $#Vtable-0-0) <...>)
  (func $"makeAdder closure at file:///.../closure_source_positions.dart:20:10" (param $var0 (ref struct)) (param $var1 i64) (result (ref $#Closure-0-0))
    (local $var2 (ref $"<context file:///.../closure_source_positions.dart:19:39>"))
    (local $var3 (ref null $"<context file:///.../closure_source_positions.dart:20:10>"))
    ;;   return 🎯(int y) {                   file:///.../closure_source_positions.dart:20
    local.get $var0
    ref.cast $"<context file:///.../closure_source_positions.dart:19:39>"
    local.set $var2
    struct.new_default $"<context file:///.../closure_source_positions.dart:20:10>"
    local.set $var3
    local.get $var3
    local.get $var2
    struct.set $"<context file:///.../closure_source_positions.dart:20:10>" $field0
    local.get $var3
    local.get $var1
    struct.set $"<context file:///.../closure_source_positions.dart:20:10>" $field1
    ;;     return 🎯() => x + y;              file:///.../closure_source_positions.dart:21
    i32.const 51
    i32.const 0
    local.get $var3
    ref.as_non_null
    global.get $global0
    global.get $_FunctionType
    struct.new $#Closure-0-0
    ;;     🎯return () => x + y;
    return
    ;;   return 🎯(int y) {                   file:///.../closure_source_positions.dart:20
  )
  (func $"makeAdder closure at file:///.../closure_source_positions.dart:21:12" (param $var0 (ref struct)) (result i64)
    (local $var1 (ref $"<context file:///.../closure_source_positions.dart:20:10>"))
    (local $var2 (ref $"<context file:///.../closure_source_positions.dart:19:39>"))
    ;;     return 🎯() => x + y;              file:///.../closure_source_positions.dart:21
    local.get $var0
    ref.cast $"<context file:///.../closure_source_positions.dart:20:10>"
    local.tee $var1
    struct.get $"<context file:///.../closure_source_positions.dart:20:10>" $field0
    ref.as_non_null
    local.set $var2
    ;;     return () => 🎯x + y;
    local.get $var2
    struct.get $"<context file:///.../closure_source_positions.dart:19:39>" $field0
    ;;     return () => x + 🎯y;
    local.get $var1
    struct.get $"<context file:///.../closure_source_positions.dart:20:10>" $field1
    ;;     return () => x 🎯+ y;
    i64.add
    ;;     return () => 🎯x + y;
    return
    ;;     return 🎯() => x + y;
  )
)