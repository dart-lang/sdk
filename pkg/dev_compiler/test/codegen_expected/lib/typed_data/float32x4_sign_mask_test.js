dart_library.library('lib/typed_data/float32x4_sign_mask_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_sign_mask_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_sign_mask_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float32x4_sign_mask_test.testImmediates = function() {
    let f = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Float32x4.new(-1.0, -2.0, -3.0, -0.0);
    m = f.signMask;
    expect$.Expect.equals(15, m);
    f = typed_data.Float32x4.new(-1.0, 2.0, 3.0, 4.0);
    m = f.signMask;
    expect$.Expect.equals(1, m);
    f = typed_data.Float32x4.new(1.0, -2.0, 3.0, 4.0);
    m = f.signMask;
    expect$.Expect.equals(2, m);
    f = typed_data.Float32x4.new(1.0, 2.0, -3.0, 4.0);
    m = f.signMask;
    expect$.Expect.equals(4, m);
    f = typed_data.Float32x4.new(1.0, 2.0, 3.0, -4.0);
    m = f.signMask;
    expect$.Expect.equals(8, m);
  };
  dart.fn(float32x4_sign_mask_test.testImmediates, VoidTovoid());
  float32x4_sign_mask_test.testZero = function() {
    let f = typed_data.Float32x4.new(0.0, 0.0, 0.0, 0.0);
    let m = f.signMask;
    expect$.Expect.equals(0, m);
    f = typed_data.Float32x4.new(-0.0, -0.0, -0.0, -0.0);
    m = f.signMask;
    expect$.Expect.equals(15, m);
  };
  dart.fn(float32x4_sign_mask_test.testZero, VoidTovoid());
  float32x4_sign_mask_test.testArithmetic = function() {
    let a = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let b = typed_data.Float32x4.new(2.0, 2.0, 2.0, 2.0);
    let c = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let m1 = a['-'](b).signMask;
    expect$.Expect.equals(15, m1);
    let m2 = b['-'](a).signMask;
    expect$.Expect.equals(0, m2);
    let m3 = c['*'](c).signMask;
    expect$.Expect.equals(0, m3);
    let m4 = a['*'](c).signMask;
    expect$.Expect.equals(15, m4);
  };
  dart.fn(float32x4_sign_mask_test.testArithmetic, VoidTovoid());
  float32x4_sign_mask_test.main = function() {
    for (let i = 0; i < 2000; i++) {
      float32x4_sign_mask_test.testImmediates();
      float32x4_sign_mask_test.testZero();
      float32x4_sign_mask_test.testArithmetic();
    }
  };
  dart.fn(float32x4_sign_mask_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_sign_mask_test = float32x4_sign_mask_test;
});
