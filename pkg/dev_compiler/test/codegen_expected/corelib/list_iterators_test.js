dart_library.library('corelib/list_iterators_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_iterators_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_iterators_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_iterators_test.ListIteratorsTest = class ListIteratorsTest extends core.Object {
    static checkListIterator(a) {
      let it = a[dartx.iterator];
      expect$.Expect.isNull(it.current);
      for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
        expect$.Expect.isTrue(it.moveNext());
        let elem = it.current;
        expect$.Expect.equals(a[dartx.get](i), elem);
      }
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
    static testMain() {
      list_iterators_test.ListIteratorsTest.checkListIterator([]);
      list_iterators_test.ListIteratorsTest.checkListIterator(JSArrayOfint().of([1, 2]));
      list_iterators_test.ListIteratorsTest.checkListIterator(core.List.new(0));
      list_iterators_test.ListIteratorsTest.checkListIterator(core.List.new(10));
      list_iterators_test.ListIteratorsTest.checkListIterator(core.List.new());
      let g = core.List.new();
      g[dartx.addAll](JSArrayOfint().of([1, 2, 3]));
      list_iterators_test.ListIteratorsTest.checkListIterator(g);
      let it = g[dartx.iterator];
      expect$.Expect.isTrue(it.moveNext());
      expect$.Expect.equals(1, it.current);
      expect$.Expect.isTrue(it.moveNext());
      g[dartx.set](1, 49);
      expect$.Expect.equals(2, it.current);
      expect$.Expect.isTrue(it.moveNext());
      g[dartx.removeLast]();
      expect$.Expect.equals(3, it.current);
      expect$.Expect.throws(dart.bind(it, 'moveNext'), dart.fn(e => core.ConcurrentModificationError.is(e), dynamicTobool()));
      expect$.Expect.equals(3, it.current);
    }
  };
  dart.setSignature(list_iterators_test.ListIteratorsTest, {
    statics: () => ({
      checkListIterator: dart.definiteFunctionType(dart.void, [core.List]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['checkListIterator', 'testMain']
  });
  list_iterators_test.main = function() {
    list_iterators_test.ListIteratorsTest.testMain();
  };
  dart.fn(list_iterators_test.main, VoidTodynamic());
  // Exports:
  exports.list_iterators_test = list_iterators_test;
});
