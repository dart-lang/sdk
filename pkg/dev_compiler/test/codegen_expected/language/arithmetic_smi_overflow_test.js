dart_library.library('language/arithmetic_smi_overflow_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__arithmetic_smi_overflow_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const arithmetic_smi_overflow_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  arithmetic_smi_overflow_test.main = function() {
    for (let i = 0; i < 10; i++) {
      expect$.Expect.equals(1073741824, i - i - -1073741824);
      expect$.Expect.equals(4611686018427387904, i - i - -4611686018427387904);
    }
  };
  dart.fn(arithmetic_smi_overflow_test.main, VoidTodynamic());
  // Exports:
  exports.arithmetic_smi_overflow_test = arithmetic_smi_overflow_test;
});
