dart_library.library('lib/typed_data/int32x4_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int32x4_list_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_list_test = Object.create(null);
  let ListOfInt32x4 = () => (ListOfInt32x4 = dart.constFn(core.List$(typed_data.Int32x4)))();
  let JSArrayOfInt32x4 = () => (JSArrayOfInt32x4 = dart.constFn(_interceptors.JSArray$(typed_data.Int32x4)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  int32x4_list_test.testLoadStore = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(ListOfInt32x4().is(array));
    dart.dsetindex(array, 0, typed_data.Int32x4.new(1, 2, 3, 4));
    expect$.Expect.equals(1, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 0), 'w'));
    dart.dsetindex(array, 1, dart.dindex(array, 0));
    dart.dsetindex(array, 0, dart.dsend(dart.dindex(array, 0), 'withX', 9));
    expect$.Expect.equals(9, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(1, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(int32x4_list_test.testLoadStore, dynamicTodynamic());
  int32x4_list_test.testLoadStoreDeopt = function(array, index, value) {
    dart.dsetindex(array, index, value);
    expect$.Expect.equals(dart.dload(value, 'x'), dart.dload(dart.dindex(array, index), 'x'));
    expect$.Expect.equals(dart.dload(value, 'y'), dart.dload(dart.dindex(array, index), 'y'));
    expect$.Expect.equals(dart.dload(value, 'z'), dart.dload(dart.dindex(array, index), 'z'));
    expect$.Expect.equals(dart.dload(value, 'w'), dart.dload(dart.dindex(array, index), 'w'));
  };
  dart.fn(int32x4_list_test.testLoadStoreDeopt, dynamicAnddynamicAnddynamicTodynamic());
  int32x4_list_test.testLoadStoreDeoptDriver = function() {
    let list = typed_data.Int32x4List.new(4);
    let value = typed_data.Int32x4.new(1, 2, 3, 4);
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 5, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(null, 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 0, null);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 3.14159, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(list, 0, (4)[dartx.toDouble]());
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
    try {
      int32x4_list_test.testLoadStoreDeopt(JSArrayOfInt32x4().of([typed_data.Int32x4.new(2, 3, 4, 5)]), 0, value);
    } catch (_) {
    }

    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStoreDeopt(list, 0, value);
    }
  };
  dart.fn(int32x4_list_test.testLoadStoreDeoptDriver, VoidTodynamic());
  int32x4_list_test.testListZero = function() {
    let list = typed_data.Int32x4List.new(1);
    expect$.Expect.equals(0, list.get(0).x);
    expect$.Expect.equals(0, list.get(0).y);
    expect$.Expect.equals(0, list.get(0).z);
    expect$.Expect.equals(0, list.get(0).w);
  };
  dart.fn(int32x4_list_test.testListZero, VoidTodynamic());
  int32x4_list_test.testView = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(ListOfInt32x4().is(array));
    expect$.Expect.equals(0, dart.dload(dart.dindex(array, 0), 'x'));
    expect$.Expect.equals(1, dart.dload(dart.dindex(array, 0), 'y'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(array, 0), 'z'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(array, 0), 'w'));
    expect$.Expect.equals(4, dart.dload(dart.dindex(array, 1), 'x'));
    expect$.Expect.equals(5, dart.dload(dart.dindex(array, 1), 'y'));
    expect$.Expect.equals(6, dart.dload(dart.dindex(array, 1), 'z'));
    expect$.Expect.equals(7, dart.dload(dart.dindex(array, 1), 'w'));
  };
  dart.fn(int32x4_list_test.testView, dynamicTodynamic());
  int32x4_list_test.testSublist = function(array) {
    expect$.Expect.equals(8, dart.dload(array, 'length'));
    expect$.Expect.isTrue(typed_data.Int32x4List.is(array));
    let a = dart.dsend(array, 'sublist', 0, 1);
    expect$.Expect.equals(1, dart.dload(a, 'length'));
    expect$.Expect.equals(0, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(1, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(2, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(3, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 1, 2);
    expect$.Expect.equals(4, dart.dload(dart.dindex(a, 0), 'x'));
    expect$.Expect.equals(5, dart.dload(dart.dindex(a, 0), 'y'));
    expect$.Expect.equals(6, dart.dload(dart.dindex(a, 0), 'z'));
    expect$.Expect.equals(7, dart.dload(dart.dindex(a, 0), 'w'));
    a = dart.dsend(array, 'sublist', 0);
    expect$.Expect.equals(dart.dload(a, 'length'), dart.dload(array, 'length'));
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(array, 'length'))); i++) {
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'x'), dart.dload(dart.dindex(a, i), 'x'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'y'), dart.dload(dart.dindex(a, i), 'y'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'z'), dart.dload(dart.dindex(a, i), 'z'));
      expect$.Expect.equals(dart.dload(dart.dindex(array, i), 'w'), dart.dload(dart.dindex(a, i), 'w'));
    }
  };
  dart.fn(int32x4_list_test.testSublist, dynamicTodynamic());
  int32x4_list_test.testSpecialValues = function(array) {
    let tests = JSArrayOfListOfint().of([JSArrayOfint().of([2410207675578512, 878082192]), JSArrayOfint().of([2410209554626704, -1537836912]), JSArrayOfint().of([2147483648, -2147483648]), JSArrayOfint().of([-2147483648, -2147483648]), JSArrayOfint().of([2147483647, 2147483647]), JSArrayOfint().of([-2147483647, -2147483647])]);
    let int32x4 = null;
    for (let test of tests) {
      let input = test[dartx.get](0);
      let expected = test[dartx.get](1);
      int32x4 = typed_data.Int32x4.new(input, 2, 3, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(expected, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, input, 3, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(expected, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, 2, input, 4);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(expected, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(4, dart.dload(int32x4, 'w'));
      int32x4 = typed_data.Int32x4.new(1, 2, 3, input);
      dart.dsetindex(array, 0, int32x4);
      int32x4 = dart.dindex(array, 0);
      expect$.Expect.equals(1, dart.dload(int32x4, 'x'));
      expect$.Expect.equals(2, dart.dload(int32x4, 'y'));
      expect$.Expect.equals(3, dart.dload(int32x4, 'z'));
      expect$.Expect.equals(expected, dart.dload(int32x4, 'w'));
    }
  };
  dart.fn(int32x4_list_test.testSpecialValues, dynamicTovoid());
  int32x4_list_test.main = function() {
    let list = null;
    list = typed_data.Int32x4List.new(8);
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testSpecialValues(list);
    }
    let uint32List = typed_data.Uint32List.new(32);
    for (let i = 0; i < dart.notNull(uint32List[dartx.length]); i++) {
      uint32List[dartx.set](i, i);
    }
    list = typed_data.Int32x4List.view(uint32List[dartx.buffer]);
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testView(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testSublist(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testLoadStore(list);
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testListZero();
    }
    for (let i = 0; i < 20; i++) {
      int32x4_list_test.testSpecialValues(list);
    }
    int32x4_list_test.testLoadStoreDeoptDriver();
  };
  dart.fn(int32x4_list_test.main, VoidTodynamic());
  // Exports:
  exports.int32x4_list_test = int32x4_list_test;
});
