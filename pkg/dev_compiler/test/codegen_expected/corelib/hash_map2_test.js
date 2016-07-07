dart_library.library('corelib/hash_map2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hash_map2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hash_map2_test = Object.create(null);
  let VoidToMap = () => (VoidToMap = dart.constFn(dart.functionType(core.Map, [])))();
  let MapToMap = () => (MapToMap = dart.constFn(dart.functionType(core.Map, [core.Map])))();
  let HashMapOfint$String = () => (HashMapOfint$String = dart.constFn(collection.HashMap$(core.int, core.String)))();
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let LinkedHashMapOfint$String = () => (LinkedHashMapOfint$String = dart.constFn(collection.LinkedHashMap$(core.int, core.String)))();
  let HashMapOfString$int = () => (HashMapOfString$int = dart.constFn(collection.HashMap$(core.String, core.int)))();
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let LinkedHashMapOfString$int = () => (LinkedHashMapOfString$int = dart.constFn(collection.LinkedHashMap$(core.String, core.int)))();
  let intAndintToMap = () => (intAndintToMap = dart.constFn(dart.definiteFunctionType(core.Map, [core.int, core.int])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let MapAndMapTovoid = () => (MapAndMapTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map, core.Map])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let FnAndFnTodynamic = () => (FnAndFnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidToMap(), MapToMap()])))();
  let VoidToHashMap = () => (VoidToHashMap = dart.constFn(dart.definiteFunctionType(collection.HashMap, [])))();
  let MapToHashMap = () => (MapToHashMap = dart.constFn(dart.definiteFunctionType(collection.HashMap, [core.Map])))();
  let VoidToLinkedHashMap = () => (VoidToLinkedHashMap = dart.constFn(dart.definiteFunctionType(collection.LinkedHashMap, [])))();
  let MapToLinkedHashMap = () => (MapToLinkedHashMap = dart.constFn(dart.definiteFunctionType(collection.LinkedHashMap, [core.Map])))();
  hash_map2_test.testMap = function(newMap, newMapFrom) {
    function gen(from, to) {
      let map = collection.LinkedHashMap.new();
      for (let i = from; dart.notNull(i) < dart.notNull(to); i = dart.notNull(i) + 1)
        map[dartx.set](i, i);
      return map;
    }
    dart.fn(gen, intAndintToMap());
    function odd(n) {
      return (dart.notNull(n) & 1) == 1;
    }
    dart.fn(odd, intTobool());
    function even(n) {
      return (dart.notNull(n) & 1) == 0;
    }
    dart.fn(even, intTobool());
    function addAll(toMap, fromMap) {
      fromMap[dartx.forEach](dart.fn((k, v) => {
        toMap[dartx.set](k, v);
      }, dynamicAnddynamicTovoid()));
    }
    dart.fn(addAll, MapAndMapTovoid());
    {
      let map = newMap();
      for (let i = 0; i < 256; i++) {
        map[dartx.set](i, i);
      }
      addAll(map, gen(256, 512));
      addAll(map, newMapFrom(gen(512, 1000)));
      expect$.Expect.equals(1000, map[dartx.length]);
      for (let i = 0; i < 1000; i = i + 2)
        map[dartx.remove](i);
      expect$.Expect.equals(500, map[dartx.length]);
      expect$.Expect.isFalse(map[dartx.keys][dartx.any](even));
      expect$.Expect.isTrue(map[dartx.keys][dartx.every](odd));
      addAll(map, gen(0, 1000));
      expect$.Expect.equals(1000, map[dartx.length]);
    }
    {
      let map = newMap();
      map[dartx.set](0, 0);
      for (let i = 0; i < 1000; i++) {
        map[dartx.set](i + 1, i + 1);
        map[dartx.remove](i);
        expect$.Expect.equals(1, map[dartx.length]);
      }
    }
    {
      let map = newMap();
      for (let i = 0; i < 1000; i++) {
        map[dartx.set](new hash_map2_test.BadHashCode(), 0);
      }
      expect$.Expect.equals(1000, map[dartx.length]);
    }
    {
      let map = newMap();
      map[dartx.set](0, 0);
      map[dartx.set](1, 1);
      {
        let iter = map[dartx.keys][dartx.iterator];
        iter.moveNext();
        map[dartx.set](1, 9);
        iter.moveNext();
        map[dartx.set](2, 2);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = map[dartx.keys][dartx.iterator];
        expect$.Expect.equals(3, map[dartx.length]);
        iter.moveNext();
        iter.moveNext();
        iter.moveNext();
        map[dartx.set](3, 3);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = map[dartx.keys][dartx.iterator];
        iter.moveNext();
        map[dartx.remove](1000);
        iter.moveNext();
        let n = core.int._check(iter.current);
        map[dartx.remove](n);
        expect$.Expect.equals(n, iter.current);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = map[dartx.keys][dartx.iterator];
        expect$.Expect.equals(3, map[dartx.length]);
        iter.moveNext();
        iter.moveNext();
        iter.moveNext();
        let n = core.int._check(iter.current);
        map[dartx.remove](n);
        expect$.Expect.equals(n, iter.current);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = map[dartx.keys][dartx.iterator];
        expect$.Expect.equals(2, map[dartx.length]);
        iter.moveNext();
        let n = core.int._check(iter.current);
        map[dartx.set](n, dart.notNull(n) * 2);
        iter.moveNext();
        expect$.Expect.equals(map[dartx.get](iter.current), iter.current);
      }
      {
        map[dartx.putIfAbsent](4, dart.fn(() => {
          map[dartx.set](5, 5);
          map[dartx.set](4, -1);
          return 4;
        }, VoidToint()));
        expect$.Expect.equals(4, map[dartx.get](4));
        expect$.Expect.equals(5, map[dartx.get](5));
      }
      {
        let map2 = newMap();
        for (let key of map[dartx.keys]) {
          map2[dartx.set](key, dart.dsend(map[dartx.get](key), '+', 1));
        }
        let iter = map[dartx.keys][dartx.iterator];
        addAll(map, map2);
        iter.moveNext();
      }
    }
    {
      let map = newMap();
      map[dartx.putIfAbsent]("S", dart.fn(() => 0, VoidToint()));
      map[dartx.putIfAbsent]("T", dart.fn(() => 0, VoidToint()));
      map[dartx.putIfAbsent]("U", dart.fn(() => 0, VoidToint()));
      map[dartx.putIfAbsent]("C", dart.fn(() => 0, VoidToint()));
      map[dartx.putIfAbsent]("a", dart.fn(() => 0, VoidToint()));
      map[dartx.putIfAbsent]("b", dart.fn(() => 0, VoidToint()));
      map[dartx.putIfAbsent]("n", dart.fn(() => 0, VoidToint()));
      expect$.Expect.isTrue(map[dartx.containsKey]("n"));
    }
    {
      let map = newMap();
      for (let i = 0; i < 128; i++) {
        map[dartx.putIfAbsent](i, dart.fn(() => i, VoidToint()));
        expect$.Expect.isTrue(map[dartx.containsKey](i));
        map[dartx.putIfAbsent](i[dartx['>>']](1), dart.fn(() => -1, VoidToint()));
      }
      for (let i = 0; i < 128; i++) {
        expect$.Expect.equals(i, map[dartx.get](i));
      }
    }
    {
      for (let i = 1; i < 128; i++) {
        let map = newMapFrom(gen(0, i));
        map[dartx.forEach](dart.fn((key, v) => {
          expect$.Expect.equals(key, map[dartx.get](key));
          map[dartx.set](key, dart.dsend(key, '+', 1));
          map[dartx.remove](1000);
          map[dartx.putIfAbsent](key, dart.fn(() => expect$.Expect.fail("SHOULD NOT BE ABSENT"), VoidTovoid()));
        }, dynamicAnddynamicTovoid()));
        for (let key of map[dartx.keys]) {
          core.int._check(key);
          expect$.Expect.equals(dart.notNull(key) + 1, map[dartx.get](key));
          map[dartx.set](key, dart.dsend(map[dartx.get](key), '+', 1));
          map[dartx.remove](1000);
          map[dartx.putIfAbsent](key, dart.fn(() => expect$.Expect.fail("SHOULD NOT BE ABSENT"), VoidTovoid()));
        }
        let iter = map[dartx.keys][dartx.iterator];
        for (let key = 0; key < i; key++) {
          expect$.Expect.equals(key + 2, map[dartx.get](key));
          map[dartx.set](key, key + 3);
          map[dartx.remove](1000);
          map[dartx.putIfAbsent](key, dart.fn(() => expect$.Expect.fail("SHOULD NOT BE ABSENT"), VoidTovoid()));
        }
        iter.moveNext();
        for (let key = 1; key < i; key++) {
          expect$.Expect.equals(key + 3, map[dartx.get](key));
          map[dartx.remove](key);
        }
        iter = map[dartx.keys][dartx.iterator];
        map[dartx.set](0, 2);
        iter.moveNext();
      }
    }
    {
      let map = newMap();
      map[dartx.set](null, 0);
      expect$.Expect.equals(1, map[dartx.length]);
      expect$.Expect.isTrue(map[dartx.containsKey](null));
      expect$.Expect.isNull(map[dartx.keys][dartx.first]);
      expect$.Expect.isNull(map[dartx.keys][dartx.last]);
      map[dartx.set](null, 1);
      expect$.Expect.equals(1, map[dartx.length]);
      expect$.Expect.isTrue(map[dartx.containsKey](null));
      map[dartx.remove](null);
      expect$.Expect.isTrue(map[dartx.isEmpty]);
      expect$.Expect.isFalse(map[dartx.containsKey](null));
      map = newMapFrom((() => {
        let _ = core.Map.new();
        _[dartx.set](null, 0);
        return _;
      })());
      expect$.Expect.equals(1, map[dartx.length]);
      expect$.Expect.isTrue(map[dartx.containsKey](null));
      expect$.Expect.isNull(map[dartx.keys][dartx.first]);
      expect$.Expect.isNull(map[dartx.keys][dartx.last]);
      map[dartx.set](null, 1);
      expect$.Expect.equals(1, map[dartx.length]);
      expect$.Expect.isTrue(map[dartx.containsKey](null));
      map[dartx.remove](null);
      expect$.Expect.isTrue(map[dartx.isEmpty]);
      expect$.Expect.isFalse(map[dartx.containsKey](null));
      let fromMap = core.Map.new();
      fromMap[dartx.set](1, 0);
      fromMap[dartx.set](2, 0);
      fromMap[dartx.set](3, 0);
      fromMap[dartx.set](null, 0);
      fromMap[dartx.set](4, 0);
      fromMap[dartx.set](5, 0);
      fromMap[dartx.set](6, 0);
      expect$.Expect.equals(7, fromMap[dartx.length]);
      map = newMapFrom(fromMap);
      expect$.Expect.equals(7, map[dartx.length]);
      for (let i = 7; i < 128; i++) {
        map[dartx.set](i, 0);
      }
      expect$.Expect.equals(128, map[dartx.length]);
      expect$.Expect.isTrue(map[dartx.containsKey](null));
      map[dartx.set](null, 1);
      expect$.Expect.equals(128, map[dartx.length]);
      expect$.Expect.isTrue(map[dartx.containsKey](null));
      map[dartx.remove](null);
      expect$.Expect.equals(127, map[dartx.length]);
      expect$.Expect.isFalse(map[dartx.containsKey](null));
    }
  };
  dart.fn(hash_map2_test.testMap, FnAndFnTodynamic());
  let const$;
  hash_map2_test.main = function() {
    expect$.Expect.isTrue(MapOfint$String().is(HashMapOfint$String().new()));
    expect$.Expect.isTrue(MapOfint$String().is(LinkedHashMapOfint$String().new()));
    expect$.Expect.isTrue(MapOfString$int().is(HashMapOfString$int().from(dart.map())));
    expect$.Expect.isTrue(MapOfString$int().is(LinkedHashMapOfString$int().from(dart.map())));
    expect$.Expect.isTrue(MapOfString$int().is(dart.map({}, core.String, core.int)));
    expect$.Expect.isTrue(MapOfString$int().is(const$ || (const$ = dart.const(dart.map({}, core.String, core.int)))));
    hash_map2_test.testMap(dart.fn(() => collection.HashMap.new(), VoidToHashMap()), dart.fn(m => collection.HashMap.from(m), MapToHashMap()));
    hash_map2_test.testMap(dart.fn(() => collection.LinkedHashMap.new(), VoidToLinkedHashMap()), dart.fn(m => collection.LinkedHashMap.from(m), MapToLinkedHashMap()));
  };
  dart.fn(hash_map2_test.main, VoidTovoid());
  hash_map2_test.BadHashCode = class BadHashCode extends core.Object {
    new() {
      this.id = (() => {
        let x = hash_map2_test.BadHashCode.idCounter;
        hash_map2_test.BadHashCode.idCounter = dart.notNull(x) + 1;
        return x;
      })();
    }
    get hashCode() {
      return 42;
    }
  };
  dart.setSignature(hash_map2_test.BadHashCode, {
    constructors: () => ({new: dart.definiteFunctionType(hash_map2_test.BadHashCode, [])})
  });
  hash_map2_test.BadHashCode.idCounter = 0;
  // Exports:
  exports.hash_map2_test = hash_map2_test;
});
