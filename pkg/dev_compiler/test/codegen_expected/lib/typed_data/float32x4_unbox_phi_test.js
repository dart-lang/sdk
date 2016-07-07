dart_library.library('lib/typed_data/float32x4_unbox_phi_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_unbox_phi_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_unbox_phi_test = Object.create(null);
  let Float32x4ListTodouble = () => (Float32x4ListTodouble = dart.constFn(dart.definiteFunctionType(core.double, [typed_data.Float32x4List])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float32x4_unbox_phi_test.testUnboxPhi = function(data) {
    let res = typed_data.Float32x4.zero();
    for (let i = 0; i < dart.notNull(data.length); i++) {
      res = res['+'](data.get(i));
    }
    return dart.notNull(res.x) + dart.notNull(res.y) + dart.notNull(res.z) + dart.notNull(res.w);
  };
  dart.fn(float32x4_unbox_phi_test.testUnboxPhi, Float32x4ListTodouble());
  float32x4_unbox_phi_test.main = function() {
    let list = typed_data.Float32x4List.new(10);
    let floatList = typed_data.Float32List.view(list.buffer);
    for (let i = 0; i < dart.notNull(floatList[dartx.length]); i++) {
      floatList[dartx.set](i, i[dartx.toDouble]());
    }
    for (let i = 0; i < 20; i++) {
      let r = float32x4_unbox_phi_test.testUnboxPhi(list);
      expect$.Expect.equals(780.0, r);
    }
  };
  dart.fn(float32x4_unbox_phi_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_unbox_phi_test = float32x4_unbox_phi_test;
});
