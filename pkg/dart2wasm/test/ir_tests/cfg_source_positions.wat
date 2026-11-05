(module $M
  (func $loopSum (param $var0 i64) (result i64)
    (local $var1 i64)
    (local $var2 i64)
    (local $var3 i64)
    (local $var4 i64)
    (local $var5 i32)
    (local $var6 i64)
    (local $var7 i64)
    i64.const 0
    local.set $var1
    i64.const 1
    local.set $var2
    block $label0
      ;;   🎯for (int i = 0; i < n; i++) {    file:///.../cfg_source_positions.dart:25
      local.get $var1
      local.get $var1
      local.set $var4
      local.set $var3
      br $label0
    end $label0
    loop $label1
      ;;   for (int i = 0; i 🎯< n; i++) {
      local.get $var3
      local.get $var0
      i64.lt_s
      local.set $var5
      block $label2
        block $label3
          ;;   🎯for (int i = 0; i < n; i++) {
          local.get $var5
          br_if $label3
          br $label2
        end $label3
        ;;     sum = sum 🎯+ i;               file:///.../cfg_source_positions.dart:26
        local.get $var4
        local.get $var3
        i64.add
        local.set $var6
        ;;   for (int i = 0; i < n; i🎯++) {  file:///.../cfg_source_positions.dart:25
        local.get $var3
        local.get $var2
        i64.add
        local.set $var7
        local.get $var7
        ;;     sum = sum 🎯+ i;               file:///.../cfg_source_positions.dart:26
        local.get $var6
        local.set $var4
        ;;   for (int i = 0; i < n; i🎯++) {  file:///.../cfg_source_positions.dart:25
        local.set $var3
        ;;   🎯for (int i = 0; i < n; i++) {
        br $label1
      end $label2
      ;;   🎯return sum;                      file:///.../cfg_source_positions.dart:28
      local.get $var4
      return
    end $label1
    unreachable
  )
  (func $testAdd (param $var0 i64) (result i64)
    (local $var1 i64)
    (local $var2 i64)
    i64.const 42
    local.set $var1
    ;;   return a 🎯+ b;                      file:///.../cfg_source_positions.dart:19
    local.get $var0
    local.get $var1
    i64.add
    local.set $var2
    ;;   🎯return a + b;
    local.get $var2
    return
  )
)