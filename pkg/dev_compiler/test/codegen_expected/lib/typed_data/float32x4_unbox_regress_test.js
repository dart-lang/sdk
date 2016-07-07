dart_library.library('lib/typed_data/float32x4_unbox_regress_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_unbox_regress_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_unbox_regress_test = Object.create(null);
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float32x4_unbox_regress_test.testListStore = function(array, index, value) {
    dart.dsetindex(array, index, value);
  };
  dart.fn(float32x4_unbox_regress_test.testListStore, dynamicAnddynamicAnddynamicTodynamic());
  float32x4_unbox_regress_test.testListStoreDeopt = function() {
    let list = null;
    let value = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let smi = 12;
    list = typed_data.Float32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testListStore(list, 0, value);
    }
    try {
      float32x4_unbox_regress_test.testListStore(list, 0, smi);
    } catch (_) {
    }

  };
  dart.fn(float32x4_unbox_regress_test.testListStoreDeopt, VoidTovoid());
  float32x4_unbox_regress_test.testAdd = function(a, b) {
    let c = dart.dsend(a, '+', b);
    expect$.Expect.equals(3.0, dart.dload(c, 'x'));
    expect$.Expect.equals(5.0, dart.dload(c, 'y'));
    expect$.Expect.equals(7.0, dart.dload(c, 'z'));
    expect$.Expect.equals(9.0, dart.dload(c, 'w'));
  };
  dart.fn(float32x4_unbox_regress_test.testAdd, dynamicAnddynamicTodynamic());
  float32x4_unbox_regress_test.testAddDeopt = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(2.0, 3.0, 4.0, 5.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testAdd(a, b);
    }
    try {
      float32x4_unbox_regress_test.testAdd(a, smi);
    } catch (_) {
    }

  };
  dart.fn(float32x4_unbox_regress_test.testAddDeopt, VoidTovoid());
  float32x4_unbox_regress_test.testGet = function(a) {
    let c = dart.dsend(dart.dsend(dart.dsend(dart.dload(a, 'x'), '+', dart.dload(a, 'y')), '+', dart.dload(a, 'z')), '+', dart.dload(a, 'w'));
    expect$.Expect.equals(10.0, c);
  };
  dart.fn(float32x4_unbox_regress_test.testGet, dynamicTodynamic());
  float32x4_unbox_regress_test.testGetDeopt = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testGet(a);
    }
    try {
      float32x4_unbox_regress_test.testGet(12);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testGet(a);
    }
  };
  dart.fn(float32x4_unbox_regress_test.testGetDeopt, VoidTovoid());
  float32x4_unbox_regress_test.testComparison = function(a, b) {
    let r = typed_data.Int32x4._check(dart.dsend(a, 'equal', b));
    expect$.Expect.equals(true, r.flagX);
    expect$.Expect.equals(false, r.flagY);
    expect$.Expect.equals(false, r.flagZ);
    expect$.Expect.equals(true, r.flagW);
  };
  dart.fn(float32x4_unbox_regress_test.testComparison, dynamicAnddynamicTovoid());
  float32x4_unbox_regress_test.testComparisonDeopt = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(1.0, 2.1, 3.1, 4.0);
    let smi = 12;
    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testComparison(a, b);
    }
    try {
      float32x4_unbox_regress_test.testComparison(a, smi);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testComparison(a, b);
    }
    try {
      float32x4_unbox_regress_test.testComparison(smi, a);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_unbox_regress_test.testComparison(a, b);
    }
  };
  dart.fn(float32x4_unbox_regress_test.testComparisonDeopt, VoidTovoid());
  float32x4_unbox_regress_test.main = function() {
    float32x4_unbox_regress_test.testListStoreDeopt();
    float32x4_unbox_regress_test.testAddDeopt();
    float32x4_unbox_regress_test.testGetDeopt();
    float32x4_unbox_regress_test.testComparisonDeopt();
  };
  dart.fn(float32x4_unbox_regress_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_unbox_regress_test = float32x4_unbox_regress_test;
});
