dart_library.library('lib/typed_data/float64x2_typed_list_test', null, /* Imports */[
  'dart_sdk'
], function load__float64x2_typed_list_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const float64x2_typed_list_test = Object.create(null);
  let Float64x2ListTovoid = () => (Float64x2ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [typed_data.Float64x2List])))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float64x2_typed_list_test.test = function(l) {
    let a = l.get(0);
    let b = l.get(1);
    l.set(0, b);
    l.set(1, a);
  };
  dart.fn(float64x2_typed_list_test.test, Float64x2ListTovoid());
  float64x2_typed_list_test.compare = function(a, b) {
    return dart.equals(dart.dload(a, 'x'), dart.dload(b, 'x')) && dart.equals(dart.dload(a, 'y'), dart.dload(b, 'y'));
  };
  dart.fn(float64x2_typed_list_test.compare, dynamicAnddynamicTobool());
  float64x2_typed_list_test.main = function() {
    let l = typed_data.Float64x2List.new(2);
    let a = typed_data.Float64x2.new(1.0, 2.0);
    let b = typed_data.Float64x2.new(3.0, 4.0);
    l.set(0, a);
    l.set(1, b);
    for (let i = 0; i < 41; i++) {
      float64x2_typed_list_test.test(l);
    }
    if (!dart.test(float64x2_typed_list_test.compare(l.get(0), b)) || !dart.test(float64x2_typed_list_test.compare(l.get(1), a))) {
      dart.throw(123);
    }
  };
  dart.fn(float64x2_typed_list_test.main, VoidTodynamic());
  // Exports:
  exports.float64x2_typed_list_test = float64x2_typed_list_test;
});
