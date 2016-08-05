dart_library.library('corelib/json_map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__json_map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const json_map_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let MapOfString$dynamic = () => (MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))();
  let HashMapOfString$dynamic = () => (HashMapOfString$dynamic = dart.constFn(collection.HashMap$(core.String, dart.dynamic)))();
  let LinkedHashMapOfString$dynamic = () => (LinkedHashMapOfString$dynamic = dart.constFn(collection.LinkedHashMap$(core.String, dart.dynamic)))();
  let MapOfint$dynamic = () => (MapOfint$dynamic = dart.constFn(core.Map$(core.int, dart.dynamic)))();
  let HashMapOfint$dynamic = () => (HashMapOfint$dynamic = dart.constFn(collection.HashMap$(core.int, dart.dynamic)))();
  let LinkedHashMapOfint$dynamic = () => (LinkedHashMapOfint$dynamic = dart.constFn(collection.LinkedHashMap$(core.int, dart.dynamic)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let MapToMap = () => (MapToMap = dart.constFn(dart.definiteFunctionType(core.Map, [core.Map])))();
  let StringAnddynamicTovoid = () => (StringAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, dart.dynamic])))();
  let MapToList = () => (MapToList = dart.constFn(dart.definiteFunctionType(core.List, [core.Map])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let boolTovoid = () => (boolTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.bool])))();
  let MapTovoid = () => (MapTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let MapAndIterableAndFunctionTovoid = () => (MapAndIterableAndFunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map, core.Iterable, core.Function])))();
  let MapAndFunctionTovoid = () => (MapAndFunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map, core.Function])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let FunctionTobool = () => (FunctionTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.Function])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  json_map_test.useReviver = false;
  json_map_test.jsonify = function(map) {
    let encoded = convert.JSON.encode(map);
    return core.Map._check(dart.test(json_map_test.useReviver) ? convert.JSON.decode(encoded, {reviver: dart.fn((key, value) => value, dynamicAnddynamicTodynamic())}) : convert.JSON.decode(encoded));
  };
  dart.fn(json_map_test.jsonify, MapToMap());
  json_map_test.listEach = function(map) {
    let result = [];
    map[dartx.forEach](dart.fn((key, value) => {
      result[dartx.add](key);
      result[dartx.add](value);
    }, StringAnddynamicTovoid()));
    return result;
  };
  dart.fn(json_map_test.listEach, MapToList());
  json_map_test.main = function() {
    json_map_test.test(false);
    json_map_test.test(true);
  };
  dart.fn(json_map_test.main, VoidTovoid());
  json_map_test.test = function(revive) {
    json_map_test.useReviver = revive;
    json_map_test.testEmpty(json_map_test.jsonify(dart.map()));
    json_map_test.testAtoB(json_map_test.jsonify(dart.map({a: 'b'}, core.String, core.String)));
    let map = json_map_test.jsonify(dart.map());
    map[dartx.set]('a', 'b');
    json_map_test.testAtoB(map);
    map = json_map_test.jsonify(dart.map());
    expect$.Expect.equals('b', map[dartx.putIfAbsent]('a', dart.fn(() => 'b', VoidToString())));
    json_map_test.testAtoB(map);
    map = json_map_test.jsonify(dart.map());
    map[dartx.addAll](dart.map({a: 'b'}, core.String, core.String));
    json_map_test.testAtoB(map);
    json_map_test.testOrder(JSArrayOfString().of(['a', 'b', 'c', 'd', 'e', 'f']));
    json_map_test.testProto();
    json_map_test.testToString();
    json_map_test.testConcurrentModifications();
    json_map_test.testType();
    json_map_test.testNonStringKeys();
    json_map_test.testClear();
    json_map_test.testListEntry();
    json_map_test.testMutation();
  };
  dart.fn(json_map_test.test, boolTovoid());
  json_map_test.testEmpty = function(map) {
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(0, map[dartx.length]);
      expect$.Expect.isTrue(map[dartx.isEmpty]);
      expect$.Expect.isFalse(map[dartx.isNotEmpty]);
      expect$.Expect.listEquals([], map[dartx.keys][dartx.toList]());
      expect$.Expect.listEquals([], map[dartx.values][dartx.toList]());
      expect$.Expect.isNull(map[dartx.get]('a'));
      expect$.Expect.listEquals([], json_map_test.listEach(map));
      expect$.Expect.isFalse(map[dartx.containsKey]('a'));
      expect$.Expect.isFalse(map[dartx.containsValue]('a'));
      expect$.Expect.isNull(map[dartx.remove]('a'));
      json_map_test.testLookupNonExistingKeys(map);
      json_map_test.testLookupNonExistingValues(map);
      map[dartx.clear]();
    }
  };
  dart.fn(json_map_test.testEmpty, MapTovoid());
  json_map_test.testAtoB = function(map) {
    expect$.Expect.equals(1, map[dartx.length]);
    expect$.Expect.isFalse(map[dartx.isEmpty]);
    expect$.Expect.isTrue(map[dartx.isNotEmpty]);
    expect$.Expect.listEquals(JSArrayOfString().of(['a']), map[dartx.keys][dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfString().of(['b']), map[dartx.values][dartx.toList]());
    expect$.Expect.equals('b', map[dartx.get]('a'));
    expect$.Expect.listEquals(JSArrayOfString().of(['a', 'b']), json_map_test.listEach(map));
    expect$.Expect.isTrue(map[dartx.containsKey]('a'));
    expect$.Expect.isFalse(map[dartx.containsKey]('b'));
    expect$.Expect.isTrue(map[dartx.containsValue]('b'));
    expect$.Expect.isFalse(map[dartx.containsValue]('a'));
    json_map_test.testLookupNonExistingKeys(map);
    json_map_test.testLookupNonExistingValues(map);
    expect$.Expect.equals('b', map[dartx.remove]('a'));
    expect$.Expect.isNull(map[dartx.remove]('b'));
    json_map_test.testLookupNonExistingKeys(map);
    json_map_test.testLookupNonExistingValues(map);
    map[dartx.clear]();
    json_map_test.testEmpty(map);
  };
  dart.fn(json_map_test.testAtoB, MapTovoid());
  json_map_test.testLookupNonExistingKeys = function(map) {
    for (let key of JSArrayOfString().of(['__proto__', 'null', null])) {
      expect$.Expect.isNull(map[dartx.get](key));
      expect$.Expect.isFalse(map[dartx.containsKey](key));
    }
  };
  dart.fn(json_map_test.testLookupNonExistingKeys, MapTovoid());
  json_map_test.testLookupNonExistingValues = function(map) {
    for (let value of JSArrayOfString().of(['__proto__', 'null', null])) {
      expect$.Expect.isFalse(map[dartx.containsValue](value));
    }
  };
  dart.fn(json_map_test.testLookupNonExistingValues, MapTovoid());
  json_map_test.testOrder = function(list) {
    if (dart.test(list[dartx.isEmpty]))
      return;
    else
      json_map_test.testOrder(list[dartx.skip](1)[dartx.toList]());
    let original = dart.map();
    for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
      original[dartx.set](list[dartx.get](i), i);
    }
    let map = json_map_test.jsonify(original);
    expect$.Expect.equals(list[dartx.length], map[dartx.length]);
    expect$.Expect.listEquals(list, map[dartx.keys][dartx.toList]());
    for (let i = 0; i < 10; i++) {
      map[dartx.set](dart.str`${i}`, i);
      expect$.Expect.equals(dart.notNull(list[dartx.length]) + i + 1, map[dartx.length]);
      expect$.Expect.listEquals(list, map[dartx.keys][dartx.take](list[dartx.length])[dartx.toList]());
    }
  };
  dart.fn(json_map_test.testOrder, ListTovoid());
  json_map_test.testProto = function() {
    let map = json_map_test.jsonify(dart.map({__proto__: 0}, core.String, core.int));
    expect$.Expect.equals(1, map[dartx.length]);
    expect$.Expect.isTrue(map[dartx.containsKey]('__proto__'));
    expect$.Expect.listEquals(JSArrayOfString().of(['__proto__']), map[dartx.keys][dartx.toList]());
    expect$.Expect.equals(0, map[dartx.get]('__proto__'));
    expect$.Expect.equals(0, map[dartx.remove]('__proto__'));
    json_map_test.testEmpty(map);
    map = json_map_test.jsonify(dart.map({__proto__: null}, core.String, dart.dynamic));
    expect$.Expect.equals(1, map[dartx.length]);
    expect$.Expect.isTrue(map[dartx.containsKey]('__proto__'));
    expect$.Expect.listEquals(JSArrayOfString().of(['__proto__']), map[dartx.keys][dartx.toList]());
    expect$.Expect.isNull(map[dartx.get]('__proto__'));
    expect$.Expect.isNull(map[dartx.remove]('__proto__'));
    json_map_test.testEmpty(map);
  };
  dart.fn(json_map_test.testProto, VoidTovoid());
  json_map_test.testToString = function() {
    expect$.Expect.equals("{}", dart.toString(json_map_test.jsonify(dart.map())));
    expect$.Expect.equals("{a: 0}", dart.toString(json_map_test.jsonify(dart.map({a: 0}, core.String, core.int))));
  };
  dart.fn(json_map_test.testToString, VoidTovoid());
  json_map_test.testConcurrentModifications = function() {
    function testIterate(map, iterable, f) {
      let iterator = iterable[dartx.iterator];
      dart.dcall(f, map);
      iterator.moveNext();
    }
    dart.fn(testIterate, MapAndIterableAndFunctionTovoid());
    function testKeys(map, f) {
      return testIterate(map, map[dartx.keys], f);
    }
    dart.fn(testKeys, MapAndFunctionTovoid());
    function testValues(map, f) {
      return testIterate(map, map[dartx.values], f);
    }
    dart.fn(testValues, MapAndFunctionTovoid());
    function testForEach(map, f) {
      map[dartx.forEach](dart.fn((key, value) => {
        dart.dcall(f, map);
      }, dynamicAnddynamicTovoid()));
    }
    dart.fn(testForEach, MapAndFunctionTovoid());
    function throwsCME(f) {
      try {
        dart.dcall(f);
      } catch (e$) {
        if (core.ConcurrentModificationError.is(e$)) {
          let e = e$;
          return true;
        } else {
          let e = e$;
          return false;
        }
      }

      return false;
    }
    dart.fn(throwsCME, FunctionTobool());
    let map = dart.map();
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'a', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'a', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'a', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'clear'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'clear'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'clear'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'a'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'a'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'a'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'a', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'a', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'a', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map()), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map()), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map()), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({a: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({a: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({a: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    map = dart.map({a: 1}, core.String, core.int);
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'a', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'a', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'a', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'b', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'b', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsetindex(map, 'b', 0), dynamicToint())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'clear'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'clear'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'clear'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'a'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'a'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'a'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'b'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'b'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'remove', 'b'), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'a', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'a', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'a', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'b', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'b', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'putIfAbsent', 'b', dart.fn(() => 0, VoidToint())), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map()), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map()), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map()), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({a: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({a: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isFalse(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({a: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testKeys(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({b: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testValues(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({b: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
    expect$.Expect.isTrue(throwsCME(dart.fn(() => testForEach(json_map_test.jsonify(map), dart.fn(map => dart.dsend(map, 'addAll', dart.map({b: 0}, core.String, core.int)), dynamicTodynamic())), VoidTovoid())));
  };
  dart.fn(json_map_test.testConcurrentModifications, VoidTovoid());
  json_map_test.testType = function() {
    expect$.Expect.isTrue(core.Map.is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(collection.HashMap.is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(MapOfString$dynamic().is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(HashMapOfString$dynamic().is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(LinkedHashMapOfString$dynamic().is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(MapOfint$dynamic().is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(HashMapOfint$dynamic().is(json_map_test.jsonify(dart.map())));
    expect$.Expect.isTrue(LinkedHashMapOfint$dynamic().is(json_map_test.jsonify(dart.map())));
  };
  dart.fn(json_map_test.testType, VoidTovoid());
  json_map_test.testNonStringKeys = function() {
    let map = json_map_test.jsonify(dart.map());
    map[dartx.set](1, 2);
    expect$.Expect.equals(1, map[dartx.length]);
    expect$.Expect.equals(2, map[dartx.get](1));
  };
  dart.fn(json_map_test.testNonStringKeys, VoidTovoid());
  json_map_test.testClear = function() {
    let map = json_map_test.jsonify(dart.map({a: 0}, core.String, core.int));
    map[dartx.clear]();
    expect$.Expect.equals(0, map[dartx.length]);
  };
  dart.fn(json_map_test.testClear, VoidTovoid());
  json_map_test.testListEntry = function() {
    let map = json_map_test.jsonify(dart.map({a: JSArrayOfObject().of([7, 8, dart.map({b: 9}, core.String, core.int)])}, core.String, ListOfObject()));
    let list = core.List._check(map[dartx.get]('a'));
    expect$.Expect.equals(3, list[dartx.length]);
    expect$.Expect.equals(7, list[dartx.get](0));
    expect$.Expect.equals(8, list[dartx.get](1));
    expect$.Expect.equals(9, dart.dindex(list[dartx.get](2), 'b'));
  };
  dart.fn(json_map_test.testListEntry, VoidTovoid());
  json_map_test.testMutation = function() {
    let map = json_map_test.jsonify(dart.map({a: 0}, core.String, core.int));
    expect$.Expect.listEquals(JSArrayOfObject().of(['a', 0]), json_map_test.listEach(map));
    map[dartx.set]('a', 1);
    expect$.Expect.listEquals(JSArrayOfObject().of(['a', 1]), json_map_test.listEach(map));
    let i = 'a';
    map[dartx.set](i, dart.dsend(map[dartx.get](i), '+', 1));
    expect$.Expect.listEquals(JSArrayOfObject().of(['a', 2]), json_map_test.listEach(map));
  };
  dart.fn(json_map_test.testMutation, VoidTovoid());
  // Exports:
  exports.json_map_test = json_map_test;
});
