dart_library.library('corelib/toInt_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__toInt_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const toInt_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  toInt_test.main = function() {
    expect$.Expect.equals(-2147483649, (-2147483649)[dartx.toInt]());
    expect$.Expect.equals(-2147483648, (-2147483648 - 0.7)[dartx.toInt]());
    expect$.Expect.equals(-2147483648, (-2147483648 - 0.3)[dartx.toInt]());
    expect$.Expect.equals(-2147483647, (-2147483648 + 0.3)[dartx.toInt]());
    expect$.Expect.equals(-2147483647, (-2147483648 + 0.7)[dartx.toInt]());
    expect$.Expect.equals(-2147483647, (-2147483647)[dartx.toInt]());
    expect$.Expect.equals(2147483646, (2147483646)[dartx.toInt]());
    expect$.Expect.equals(2147483646, (2147483647 - 0.7)[dartx.toInt]());
    expect$.Expect.equals(2147483646, (2147483647 - 0.3)[dartx.toInt]());
    expect$.Expect.equals(2147483647, (2147483647 + 0.3)[dartx.toInt]());
    expect$.Expect.equals(2147483647, (2147483647 + 0.7)[dartx.toInt]());
    expect$.Expect.equals(2147483648, (2147483648)[dartx.toInt]());
  };
  dart.fn(toInt_test.main, VoidTodynamic());
  // Exports:
  exports.toInt_test = toInt_test;
});
