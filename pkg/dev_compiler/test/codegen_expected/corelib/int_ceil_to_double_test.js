dart_library.library('corelib/int_ceil_to_double_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int_ceil_to_double_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int_ceil_to_double_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int_ceil_to_double_test.main = function() {
    expect$.Expect.equals(0.0, (0)[dartx.ceilToDouble]());
    expect$.Expect.equals(1.0, (1)[dartx.ceilToDouble]());
    expect$.Expect.equals(4660, (4660)[dartx.ceilToDouble]());
    expect$.Expect.equals(305419896, (305419896)[dartx.ceilToDouble]());
    expect$.Expect.equals(1250999896491, (1250999896491)[dartx.ceilToDouble]());
    expect$.Expect.equals(81985529216486900.0, (81985529216486895)[dartx.ceilToDouble]());
    expect$.Expect.equals(2.7898229935051914e+55, (27898229935051914142968983831921934135401027036219428335)[dartx.ceilToDouble]());
    expect$.Expect.equals(-1.0, -dart.notNull((1)[dartx.ceilToDouble]()));
    expect$.Expect.equals(-4660, -dart.notNull((4660)[dartx.ceilToDouble]()));
    expect$.Expect.equals(-305419896, -dart.notNull((305419896)[dartx.ceilToDouble]()));
    expect$.Expect.equals(-1250999896491, -dart.notNull((1250999896491)[dartx.ceilToDouble]()));
    expect$.Expect.equals(-81985529216486900.0, -dart.notNull((81985529216486895)[dartx.ceilToDouble]()));
    expect$.Expect.equals(-2.7898229935051914e+55, -dart.notNull((27898229935051914142968983831921934135401027036219428335)[dartx.ceilToDouble]()));
    expect$.Expect.isTrue(typeof (0)[dartx.ceilToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (1)[dartx.ceilToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (4660)[dartx.ceilToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (305419896)[dartx.ceilToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (1250999896491)[dartx.ceilToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (81985529216486895)[dartx.ceilToDouble]() == 'number');
    expect$.Expect.isTrue(typeof (27898229935051914142968983831921934135401027036219428335)[dartx.ceilToDouble]() == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((1)[dartx.ceilToDouble]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((4660)[dartx.ceilToDouble]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((305419896)[dartx.ceilToDouble]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((1250999896491)[dartx.ceilToDouble]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((81985529216486895)[dartx.ceilToDouble]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((27898229935051914142968983831921934135401027036219428335)[dartx.ceilToDouble]()) == 'number');
  };
  dart.fn(int_ceil_to_double_test.main, VoidTodynamic());
  // Exports:
  exports.int_ceil_to_double_test = int_ceil_to_double_test;
});
