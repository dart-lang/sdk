dart_library.library('corelib/duration_double_multiplication_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__duration_double_multiplication_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const duration_double_multiplication_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  duration_double_multiplication_test.main = function() {
    let d = null, d1 = null;
    d1 = new core.Duration({milliseconds: 1});
    d = d1['*'](0.005);
    expect$.Expect.equals(1000 * 0.005, d.inMicroseconds);
    d = d1['*'](0.0);
    expect$.Expect.equals(0, d.inMicroseconds);
    d = d1['*'](-0.005);
    expect$.Expect.equals(1000 * -0.005, d.inMicroseconds);
    d = d1['*'](0.0015);
    expect$.Expect.equals((1000 * 0.0015)[dartx.round](), d.inMicroseconds);
  };
  dart.fn(duration_double_multiplication_test.main, VoidTodynamic());
  // Exports:
  exports.duration_double_multiplication_test = duration_double_multiplication_test;
});
