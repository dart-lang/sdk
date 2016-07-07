dart_library.library('corelib/map_from_iterable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_from_iterable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_from_iterable_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let HashMapOfString$String = () => (HashMapOfString$String = dart.constFn(collection.HashMap$(core.String, core.String)))();
  let MapOfString$String = () => (MapOfString$String = dart.constFn(core.Map$(core.String, core.String)))();
  let MapOfint$dynamic = () => (MapOfint$dynamic = dart.constFn(core.Map$(core.int, dart.dynamic)))();
  let MapOfdynamic$int = () => (MapOfdynamic$int = dart.constFn(core.Map$(dart.dynamic, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  map_from_iterable_test.main = function() {
    map_from_iterable_test.defaultFunctionValuesTest();
    map_from_iterable_test.defaultKeyFunctionTest();
    map_from_iterable_test.defaultValueFunctionTest();
    map_from_iterable_test.noDefaultValuesTest();
    map_from_iterable_test.emptyIterableTest();
    map_from_iterable_test.equalElementsTest();
    map_from_iterable_test.genericTypeTest();
  };
  dart.fn(map_from_iterable_test.main, VoidTodynamic());
  map_from_iterable_test.defaultFunctionValuesTest = function() {
    let map = collection.HashMap.fromIterable(JSArrayOfint().of([1, 2, 3]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(1, map.get(1));
    expect$.Expect.equals(2, map.get(2));
    expect$.Expect.equals(3, map.get(3));
  };
  dart.fn(map_from_iterable_test.defaultFunctionValuesTest, VoidTovoid());
  map_from_iterable_test.defaultKeyFunctionTest = function() {
    let map = collection.HashMap.fromIterable(JSArrayOfint().of([1, 2, 3]), {value: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(2, map.get(1));
    expect$.Expect.equals(3, map.get(2));
    expect$.Expect.equals(4, map.get(3));
  };
  dart.fn(map_from_iterable_test.defaultKeyFunctionTest, VoidTovoid());
  map_from_iterable_test.defaultValueFunctionTest = function() {
    let map = collection.HashMap.fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(1, map.get(2));
    expect$.Expect.equals(2, map.get(3));
    expect$.Expect.equals(3, map.get(4));
  };
  dart.fn(map_from_iterable_test.defaultValueFunctionTest, VoidTovoid());
  map_from_iterable_test.noDefaultValuesTest = function() {
    let map = collection.HashMap.fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic()), value: dart.fn(x => dart.dsend(x, '-', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(0, map.get(2));
    expect$.Expect.equals(1, map.get(3));
    expect$.Expect.equals(2, map.get(4));
  };
  dart.fn(map_from_iterable_test.noDefaultValuesTest, VoidTovoid());
  map_from_iterable_test.emptyIterableTest = function() {
    let map = collection.HashMap.fromIterable([]);
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.HashMap.is(map));
    expect$.Expect.equals(0, map.length);
    expect$.Expect.equals(0, map.keys[dartx.length]);
    expect$.Expect.equals(0, map.values[dartx.length]);
  };
  dart.fn(map_from_iterable_test.emptyIterableTest, VoidTovoid());
  map_from_iterable_test.equalElementsTest = function() {
    let map = collection.HashMap.fromIterable(JSArrayOfint().of([1, 2, 2]), {key: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.HashMap.is(map));
    expect$.Expect.equals(2, map.length);
    expect$.Expect.equals(2, map.keys[dartx.length]);
    expect$.Expect.equals(2, map.values[dartx.length]);
    expect$.Expect.equals(1, map.get(2));
    expect$.Expect.equals(2, map.get(3));
  };
  dart.fn(map_from_iterable_test.equalElementsTest, VoidTovoid());
  map_from_iterable_test.genericTypeTest = function() {
    let map = HashMapOfString$String().fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dart.fn(x => dart.str`${x}`, dynamicToString()), value: dart.fn(x => dart.str`${x}`, dynamicToString())});
    expect$.Expect.isTrue(MapOfString$String().is(map));
    expect$.Expect.isFalse(MapOfint$dynamic().is(map));
    expect$.Expect.isFalse(MapOfdynamic$int().is(map));
  };
  dart.fn(map_from_iterable_test.genericTypeTest, VoidTovoid());
  // Exports:
  exports.map_from_iterable_test = map_from_iterable_test;
});
