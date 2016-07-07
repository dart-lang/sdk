dart_library.library('language/double_to_string_as_precision_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_to_string_as_precision_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_to_string_as_precision_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_to_string_as_precision_test.main = function() {
    expect$.Expect.equals("NaN", core.double.NAN[dartx.toStringAsPrecision](1));
    expect$.Expect.equals("Infinity", core.double.INFINITY[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-Infinity", (-dart.notNull(core.double.INFINITY))[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("0.000555000000000000", 0.000555[dartx.toStringAsPrecision](15));
    expect$.Expect.equals("5.55000000000000e-7", 5.55e-7[dartx.toStringAsPrecision](15));
    expect$.Expect.equals("-5.55000000000000e-7", (-5.55e-7)[dartx.toStringAsPrecision](15));
    expect$.Expect.equals("1e+8", 123456789.0[dartx.toStringAsPrecision](1));
    expect$.Expect.equals("123456789", 123456789.0[dartx.toStringAsPrecision](9));
    expect$.Expect.equals("1.2345679e+8", 123456789.0[dartx.toStringAsPrecision](8));
    expect$.Expect.equals("1.234568e+8", 123456789.0[dartx.toStringAsPrecision](7));
    expect$.Expect.equals("-1.234568e+8", (-123456789.0)[dartx.toStringAsPrecision](7));
    expect$.Expect.equals("-1.2e-9", (-1.2345e-9)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-1.2e-8", (-1.2345e-8)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-1.2e-7", (-1.2345e-7)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-0.0000012", (-0.0000012345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-0.000012", (-0.000012345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-0.00012", (-0.00012345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-0.0012", (-0.0012345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-0.012", (-0.012345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-0.12", (-0.12345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-1.2", (-1.2345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-12", (-12.345)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-1.2e+2", (-123.45)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-1.2e+3", (-1234.5)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-1.2e+4", (-12345.0)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-1.235e+4", (-12345.67)[dartx.toStringAsPrecision](4));
    expect$.Expect.equals("-1.234e+4", (-12344.67)[dartx.toStringAsPrecision](4));
    expect$.Expect.equals("-0.0", (-0.0)[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("-0", (-0.0)[dartx.toStringAsPrecision](1));
    expect$.Expect.equals("1.3", 1.25[dartx.toStringAsPrecision](2));
    expect$.Expect.equals("1.4", 1.35[dartx.toStringAsPrecision](2));
  };
  dart.fn(double_to_string_as_precision_test.main, VoidTodynamic());
  // Exports:
  exports.double_to_string_as_precision_test = double_to_string_as_precision_test;
});
