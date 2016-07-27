dart_library.library('corelib/list_removeat_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_removeat_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_removeat_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  list_removeat_test.MyList = class MyList extends collection.ListBase {
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
  dart.addSimpleTypeTests(list_removeat_test.MyList);
  dart.setSignature(list_removeat_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(list_removeat_test.MyList, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_removeat_test.MyList, [
    'get',
    'set',
    'toString',
    'length',
    'length'
  ]);
  list_removeat_test.testModifiableList = function(l1) {
    let checkedMode = false;
    dart.assert(checkedMode = true);
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'removeAt', -1);
    }, VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()), "negative");
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'removeAt', 5);
    }, VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()), "too large");
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'removeAt', null);
    }, VoidTovoid()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()), "too large");
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'removeAt', "1");
    }, VoidTovoid()), dart.fn(e => checkedMode ? core.TypeError.is(e) : core.ArgumentError.is(e), dynamicTobool()), "string");
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'removeAt', 1.5);
    }, VoidTovoid()), dart.fn(e => checkedMode ? core.TypeError.is(e) : core.ArgumentError.is(e), dynamicTobool()), "double");
    expect$.Expect.equals(2, dart.dsend(l1, 'removeAt', 2), "l1-remove2");
    expect$.Expect.equals(1, dart.dindex(l1, 1), "l1-1[1]");
    expect$.Expect.equals(3, dart.dindex(l1, 2), "l1-1[2]");
    expect$.Expect.equals(4, dart.dindex(l1, 3), "l1-1[3]");
    expect$.Expect.equals(4, dart.dload(l1, 'length'), "length-1");
    expect$.Expect.equals(0, dart.dsend(l1, 'removeAt', 0), "l1-remove0");
    expect$.Expect.equals(1, dart.dindex(l1, 0), "l1-2[0]");
    expect$.Expect.equals(3, dart.dindex(l1, 1), "l1-2[1]");
    expect$.Expect.equals(4, dart.dindex(l1, 2), "l1-2[2]");
    expect$.Expect.equals(3, dart.dload(l1, 'length'), "length-2");
  };
  dart.fn(list_removeat_test.testModifiableList, dynamicTovoid());
  let const$;
  list_removeat_test.main = function() {
    list_removeat_test.testModifiableList(JSArrayOfint().of([0, 1, 2, 3, 4]));
    list_removeat_test.testModifiableList(new list_removeat_test.MyList(JSArrayOfint().of([0, 1, 2, 3, 4])));
    let l2 = core.List.new(5);
    for (let i = 0; i < 5; i++)
      l2[dartx.set](i, i);
    expect$.Expect.throws(dart.fn(() => {
      l2[dartx.removeAt](2);
    }, VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()), "fixed-length");
    let l3 = const$ || (const$ = dart.constList([0, 1, 2, 3, 4], core.int));
    expect$.Expect.throws(dart.fn(() => {
      l3[dartx.removeAt](2);
    }, VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()), "unmodifiable");
    let l4 = [];
    expect$.Expect.throws(dart.fn(() => {
      l4[dartx.removeAt](0);
    }, VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()), "empty");
  };
  dart.fn(list_removeat_test.main, VoidTovoid());
  // Exports:
  exports.list_removeat_test = list_removeat_test;
});
