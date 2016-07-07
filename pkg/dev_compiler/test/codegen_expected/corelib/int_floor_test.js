dart_library.library('corelib/int_floor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int_floor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int_floor_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int_floor_test.main = function() {
    expect$.Expect.equals(0, (0)[dartx.floor]());
    expect$.Expect.equals(1, (1)[dartx.floor]());
    expect$.Expect.equals(4660, (4660)[dartx.floor]());
    expect$.Expect.equals(305419896, (305419896)[dartx.floor]());
    expect$.Expect.equals(1250999896491, (1250999896491)[dartx.floor]());
    expect$.Expect.equals(81985529216486895, (81985529216486895)[dartx.floor]());
    expect$.Expect.equals(27898229935051914142968983831921934135401027036219428335, (27898229935051914142968983831921934135401027036219428335)[dartx.floor]());
    expect$.Expect.equals(-1, -dart.notNull((1)[dartx.floor]()));
    expect$.Expect.equals(-4660, -dart.notNull((4660)[dartx.floor]()));
    expect$.Expect.equals(-305419896, -dart.notNull((305419896)[dartx.floor]()));
    expect$.Expect.equals(-1250999896491, -dart.notNull((1250999896491)[dartx.floor]()));
    expect$.Expect.equals(-81985529216486895, -dart.notNull((81985529216486895)[dartx.floor]()));
    expect$.Expect.equals(-27898229935051914142968983831921934135401027036219428335, -dart.notNull((27898229935051914142968983831921934135401027036219428335)[dartx.floor]()));
    expect$.Expect.isTrue(typeof (0)[dartx.floor]() == 'number');
    expect$.Expect.isTrue(typeof (1)[dartx.floor]() == 'number');
    expect$.Expect.isTrue(typeof (4660)[dartx.floor]() == 'number');
    expect$.Expect.isTrue(typeof (305419896)[dartx.floor]() == 'number');
    expect$.Expect.isTrue(typeof (1250999896491)[dartx.floor]() == 'number');
    expect$.Expect.isTrue(typeof (81985529216486895)[dartx.floor]() == 'number');
    expect$.Expect.isTrue(typeof (27898229935051914142968983831921934135401027036219428335)[dartx.floor]() == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((1)[dartx.floor]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((4660)[dartx.floor]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((305419896)[dartx.floor]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((1250999896491)[dartx.floor]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((81985529216486895)[dartx.floor]()) == 'number');
    expect$.Expect.isTrue(typeof -dart.notNull((27898229935051914142968983831921934135401027036219428335)[dartx.floor]()) == 'number');
  };
  dart.fn(int_floor_test.main, VoidTodynamic());
  // Exports:
  exports.int_floor_test = int_floor_test;
});
