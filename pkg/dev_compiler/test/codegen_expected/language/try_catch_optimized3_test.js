dart_library.library('language/try_catch_optimized3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch_optimized3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch_optimized3_test = Object.create(null);
  let boolTodynamic = () => (boolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.bool])))();
  let doubleAndboolTodynamic = () => (doubleAndboolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.double, core.bool])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  try_catch_optimized3_test.foo = function(b) {
    if (dart.test(b)) dart.throw(123);
  };
  dart.fn(try_catch_optimized3_test.foo, boolTodynamic());
  try_catch_optimized3_test.test_double = function(x, b) {
    try {
      x = dart.notNull(x) + 1.0;
      try_catch_optimized3_test.foo(b);
    } catch (e) {
      let result = dart.notNull(x) - 1.0;
      expect$.Expect.equals(1.0, result);
      return result;
    }

  };
  dart.fn(try_catch_optimized3_test.test_double, doubleAndboolTodynamic());
  try_catch_optimized3_test.main = function() {
    for (let i = 0; i < 100; i++)
      try_catch_optimized3_test.test_double(1.0, false);
    try_catch_optimized3_test.test_double(1.0, false);
    expect$.Expect.equals(1.0, try_catch_optimized3_test.test_double(1.0, true));
  };
  dart.fn(try_catch_optimized3_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch_optimized3_test = try_catch_optimized3_test;
});
