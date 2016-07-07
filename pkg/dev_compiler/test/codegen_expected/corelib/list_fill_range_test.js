dart_library.library('corelib/list_fill_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_fill_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_fill_range_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListAndintAndint__Todynamic = () => (ListAndintAndint__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List, core.int, core.int], [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  list_fill_range_test.test = function(list, start, end, fillValue) {
    if (fillValue === void 0) fillValue = null;
    let copy = list[dartx.toList]();
    list[dartx.fillRange](start, end, fillValue);
    expect$.Expect.equals(copy[dartx.length], list[dartx.length]);
    for (let i = 0; i < dart.notNull(start); i++) {
      expect$.Expect.equals(copy[dartx.get](i), list[dartx.get](i));
    }
    for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
      expect$.Expect.equals(fillValue, list[dartx.get](i));
    }
    for (let i = end; dart.notNull(i) < dart.notNull(list[dartx.length]); i = dart.notNull(i) + 1) {
      expect$.Expect.equals(copy[dartx.get](i), list[dartx.get](i));
    }
  };
  dart.fn(list_fill_range_test.test, ListAndintAndint__Todynamic());
  list_fill_range_test.MyList = class MyList extends collection.ListBase {
    new(list) {
      this.list = list;
    }
    get length() {
      return this.list[dartx.length];
    }
    set length(value) {
      this.list[dartx.length] = value;
    }
    get(index) {
      return this.list[dartx.get](index);
    }
    set(index, val) {
      this.list[dartx.set](index, val);
      return val;
    }
    toString() {
      return dart.toString(this.list);
    }
  };
  dart.addSimpleTypeTests(list_fill_range_test.MyList);
  dart.setSignature(list_fill_range_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(list_fill_range_test.MyList, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_fill_range_test.MyList, [
    'get',
    'set',
    'toString',
    'length',
    'length'
  ]);
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  list_fill_range_test.main = function() {
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 1);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 1, 99);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 1);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 1, 499);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 3, 3);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 3, 3, 499);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 0, 1);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 0, 1, 99);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, 1);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, 1, 499);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 3, 3);
    list_fill_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 3, 3, 499);
    list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 1);
    list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 1, 99);
    list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 1);
    list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 1, 499);
    list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, 3);
    list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, 3, 499);
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), -1, 0), VoidTodynamic()));
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 1), VoidTodynamic()));
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, -1), VoidTodynamic()));
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 4), VoidTodynamic()));
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), -1, 0), VoidTodynamic()));
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 1), VoidTodynamic()));
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, -1), VoidTodynamic()));
    list_fill_range_test.expectRE(dart.fn(() => list_fill_range_test.test(new list_fill_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 4), VoidTodynamic()));
    list_fill_range_test.expectUE(dart.fn(() => list_fill_range_test.test(const$ || (const$ = dart.constList([1, 2, 3], core.int)), 2, 3), VoidTodynamic()));
    list_fill_range_test.expectUE(dart.fn(() => list_fill_range_test.test(const$0 || (const$0 = dart.constList([1, 2, 3], core.int)), -1, 0), VoidTodynamic()));
    list_fill_range_test.expectUE(dart.fn(() => list_fill_range_test.test(const$1 || (const$1 = dart.constList([1, 2, 3], core.int)), 2, 1), VoidTodynamic()));
    list_fill_range_test.expectUE(dart.fn(() => list_fill_range_test.test(const$2 || (const$2 = dart.constList([1, 2, 3], core.int)), 0, -1), VoidTodynamic()));
    list_fill_range_test.expectUE(dart.fn(() => list_fill_range_test.test(const$3 || (const$3 = dart.constList([1, 2, 3], core.int)), 1, 4), VoidTodynamic()));
  };
  dart.fn(list_fill_range_test.main, VoidTodynamic());
  list_fill_range_test.expectRE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(list_fill_range_test.expectRE, FunctionTovoid());
  list_fill_range_test.expectUE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(list_fill_range_test.expectUE, FunctionTovoid());
  // Exports:
  exports.list_fill_range_test = list_fill_range_test;
});
