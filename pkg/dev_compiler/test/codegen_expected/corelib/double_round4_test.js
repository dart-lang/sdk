dart_library.library('corelib/double_round4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_round4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_round4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_round4_test.main = function() {
    expect$.Expect.equals(4503599627370496, 4503599627370496.0[dartx.round]());
    expect$.Expect.equals(4503599627370497, 4503599627370497.0[dartx.round]());
    expect$.Expect.equals(4503599627370498, 4503599627370498.0[dartx.round]());
    expect$.Expect.equals(4503599627370499, 4503599627370499.0[dartx.round]());
    expect$.Expect.equals(9007199254740991, 9007199254740991.0[dartx.round]());
    expect$.Expect.equals(9007199254740992, 9007199254740992.0[dartx.round]());
    expect$.Expect.equals(-4503599627370496, (-4503599627370496.0)[dartx.round]());
    expect$.Expect.equals(-4503599627370497, (-4503599627370497.0)[dartx.round]());
    expect$.Expect.equals(-4503599627370498, (-4503599627370498.0)[dartx.round]());
    expect$.Expect.equals(-4503599627370499, (-4503599627370499.0)[dartx.round]());
    expect$.Expect.equals(-9007199254740991, (-9007199254740991.0)[dartx.round]());
    expect$.Expect.equals(-9007199254740992, (-9007199254740992.0)[dartx.round]());
    expect$.Expect.isTrue(typeof 4503599627370496.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 4503599627370497.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 4503599627370498.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 4503599627370499.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 9007199254740991.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof 9007199254740992.0[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370496.0)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370497.0)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370498.0)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-4503599627370499.0)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-9007199254740991.0)[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-9007199254740992.0)[dartx.round]() == 'number');
  };
  dart.fn(double_round4_test.main, VoidTodynamic());
  // Exports:
  exports.double_round4_test = double_round4_test;
});
