dart_library.library('lib/typed_data/simd_store_to_load_forward_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__simd_store_to_load_forward_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const simd_store_to_load_forward_test = Object.create(null);
  let Float32x4ListAndFloat32x4ToFloat32x4 = () => (Float32x4ListAndFloat32x4ToFloat32x4 = dart.constFn(dart.definiteFunctionType(typed_data.Float32x4, [typed_data.Float32x4List, typed_data.Float32x4])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  simd_store_to_load_forward_test.testLoadStoreForwardingFloat32x4 = function(l, v) {
    l.set(1, v);
    let r = l.get(1);
    return r;
  };
  dart.fn(simd_store_to_load_forward_test.testLoadStoreForwardingFloat32x4, Float32x4ListAndFloat32x4ToFloat32x4());
  simd_store_to_load_forward_test.main = function() {
    let l = typed_data.Float32x4List.new(4);
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = null;
    for (let i = 0; i < 20; i++) {
      b = simd_store_to_load_forward_test.testLoadStoreForwardingFloat32x4(l, a);
    }
    expect$.Expect.equals(a.x, b.x);
    expect$.Expect.equals(a.y, b.y);
    expect$.Expect.equals(a.z, b.z);
    expect$.Expect.equals(a.w, b.w);
  };
  dart.fn(simd_store_to_load_forward_test.main, VoidTodynamic());
  // Exports:
  exports.simd_store_to_load_forward_test = simd_store_to_load_forward_test;
});
