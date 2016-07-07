dart_library.library('lib/typed_data/float32x4_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_list_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_list_test = Object.create(null);
  let ListOfFloat32x4 = () => (ListOfFloat32x4 = dart.constFn(core.List$(typed_data.Float32x4)))();
  let JSArrayOfFloat32x4 = () => (JSArrayOfFloat32x4 = dart.constFn(_interceptors.JSArray$(typed_data.Float32x4)))();
  let JSArrayOfdouble = () => (JSArrayOfdouble = dart.constFn(_interceptors.JSArray$(core.double)))();
  let ListOfdouble = () => (ListOfdouble = dart.constFn(core.List$(core.double)))();
  let JSArrayOfListOfdouble = () => (JSArrayOfListOfdouble = dart.constFn(_interceptors.JSArray$(ListOfdouble())))();
  let IterableOfListOfdouble = () => (IterableOfListOfdouble = dart.constFn(core.Iterable$(ListOfdouble())))();
  let JSArrayOfIterableOfListOfdouble = () => (JSArrayOfIterableOfListOfdouble = dart.constFn(_interceptors.JSArray$(IterableOfListOfdouble())))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let ListOfdoubleToListOfdouble = () => (ListOfdoubleToListOfdouble = dart.constFn(dart.definiteFunctionType(ListOfdouble(), [ListOfdouble()])))();
  let doubleToListOfdouble = () => (doubleToListOfdouble = dart.constFn(dart.definiteFunctionType(ListOfdouble(), [core.double])))();
  let IterableOfListOfdoubleToIterableOfListOfdouble = () => (IterableOfListOfdoubleToIterableOfListOfdouble = dart.constFn(dart.definiteFunctionType(IterableOfListOfdouble(), [IterableOfListOfdouble()])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  float32x4_list_test.testLoadStore = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(ListOfFloat32x4().is(array));
    dart.dsetindex(array, 0, typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 0), 'w'));
    dart.dsetindex(array, 1, dart.dindex(array, 0));
    dart.dsetindex(array, 0, dart.dsend(dart.dindex(array, 0), 'withX', 9.0));
    expect$.Expect.equals(9.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(float32x4_list_test.testLoadStore, dynamicTodynamic());
  float32x4_list_test.testLoadStoreDeopt = function(array, index, value) {
    dart.dsetindex(array, index, value);
    expect$.Expect.equals(dart.dload(value, 'x'), dart.dload(dart.dindex(array, index), 'x'));
    expect$.Expect.equals(dart.dload(value, 'y'), dart.dload(dart.dindex(array, index), 'y'));
    expect$.Expect.equals(dart.dload(value, 'z'), dart.dload(dart.dindex(array, index), 'z'));
    expect$.Expect.equals(dart.dload(value, 'w'), dart.dload(dart.dindex(array, index), 'w'));
  };
  dart.fn(float32x4_list_test.testLoadStoreDeopt, dynamicAnddynamicAnddynamicTodynamic());
  float32x4_list_test.testLoadStoreDeoptDriver = function() {
    let list = typed_data.Float32x4List.new(4);
    let value = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 5, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(null, 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 0, null);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 3.14159, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(list, 0, (4)[dartx.toDouble]());
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      float32x4_list_test.testLoadStoreDeopt(JSArrayOfFloat32x4().of([typed_data.Float32x4.new(2.0, 3.0, 4.0, 5.0)]), 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
  };
  dart.fn(float32x4_list_test.testLoadStoreDeoptDriver, VoidTodynamic());
  float32x4_list_test.testListZero = function() {
    let list = typed_data.Float32x4List.new(1);
    expect$.Expect.equals(0.0, list.get(0).x);
    expect$.Expect.equals(0.0, list.get(0).y);
    expect$.Expect.equals(0.0, list.get(0).z);
    expect$.Expect.equals(0.0, list.get(0).w);
  };
  dart.fn(float32x4_list_test.testListZero, VoidTodynamic());
  float32x4_list_test.testView = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(ListOfFloat32x4().is(array));
    expect$.Expect.equals(0.0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(5.0, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(6.0, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(7.0, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(float32x4_list_test.testView, dynamicTodynamic());
  float32x4_list_test.testSublist = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(typed_data.Float32x4List.is(array));
    let a = dart.dsend(array, 'sublist', 0, 1);
    expect$.Expect.equals(1, dart.dload(a, 'length'));
    expect$.Expect.equals(0.0, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(1.0, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(2.0, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(3.0, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 1, 2);
    expect$.Expect.equals(4.0, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(5.0, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(6.0, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(7.0, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 0);
    expect$.Expect.equals(dart.dload(a, 'length'), dart.dload(array, 'length'));
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(array, 'length'))); i++) {
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'x'), dart.dload(dart.dindex(a, i), 'x'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'y'), dart.dload(dart.dindex(a, i), 'y'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'z'), dart.dload(dart.dindex(a, i), 'z'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'w'), dart.dload(dart.dindex(a, i), 'w'));
    }
  };
  dart.fn(float32x4_list_test.testSublist, dynamicTodynamic());
  float32x4_list_test.testSpecialValues = function(array) {
    function checkEquals(expected, actual) {
      if (dart.test(dart.dload(expected, 'isNaN'))) {
        expect$.Expect.isTrue(dart.dload(actual, 'isNaN'));
      } else if (dart.equals(expected, 0.0) && dart.test(dart.dload(expected, 'isNegative'))) {
        expect$.Expect.isTrue(dart.equals(actual, 0.0) && dart.test(dart.dload(actual, 'isNegative')));
      } else {
        expect$.Expect.equals(expected, actual);
      }
    }
    dart.fn(checkEquals, dynamicAnddynamicTovoid());
    let pairs = JSArrayOfListOfdouble().of([JSArrayOfdouble().of([0.0, 0.0]), JSArrayOfdouble().of([5e-324, 0.0]), JSArrayOfdouble().of([2.225073858507201e-308, 0.0]), JSArrayOfdouble().of([2.2250738585072014e-308, 0.0]), JSArrayOfdouble().of([0.9999999999999999, 1.0]), JSArrayOfdouble().of([1.0, 1.0]), JSArrayOfdouble().of([1.0000000000000002, 1.0]), JSArrayOfdouble().of([4294967295.0, 4294967296.0]), JSArrayOfdouble().of([4294967296.0, 4294967296.0]), JSArrayOfdouble().of([4503599627370495.5, 4503599627370496.0]), JSArrayOfdouble().of([9007199254740992.0, 9007199254740992.0]), JSArrayOfdouble().of([1.7976931348623157e+308, core.double.INFINITY]), JSArrayOfdouble().of([0.49999999999999994, 0.5]), JSArrayOfdouble().of([4503599627370497.0, 4503599627370496.0]), JSArrayOfdouble().of([9007199254740991.0, 9007199254740992.0]), JSArrayOfdouble().of([core.double.INFINITY, core.double.INFINITY]), JSArrayOfdouble().of([core.double.NAN, core.double.NAN])]);
    let conserved = JSArrayOfdouble().of([1.401298464324817e-45, 1.1754942106924411e-38, 1.1754943508222875e-38, 0.9999999403953552, 1.0000001192092896, 8388607.5, 8388608.0, 3.4028234663852886e+38, 8388609.0, 16777215.0]);
    let minusPairs = pairs[dartx.map](ListOfdouble())(dart.fn(pair => JSArrayOfdouble().of([-dart.notNull(pair[dartx.get](0)), -dart.notNull(pair[dartx.get](1))]), ListOfdoubleToListOfdouble()));
    let conservedPairs = conserved[dartx.map](ListOfdouble())(dart.fn(value => JSArrayOfdouble().of([value, value]), doubleToListOfdouble()));
    let allTests = JSArrayOfIterableOfListOfdouble().of([pairs, minusPairs, conservedPairs])[dartx.expand](ListOfdouble())(dart.fn(x => x, IterableOfListOfdoubleToIterableOfListOfdouble()));
    for (let pair of allTests) {
      let input = pair[dartx.get](0);
      let expected = pair[dartx.get](1);
      let f = null;
      f = typed_data.Float32x4.new(input, 2.0, 3.0, 4.0);
      dart.dsetindex(array, 0, f);
      f = dart.dindex(array, 0);
      checkEquals(expected, dart.dload(f, 'x'));
      expect$.Expect.equals(2.0, dart.dload(f, 'y'));
      expect$.Expect.equals(3.0, dart.dload(f, 'z'));
      expect$.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, input, 3.0, 4.0);
      dart.dsetindex(array, 1, f);
      f = dart.dindex(array, 1);
      expect$.Expect.equals(1.0, dart.dload(f, 'x'));
      checkEquals(expected, dart.dload(f, 'y'));
      expect$.Expect.equals(3.0, dart.dload(f, 'z'));
      expect$.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, 2.0, input, 4.0);
      dart.dsetindex(array, 2, f);
      f = dart.dindex(array, 2);
      expect$.Expect.equals(1.0, dart.dload(f, 'x'));
      expect$.Expect.equals(2.0, dart.dload(f, 'y'));
      checkEquals(expected, dart.dload(f, 'z'));
      expect$.Expect.equals(4.0, dart.dload(f, 'w'));
      f = typed_data.Float32x4.new(1.0, 2.0, 3.0, input);
      dart.dsetindex(array, 3, f);
      f = dart.dindex(array, 3);
      expect$.Expect.equals(1.0, dart.dload(f, 'x'));
      expect$.Expect.equals(2.0, dart.dload(f, 'y'));
      expect$.Expect.equals(3.0, dart.dload(f, 'z'));
      checkEquals(expected, dart.dload(f, 'w'));
    }
  };
  dart.fn(float32x4_list_test.testSpecialValues, dynamicTovoid());
  float32x4_list_test.main = function() {
    let list = null;
    list = typed_data.Float32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStore(list);
    }
    let floatList = typed_data.Float32List.new(32);
    for (let i = 0; i < dart.notNull(floatList[dartx.length]); i++) {
      floatList[dartx.set](i, i[dartx.toDouble]());
    }
    list = typed_data.Float32x4List.view(floatList[dartx.buffer]);
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testView(list);
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testSublist(list);
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testListZero();
    }
    for (let i = 0; i < 20; i++) {
      float32x4_list_test.testSpecialValues(list);
    }
    float32x4_list_test.testLoadStoreDeoptDriver();
  };
  dart.fn(float32x4_list_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_list_test = float32x4_list_test;
});
