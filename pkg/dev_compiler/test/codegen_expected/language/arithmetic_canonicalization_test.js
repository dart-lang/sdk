dart_library.library('language/arithmetic_canonicalization_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__arithmetic_canonicalization_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const arithmetic_canonicalization_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  arithmetic_canonicalization_test.main = function() {
    for (let i = 0; i < 50; i++) {
      expect$.Expect.isTrue(typeof arithmetic_canonicalization_test.mul1double(i) == 'number');
      expect$.Expect.equals(i[dartx.toDouble](), arithmetic_canonicalization_test.mul1double(i));
      expect$.Expect.equals(0.0, arithmetic_canonicalization_test.mul0double(i));
      expect$.Expect.equals(i[dartx.toDouble](), arithmetic_canonicalization_test.add0double(i));
      expect$.Expect.equals(i, arithmetic_canonicalization_test.mul1int(i));
      expect$.Expect.equals(i, arithmetic_canonicalization_test.add0int(i));
      expect$.Expect.equals(0, arithmetic_canonicalization_test.mul0int(i));
      expect$.Expect.equals(0, arithmetic_canonicalization_test.and0(i));
      expect$.Expect.equals(i, arithmetic_canonicalization_test.and1(i));
      expect$.Expect.equals(i, arithmetic_canonicalization_test.or0(i));
      expect$.Expect.equals(i, arithmetic_canonicalization_test.xor0(i));
    }
    expect$.Expect.isTrue(dart.dload(arithmetic_canonicalization_test.mul0double(core.double.NAN), 'isNaN'));
    expect$.Expect.isFalse(dart.dload(arithmetic_canonicalization_test.add0double(-0.0), 'isNegative'));
  };
  dart.fn(arithmetic_canonicalization_test.main, VoidTodynamic());
  arithmetic_canonicalization_test.mul1double = function(x) {
    return 1.0 * dart.notNull(core.num._check(x));
  };
  dart.fn(arithmetic_canonicalization_test.mul1double, dynamicTodynamic());
  arithmetic_canonicalization_test.mul0double = function(x) {
    return 0.0 * dart.notNull(core.num._check(x));
  };
  dart.fn(arithmetic_canonicalization_test.mul0double, dynamicTodynamic());
  arithmetic_canonicalization_test.add0double = function(x) {
    return 0.0 + dart.notNull(core.num._check(x));
  };
  dart.fn(arithmetic_canonicalization_test.add0double, dynamicTodynamic());
  arithmetic_canonicalization_test.mul1int = function(x) {
    return 1 * dart.notNull(core.num._check(x));
  };
  dart.fn(arithmetic_canonicalization_test.mul1int, dynamicTodynamic());
  arithmetic_canonicalization_test.mul0int = function(x) {
    return 0 * dart.notNull(core.num._check(x));
  };
  dart.fn(arithmetic_canonicalization_test.mul0int, dynamicTodynamic());
  arithmetic_canonicalization_test.add0int = function(x) {
    return 0 + dart.notNull(core.num._check(x));
  };
  dart.fn(arithmetic_canonicalization_test.add0int, dynamicTodynamic());
  arithmetic_canonicalization_test.and0 = function(x) {
    return 0 & dart.notNull(core.int._check(x));
  };
  dart.fn(arithmetic_canonicalization_test.and0, dynamicTodynamic());
  arithmetic_canonicalization_test.or0 = function(x) {
    return (0 | dart.notNull(core.int._check(x))) >>> 0;
  };
  dart.fn(arithmetic_canonicalization_test.or0, dynamicTodynamic());
  arithmetic_canonicalization_test.xor0 = function(x) {
    return (0 ^ dart.notNull(core.int._check(x))) >>> 0;
  };
  dart.fn(arithmetic_canonicalization_test.xor0, dynamicTodynamic());
  arithmetic_canonicalization_test.and1 = function(x) {
    return (-1 & dart.notNull(core.int._check(x))) >>> 0;
  };
  dart.fn(arithmetic_canonicalization_test.and1, dynamicTodynamic());
  // Exports:
  exports.arithmetic_canonicalization_test = arithmetic_canonicalization_test;
});
