dart_library.library('corelib/list_insert_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_insert_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_insert_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  list_insert_test.MyList = class MyList extends collection.ListBase {
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
  dart.addSimpleTypeTests(list_insert_test.MyList);
  dart.setSignature(list_insert_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(list_insert_test.MyList, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_insert_test.MyList, [
    'get',
    'set',
    'toString',
    'length',
    'length'
  ]);
  list_insert_test.testModifiableList = function(l1) {
    let checkedMode = false;
    dart.assert(checkedMode = true);
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'insert', -1, 5);
    }, VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()), "negative");
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'insert', 6, 5);
    }, VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()), "too large");
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'insert', null, 5);
    }, VoidTovoid()));
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'insert', "1", 5);
    }, VoidTovoid()));
    expect$.Expect.throws(dart.fn(() => {
      dart.dsend(l1, 'insert', 1.5, 5);
    }, VoidTovoid()));
    dart.dsend(l1, 'insert', 5, 5);
    expect$.Expect.equals(6, dart.dload(l1, 'length'));
    expect$.Expect.equals(5, dart.dindex(l1, 5));
    expect$.Expect.equals("[0, 1, 2, 3, 4, 5]", dart.toString(l1));
    dart.dsend(l1, 'insert', 0, -1);
    expect$.Expect.equals(7, dart.dload(l1, 'length'));
    expect$.Expect.equals(-1, dart.dindex(l1, 0));
    expect$.Expect.equals("[-1, 0, 1, 2, 3, 4, 5]", dart.toString(l1));
  };
  dart.fn(list_insert_test.testModifiableList, dynamicTovoid());
  let const$;
  list_insert_test.main = function() {
    list_insert_test.testModifiableList(JSArrayOfint().of([0, 1, 2, 3, 4]));
    list_insert_test.testModifiableList(new list_insert_test.MyList(JSArrayOfint().of([0, 1, 2, 3, 4])));
    let l2 = core.List.new(5);
    for (let i = 0; i < 5; i++)
      l2[dartx.set](i, i);
    expect$.Expect.throws(dart.fn(() => {
      l2[dartx.insert](2, 5);
    }, VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()), "fixed-length");
    let l3 = const$ || (const$ = dart.constList([0, 1, 2, 3, 4], core.int));
    expect$.Expect.throws(dart.fn(() => {
      l3[dartx.insert](2, 5);
    }, VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()), "unmodifiable");
    let l4 = [];
    l4[dartx.insert](0, 499);
    expect$.Expect.equals(1, l4[dartx.length]);
    expect$.Expect.equals(499, l4[dartx.get](0));
  };
  dart.fn(list_insert_test.main, VoidTovoid());
  // Exports:
  exports.list_insert_test = list_insert_test;
});
