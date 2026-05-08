(module $module0
  (type $Bar <...>)
  (type $Baz <...>)
  (type $Foo <...>)
  (type $JSExternWrapper <...>)
  (table $dtable0 10 (ref null $Bar))
  (table $dtable2 9 (ref null $Foo))
  (global $"DartGlobals.bar1_newInit initialized" (mut i32) <...>)
  (global $"DartGlobals.bar2_newInit_final initialized" (mut i32) <...>)
  (global $"DartGlobals.baz1_newInit initialized" (mut i32) <...>)
  (global $"DartGlobals.baz2_newInit_final initialized" (mut i32) <...>)
  (global $"\"bar1\"" (ref $JSExternWrapper) <...>)
  (global $"\"bar2\"" (ref $JSExternWrapper) <...>)
  (global $"\"baz1\"" (ref $JSExternWrapper) <...>)
  (global $"\"baz2\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo1\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo2\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo3\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo4\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo5\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo6\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo7\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo8\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo9\"" (ref $JSExternWrapper) <...>)
  (global $DartGlobals.baz0_constInit (mut (ref null $Baz)) <...>)
  (global $DartGlobals.baz1_newInit (mut (ref null $Baz)) <...>)
  (global $DartGlobals.baz2_newInit_final (mut (ref null $Baz)) <...>)
  (global $DartGlobals.baz3_noInit (mut (ref null $Baz)) <...>)
  (global $DartGlobals.foo0_constInit (mut (ref $Foo)) <...>)
  (elem $dtable0 <...>)
  (func $"DartGlobals.bar0_constInit implicit getter" (result (ref null $Bar))
    i32.const 8
    table.get $dtable0
  )
  (func $"DartGlobals.bar0_constInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 8
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.bar1_newInit field initializer" (result (ref null $Bar))
    (local $var0 (ref null $Bar))
    i32.const 7
    global.get $"\"bar1\""
    call $Bar
    local.tee $var0
    table.set $dtable0
    local.get $var0
    i32.const 1
    global.set $"DartGlobals.bar1_newInit initialized"
  )
  (func $"DartGlobals.bar1_newInit implicit getter" (result (ref null $Bar))
    global.get $"DartGlobals.bar1_newInit initialized"
    if (result (ref null $Bar))
      i32.const 7
      table.get $dtable0
    else
      call $"DartGlobals.bar1_newInit field initializer"
    end
  )
  (func $"DartGlobals.bar1_newInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 7
    local.get $var0
    table.set $dtable0
    i32.const 1
    global.set $"DartGlobals.bar1_newInit initialized"
  )
  (func $"DartGlobals.bar2_newInit_final field initializer" (result (ref null $Bar))
    (local $var0 (ref null $Bar))
    i32.const 9
    global.get $"\"bar2\""
    call $Bar
    local.tee $var0
    table.set $dtable0
    local.get $var0
    i32.const 1
    global.set $"DartGlobals.bar2_newInit_final initialized"
  )
  (func $"DartGlobals.bar2_newInit_final implicit getter" (result (ref null $Bar))
    global.get $"DartGlobals.bar2_newInit_final initialized"
    if (result (ref null $Bar))
      i32.const 9
      table.get $dtable0
    else
      call $"DartGlobals.bar2_newInit_final field initializer"
    end
  )
  (func $"DartGlobals.bar3_noInit implicit getter" (result (ref null $Bar))
    i32.const 6
    table.get $dtable0
  )
  (func $"DartGlobals.bar3_noInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 6
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.bar4_noInit implicit getter" (result (ref null $Bar))
    i32.const 5
    table.get $dtable0
  )
  (func $"DartGlobals.bar4_noInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 5
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.bar5_noInit implicit getter" (result (ref null $Bar))
    i32.const 4
    table.get $dtable0
  )
  (func $"DartGlobals.bar5_noInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 4
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.bar6_noInit implicit getter" (result (ref null $Bar))
    i32.const 3
    table.get $dtable0
  )
  (func $"DartGlobals.bar6_noInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 3
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.bar7_noInit implicit getter" (result (ref null $Bar))
    i32.const 2
    table.get $dtable0
  )
  (func $"DartGlobals.bar7_noInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 2
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.bar8_noInit implicit getter" (result (ref null $Bar))
    i32.const 1
    table.get $dtable0
  )
  (func $"DartGlobals.bar8_noInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 1
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.bar9_noInit implicit getter" (result (ref null $Bar))
    i32.const 0
    table.get $dtable0
  )
  (func $"DartGlobals.bar9_noInit= implicit setter" (param $var0 (ref null $Bar))
    i32.const 0
    local.get $var0
    table.set $dtable0
  )
  (func $"DartGlobals.baz0_constInit implicit getter" (result (ref null $Baz))
    global.get $DartGlobals.baz0_constInit
  )
  (func $"DartGlobals.baz0_constInit= implicit setter" (param $var0 (ref null $Baz))
    local.get $var0
    global.set $DartGlobals.baz0_constInit
  )
  (func $"DartGlobals.baz1_newInit field initializer" (result (ref null $Baz))
    (local $var0 (ref null $Baz))
    global.get $"\"baz1\""
    call $Baz
    local.tee $var0
    global.set $DartGlobals.baz1_newInit
    local.get $var0
    i32.const 1
    global.set $"DartGlobals.baz1_newInit initialized"
  )
  (func $"DartGlobals.baz1_newInit implicit getter" (result (ref null $Baz))
    global.get $"DartGlobals.baz1_newInit initialized"
    if (result (ref null $Baz))
      global.get $DartGlobals.baz1_newInit
    else
      call $"DartGlobals.baz1_newInit field initializer"
    end
  )
  (func $"DartGlobals.baz1_newInit= implicit setter" (param $var0 (ref null $Baz))
    local.get $var0
    global.set $DartGlobals.baz1_newInit
    i32.const 1
    global.set $"DartGlobals.baz1_newInit initialized"
  )
  (func $"DartGlobals.baz2_newInit_final field initializer" (result (ref null $Baz))
    (local $var0 (ref null $Baz))
    global.get $"\"baz2\""
    call $Baz
    local.tee $var0
    global.set $DartGlobals.baz2_newInit_final
    local.get $var0
    i32.const 1
    global.set $"DartGlobals.baz2_newInit_final initialized"
  )
  (func $"DartGlobals.baz2_newInit_final implicit getter" (result (ref null $Baz))
    global.get $"DartGlobals.baz2_newInit_final initialized"
    if (result (ref null $Baz))
      global.get $DartGlobals.baz2_newInit_final
    else
      call $"DartGlobals.baz2_newInit_final field initializer"
    end
  )
  (func $"DartGlobals.baz3_noInit implicit getter" (result (ref null $Baz))
    global.get $DartGlobals.baz3_noInit
  )
  (func $"DartGlobals.baz3_noInit= implicit setter" (param $var0 (ref null $Baz))
    local.get $var0
    global.set $DartGlobals.baz3_noInit
  )
  (func $"DartGlobals.foo0_constInit implicit getter" (result (ref $Foo))
    global.get $DartGlobals.foo0_constInit
  )
  (func $"DartGlobals.foo0_constInit= implicit setter" (param $var0 (ref $Foo))
    local.get $var0
    global.set $DartGlobals.foo0_constInit
  )
  (func $"DartGlobals.foo1_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 7
    global.get $"\"foo1\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo1_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 7
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo1_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo1_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 7
    local.get $var0
    table.set $dtable2
  )
  (func $"DartGlobals.foo2_newInit_final field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 8
    global.get $"\"foo2\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo2_newInit_final implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 8
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo2_newInit_final field initializer"
    end $label0
  )
  (func $"DartGlobals.foo3_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 6
    global.get $"\"foo3\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo3_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 6
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo3_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo3_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 6
    local.get $var0
    table.set $dtable2
  )
  (func $"DartGlobals.foo4_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 5
    global.get $"\"foo4\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo4_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 5
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo4_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo4_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 5
    local.get $var0
    table.set $dtable2
  )
  (func $"DartGlobals.foo5_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 4
    global.get $"\"foo5\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo5_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 4
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo5_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo5_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 4
    local.get $var0
    table.set $dtable2
  )
  (func $"DartGlobals.foo6_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 3
    global.get $"\"foo6\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo6_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 3
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo6_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo6_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 3
    local.get $var0
    table.set $dtable2
  )
  (func $"DartGlobals.foo7_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 2
    global.get $"\"foo7\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo7_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 2
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo7_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo7_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 2
    local.get $var0
    table.set $dtable2
  )
  (func $"DartGlobals.foo8_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 1
    global.get $"\"foo8\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo8_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 1
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo8_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo8_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 1
    local.get $var0
    table.set $dtable2
  )
  (func $"DartGlobals.foo9_newInit field initializer" (result (ref $Foo))
    (local $var0 (ref null $Foo))
    i32.const 0
    global.get $"\"foo9\""
    call $Foo
    local.tee $var0
    table.set $dtable2
    local.get $var0
    ref.as_non_null
  )
  (func $"DartGlobals.foo9_newInit implicit getter" (result (ref $Foo))
    block $label0 (result (ref $Foo))
      i32.const 0
      table.get $dtable2
      br_on_non_null $label0
      call $"DartGlobals.foo9_newInit field initializer"
    end $label0
  )
  (func $"DartGlobals.foo9_newInit= implicit setter" (param $var0 (ref $Foo))
    i32.const 0
    local.get $var0
    table.set $dtable2
  )
  (func $Bar (param $value (ref $JSExternWrapper)) (result (ref $Bar)) <...>)
  (func $Baz (param $value (ref $JSExternWrapper)) (result (ref $Baz)) <...>)
  (func $Foo (param $value (ref $JSExternWrapper)) (result (ref $Foo)) <...>)
)