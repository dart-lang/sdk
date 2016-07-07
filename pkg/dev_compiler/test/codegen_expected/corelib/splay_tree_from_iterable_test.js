dart_library.library('corelib/splay_tree_from_iterable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__splay_tree_from_iterable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const splay_tree_from_iterable_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let SplayTreeMapOfint$String = () => (SplayTreeMapOfint$String = dart.constFn(collection.SplayTreeMap$(core.int, core.String)))();
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let SplayTreeMapOfString$dynamic = () => (SplayTreeMapOfString$dynamic = dart.constFn(collection.SplayTreeMap$(core.String, dart.dynamic)))();
  let SplayTreeMapOfdynamic$int = () => (SplayTreeMapOfdynamic$int = dart.constFn(collection.SplayTreeMap$(dart.dynamic, core.int)))();
  let SplayTreeMapOfString$bool = () => (SplayTreeMapOfString$bool = dart.constFn(collection.SplayTreeMap$(core.String, core.bool)))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.functionType(core.String, [dart.dynamic])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicToString$ = () => (dynamicToString$ = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  splay_tree_from_iterable_test.main = function() {
    splay_tree_from_iterable_test.defaultFunctionValuesTest();
    splay_tree_from_iterable_test.defaultKeyFunctionTest();
    splay_tree_from_iterable_test.defaultValueFunctionTest();
    splay_tree_from_iterable_test.noDefaultValuesTest();
    splay_tree_from_iterable_test.emptyIterableTest();
    splay_tree_from_iterable_test.equalElementsTest();
    splay_tree_from_iterable_test.genericTypeTest();
    splay_tree_from_iterable_test.typedTest();
  };
  dart.fn(splay_tree_from_iterable_test.main, VoidTodynamic());
  splay_tree_from_iterable_test.defaultFunctionValuesTest = function() {
    let map = collection.SplayTreeMap.fromIterable(JSArrayOfint().of([1, 2, 3]));
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(1, map.get(1));
    expect$.Expect.equals(2, map.get(2));
    expect$.Expect.equals(3, map.get(3));
  };
  dart.fn(splay_tree_from_iterable_test.defaultFunctionValuesTest, VoidTovoid());
  splay_tree_from_iterable_test.defaultKeyFunctionTest = function() {
    let map = collection.SplayTreeMap.fromIterable(JSArrayOfint().of([1, 2, 3]), {value: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(2, map.get(1));
    expect$.Expect.equals(3, map.get(2));
    expect$.Expect.equals(4, map.get(3));
  };
  dart.fn(splay_tree_from_iterable_test.defaultKeyFunctionTest, VoidTovoid());
  splay_tree_from_iterable_test.defaultValueFunctionTest = function() {
    let map = collection.SplayTreeMap.fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(1, map.get(2));
    expect$.Expect.equals(2, map.get(3));
    expect$.Expect.equals(3, map.get(4));
  };
  dart.fn(splay_tree_from_iterable_test.defaultValueFunctionTest, VoidTovoid());
  splay_tree_from_iterable_test.noDefaultValuesTest = function() {
    let map = collection.SplayTreeMap.fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic()), value: dart.fn(x => dart.dsend(x, '-', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(3, map.length);
    expect$.Expect.equals(3, map.keys[dartx.length]);
    expect$.Expect.equals(3, map.values[dartx.length]);
    expect$.Expect.equals(0, map.get(2));
    expect$.Expect.equals(1, map.get(3));
    expect$.Expect.equals(2, map.get(4));
  };
  dart.fn(splay_tree_from_iterable_test.noDefaultValuesTest, VoidTovoid());
  splay_tree_from_iterable_test.emptyIterableTest = function() {
    let map = collection.SplayTreeMap.fromIterable([]);
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(0, map.length);
    expect$.Expect.equals(0, map.keys[dartx.length]);
    expect$.Expect.equals(0, map.values[dartx.length]);
  };
  dart.fn(splay_tree_from_iterable_test.emptyIterableTest, VoidTovoid());
  splay_tree_from_iterable_test.equalElementsTest = function() {
    let map = collection.SplayTreeMap.fromIterable(JSArrayOfint().of([1, 2, 2]), {key: dart.fn(x => dart.dsend(x, '+', 1), dynamicTodynamic())});
    expect$.Expect.isTrue(core.Map.is(map));
    expect$.Expect.isTrue(collection.SplayTreeMap.is(map));
    expect$.Expect.isFalse(collection.HashMap.is(map));
    expect$.Expect.equals(2, map.length);
    expect$.Expect.equals(2, map.keys[dartx.length]);
    expect$.Expect.equals(2, map.values[dartx.length]);
    expect$.Expect.equals(1, map.get(2));
    expect$.Expect.equals(2, map.get(3));
  };
  dart.fn(splay_tree_from_iterable_test.equalElementsTest, VoidTovoid());
  splay_tree_from_iterable_test.genericTypeTest = function() {
    let map = SplayTreeMapOfint$String().fromIterable(JSArrayOfint().of([1, 2, 3]), {value: dart.fn(x => dart.str`${x}`, dynamicToString$())});
    expect$.Expect.isTrue(MapOfint$String().is(map));
    expect$.Expect.isTrue(SplayTreeMapOfint$String().is(map));
    expect$.Expect.isFalse(SplayTreeMapOfString$dynamic().is(map));
    expect$.Expect.isFalse(SplayTreeMapOfdynamic$int().is(map));
  };
  dart.fn(splay_tree_from_iterable_test.genericTypeTest, VoidTovoid());
  splay_tree_from_iterable_test.typedTest = function() {
    let isCheckedMode = false;
    dart.assert(isCheckedMode = true);
    if (!isCheckedMode) return;
    let key = dart.fn(v => dart.str`${v}`, intToString());
    let value = dart.fn(v => v[dartx.isOdd], intTobool());
    let id = dart.fn(i => i, intToint());
    expect$.Expect.throws(dart.fn(() => {
      SplayTreeMapOfString$bool().fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dynamicToString()._check(key)});
    }, VoidTovoid()));
    expect$.Expect.throws(dart.fn(() => {
      SplayTreeMapOfString$bool().fromIterable(JSArrayOfint().of([1, 2, 3]), {value: dynamicTobool()._check(value)});
    }, VoidTovoid()));
    expect$.Expect.throws(dart.fn(() => {
      SplayTreeMapOfString$bool().fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dynamicToString()._check(id), value: dynamicTobool()._check(value)});
    }, VoidTovoid()));
    expect$.Expect.throws(dart.fn(() => {
      SplayTreeMapOfString$bool().fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dynamicToString()._check(key), value: dynamicTobool()._check(id)});
    }, VoidTovoid()));
    let map = SplayTreeMapOfString$bool().fromIterable(JSArrayOfint().of([1, 2, 3]), {key: dynamicToString()._check(key), value: dynamicTobool()._check(value)});
    let keys = map.keys;
    let values = map.values;
    let keyList = keys[dartx.toList]();
    let valueList = values[dartx.toList]();
    expect$.Expect.equals(3, keyList[dartx.length]);
    expect$.Expect.equals(3, valueList[dartx.length]);
    expect$.Expect.equals(keys[dartx.first], map.firstKey());
    expect$.Expect.equals(keys[dartx.last], map.lastKey());
  };
  dart.fn(splay_tree_from_iterable_test.typedTest, VoidTovoid());
  // Exports:
  exports.splay_tree_from_iterable_test = splay_tree_from_iterable_test;
});
