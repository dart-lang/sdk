dart_library.library('corelib/map_from_iterables_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_from_iterables_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_from_iterables_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let MapOfString$dynamic = () => (MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))();
  let MapOfdynamic$int = () => (MapOfdynamic$int = dart.constFn(core.Map$(dart.dynamic, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToMap = () => (VoidToMap = dart.constFn(dart.definiteFunctionType(core.Map, [])))();
  map_from_iterables_test.main = function() {
    map_from_iterables_test.positiveTest();
    map_from_iterables_test.emptyMapTest();
    map_from_iterables_test.fewerKeysIterableTest();
    map_from_iterables_test.fewerValuesIterableTest();
    map_from_iterables_test.equalElementsTest();
    map_from_iterables_test.genericTypeTest();
  };
  dart.fn(map_from_iterables_test.main, VoidTodynamic());
  map_from_iterables_test.positiveTest = function() {
    let map = core.Map.fromIterables(JSArrayOfint().of([1, 2, 3]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(map));
    expect$.Expect.equals(3, map[dartx.length]);
    expect$.Expect.equals(3, map[dartx.keys][dartx.length]);
    expect$.Expect.equals(3, map[dartx.values][dartx.length]);
    expect$.Expect.equals("one", map[dartx.get](1));
    expect$.Expect.equals("two", map[dartx.get](2));
    expect$.Expect.equals("three", map[dartx.get](3));
  };
  dart.fn(map_from_iterables_test.positiveTest, VoidTovoid());
  map_from_iterables_test.emptyMapTest = function() {
    let map = core.Map.fromIterables([], []);
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(map));
    expect$.Expect.equals(0, map[dartx.length]);
    expect$.Expect.equals(0, map[dartx.keys][dartx.length]);
    expect$.Expect.equals(0, map[dartx.values][dartx.length]);
  };
  dart.fn(map_from_iterables_test.emptyMapTest, VoidTovoid());
  map_from_iterables_test.fewerValuesIterableTest = function() {
    expect$.Expect.throws(dart.fn(() => core.Map.fromIterables(JSArrayOfint().of([1, 2]), JSArrayOfint().of([0])), VoidToMap()));
  };
  dart.fn(map_from_iterables_test.fewerValuesIterableTest, VoidTovoid());
  map_from_iterables_test.fewerKeysIterableTest = function() {
    expect$.Expect.throws(dart.fn(() => core.Map.fromIterables(JSArrayOfint().of([1]), JSArrayOfint().of([0, 2])), VoidToMap()));
  };
  dart.fn(map_from_iterables_test.fewerKeysIterableTest, VoidTovoid());
  map_from_iterables_test.equalElementsTest = function() {
    let map = core.Map.fromIterables(JSArrayOfint().of([1, 2, 2]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(map));
    expect$.Expect.equals(2, map[dartx.length]);
    expect$.Expect.equals(2, map[dartx.keys][dartx.length]);
    expect$.Expect.equals(2, map[dartx.values][dartx.length]);
    expect$.Expect.equals("one", map[dartx.get](1));
    expect$.Expect.equals("three", map[dartx.get](2));
  };
  dart.fn(map_from_iterables_test.equalElementsTest, VoidTovoid());
  map_from_iterables_test.genericTypeTest = function() {
    let map = MapOfint$String().fromIterables(JSArrayOfint().of([1, 2, 3]), JSArrayOfString().of(["one", "two", "three"]));
    expect$.Expect.isTrue(MapOfint$String().is(map));
    expect$.Expect.isFalse(MapOfString$dynamic().is(map));
    expect$.Expect.isFalse(MapOfdynamic$int().is(map));
    expect$.Expect.equals(3, map[dartx.length]);
    expect$.Expect.equals(3, map[dartx.keys][dartx.length]);
    expect$.Expect.equals(3, map[dartx.values][dartx.length]);
    expect$.Expect.equals("one", map[dartx.get](1));
    expect$.Expect.equals("two", map[dartx.get](2));
    expect$.Expect.equals("three", map[dartx.get](3));
  };
  dart.fn(map_from_iterables_test.genericTypeTest, VoidTovoid());
  // Exports:
  exports.map_from_iterables_test = map_from_iterables_test;
});
