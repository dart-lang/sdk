dart_library.library('corelib/list_remove_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_remove_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_remove_range_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  list_remove_range_test.main = function() {
    let list = [];
    list[dartx.removeRange](0, 0);
    expect$.Expect.equals(0, list[dartx.length]);
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](0, 1);
    }, VoidTodynamic()));
    list[dartx.add](1);
    list[dartx.removeRange](0, 0);
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(1, list[dartx.get](0));
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](0, 2);
    }, VoidTodynamic()));
    expect$.Expect.equals(1, list[dartx.length]);
    expect$.Expect.equals(1, list[dartx.get](0));
    list[dartx.removeRange](0, 1);
    expect$.Expect.equals(0, list[dartx.length]);
    list[dartx.addAll](JSArrayOfint().of([3, 4, 5, 6]));
    expect$.Expect.equals(4, list[dartx.length]);
    list[dartx.removeRange](0, 4);
    expect$.Expect.listEquals([], list);
    list[dartx.addAll](JSArrayOfint().of([3, 4, 5, 6]));
    list[dartx.removeRange](2, 4);
    expect$.Expect.listEquals(JSArrayOfint().of([3, 4]), list);
    list[dartx.addAll](JSArrayOfint().of([5, 6]));
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](4, 5);
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([3, 4, 5, 6]), list);
    list[dartx.removeRange](1, 3);
    expect$.Expect.listEquals(JSArrayOfint().of([3, 6]), list);
    list_remove_range_test.testNegativeIndices();
  };
  dart.fn(list_remove_range_test.main, VoidTodynamic());
  list_remove_range_test.expectIOORE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(list_remove_range_test.expectIOORE, FunctionTovoid());
  list_remove_range_test.testNegativeIndices = function() {
    let list = JSArrayOfint().of([1, 2]);
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](-1, 1);
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2]), list);
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](0, -1);
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2]), list);
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](-1, -1);
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2]), list);
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](-1, 0);
    }, VoidTodynamic()));
    list_remove_range_test.expectIOORE(dart.fn(() => {
      list[dartx.removeRange](4, 4);
    }, VoidTodynamic()));
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2]), list);
  };
  dart.fn(list_remove_range_test.testNegativeIndices, VoidTovoid$());
  // Exports:
  exports.list_remove_range_test = list_remove_range_test;
});
