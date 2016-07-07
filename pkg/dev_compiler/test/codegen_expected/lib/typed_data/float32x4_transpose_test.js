dart_library.library('lib/typed_data/float32x4_transpose_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_transpose_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_transpose_test = Object.create(null);
  let Float32x4ListTovoid = () => (Float32x4ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [typed_data.Float32x4List])))();
  let Float32x4ListAndFloat32x4ListTovoid = () => (Float32x4ListAndFloat32x4ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [typed_data.Float32x4List, typed_data.Float32x4List])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float32x4_transpose_test.transpose = function(m) {
    expect$.Expect.equals(4, m.length);
    let m0 = m.get(0);
    let m1 = m.get(1);
    let m2 = m.get(2);
    let m3 = m.get(3);
    let t0 = m0.shuffleMix(m1, typed_data.Float32x4.XYXY);
    let t1 = m2.shuffleMix(m3, typed_data.Float32x4.XYXY);
    m.set(0, t0.shuffleMix(t1, typed_data.Float32x4.XZXZ));
    m.set(1, t0.shuffleMix(t1, typed_data.Float32x4.YWYW));
    let t2 = m0.shuffleMix(m1, typed_data.Float32x4.ZWZW);
    let t3 = m2.shuffleMix(m3, typed_data.Float32x4.ZWZW);
    m.set(2, t2.shuffleMix(t3, typed_data.Float32x4.XZXZ));
    m.set(3, t2.shuffleMix(t3, typed_data.Float32x4.YWYW));
  };
  dart.fn(float32x4_transpose_test.transpose, Float32x4ListTovoid());
  float32x4_transpose_test.testTranspose = function(m, r) {
    float32x4_transpose_test.transpose(m);
    for (let i = 0; i < 4; i++) {
      let a = m.get(i);
      let b = r.get(i);
      expect$.Expect.equals(b.x, a.x);
      expect$.Expect.equals(b.y, a.y);
      expect$.Expect.equals(b.z, a.z);
      expect$.Expect.equals(b.w, a.w);
    }
  };
  dart.fn(float32x4_transpose_test.testTranspose, Float32x4ListAndFloat32x4ListTovoid());
  float32x4_transpose_test.main = function() {
    let A = typed_data.Float32x4List.new(4);
    A.set(0, typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0));
    A.set(1, typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0));
    A.set(2, typed_data.Float32x4.new(9.0, 10.0, 11.0, 12.0));
    A.set(3, typed_data.Float32x4.new(13.0, 14.0, 15.0, 16.0));
    let B = typed_data.Float32x4List.new(4);
    B.set(0, typed_data.Float32x4.new(1.0, 5.0, 9.0, 13.0));
    B.set(1, typed_data.Float32x4.new(2.0, 6.0, 10.0, 14.0));
    B.set(2, typed_data.Float32x4.new(3.0, 7.0, 11.0, 15.0));
    B.set(3, typed_data.Float32x4.new(4.0, 8.0, 12.0, 16.0));
    let I = typed_data.Float32x4List.new(4);
    I.set(0, typed_data.Float32x4.new(1.0, 0.0, 0.0, 0.0));
    I.set(1, typed_data.Float32x4.new(0.0, 1.0, 0.0, 0.0));
    I.set(2, typed_data.Float32x4.new(0.0, 0.0, 1.0, 0.0));
    I.set(3, typed_data.Float32x4.new(0.0, 0.0, 0.0, 1.0));
    for (let i = 0; i < 20; i++) {
      let m = typed_data.Float32x4List.fromList(I);
      float32x4_transpose_test.testTranspose(m, I);
      m = typed_data.Float32x4List.fromList(A);
      float32x4_transpose_test.testTranspose(m, B);
    }
  };
  dart.fn(float32x4_transpose_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_transpose_test = float32x4_transpose_test;
});
