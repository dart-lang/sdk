dart_library.library('corelib/sort_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__sort_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const sort_test = Object.create(null);
  const sort_helper = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.functionType(core.int, [core.int, core.int])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  sort_test.main = function() {
    let compare = dart.fn((a, b) => dart.dsend(a, 'compareTo', b), dynamicAnddynamicTodynamic());
    let sort = dart.fn(list => dart.dsend(list, 'sort', compare), dynamicTodynamic());
    new sort_helper.SortHelper(sort, compare).run();
    compare = dart.fn((a, b) => dart.dsend(dart.dsend(a, 'compareTo', b), 'unary-'), dynamicAnddynamicTodynamic());
    new sort_helper.SortHelper(sort, compare).run();
    compare = dart.fn((a, b) => dart.dsend(a, 'compareTo', b), dynamicAnddynamicTodynamic());
    let list = JSArrayOfint().of([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
    list[dartx.sort](intAndintToint()._check(compare));
    expect$.Expect.listEquals(list, JSArrayOfint().of([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]));
    list = JSArrayOfint().of([0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
    list[dartx.sort](intAndintToint()._check(compare));
    expect$.Expect.listEquals(list, JSArrayOfint().of([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]));
    list = JSArrayOfint().of([0, 9, 0, 9, 3, 9, 0, 1, 1, 0, 1, 9, 8, 2, 1, 1, 4, 5, 2, 5, 0, 1, 8, 8, 8, 5, 2, 2, 9, 8, 8, 4, 4, 1, 5, 3, 2, 8, 5, 1, 2, 8, 5, 6, 8]);
    list[dartx.sort](intAndintToint()._check(compare));
    expect$.Expect.listEquals(list, JSArrayOfint().of([0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5, 5, 5, 5, 5, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9]));
  };
  dart.fn(sort_test.main, VoidTodynamic());
  sort_helper.SortHelper = class SortHelper extends core.Object {
    new(sortFunction, compareFunction) {
      this.sortFunction = sortFunction;
      this.compareFunction = compareFunction;
    }
    run() {
      this.testSortIntLists();
      this.testSortDoubleLists();
    }
    isSorted(a) {
      for (let i = 1; i < dart.notNull(a[dartx.length]); i++) {
        if (dart.test(dart.dsend(dart.dcall(this.compareFunction, a[dartx.get](i - 1), a[dartx.get](i)), '>', 0))) {
          return false;
        }
      }
      return true;
    }
    testSortIntLists() {
      let a = core.List.new(40);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, i);
      }
      this.testSort(a);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](dart.notNull(a[dartx.length]) - i - 1, i);
      }
      this.testSort(a);
      for (let i = 0; i < 21; i++) {
        a[dartx.set](i, 1);
      }
      for (let i = 21; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, 2);
      }
      this.testSort(a);
      for (let i = 0; i < 21; i++) {
        a[dartx.set](i, 1);
      }
      for (let i = 21; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, 2);
      }
      a[dartx.set](6, 1);
      a[dartx.set](13, 1);
      a[dartx.set](19, 1);
      a[dartx.set](25, 1);
      a[dartx.set](33, 2);
      this.testSort(a);
      for (let i = 0; i < 21; i++) {
        a[dartx.set](i, 2);
      }
      for (let i = 21; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, 1);
      }
      this.testSort(a);
      for (let i = 0; i < 21; i++) {
        a[dartx.set](i, 2);
      }
      for (let i = 21; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, 1);
      }
      a[dartx.set](6, 2);
      a[dartx.set](13, 2);
      a[dartx.set](19, 2);
      a[dartx.set](25, 2);
      a[dartx.set](33, 1);
      this.testSort(a);
      let a2 = core.List.new(0);
      this.testSort(a2);
      let a3 = core.List.new(1);
      a3[dartx.set](0, 1);
      this.testSort(a3);
      this.testInsertionSort(0, 1, 2, 3);
      this.testInsertionSort(0, 1, 3, 2);
      this.testInsertionSort(0, 3, 2, 1);
      this.testInsertionSort(0, 3, 1, 2);
      this.testInsertionSort(0, 2, 1, 3);
      this.testInsertionSort(0, 2, 3, 1);
      this.testInsertionSort(1, 0, 2, 3);
      this.testInsertionSort(1, 0, 3, 2);
      this.testInsertionSort(1, 2, 3, 0);
      this.testInsertionSort(1, 2, 0, 3);
      this.testInsertionSort(1, 3, 2, 0);
      this.testInsertionSort(1, 3, 0, 2);
      this.testInsertionSort(2, 0, 1, 3);
      this.testInsertionSort(2, 0, 3, 1);
      this.testInsertionSort(2, 1, 3, 0);
      this.testInsertionSort(2, 1, 0, 3);
      this.testInsertionSort(2, 3, 1, 0);
      this.testInsertionSort(2, 3, 0, 1);
      this.testInsertionSort(3, 0, 1, 2);
      this.testInsertionSort(3, 0, 2, 1);
      this.testInsertionSort(3, 1, 2, 0);
      this.testInsertionSort(3, 1, 0, 2);
      this.testInsertionSort(3, 2, 1, 0);
      this.testInsertionSort(3, 2, 0, 1);
    }
    testSort(a) {
      dart.dcall(this.sortFunction, a);
      expect$.Expect.isTrue(this.isSorted(a));
    }
    testInsertionSort(i1, i2, i3, i4) {
      let a = core.List.new(4);
      a[dartx.set](0, i1);
      a[dartx.set](1, i2);
      a[dartx.set](2, i3);
      a[dartx.set](3, i4);
      this.testSort(a);
    }
    testSortDoubleLists() {
      let a = core.List.new(40);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, 1.0 * i + 0.5);
      }
      this.testSort(a);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, 1.0 * (dart.notNull(a[dartx.length]) - i) + 0.5);
      }
      this.testSort(a);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        a[dartx.set](i, 1.5);
      }
      this.testSort(a);
    }
  };
  dart.setSignature(sort_helper.SortHelper, {
    constructors: () => ({new: dart.definiteFunctionType(sort_helper.SortHelper, [core.Function, core.Function])}),
    methods: () => ({
      run: dart.definiteFunctionType(dart.void, []),
      isSorted: dart.definiteFunctionType(core.bool, [core.List]),
      testSortIntLists: dart.definiteFunctionType(dart.void, []),
      testSort: dart.definiteFunctionType(dart.void, [core.List]),
      testInsertionSort: dart.definiteFunctionType(dart.void, [core.int, core.int, core.int, core.int]),
      testSortDoubleLists: dart.definiteFunctionType(dart.void, [])
    })
  });
  // Exports:
  exports.sort_test = sort_test;
  exports.sort_helper = sort_helper;
});
