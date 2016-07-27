dart_library.library('corelib/splay_tree_from_iterables_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__splay_tree_from_iterables_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const splay_tree_from_iterables_test = Object.create(null);
  let SplayTreeMapOfint$String = () => (SplayTreeMapOfint$String = dart.constFn(collection.SplayTreeMap$(core.int, core.String)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let SplayTreeMapOfint$int = () => (SplayTreeMapOfint$int = dart.constFn(collection.SplayTreeMap$(core.int, core.int)))();
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let SplayTreeMapOfString$dynamic = () => (SplayTreeMapOfString$dynamic = dart.constFn(collection.SplayTreeMap$(core.String, dart.dynamic)))();
  let SplayTreeMapOfdynamic$int = () => (SplayTreeMapOfdynamic$int = dart.constFn(collection.SplayTreeMap$(dart.dynamic, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToSplayTreeMapOfint$int = () => (VoidToSplayTreeMapOfint$int = dart.constFn(dart.definiteFunctionType(SplayTreeMapOfint$int(), [])))();
  splay_tree_from_iterables_test.main = function() {
    splay_tree_from_iterables_test.positiveTest();
    splay_tree_from_iterables_test.emptyMapTest();
    splay_tree_from_iterables_test.fewerKeysIterableTest();
    splay_tree_from_iterables_test.fewerValuesIterableTest();
    splay_tree_from_iterables_test.equalElementsTest();
    splay_tree_from_iterables_test.genericTypeTest();
  };
  dart.fn(splay_tree_from_iterables_test.main, VoidTodynamic());
  splay_tree_from_iterables_test.positiveTest = function() {
    let map = SplayTreeMapOfint$String().fromIterables(JSArrayOfint().of([1, 2, 3]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals("one", map.get(1));
    expect$.Expect.equals("two", map.get(2));
    expect$.Expect.equals("three", map.get(3));
  };
  dart.fn(splay_tree_from_iterables_test.positiveTest, VoidTovoid());
  splay_tree_from_iterables_test.emptyMapTest = function() {
    let map = collection.SplayTreeMap.fromIterables([], []);
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(0, map.length);
    expect$.Expect.equals(0, map.keys[dartx.length]);
    expect$.Expect.equals(0, map.values[dartx.length]);
  };
  dart.fn(splay_tree_from_iterables_test.emptyMapTest, VoidTovoid());
  splay_tree_from_iterables_test.fewerValuesIterableTest = function() {
    expect$.Expect.throws(dart.fn(() => SplayTreeMapOfint$int().fromIterables(JSArrayOfint().of([1, 2]), JSArrayOfint().of([0])), VoidToSplayTreeMapOfint$int()));
  };
  dart.fn(splay_tree_from_iterables_test.fewerValuesIterableTest, VoidTovoid());
  splay_tree_from_iterables_test.fewerKeysIterableTest = function() {
    expect$.Expect.throws(dart.fn(() => SplayTreeMapOfint$int().fromIterables(JSArrayOfint().of([1]), JSArrayOfint().of([0, 2])), VoidToSplayTreeMapOfint$int()));
  };
  dart.fn(splay_tree_from_iterables_test.fewerKeysIterableTest, VoidTovoid());
  splay_tree_from_iterables_test.equalElementsTest = function() {
    let map = SplayTreeMapOfint$String().fromIterables(JSArrayOfint().of([1, 2, 2]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(2, map.length);
    expect$.Expect.equals(2, map.keys[dartx.length]);
    expect$.Expect.equals(2, map.values[dartx.length]);
    expect$.Expect.equals("one", map.get(1));
    expect$.Expect.equals("three", map.get(2));
  };
  dart.fn(splay_tree_from_iterables_test.equalElementsTest, VoidTovoid());
  splay_tree_from_iterables_test.genericTypeTest = function() {
    let map = SplayTreeMapOfint$String().fromIterables(JSArrayOfint().of([1, 2, 3]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(MapOfint$String().is(map));
    expect$.Expect.isTrue(SplayTreeMapOfint$String().is(map));
    expect$.Expect.isFalse(SplayTreeMapOfString$dynamic().is(map));
    expect$.Expect.isFalse(SplayTreeMapOfdynamic$int().is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals("one", map.get(1));
    expect$.Expect.equals("two", map.get(2));
    expect$.Expect.equals("three", map.get(3));
  };
  dart.fn(splay_tree_from_iterables_test.genericTypeTest, VoidTovoid());
  // Exports:
  exports.splay_tree_from_iterables_test = splay_tree_from_iterables_test;
});
