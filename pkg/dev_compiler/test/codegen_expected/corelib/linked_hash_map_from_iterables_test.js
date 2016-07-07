dart_library.library('corelib/linked_hash_map_from_iterables_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__linked_hash_map_from_iterables_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const linked_hash_map_from_iterables_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let LinkedHashMapOfint$String = () => (LinkedHashMapOfint$String = dart.constFn(collection.LinkedHashMap$(core.int, core.String)))();
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let LinkedHashMapOfString$dynamic = () => (LinkedHashMapOfString$dynamic = dart.constFn(collection.LinkedHashMap$(core.String, dart.dynamic)))();
  let LinkedHashMapOfdynamic$int = () => (LinkedHashMapOfdynamic$int = dart.constFn(collection.LinkedHashMap$(dart.dynamic, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToLinkedHashMap = () => (VoidToLinkedHashMap = dart.constFn(dart.definiteFunctionType(collection.LinkedHashMap, [])))();
  linked_hash_map_from_iterables_test.main = function() {
    linked_hash_map_from_iterables_test.positiveTest();
    linked_hash_map_from_iterables_test.emptyMapTest();
    linked_hash_map_from_iterables_test.fewerKeysIterableTest();
    linked_hash_map_from_iterables_test.fewerValuesIterableTest();
    linked_hash_map_from_iterables_test.equalElementsTest();
    linked_hash_map_from_iterables_test.genericTypeTest();
  };
  dart.fn(linked_hash_map_from_iterables_test.main, VoidTodynamic());
  linked_hash_map_from_iterables_test.positiveTest = function() {
    let map = collection.LinkedHashMap.fromIterables(JSArrayOfint().of([1, 2, 3]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals("one", map.get(1));
    expect$.Expect.equals("two", map.get(2));
    expect$.Expect.equals("three", map.get(3));
  };
  dart.fn(linked_hash_map_from_iterables_test.positiveTest, VoidTovoid());
  linked_hash_map_from_iterables_test.emptyMapTest = function() {
    let map = collection.LinkedHashMap.fromIterables([], []);
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(map));
    expect$.Expect.equals(0, map.length);
    expect$.Expect.equals(0, map.keys[dartx.length]);
    expect$.Expect.equals(0, map.values[dartx.length]);
  };
  dart.fn(linked_hash_map_from_iterables_test.emptyMapTest, VoidTovoid());
  linked_hash_map_from_iterables_test.fewerValuesIterableTest = function() {
    expect$.Expect.throws(dart.fn(() => collection.LinkedHashMap.fromIterables(JSArrayOfint().of([1, 2]), JSArrayOfint().of([0])), VoidToLinkedHashMap()));
  };
  dart.fn(linked_hash_map_from_iterables_test.fewerValuesIterableTest, VoidTovoid());
  linked_hash_map_from_iterables_test.fewerKeysIterableTest = function() {
    expect$.Expect.throws(dart.fn(() => collection.LinkedHashMap.fromIterables(JSArrayOfint().of([1]), JSArrayOfint().of([0, 2])), VoidToLinkedHashMap()));
  };
  dart.fn(linked_hash_map_from_iterables_test.fewerKeysIterableTest, VoidTovoid());
  linked_hash_map_from_iterables_test.equalElementsTest = function() {
    let map = collection.LinkedHashMap.fromIterables(JSArrayOfint().of([1, 2, 2]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(map));
    expect$.Expect.equals(2, map.length);
    expect$.Expect.equals(2, map.keys[dartx.length]);
    expect$.Expect.equals(2, map.values[dartx.length]);
    expect$.Expect.equals("one", map.get(1));
    expect$.Expect.equals("three", map.get(2));
  };
  dart.fn(linked_hash_map_from_iterables_test.equalElementsTest, VoidTovoid());
  linked_hash_map_from_iterables_test.genericTypeTest = function() {
    let map = LinkedHashMapOfint$String().fromIterables(JSArrayOfint().of([1, 2, 3]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(MapOfint$String().is(map));
    expect$.Expect.isTrue(LinkedHashMapOfint$String().is(map));
    expect$.Expect.isFalse(LinkedHashMapOfString$dynamic().is(map));
    expect$.Expect.isFalse(LinkedHashMapOfdynamic$int().is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals("one", map.get(1));
    expect$.Expect.equals("two", map.get(2));
    expect$.Expect.equals("three", map.get(3));
  };
  dart.fn(linked_hash_map_from_iterables_test.genericTypeTest, VoidTovoid());
  // Exports:
  exports.linked_hash_map_from_iterables_test = linked_hash_map_from_iterables_test;
});
