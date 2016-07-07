dart_library.library('language/double_to_string_as_precision3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_to_string_as_precision3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_to_string_as_precision3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_to_string_as_precision3_test.main = function() {
    expect$.Expect.equals("0.000555000000000000046248", 0.000555[dartx.toStringAsPrecision](21));
    expect$.Expect.equals(0.000555, 0.000555);
    expect$.Expect.equals("5.54999999999999980179e-7", 5.55e-7[dartx.toStringAsPrecision](21));
    expect$.Expect.equals(5.55e-7, 5.55e-7);
    expect$.Expect.equals("-5.54999999999999980179e-7", (-5.55e-7)[dartx.toStringAsPrecision](21));
    expect$.Expect.equals(-5.55e-7, -5.55e-7);
  };
  dart.fn(double_to_string_as_precision3_test.main, VoidTodynamic());
  // Exports:
  exports.double_to_string_as_precision3_test = double_to_string_as_precision3_test;
});
