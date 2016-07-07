dart_library.library('lib/typed_data/float32x4_cross_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_cross_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_cross_test = Object.create(null);
  let Float32x4AndFloat32x4ToFloat32x4 = () => (Float32x4AndFloat32x4ToFloat32x4 = dart.constFn(dart.definiteFunctionType(typed_data.Float32x4, [typed_data.Float32x4, typed_data.Float32x4])))();
  let Float32x4AndFloat32x4AndFloat32x4Tovoid = () => (Float32x4AndFloat32x4AndFloat32x4Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [typed_data.Float32x4, typed_data.Float32x4, typed_data.Float32x4])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float32x4_cross_test.cross = function(a, b) {
    let t0 = a.shuffle(typed_data.Float32x4.YZXW);
    let t1 = b.shuffle(typed_data.Float32x4.ZXYW);
    let l = t0['*'](t1);
    t0 = a.shuffle(typed_data.Float32x4.ZXYW);
    t1 = b.shuffle(typed_data.Float32x4.YZXW);
    let r = t0['*'](t1);
    return l['-'](r);
  };
  dart.fn(float32x4_cross_test.cross, Float32x4AndFloat32x4ToFloat32x4());
  float32x4_cross_test.testCross = function(a, b, r) {
    let x = float32x4_cross_test.cross(a, b);
    expect$.Expect.equals(r.x, x.x);
    expect$.Expect.equals(r.y, x.y);
    expect$.Expect.equals(r.z, x.z);
    expect$.Expect.equals(r.w, x.w);
  };
  dart.fn(float32x4_cross_test.testCross, Float32x4AndFloat32x4AndFloat32x4Tovoid());
  float32x4_cross_test.main = function() {
    let x = typed_data.Float32x4.new(1.0, 0.0, 0.0, 0.0);
    let y = typed_data.Float32x4.new(0.0, 1.0, 0.0, 0.0);
    let z = typed_data.Float32x4.new(0.0, 0.0, 1.0, 0.0);
    let zero = typed_data.Float32x4.zero();
    for (let i = 0; i < 20; i++) {
      float32x4_cross_test.testCross(x, y, z);
      float32x4_cross_test.testCross(z, x, y);
      float32x4_cross_test.testCross(y, z, x);
      float32x4_cross_test.testCross(z, y, x['unary-']());
      float32x4_cross_test.testCross(x, z, y['unary-']());
      float32x4_cross_test.testCross(y, x, z['unary-']());
      float32x4_cross_test.testCross(x, x, zero);
      float32x4_cross_test.testCross(y, y, zero);
      float32x4_cross_test.testCross(z, z, zero);
      float32x4_cross_test.testCross(x, y, float32x4_cross_test.cross(y['unary-'](), x));
      float32x4_cross_test.testCross(x, y['+'](z), float32x4_cross_test.cross(x, y)['+'](float32x4_cross_test.cross(x, z)));
    }
  };
  dart.fn(float32x4_cross_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_cross_test = float32x4_cross_test;
});
