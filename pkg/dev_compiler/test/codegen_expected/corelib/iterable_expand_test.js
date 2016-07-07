dart_library.library('corelib/iterable_expand_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_expand_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_expand_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicToIterable = () => (dynamicToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [dart.dynamic])))();
  let intToIterable = () => (intToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [core.int])))();
  let intToListOfint = () => (intToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [core.int])))();
  let intToList = () => (intToList = dart.constFn(dart.definiteFunctionType(core.List, [core.int])))();
  let intToIterableOfint = () => (intToIterableOfint = dart.constFn(dart.definiteFunctionType(IterableOfint(), [core.int])))();
  let dynamicToList = () => (dynamicToList = dart.constFn(dart.definiteFunctionType(core.List, [dart.dynamic])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  iterable_expand_test.MyList = class MyList extends collection.ListBase {
    new(list) {
      this.list = list;
    }
    get length() {
      return this.list[dartx.length];
    }
    set length(val) {
      this.list[dartx.length] = val;
    }
    get(index) {
      return this.list[dartx.get](index);
    }
    set(index, val) {
      (() => {
        return this.list[dartx.set](index, val);
      })();
      return val;
    }
    toString() {
      return "[" + dart.notNull(this[dartx.join](", ")) + "]";
    }
  };
  dart.addSimpleTypeTests(iterable_expand_test.MyList);
  dart.setSignature(iterable_expand_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(iterable_expand_test.MyList, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(iterable_expand_test.MyList, [
    'get',
    'set',
    'toString',
    'length',
    'length'
  ]);
  iterable_expand_test.main = function() {
    function test(expectation, iterable) {
      expect$.Expect.listEquals(core.List._check(expectation), core.List._check(dart.dsend(iterable, 'toList')));
    }
    dart.fn(test, dynamicAnddynamicTodynamic());
    test([], [][dartx.expand](dart.dynamic)(dart.fn(x => {
      dart.throw("not called");
    }, dynamicToIterable())));
    JSArrayOfint().of([1])[dartx.expand](dart.dynamic)(dart.fn(x => {
      dart.throw("not called");
    }, intToIterable()));
    test(JSArrayOfint().of([1]), JSArrayOfint().of([1])[dartx.expand](core.int)(dart.fn(x => JSArrayOfint().of([x]), intToListOfint())));
    test(JSArrayOfint().of([1, 2, 3]), JSArrayOfint().of([1, 2, 3])[dartx.expand](core.int)(dart.fn(x => JSArrayOfint().of([x]), intToListOfint())));
    test([], JSArrayOfint().of([1])[dartx.expand](dart.dynamic)(dart.fn(x => [], intToList())));
    test([], JSArrayOfint().of([1, 2, 3])[dartx.expand](dart.dynamic)(dart.fn(x => [], intToList())));
    test(JSArrayOfint().of([2]), JSArrayOfint().of([1, 2, 3])[dartx.expand](dart.dynamic)(dart.fn(x => x == 2 ? JSArrayOfint().of([2]) : [], intToList())));
    test(JSArrayOfint().of([1, 1, 2, 2, 3, 3]), JSArrayOfint().of([1, 2, 3])[dartx.expand](core.int)(dart.fn(x => JSArrayOfint().of([x, x]), intToListOfint())));
    test(JSArrayOfint().of([1, 1, 2]), JSArrayOfint().of([1, 2, 3])[dartx.expand](core.int)(dart.fn(x => JSArrayOfint().of([x, x, x])[dartx.skip](x), intToIterableOfint())));
    test(JSArrayOfint().of([1]), new iterable_expand_test.MyList(JSArrayOfint().of([1])).expand(dart.dynamic)(dart.fn(x => [x], dynamicToList())));
    test(JSArrayOfint().of([1, 2, 3]), new iterable_expand_test.MyList(JSArrayOfint().of([1, 2, 3])).expand(dart.dynamic)(dart.fn(x => [x], dynamicToList())));
    test([], new iterable_expand_test.MyList(JSArrayOfint().of([1])).expand(dart.dynamic)(dart.fn(x => [], dynamicToList())));
    test([], new iterable_expand_test.MyList(JSArrayOfint().of([1, 2, 3])).expand(dart.dynamic)(dart.fn(x => [], dynamicToList())));
    test(JSArrayOfint().of([2]), new iterable_expand_test.MyList(JSArrayOfint().of([1, 2, 3])).expand(dart.dynamic)(dart.fn(x => dart.equals(x, 2) ? JSArrayOfint().of([2]) : [], dynamicToList())));
    test(JSArrayOfint().of([1, 1, 2, 2, 3, 3]), new iterable_expand_test.MyList(JSArrayOfint().of([1, 2, 3])).expand(dart.dynamic)(dart.fn(x => [x, x], dynamicToList())));
    test(JSArrayOfint().of([1, 1, 2]), new iterable_expand_test.MyList(JSArrayOfint().of([1, 2, 3])).expand(dart.dynamic)(dart.fn(x => [x, x, x][dartx.skip](core.int._check(x)), dynamicToIterable())));
    let iterable = JSArrayOfint().of([1, 2, 3])[dartx.expand](dart.dynamic)(dart.fn(x => {
      if (x == 2) dart.throw("FAIL");
      return JSArrayOfint().of([x, x]);
    }, intToIterable()));
    let it = iterable[dartx.iterator];
    expect$.Expect.isTrue(it.moveNext());
    expect$.Expect.equals(1, it.current);
    expect$.Expect.isTrue(it.moveNext());
    expect$.Expect.equals(1, it.current);
    expect$.Expect.throws(dart.bind(it, 'moveNext'), dart.fn(e => dart.equals(e, "FAIL"), dynamicTobool()));
    expect$.Expect.equals(null, it.current);
    expect$.Expect.isFalse(it.moveNext());
  };
  dart.fn(iterable_expand_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_expand_test = iterable_expand_test;
});
