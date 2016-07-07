dart_library.library('language/double_to_string_as_fixed_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_to_string_as_fixed_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_to_string_as_fixed_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_to_string_as_fixed_test.ToStringAsFixedTest = class ToStringAsFixedTest extends core.Object {
    static testMain() {
      expect$.Expect.equals("2.000", 2.0[dartx.toStringAsFixed](3));
      expect$.Expect.equals("2.100", 2.1[dartx.toStringAsFixed](3));
      expect$.Expect.equals("2.120", 2.12[dartx.toStringAsFixed](3));
      expect$.Expect.equals("2.123", 2.123[dartx.toStringAsFixed](3));
      expect$.Expect.equals("2.124", 2.1239[dartx.toStringAsFixed](3));
      expect$.Expect.equals("NaN", (0.0 / 0.0)[dartx.toStringAsFixed](3));
      expect$.Expect.equals("Infinity", (1.0 / 0.0)[dartx.toStringAsFixed](3));
      expect$.Expect.equals("-Infinity", (-1.0 / 0.0)[dartx.toStringAsFixed](3));
      expect$.Expect.equals("1.1111111111111111e+21", 1.1111111111111111e+21[dartx.toStringAsFixed](8));
      expect$.Expect.equals("0.1", 0.1[dartx.toStringAsFixed](1));
      expect$.Expect.equals("0.10", 0.1[dartx.toStringAsFixed](2));
      expect$.Expect.equals("0.100", 0.1[dartx.toStringAsFixed](3));
      expect$.Expect.equals("0.01", 0.01[dartx.toStringAsFixed](2));
      expect$.Expect.equals("0.010", 0.01[dartx.toStringAsFixed](3));
      expect$.Expect.equals("0.0100", 0.01[dartx.toStringAsFixed](4));
      expect$.Expect.equals("0.00", 0.001[dartx.toStringAsFixed](2));
      expect$.Expect.equals("0.001", 0.001[dartx.toStringAsFixed](3));
      expect$.Expect.equals("0.0010", 0.001[dartx.toStringAsFixed](4));
      expect$.Expect.equals("1.0000", 1.0[dartx.toStringAsFixed](4));
      expect$.Expect.equals("1.0", 1.0[dartx.toStringAsFixed](1));
      expect$.Expect.equals("1", 1.0[dartx.toStringAsFixed](0));
      expect$.Expect.equals("12", 12.0[dartx.toStringAsFixed](0));
      expect$.Expect.equals("1", 1.1[dartx.toStringAsFixed](0));
      expect$.Expect.equals("12", 12.1[dartx.toStringAsFixed](0));
      expect$.Expect.equals("1", 1.12[dartx.toStringAsFixed](0));
      expect$.Expect.equals("12", 12.12[dartx.toStringAsFixed](0));
      expect$.Expect.equals("0.0000006", (6e-7)[dartx.toStringAsFixed](7));
      expect$.Expect.equals("0.00000006", (6e-8)[dartx.toStringAsFixed](8));
      expect$.Expect.equals("0.000000060", (6e-8)[dartx.toStringAsFixed](9));
      expect$.Expect.equals("0.0000000600", (6e-8)[dartx.toStringAsFixed](10));
      expect$.Expect.equals("0", 0.0[dartx.toStringAsFixed](0));
      expect$.Expect.equals("0.0", 0.0[dartx.toStringAsFixed](1));
      expect$.Expect.equals("0.00", 0.0[dartx.toStringAsFixed](2));
      expect$.Expect.equals("-0.1", (-0.1)[dartx.toStringAsFixed](1));
      expect$.Expect.equals("-0.10", (-0.1)[dartx.toStringAsFixed](2));
      expect$.Expect.equals("-0.100", (-0.1)[dartx.toStringAsFixed](3));
      expect$.Expect.equals("-0.01", (-0.01)[dartx.toStringAsFixed](2));
      expect$.Expect.equals("-0.010", (-0.01)[dartx.toStringAsFixed](3));
      expect$.Expect.equals("-0.0100", (-0.01)[dartx.toStringAsFixed](4));
      expect$.Expect.equals("-0.00", (-0.001)[dartx.toStringAsFixed](2));
      expect$.Expect.equals("-0.001", (-0.001)[dartx.toStringAsFixed](3));
      expect$.Expect.equals("-0.0010", (-0.001)[dartx.toStringAsFixed](4));
      expect$.Expect.equals("-1.0000", (-1.0)[dartx.toStringAsFixed](4));
      expect$.Expect.equals("-1.0", (-1.0)[dartx.toStringAsFixed](1));
      expect$.Expect.equals("-1", (-1.0)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-1", (-1.1)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-12", (-12.1)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-1", (-1.12)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-12", (-12.12)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-0.0000006", (-6e-7)[dartx.toStringAsFixed](7));
      expect$.Expect.equals("-0.00000006", (-6e-8)[dartx.toStringAsFixed](8));
      expect$.Expect.equals("-0.000000060", (-6e-8)[dartx.toStringAsFixed](9));
      expect$.Expect.equals("-0.0000000600", (-6e-8)[dartx.toStringAsFixed](10));
      expect$.Expect.equals("-0", (-0.0)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-0.0", (-0.0)[dartx.toStringAsFixed](1));
      expect$.Expect.equals("-0.00", (-0.0)[dartx.toStringAsFixed](2));
      expect$.Expect.equals("1000", 1000.0[dartx.toStringAsFixed](0));
      expect$.Expect.equals("0", 0.00001[dartx.toStringAsFixed](0));
      expect$.Expect.equals("0.00001", 0.00001[dartx.toStringAsFixed](5));
      expect$.Expect.equals("0.00000000000000000010", (1e-19)[dartx.toStringAsFixed](20));
      expect$.Expect.equals("0.00001000000000000", 0.00001[dartx.toStringAsFixed](17));
      expect$.Expect.equals("1.00000000000000000", 1.0[dartx.toStringAsFixed](17));
      expect$.Expect.equals("1000000000000000128", 1000000000000000100.0[dartx.toStringAsFixed](0));
      expect$.Expect.equals("100000000000000128.0", 100000000000000130.0[dartx.toStringAsFixed](1));
      expect$.Expect.equals("10000000000000128.00", 10000000000000128.0[dartx.toStringAsFixed](2));
      expect$.Expect.equals("10000000000000128.00000000000000000000", 10000000000000128.0[dartx.toStringAsFixed](20));
      expect$.Expect.equals("0", 0.0[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-42.000", (-42.0)[dartx.toStringAsFixed](3));
      expect$.Expect.equals("-1000000000000000128", (-1000000000000000100.0)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-0.00000000000000000010", (-1e-19)[dartx.toStringAsFixed](20));
      expect$.Expect.equals("0.12312312312312299889", 0.123123123123123[dartx.toStringAsFixed](20));
      expect$.Expect.equals("1", 0.5[dartx.toStringAsFixed](0));
      expect$.Expect.equals("-1", (-0.5)[dartx.toStringAsFixed](0));
      expect$.Expect.equals("1.3", 1.25[dartx.toStringAsFixed](1));
      expect$.Expect.equals("234.2040", 234.20405[dartx.toStringAsFixed](4));
      expect$.Expect.equals("234.2041", 234.2040506[dartx.toStringAsFixed](4));
    }
  };
  dart.setSignature(double_to_string_as_fixed_test.ToStringAsFixedTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  double_to_string_as_fixed_test.main = function() {
    double_to_string_as_fixed_test.ToStringAsFixedTest.testMain();
  };
  dart.fn(double_to_string_as_fixed_test.main, VoidTodynamic());
  // Exports:
  exports.double_to_string_as_fixed_test = double_to_string_as_fixed_test;
});
