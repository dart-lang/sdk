dart_library.library('corelib/int_ceil_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int_ceil_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int_ceil_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int_ceil_test.main = function() {
    expect$.Expect.equals(0, (0)[dartx.ceil]());
    expect$.Expect.equals(1, (1)[dartx.ceil]());
    expect$.Expect.equals(4660, (4660)[dartx.ceil]());
    expect$.Expect.equals(305419896, (305419896)[dartx.ceil]());
    expect$.Expect.equals(1250999896491, (1250999896491)[dartx.ceil]());
    expect$.Expect.equals(81985529216486895, (81985529216486895)[dartx.ceil]());
    expect$.Expect.equals(27898229935051914142968983831921934135401027036219428335, (27898229935051914142968983831921934135401027036219428335)[dartx.ceil]());
    expect$.Expect.equals(-1, -dart.notNull((1)[dartx.ceil]()));
    expect$.Expect.equals(-4660, -dart.notNull((4660)[dartx.ceil]()));
    expect$.Expect.equals(-305419896, -dart.notNull((305419896)[dartx.ceil]()));
    expect$.Expect.equals(-1250999896491, -dart.notNull((1250999896491)[dartx.ceil]()));
    expect$.Expect.equals(-81985529216486895, -dart.notNull((81985529216486895)[dartx.ceil]()));
    expect$.Expect.equals(-27898229935051914142968983831921934135401027036219428335, -dart.notNull((27898229935051914142968983831921934135401027036219428335)[dartx.ceil]()));
    expect$.Expect.isTrue(typeof (0)[dartx.ceil]() == 'number');
    expect$.Expect.isTrue(typeof (1)[dartx.ceil]() == 'number');
    expect$.Expect.isTrue(typeof (4660)[dartx.ceil]() == 'number');
    expect$.Expect.isTrue(typeof (305419896)[dartx.ceil]() == 'number');
    expect$.Expect.isTrue(typeof (1250999896491)[dartx.ceil]() == 'number');
    expect$.Expect.isTrue(typeof (81985529216486895)[dartx.ceil]() == 'number');
    expect$.Expect.isTrue(typeof (27898229935051914142968983831921934135401027036219428335)[dartx.ceil]() == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((1)[dartx.ceil]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((4660)[dartx.ceil]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((305419896)[dartx.ceil]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((1250999896491)[dartx.ceil]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((81985529216486895)[dartx.ceil]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((27898229935051914142968983831921934135401027036219428335)[dartx.ceil]()) == 'number');
  };
  dart.fn(int_ceil_test.main, VoidTodynamic());
  // Exports:
  exports.int_ceil_test = int_ceil_test;
});
