dart_library.library('corelib/double_round_to_double3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_round_to_double3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_round_to_double3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_round_to_double3_test.main = function() {
    expect$.Expect.equals(4503599627370496.0, 4503599627370496.0[dartx.roundToDouble]());
    expect$.Expect.equals(4503599627370497.0, 4503599627370497.0[dartx.roundToDouble]());
    expect$.Expect.equals(4503599627370498.0, 4503599627370498.0[dartx.roundToDouble]());
    expect$.Expect.equals(4503599627370499.0, 4503599627370499.0[dartx.roundToDouble]());
    expect$.Expect.equals(9007199254740991.0, 9007199254740991.0[dartx.roundToDouble]());
    expect$.Expect.equals(9007199254740992.0, 9007199254740992.0[dartx.roundToDouble]());
    expect$.Expect.equals(-4503599627370496.0, (-4503599627370496.0)[dartx.roundToDouble]());
    expect$.Expect.equals(-4503599627370497.0, (-4503599627370497.0)[dartx.roundToDouble]());
    expect$.Expect.equals(-4503599627370498.0, (-4503599627370498.0)[dartx.roundToDouble]());
    expect$.Expect.equals(-4503599627370499.0, (-4503599627370499.0)[dartx.roundToDouble]());
    expect$.Expect.equals(-9007199254740991.0, (-9007199254740991.0)[dartx.roundToDouble]());
    expect$.Expect.equals(-9007199254740992.0, (-9007199254740992.0)[dartx.roundToDouble]());
    expect$.Expect.isTrue(typeof 4503599627370496.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 4503599627370497.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 4503599627370498.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 4503599627370499.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 9007199254740991.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof 9007199254740992.0[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370496.0)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370497.0)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370498.0)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370499.0)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-9007199254740991.0)[dartx.roundToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (-9007199254740992.0)[dartx.roundToDouble]() == 'number');
  };
  dart.fn(double_round_to_double3_test.main, VoidTodynamic());
  // Exports:
  exports.double_round_to_double3_test = double_round_to_double3_test;
});
