dart_library.library('language/double_to_string_as_exponential3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_to_string_as_exponential3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_to_string_as_exponential3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_to_string_as_exponential3_test.main = function() {
    expect$.Expect.equals("1.00000000000000000000e+0", 1.0[dartx.toStringAsExponential](20));
    expect$.Expect.equals("1.00000000000000005551e-1", 0.1[dartx.toStringAsExponential](20));
    expect$.Expect.equals(0.1, 0.1);
  };
  dart.fn(double_to_string_as_exponential3_test.main, VoidTodynamic());
  // Exports:
  exports.double_to_string_as_exponential3_test = double_to_string_as_exponential3_test;
});
