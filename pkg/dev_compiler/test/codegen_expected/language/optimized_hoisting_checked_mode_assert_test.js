dart_library.library('language/optimized_hoisting_checked_mode_assert_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optimized_hoisting_checked_mode_assert_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optimized_hoisting_checked_mode_assert_test = Object.create(null);
  let dynamicAnddynamicToint = () => (dynamicAnddynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  optimized_hoisting_checked_mode_assert_test.foo = function(x, n) {
    let z = 0.0;
    for (let i = 0; i < dart.notNull(core.num._check(n)); i++) {
      let z = core.double._check(x);
    }
    return 0;
  };
  dart.fn(optimized_hoisting_checked_mode_assert_test.foo, dynamicAnddynamicToint());
  optimized_hoisting_checked_mode_assert_test.main = function() {
    for (let i = 0; i < 20; i++)
      optimized_hoisting_checked_mode_assert_test.foo(1.0, 10);
    expect$.Expect.equals(0, optimized_hoisting_checked_mode_assert_test.foo(1.0, 10));
    expect$.Expect.equals(0, optimized_hoisting_checked_mode_assert_test.foo(2, 0));
  };
  dart.fn(optimized_hoisting_checked_mode_assert_test.main, VoidTodynamic());
  // Exports:
  exports.optimized_hoisting_checked_mode_assert_test = optimized_hoisting_checked_mode_assert_test;
});
