dart_library.library('corelib/list_set_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_set_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_set_range_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let const$;
  let const$0;
  let const$1;
  let const$2;
  list_set_range_test.main = function() {
    let list = [];
    list[dartx.setRange](0, 0, const$ || (const$ = dart.constList([], dart.dynamic)));
    list[dartx.setRange](0, 0, []);
    list[dartx.setRange](0, 0, const$0 || (const$0 = dart.constList([], dart.dynamic)), 1);
    list[dartx.setRange](0, 0, [], 1);
    expect$.Expect.equals(0, list[dartx.length]);
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](0, 1, []);
    }, VoidTodynamic()));
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](0, 1, [], 1);
    }, VoidTodynamic()));
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](0, 1, JSArrayOfint().of([1]), 0);
    }, VoidTodynamic()));
    list[dartx.add](1);
    list[dartx.setRange](0, 0, [], 0);
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(1, list[dartx.get](0));
    list[dartx.setRange](0, 0, const$1 || (const$1 = dart.constList([], dart.dynamic)), 0);
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(1, list[dartx.get](0));
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](0, 2, JSArrayOfint().of([1, 2]));
    }, VoidTodynamic()));
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(1, list[dartx.get](0));
    list_set_range_test.expectSE(dart.fn(() => {
      list[dartx.setRange](0, 1, JSArrayOfint().of([1, 2]), 2);
    }, VoidTodynamic()));
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(1, list[dartx.get](0));
    list[dartx.setRange](0, 1, JSArrayOfint().of([2]), 0);
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(2, list[dartx.get](0));
    list[dartx.setRange](0, 1, const$2 || (const$2 = dart.constList([3], core.int)), 0);
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(3, list[dartx.get](0));
    list[dartx.addAll](JSArrayOfint().of([4, 5, 6]));
    expect$.Expect.equals(4, list[dartx.length]);
    list[dartx.setRange](0, 4, JSArrayOfint().of([1, 2, 3, 4]));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 3, 4]), list);
    list[dartx.setRange](2, 4, JSArrayOfint().of([5, 6, 7, 8]));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 5, 6]), list);
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](4, 5, JSArrayOfint().of([5, 6, 7, 8]));
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 5, 6]), list);
    list[dartx.setRange](1, 3, JSArrayOfint().of([9, 10, 11, 12]));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 9, 10, 6]), list);
    list_set_range_test.testNegativeIndices();
    list_set_range_test.testNonExtendableList();
  };
  dart.fn(list_set_range_test.main, VoidTodynamic());
  list_set_range_test.expectIOORE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(list_set_range_test.expectIOORE, FunctionTovoid());
  list_set_range_test.expectSE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.StateError.is(e), dynamicTobool()));
  };
  dart.fn(list_set_range_test.expectSE, FunctionTovoid());
  list_set_range_test.expectAE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
  };
  dart.fn(list_set_range_test.expectAE, FunctionTovoid());
  list_set_range_test.testNegativeIndices = function() {
    let list = JSArrayOfint().of([1, 2]);
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](-1, 1, JSArrayOfint().of([1]));
    }, VoidTodynamic()));
    list_set_range_test.expectAE(dart.fn(() => {
      list[dartx.setRange](0, 1, JSArrayOfint().of([1]), -1);
    }, VoidTodynamic()));
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](2, 1, JSArrayOfint().of([1]));
    }, VoidTodynamic()));
    list_set_range_test.expectAE(dart.fn(() => {
      list[dartx.setRange](-1, -2, JSArrayOfint().of([1]), -1);
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2]), list);
    list_set_range_test.expectIOORE(dart.fn(() => {
      list[dartx.setRange](-1, -1, JSArrayOfint().of([1]));
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2]), list);
    list[dartx.setRange](0, 0, JSArrayOfint().of([1]), -1);
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2]), list);
  };
  dart.fn(list_set_range_test.testNegativeIndices, VoidTovoid$());
  list_set_range_test.testNonExtendableList = function() {
    let list = ListOfint().new(6);
    expect$.Expect.listEquals([null, null, null, null, null, null], list);
    list[dartx.setRange](0, 3, JSArrayOfint().of([1, 2, 3, 4]));
    list[dartx.setRange](3, 6, JSArrayOfint().of([1, 2, 3, 4]));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 3, 1, 2, 3]), list);
  };
  dart.fn(list_set_range_test.testNonExtendableList, VoidTovoid$());
  // Exports:
  exports.list_set_range_test = list_set_range_test;
});
