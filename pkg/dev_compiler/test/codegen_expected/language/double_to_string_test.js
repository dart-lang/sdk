dart_library.library('language/double_to_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_to_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_to_string_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_to_string_test.main = function() {
    expect$.Expect.equals("NaN", dart.toString(core.double.NAN));
    expect$.Expect.equals("Infinity", dart.toString(1 / 0));
    expect$.Expect.equals("-Infinity", dart.toString(-1 / 0));
    expect$.Expect.equals("90.12", dart.toString(90.12));
    expect$.Expect.equals("0.1", dart.toString(0.1));
    expect$.Expect.equals("0.01", dart.toString(0.01));
    expect$.Expect.equals("0.0123", dart.toString(0.0123));
    expect$.Expect.equals("1.1111111111111111e+21", dart.toString(1.1111111111111111e+21));
    expect$.Expect.equals("1.1111111111111111e+22", dart.toString(1.1111111111111111e+22));
    expect$.Expect.equals("0.00001", dart.toString(0.00001));
    expect$.Expect.equals("0.000001", dart.toString(0.000001));
    expect$.Expect.equals("1e-7", dart.toString(1e-7));
    expect$.Expect.equals("1.2e-7", dart.toString(1.2e-7));
    expect$.Expect.equals("1.23e-7", dart.toString(1.23e-7));
    expect$.Expect.equals("1e-8", dart.toString(1e-8));
    expect$.Expect.equals("1.2e-8", dart.toString(1.2e-8));
    expect$.Expect.equals("1.23e-8", dart.toString(1.23e-8));
    expect$.Expect.equals("-0.0", dart.toString(-0.0));
    expect$.Expect.equals("-90.12", dart.toString(-90.12));
    expect$.Expect.equals("-0.1", dart.toString(-0.1));
    expect$.Expect.equals("-0.01", dart.toString(-0.01));
    expect$.Expect.equals("-0.0123", dart.toString(-0.0123));
    expect$.Expect.equals("-1.1111111111111111e+21", dart.toString(-1.1111111111111111e+21));
    expect$.Expect.equals("-1.1111111111111111e+22", dart.toString(-1.1111111111111111e+22));
    expect$.Expect.equals("-0.00001", dart.toString(-0.00001));
    expect$.Expect.equals("-0.000001", dart.toString(-0.000001));
    expect$.Expect.equals("-1e-7", dart.toString(-1e-7));
    expect$.Expect.equals("-1.2e-7", dart.toString(-1.2e-7));
    expect$.Expect.equals("-1.23e-7", dart.toString(-1.23e-7));
    expect$.Expect.equals("-1e-8", dart.toString(-1e-8));
    expect$.Expect.equals("-1.2e-8", dart.toString(-1.2e-8));
    expect$.Expect.equals("-1.23e-8", dart.toString(-1.23e-8));
    expect$.Expect.equals("0.00001", dart.toString(0.00001));
    expect$.Expect.equals("1e+21", dart.toString(1e+21));
    expect$.Expect.equals("-1e+21", dart.toString(-1e+21));
    expect$.Expect.equals("1e-7", dart.toString(1e-7));
    expect$.Expect.equals("-1e-7", dart.toString(-1e-7));
    expect$.Expect.equals("1.0000000000000001e+21", dart.toString(1.0000000000000001e+21));
    expect$.Expect.equals("0.000001", dart.toString(0.000001));
    expect$.Expect.equals("1e-7", dart.toString(1e-7));
  };
  dart.fn(double_to_string_test.main, VoidTodynamic());
  // Exports:
  exports.double_to_string_test = double_to_string_test;
});
