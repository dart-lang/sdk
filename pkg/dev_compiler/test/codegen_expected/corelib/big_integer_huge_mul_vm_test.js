dart_library.library('corelib/big_integer_huge_mul_vm_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__big_integer_huge_mul_vm_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const big_integer_huge_mul_vm_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  big_integer_huge_mul_vm_test.testBigintHugeMul = function() {
    let bits = 65536;
    let a = (1)[dartx['<<']](bits);
    let a1 = a - 1;
    let p1 = a1 * a1;
    let p2 = a * a - a - a + 1;
    expect$.Expect.isTrue(p1 == p2, 'products do not match');
  };
  dart.fn(big_integer_huge_mul_vm_test.testBigintHugeMul, VoidTodynamic());
  big_integer_huge_mul_vm_test.main = function() {
    big_integer_huge_mul_vm_test.testBigintHugeMul();
  };
  dart.fn(big_integer_huge_mul_vm_test.main, VoidTodynamic());
  // Exports:
  exports.big_integer_huge_mul_vm_test = big_integer_huge_mul_vm_test;
});
