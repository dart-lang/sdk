dart_library.library('corelib/collection_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__collection_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const collection_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  collection_test.CollectionTest = class CollectionTest extends core.Object {
    new(iterable) {
      this.testFold(iterable);
    }
    testFold(iterable) {
      expect$.Expect.equals(28, iterable[dartx.fold](dart.dynamic)(0, dart.fn((prev, element) => dart.dsend(prev, '+', element), dynamicAnddynamicTodynamic())));
      expect$.Expect.equals(3024, iterable[dartx.fold](dart.dynamic)(1, dart.fn((prev, element) => dart.dsend(prev, '*', element), dynamicAnddynamicTodynamic())));
    }
  };
  dart.setSignature(collection_test.CollectionTest, {
    constructors: () => ({new: dart.definiteFunctionType(collection_test.CollectionTest, [core.Iterable])}),
    methods: () => ({testFold: dart.definiteFunctionType(dart.void, [core.Iterable])})
  });
  let const$;
  collection_test.main = function() {
    let TEST_ELEMENTS = const$ || (const$ = dart.constList([4, 2, 6, 7, 9], core.int));
    new collection_test.CollectionTest(TEST_ELEMENTS);
    let fixedList = core.List.new(TEST_ELEMENTS[dartx.length]);
    for (let i = 0; i < dart.notNull(TEST_ELEMENTS[dartx.length]); i++) {
      fixedList[dartx.set](i, TEST_ELEMENTS[dartx.get](i));
    }
    new collection_test.CollectionTest(fixedList);
    new collection_test.CollectionTest(core.List.from(TEST_ELEMENTS));
    new collection_test.CollectionTest(core.Set.from(TEST_ELEMENTS));
    new collection_test.CollectionTest(collection.Queue.from(TEST_ELEMENTS));
  };
  dart.fn(collection_test.main, VoidTodynamic());
  // Exports:
  exports.collection_test = collection_test;
});
