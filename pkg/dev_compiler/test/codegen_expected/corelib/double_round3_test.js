dart_library.library('corelib/double_round3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_round3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_round3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_round3_test.main = function() {
    expect$.Expect.equals(0, 0.49999999999999994[dartx.round]());
    expect$.Expect.equals(0, (-0.49999999999999994)[dartx.round]());
    expect$.Expect.isTrue(typeof 0.49999999999999994[dartx.round]() == 'number');
    expect$.Expect.isTrue(typeof (-0.49999999999999994)[dartx.round]() == 'number');
  };
  dart.fn(double_round3_test.main, VoidTodynamic());
  // Exports:
  exports.double_round3_test = double_round3_test;
});
