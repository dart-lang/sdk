dart_library.library('language/value_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__value_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const value_range_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  value_range_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(value_range_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(value_range_test.inscrutable, intToint());
  let const$;
  value_range_test.foo = function() {
    let x = 258;
    if (value_range_test.inscrutable(x) == 0) x = 0;
    if (value_range_test.inscrutable(10) == 10) x = 16;
    x = x & 255;
    let a = const$ || (const$ = dart.constList([1, 2, 3], core.int));
    return a[dartx.get](x);
  };
  dart.fn(value_range_test.foo, VoidTodynamic());
  value_range_test.main = function() {
    expect$.Expect.throws(dart.fn(() => value_range_test.foo(), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(value_range_test.main, VoidTodynamic());
  // Exports:
  exports.value_range_test = value_range_test;
});
