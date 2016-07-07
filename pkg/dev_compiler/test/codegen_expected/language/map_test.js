dart_library.library('language/map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_test = Object.create(null);
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  map_test.MapTest = class MapTest extends core.Object {
    static testDeletedElement(map) {
      map[dartx.clear]();
      for (let i = 0; i < 100; i++) {
        map[dartx.set](1, 2);
        expect$.Expect.equals(1, map[dartx.length]);
        let x = core.int._check(map[dartx.remove](1));
        expect$.Expect.equals(2, x);
        expect$.Expect.equals(0, map[dartx.length]);
      }
      expect$.Expect.equals(0, map[dartx.length]);
      for (let i = 0; i < 100; i++) {
        map[dartx.set](i, 2);
        expect$.Expect.equals(1, map[dartx.length]);
        let x = core.int._check(map[dartx.remove](105));
        expect$.Expect.equals(null, x);
        expect$.Expect.equals(1, map[dartx.length]);
        x = core.int._check(map[dartx.remove](i));
        expect$.Expect.equals(2, x);
        expect$.Expect.equals(0, map[dartx.length]);
      }
      expect$.Expect.equals(0, map[dartx.length]);
      map[dartx.remove](105);
    }
    static test(map) {
      map_test.MapTest.testDeletedElement(map);
      map_test.MapTest.testMap(map, 1, 2, 3, 4, 5, 6, 7, 8);
      map[dartx.clear]();
      map_test.MapTest.testMap(map, "value1", "value2", "value3", "value4", "value5", "value6", "value7", "value8");
    }
    static testMap(map, key1, key2, key3, key4, key5, key6, key7, key8) {
      let value1 = 10;
      let value2 = 20;
      let value3 = 30;
      let value4 = 40;
      let value5 = 50;
      let value6 = 60;
      let value7 = 70;
      let value8 = 80;
      expect$.Expect.equals(0, map[dartx.length]);
      map[dartx.set](key1, value1);
      expect$.Expect.equals(value1, map[dartx.get](key1));
      map[dartx.set](key1, value2);
      expect$.Expect.equals(false, map[dartx.containsKey](key2));
      expect$.Expect.equals(1, map[dartx.length]);
      map[dartx.set](key1, value1);
      expect$.Expect.equals(value1, map[dartx.get](key1));
      map[dartx.set](key2, value2);
      expect$.Expect.equals(value2, map[dartx.get](key2));
      expect$.Expect.equals(2, map[dartx.length]);
      map[dartx.set](key3, value3);
      expect$.Expect.equals(value2, map[dartx.get](key2));
      expect$.Expect.equals(value3, map[dartx.get](key3));
      map[dartx.set](key4, value4);
      expect$.Expect.equals(value3, map[dartx.get](key3));
      expect$.Expect.equals(value4, map[dartx.get](key4));
      map[dartx.set](key5, value5);
      expect$.Expect.equals(value4, map[dartx.get](key4));
      expect$.Expect.equals(value5, map[dartx.get](key5));
      map[dartx.set](key6, value6);
      expect$.Expect.equals(value5, map[dartx.get](key5));
      expect$.Expect.equals(value6, map[dartx.get](key6));
      map[dartx.set](key7, value7);
      expect$.Expect.equals(value6, map[dartx.get](key6));
      expect$.Expect.equals(value7, map[dartx.get](key7));
      map[dartx.set](key8, value8);
      expect$.Expect.equals(value1, map[dartx.get](key1));
      expect$.Expect.equals(value2, map[dartx.get](key2));
      expect$.Expect.equals(value3, map[dartx.get](key3));
      expect$.Expect.equals(value4, map[dartx.get](key4));
      expect$.Expect.equals(value5, map[dartx.get](key5));
      expect$.Expect.equals(value6, map[dartx.get](key6));
      expect$.Expect.equals(value7, map[dartx.get](key7));
      expect$.Expect.equals(value8, map[dartx.get](key8));
      expect$.Expect.equals(8, map[dartx.length]);
      map[dartx.remove](key4);
      expect$.Expect.equals(false, map[dartx.containsKey](key4));
      expect$.Expect.equals(7, map[dartx.length]);
      map[dartx.clear]();
      expect$.Expect.equals(0, map[dartx.length]);
      expect$.Expect.equals(false, map[dartx.containsKey](key1));
      expect$.Expect.equals(false, map[dartx.containsKey](key2));
      expect$.Expect.equals(false, map[dartx.containsKey](key3));
      expect$.Expect.equals(false, map[dartx.containsKey](key4));
      expect$.Expect.equals(false, map[dartx.containsKey](key5));
      expect$.Expect.equals(false, map[dartx.containsKey](key6));
      expect$.Expect.equals(false, map[dartx.containsKey](key7));
      expect$.Expect.equals(false, map[dartx.containsKey](key8));
      map[dartx.set](key1, value1);
      expect$.Expect.equals(value1, map[dartx.get](key1));
      expect$.Expect.equals(1, map[dartx.length]);
      map[dartx.set](key2, value2);
      expect$.Expect.equals(value2, map[dartx.get](key2));
      expect$.Expect.equals(2, map[dartx.length]);
      map[dartx.set](key3, value3);
      expect$.Expect.equals(value3, map[dartx.get](key3));
      map[dartx.remove](key3);
      expect$.Expect.equals(2, map[dartx.length]);
      map[dartx.set](key4, value4);
      expect$.Expect.equals(value4, map[dartx.get](key4));
      map[dartx.remove](key4);
      expect$.Expect.equals(2, map[dartx.length]);
      map[dartx.set](key5, value5);
      expect$.Expect.equals(value5, map[dartx.get](key5));
      map[dartx.remove](key5);
      expect$.Expect.equals(2, map[dartx.length]);
      map[dartx.set](key6, value6);
      expect$.Expect.equals(value6, map[dartx.get](key6));
      map[dartx.remove](key6);
      expect$.Expect.equals(2, map[dartx.length]);
      map[dartx.set](key7, value7);
      expect$.Expect.equals(value7, map[dartx.get](key7));
      map[dartx.remove](key7);
      expect$.Expect.equals(2, map[dartx.length]);
      map[dartx.set](key8, value8);
      expect$.Expect.equals(value8, map[dartx.get](key8));
      map[dartx.remove](key8);
      expect$.Expect.equals(2, map[dartx.length]);
      expect$.Expect.equals(true, map[dartx.containsKey](key1));
      expect$.Expect.equals(true, map[dartx.containsValue](value1));
      let other_map = core.Map.new();
      function testForEachMap(key, value) {
        other_map[dartx.set](key, value);
      }
      dart.fn(testForEachMap, dynamicAnddynamicTovoid());
      map[dartx.forEach](testForEachMap);
      expect$.Expect.equals(true, other_map[dartx.containsKey](key1));
      expect$.Expect.equals(true, other_map[dartx.containsKey](key2));
      expect$.Expect.equals(true, other_map[dartx.containsValue](value1));
      expect$.Expect.equals(true, other_map[dartx.containsValue](value2));
      expect$.Expect.equals(2, other_map[dartx.length]);
      other_map[dartx.clear]();
      expect$.Expect.equals(0, other_map[dartx.length]);
      function testForEachCollection(value) {
        other_map[dartx.set](value, value);
      }
      dart.fn(testForEachCollection, dynamicTovoid());
      let keys = map[dartx.keys];
      keys[dartx.forEach](testForEachCollection);
      expect$.Expect.equals(true, other_map[dartx.containsKey](key1));
      expect$.Expect.equals(true, other_map[dartx.containsKey](key2));
      expect$.Expect.equals(true, other_map[dartx.containsValue](key1));
      expect$.Expect.equals(true, other_map[dartx.containsValue](key2));
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsKey](value1)));
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsKey](value2)));
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsValue](value1)));
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsValue](value2)));
      expect$.Expect.equals(2, other_map[dartx.length]);
      other_map[dartx.clear]();
      expect$.Expect.equals(0, other_map[dartx.length]);
      let values = map[dartx.values];
      values[dartx.forEach](testForEachCollection);
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsKey](key1)));
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsKey](key2)));
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsValue](key1)));
      expect$.Expect.equals(true, !dart.test(other_map[dartx.containsValue](key2)));
      expect$.Expect.equals(true, other_map[dartx.containsKey](value1));
      expect$.Expect.equals(true, other_map[dartx.containsKey](value2));
      expect$.Expect.equals(true, other_map[dartx.containsValue](value1));
      expect$.Expect.equals(true, other_map[dartx.containsValue](value2));
      expect$.Expect.equals(2, other_map[dartx.length]);
      other_map[dartx.clear]();
      expect$.Expect.equals(0, other_map[dartx.length]);
      map[dartx.clear]();
      expect$.Expect.equals(false, map[dartx.containsKey](key1));
      map[dartx.putIfAbsent](key1, dart.fn(() => 10, VoidToint()));
      expect$.Expect.equals(true, map[dartx.containsKey](key1));
      expect$.Expect.equals(10, map[dartx.get](key1));
      expect$.Expect.equals(10, map[dartx.putIfAbsent](key1, dart.fn(() => 11, VoidToint())));
    }
    static testKeys(map) {
      map[dartx.set](1, 101);
      map[dartx.set](2, 102);
      let k = map[dartx.keys];
      expect$.Expect.equals(2, k[dartx.length]);
      let v = map[dartx.values];
      expect$.Expect.equals(2, v[dartx.length]);
      expect$.Expect.equals(true, map[dartx.containsValue](101));
      expect$.Expect.equals(true, map[dartx.containsValue](102));
      expect$.Expect.equals(false, map[dartx.containsValue](103));
    }
    static testMain() {
      map_test.MapTest.test(core.Map.new());
      map_test.MapTest.testKeys(core.Map.new());
    }
  };
  dart.setSignature(map_test.MapTest, {
    statics: () => ({
      testDeletedElement: dart.definiteFunctionType(dart.void, [core.Map]),
      test: dart.definiteFunctionType(dart.void, [core.Map]),
      testMap: dart.definiteFunctionType(dart.void, [core.Map, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      testKeys: dart.definiteFunctionType(dart.dynamic, [core.Map]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['testDeletedElement', 'test', 'testMap', 'testKeys', 'testMain']
  });
  map_test.main = function() {
    map_test.MapTest.testMain();
  };
  dart.fn(map_test.main, VoidTodynamic());
  // Exports:
  exports.map_test = map_test;
});
