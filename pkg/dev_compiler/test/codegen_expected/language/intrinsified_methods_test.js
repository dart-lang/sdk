dart_library.library('language/intrinsified_methods_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__intrinsified_methods_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const intrinsified_methods_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let intTonum = () => (intTonum = dart.constFn(dart.definiteFunctionType(core.num, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  intrinsified_methods_test.testIsNegative = function() {
    expect$.Expect.isFalse(12.0[dartx.isNegative]);
    expect$.Expect.isTrue((-12.0)[dartx.isNegative]);
    expect$.Expect.isFalse(core.double.NAN[dartx.isNegative]);
    expect$.Expect.isFalse(0.0[dartx.isNegative]);
    expect$.Expect.isTrue((-0.0)[dartx.isNegative]);
    expect$.Expect.isFalse(core.double.INFINITY[dartx.isNegative]);
    expect$.Expect.isTrue(core.double.NEGATIVE_INFINITY[dartx.isNegative]);
  };
  dart.fn(intrinsified_methods_test.testIsNegative, VoidTodynamic());
  intrinsified_methods_test.testIsNaN = function() {
    expect$.Expect.isFalse(1.0[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.NAN[dartx.isNaN]);
  };
  dart.fn(intrinsified_methods_test.testIsNaN, VoidTodynamic());
  intrinsified_methods_test.testTrigonometric = function() {
    expect$.Expect.approxEquals(1.0, math.sin(math.PI / 2.0), 0.0001);
    expect$.Expect.approxEquals(1.0, math.cos(0), 0.0001);
    expect$.Expect.approxEquals(1.0, math.cos(0.0), 0.0001);
  };
  dart.fn(intrinsified_methods_test.testTrigonometric, VoidTodynamic());
  intrinsified_methods_test.foo = function(n) {
    let x = null;
    for (let i = 0; i <= dart.notNull(n); ++i) {
      expect$.Expect.equals(2.0, math.sqrt(4.0));
      intrinsified_methods_test.testIsNegative();
      intrinsified_methods_test.testIsNaN();
      intrinsified_methods_test.testTrigonometric();
    }
    return core.num._check(x);
  };
  dart.fn(intrinsified_methods_test.foo, intTonum());
  intrinsified_methods_test.main = function() {
    let m = intrinsified_methods_test.foo(4000);
  };
  dart.fn(intrinsified_methods_test.main, VoidTovoid());
  // Exports:
  exports.intrinsified_methods_test = intrinsified_methods_test;
});
