dart_library.library('corelib/list_for_each_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_for_each_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_for_each_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_for_each_test.MyList = class MyList extends collection.ListBase {
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
  dart.addSimpleTypeTests(list_for_each_test.MyList);
  dart.setSignature(list_for_each_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(list_for_each_test.MyList, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_for_each_test.MyList, [
    'get',
    'set',
    'toString',
    'length',
    'length'
  ]);
  list_for_each_test.testWithoutModification = function(list) {
    let seen = [];
    list[dartx.forEach](dart.bind(seen, dartx.add));
    expect$.Expect.listEquals(list, seen);
  };
  dart.fn(list_for_each_test.testWithoutModification, ListTovoid());
  list_for_each_test.testWithModification = function(list) {
    if (dart.test(list[dartx.isEmpty])) return;
    expect$.Expect.throws(dart.fn(() => list[dartx.forEach](dart.fn(_ => list[dartx.add](0), dynamicTovoid())), VoidTovoid()), dart.fn(e => core.ConcurrentModificationError.is(e), dynamicTobool()));
  };
  dart.fn(list_for_each_test.testWithModification, ListTovoid());
  let const$;
  let const$0;
  let const$1;
  list_for_each_test.main = function() {
    let fixedLengthList = core.List.new(10);
    for (let i = 0; i < 10; i++)
      fixedLengthList[dartx.set](i, i + 1);
    let growableList = core.List.new();
    growableList[dartx.length] = 10;
    for (let i = 0; i < 10; i++)
      growableList[dartx.set](i, i + 1);
    let growableLists = JSArrayOfList().of([[], JSArrayOfint().of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]), new list_for_each_test.MyList(JSArrayOfint().of([1, 2, 3, 4, 5])), growableList]);
    let fixedLengthLists = JSArrayOfList().of([const$ || (const$ = dart.constList([], dart.dynamic)), fixedLengthList, const$0 || (const$0 = dart.constList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], core.int)), new list_for_each_test.MyList(const$1 || (const$1 = dart.constList([1, 2], core.int)))]);
    for (let list of growableLists) {
      core.print(list);
      list_for_each_test.testWithoutModification(list);
      list_for_each_test.testWithModification(list);
    }
    for (let list of fixedLengthLists) {
      list_for_each_test.testWithoutModification(list);
    }
  };
  dart.fn(list_for_each_test.main, VoidTodynamic());
  // Exports:
  exports.list_for_each_test = list_for_each_test;
});
