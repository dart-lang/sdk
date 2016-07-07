dart_library.library('lib/typed_data/int32x4_sign_mask_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int32x4_sign_mask_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_sign_mask_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int32x4_sign_mask_test.testImmediates = function() {
    let f = typed_data.Int32x4.new(1, 2, 3, 4);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Int32x4.new(-1, -2, -3, -4);
    m = f.signMask;
    expect$.Expect.equals(15, m);
    f = typed_data.Int32x4.bool(true, false, false, false);
    m = f.signMask;
    expect$.Expect.equals(1, m);
    f = typed_data.Int32x4.bool(false, true, false, false);
    m = f.signMask;
    expect$.Expect.equals(2, m);
    f = typed_data.Int32x4.bool(false, false, true, false);
    m = f.signMask;
    expect$.Expect.equals(4, m);
    f = typed_data.Int32x4.bool(false, false, false, true);
    m = f.signMask;
    expect$.Expect.equals(8, m);
  };
  dart.fn(int32x4_sign_mask_test.testImmediates, VoidTovoid());
  int32x4_sign_mask_test.testZero = function() {
    let f = typed_data.Int32x4.new(0, 0, 0, 0);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Int32x4.new(-0, -0, -0, -0);
    m = f.signMask;
    expect$.Expect.equals(0, m);
  };
  dart.fn(int32x4_sign_mask_test.testZero, VoidTovoid());
  int32x4_sign_mask_test.testLogic = function() {
    let a = typed_data.Int32x4.new(2147483648, 2147483648, 2147483648, 2147483648);
    let b = typed_data.Int32x4.new(1879048192, 1879048192, 1879048192, 1879048192);
    let c = typed_data.Int32x4.new(4026531840, 4026531840, 4026531840, 4026531840);
    let m1 = a['&'](c).signMask;
    expect$.Expect.equals(15, m1);
    let m2 = a['&'](b).signMask;
    expect$.Expect.equals(0, m2);
    let m3 = b['^'](a).signMask;
    expect$.Expect.equals(15, m3);
    let m4 = b['|'](c).signMask;
    expect$.Expect.equals(15, m4);
  };
  dart.fn(int32x4_sign_mask_test.testLogic, VoidTovoid());
  int32x4_sign_mask_test.main = function() {
    for (let i = 0; i < 2000; i++) {
      int32x4_sign_mask_test.testImmediates();
      int32x4_sign_mask_test.testZero();
      int32x4_sign_mask_test.testLogic();
    }
  };
  dart.fn(int32x4_sign_mask_test.main, VoidTodynamic());
  // Exports:
  exports.int32x4_sign_mask_test = int32x4_sign_mask_test;
});
