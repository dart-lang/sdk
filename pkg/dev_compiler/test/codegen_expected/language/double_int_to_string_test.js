dart_library.library('language/double_int_to_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_int_to_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_int_to_string_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_int_to_string_test.main = function() {
    expect$.Expect.equals("0.0", dart.toString(0.0));
    expect$.Expect.equals("9.0", dart.toString(9.0));
    expect$.Expect.equals("90.0", dart.toString(90.0));
    expect$.Expect.equals("111111111111111110000.0", dart.toString(111111111111111110000.0));
    expect$.Expect.equals("-9.0", dart.toString(-9.0));
    expect$.Expect.equals("-90.0", dart.toString(-90.0));
    expect$.Expect.equals("-111111111111111110000.0", dart.toString(-111111111111111110000.0));
    expect$.Expect.equals("1000.0", dart.toString(1000.0));
    expect$.Expect.equals("1000000000000000100.0", dart.toString(1000000000000000100.0));
  };
  dart.fn(double_int_to_string_test.main, VoidTodynamic());
  // Exports:
  exports.double_int_to_string_test = double_int_to_string_test;
});
