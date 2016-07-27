dart_library.library('corelib/collection_from_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__collection_from_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const collection_from_test = Object.create(null);
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let QueueOfint = () => (QueueOfint = dart.constFn(collection.Queue$(core.int)))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  collection_from_test.CollectionFromTest = class CollectionFromTest extends core.Object {
    static testMain() {
      let set = SetOfint().new();
      set.add(1);
      set.add(2);
      set.add(4);
      collection_from_test.CollectionFromTest.check(set, ListOfint().from(set));
      collection_from_test.CollectionFromTest.check(set, core.List.from(set));
      collection_from_test.CollectionFromTest.check(set, QueueOfint().from(set));
      collection_from_test.CollectionFromTest.check(set, collection.Queue.from(set));
      collection_from_test.CollectionFromTest.check(set, SetOfint().from(set));
      collection_from_test.CollectionFromTest.check(set, SetOfint().from(set));
    }
    static check(initial, other) {
      expect$.Expect.equals(3, initial[dartx.length]);
      expect$.Expect.equals(initial[dartx.length], other[dartx.length]);
      let initialSum = 0;
      let otherSum = 0;
      initial[dartx.forEach](dart.fn(e => {
        initialSum = dart.notNull(initialSum) + dart.notNull(core.int._check(e));
      }, dynamicTovoid()));
      other[dartx.forEach](dart.fn(e => {
        otherSum = dart.notNull(otherSum) + dart.notNull(core.int._check(e));
      }, dynamicTovoid()));
      expect$.Expect.equals(4 + 2 + 1, otherSum);
      expect$.Expect.equals(otherSum, initialSum);
    }
  };
  dart.setSignature(collection_from_test.CollectionFromTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      check: dart.definiteFunctionType(dart.dynamic, [core.Iterable, core.Iterable])
    }),
    names: ['testMain', 'check']
  });
  collection_from_test.main = function() {
    collection_from_test.CollectionFromTest.testMain();
  };
  dart.fn(collection_from_test.main, VoidTodynamic());
  // Exports:
  exports.collection_from_test = collection_from_test;
});
