dart_library.library('language/local_function_non_equal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__local_function_non_equal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const local_function_non_equal_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  local_function_non_equal_test.foo = function() {
    return dart.fn(() => 42, VoidToint());
  };
  dart.fn(local_function_non_equal_test.foo, VoidTodynamic());
  local_function_non_equal_test.bar = function() {
    let c = dart.fn(() => 54, VoidToint());
    return c;
  };
  dart.fn(local_function_non_equal_test.bar, VoidTodynamic());
  local_function_non_equal_test.baz = function() {
    function c() {
      return 68;
    }
    dart.fn(c, VoidToint());
    return c;
  };
  dart.fn(local_function_non_equal_test.baz, VoidTodynamic());
  local_function_non_equal_test.main = function() {
    let first = local_function_non_equal_test.foo();
    let second = local_function_non_equal_test.foo();
    expect$.Expect.isFalse(core.identical(first, second));
    expect$.Expect.notEquals(first, second);
    first = local_function_non_equal_test.bar();
    second = local_function_non_equal_test.bar();
    expect$.Expect.isFalse(core.identical(first, second));
    expect$.Expect.notEquals(first, second);
    first = local_function_non_equal_test.baz();
    second = local_function_non_equal_test.baz();
    expect$.Expect.isFalse(core.identical(first, second));
    expect$.Expect.notEquals(first, second);
  };
  dart.fn(local_function_non_equal_test.main, VoidTodynamic());
  // Exports:
  exports.local_function_non_equal_test = local_function_non_equal_test;
});
