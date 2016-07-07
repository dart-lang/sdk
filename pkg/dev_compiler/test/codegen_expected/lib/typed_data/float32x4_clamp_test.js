dart_library.library('lib/typed_data/float32x4_clamp_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_clamp_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_clamp_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float32x4_clamp_test.testClampLowerGreaterThanUpper = function() {
    let l = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let u = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let z = typed_data.Float32x4.zero();
    let a = z.clamp(l, u);
    expect$.Expect.equals(a.x, 1.0);
    expect$.Expect.equals(a.y, 1.0);
    expect$.Expect.equals(a.z, 1.0);
    expect$.Expect.equals(a.w, 1.0);
  };
  dart.fn(float32x4_clamp_test.testClampLowerGreaterThanUpper, VoidTovoid());
  float32x4_clamp_test.testClamp = function() {
    let l = typed_data.Float32x4.new(-1.0, -1.0, -1.0, -1.0);
    let u = typed_data.Float32x4.new(1.0, 1.0, 1.0, 1.0);
    let z = typed_data.Float32x4.zero();
    let a = z.clamp(l, u);
    expect$.Expect.equals(a.x, 0.0);
    expect$.Expect.equals(a.y, 0.0);
    expect$.Expect.equals(a.z, 0.0);
    expect$.Expect.equals(a.w, 0.0);
  };
  dart.fn(float32x4_clamp_test.testClamp, VoidTovoid());
  float32x4_clamp_test.main = function() {
    for (let i = 0; i < 2000; i++) {
      float32x4_clamp_test.testClampLowerGreaterThanUpper();
      float32x4_clamp_test.testClamp();
    }
  };
  dart.fn(float32x4_clamp_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_clamp_test = float32x4_clamp_test;
});
