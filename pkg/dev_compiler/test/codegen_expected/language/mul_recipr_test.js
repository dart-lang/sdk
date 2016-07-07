dart_library.library('language/mul_recipr_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mul_recipr_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mul_recipr_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let doubleTodynamic = () => (doubleTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.double])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  mul_recipr_test.xx = 23.0;
  mul_recipr_test.main = function() {
    mul_recipr_test.xx = 0.000001;
    mul_recipr_test.scaleIt(1e-310);
    expect$.Expect.isTrue(mul_recipr_test.xx[dartx.isInfinite]);
    for (let i = 0; i < 10; i++) {
      mul_recipr_test.xx = 24.0;
      mul_recipr_test.scaleIt(6.0);
      expect$.Expect.equals(4.0, mul_recipr_test.xx);
    }
    mul_recipr_test.xx = 0.000001;
    mul_recipr_test.scaleIt(1e-310);
    expect$.Expect.isTrue(mul_recipr_test.xx[dartx.isInfinite]);
  };
  dart.fn(mul_recipr_test.main, VoidTodynamic());
  mul_recipr_test.scaleIt = function(b) {
    mul_recipr_test.scale(1.0 / dart.notNull(b));
  };
  dart.fn(mul_recipr_test.scaleIt, doubleTodynamic());
  mul_recipr_test.scale = function(a) {
    mul_recipr_test.xx = dart.notNull(mul_recipr_test.xx) * dart.notNull(core.num._check(a));
  };
  dart.fn(mul_recipr_test.scale, dynamicTodynamic());
  // Exports:
  exports.mul_recipr_test = mul_recipr_test;
});
