dart_library.library('language/double_int_addition_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_int_addition_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_int_addition_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  double_int_addition_test.main = function() {
    for (let i = 0; i < 20; i++) {
      double_int_addition_test.addOp(1.1, 2.1);
    }
    expect$.Expect.isTrue(typeof double_int_addition_test.addOp(1.1, 2.1) == 'number');
    expect$.Expect.isTrue(typeof double_int_addition_test.addOp(1, 2) == 'number');
  };
  dart.fn(double_int_addition_test.main, VoidTodynamic());
  double_int_addition_test.addOp = function(a, b) {
    return dart.dsend(a, '+', b);
  };
  dart.fn(double_int_addition_test.addOp, dynamicAnddynamicTodynamic());
  // Exports:
  exports.double_int_addition_test = double_int_addition_test;
});
