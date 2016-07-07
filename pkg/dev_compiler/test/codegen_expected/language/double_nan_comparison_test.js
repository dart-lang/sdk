dart_library.library('language/double_nan_comparison_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_nan_comparison_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_nan_comparison_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_nan_comparison_test.test_expr = function(a, b) {
    return !dart.equals(a, b);
  };
  dart.fn(double_nan_comparison_test.test_expr, dynamicAnddynamicTodynamic());
  double_nan_comparison_test.test_conditional = function(a, b) {
    return !dart.equals(a, b) ? true : false;
  };
  dart.fn(double_nan_comparison_test.test_conditional, dynamicAnddynamicTodynamic());
  double_nan_comparison_test.test_branch = function(a, b) {
    if (!dart.equals(a, b)) {
      return true;
    }
    return false;
  };
  dart.fn(double_nan_comparison_test.test_branch, dynamicAnddynamicTodynamic());
  double_nan_comparison_test.main = function() {
    expect$.Expect.equals(true, double_nan_comparison_test.test_expr(0.5, core.double.NAN));
    for (let i = 0; i < 20; i++)
      double_nan_comparison_test.test_expr(0.5, core.double.NAN);
    expect$.Expect.equals(true, double_nan_comparison_test.test_expr(0.5, core.double.NAN));
    expect$.Expect.equals(true, double_nan_comparison_test.test_conditional(0.5, core.double.NAN));
    for (let i = 0; i < 20; i++)
      double_nan_comparison_test.test_conditional(0.5, core.double.NAN);
    expect$.Expect.equals(true, double_nan_comparison_test.test_conditional(0.5, core.double.NAN));
    expect$.Expect.equals(true, double_nan_comparison_test.test_branch(0.5, core.double.NAN));
    for (let i = 0; i < 20; i++)
      double_nan_comparison_test.test_branch(0.5, core.double.NAN);
    expect$.Expect.equals(true, double_nan_comparison_test.test_branch(0.5, core.double.NAN));
  };
  dart.fn(double_nan_comparison_test.main, VoidTodynamic());
  // Exports:
  exports.double_nan_comparison_test = double_nan_comparison_test;
});
