dart_library.library('language/deopt_smi_op_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__deopt_smi_op_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const deopt_smi_op_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deopt_smi_op_test.test_mul = function(h) {
    let x = null;
    for (let i = 0; i < 3; i++) {
      x = dart.dsend(h, '*', 100000);
    }
    return x;
  };
  dart.fn(deopt_smi_op_test.test_mul, dynamicTodynamic());
  deopt_smi_op_test.test_neg = function(h) {
    let x = null;
    for (let i = 0; i < 3; i++) {
      x = dart.dsend(h, 'unary-');
    }
    return x;
  };
  dart.fn(deopt_smi_op_test.test_neg, dynamicTodynamic());
  deopt_smi_op_test.main = function() {
    for (let i = 0; i < 20; i++)
      deopt_smi_op_test.test_mul(10);
    expect$.Expect.equals(1000000, deopt_smi_op_test.test_mul(10));
    expect$.Expect.equals(100000000000, deopt_smi_op_test.test_mul(1000000));
    expect$.Expect.equals(100000 * 4611686018427387903, deopt_smi_op_test.test_mul(4611686018427387903));
    for (let i = 0; i < 20; i++)
      deopt_smi_op_test.test_neg(10);
    expect$.Expect.equals(-10, deopt_smi_op_test.test_neg(10));
    expect$.Expect.equals(1073741824, deopt_smi_op_test.test_neg(-1073741824));
    expect$.Expect.equals(4611686018427387904, deopt_smi_op_test.test_neg(-4611686018427387904));
  };
  dart.fn(deopt_smi_op_test.main, VoidTodynamic());
  // Exports:
  exports.deopt_smi_op_test = deopt_smi_op_test;
});
