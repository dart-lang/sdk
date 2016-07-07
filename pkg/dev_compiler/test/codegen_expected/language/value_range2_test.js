dart_library.library('language/value_range2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__value_range2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const value_range2_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  value_range2_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(value_range2_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(value_range2_test.inscrutable, intToint());
  let const$;
  value_range2_test.foo = function() {
    let x = 0;
    if (value_range2_test.inscrutable(0) == 0) x = -2;
    let y = 2;
    if (value_range2_test.inscrutable(0) == 0) y = 4;
    let i = y - x;
    i = i - 4;
    let a = const$ || (const$ = dart.constList([1], core.int));
    return a[dartx.get](i);
  };
  dart.fn(value_range2_test.foo, VoidTodynamic());
  value_range2_test.main = function() {
    expect$.Expect.throws(dart.fn(() => value_range2_test.foo(), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(value_range2_test.main, VoidTodynamic());
  // Exports:
  exports.value_range2_test = value_range2_test;
});
