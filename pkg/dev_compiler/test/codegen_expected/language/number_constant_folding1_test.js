dart_library.library('language/number_constant_folding1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__number_constant_folding1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const number_constant_folding1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  number_constant_folding1_test.highDigitTruncationTest = function() {
    expect$.Expect.equals(4886718346, 4886718345 + 1);
    expect$.Expect.isTrue(8321499136 > 0);
    expect$.Expect.equals(240, 15 * 16);
    expect$.Expect.equals(4080, 255 * 16);
    expect$.Expect.equals(65520, 4095 * 16);
    expect$.Expect.equals(1048560, 65535 * 16);
    expect$.Expect.equals(16777200, 1048575 * 16);
    expect$.Expect.equals(268435440, 16777215 * 16);
    expect$.Expect.equals(4294967280, 268435455 * 16);
    expect$.Expect.equals(68719476720, 4294967295 * 16);
    expect$.Expect.equals(1099511627760, 68719476735 * 16);
    expect$.Expect.equals(17592186044400, 1099511627775 * 16);
  };
  dart.fn(number_constant_folding1_test.highDigitTruncationTest, VoidTodynamic());
  number_constant_folding1_test.main = function() {
    number_constant_folding1_test.highDigitTruncationTest();
  };
  dart.fn(number_constant_folding1_test.main, VoidTodynamic());
  // Exports:
  exports.number_constant_folding1_test = number_constant_folding1_test;
});
