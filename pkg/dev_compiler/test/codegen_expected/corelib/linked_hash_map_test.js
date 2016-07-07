dart_library.library('corelib/linked_hash_map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__linked_hash_map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const linked_hash_map_test = Object.create(null);
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListOfStringTodynamic = () => (ListOfStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfString()])))();
  let ListOfintTodynamic = () => (ListOfintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfint()])))();
  let ObjectAndObjectTodynamic = () => (ObjectAndObjectTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.Object, core.Object])))();
  let ObjectTodynamic = () => (ObjectTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.Object])))();
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  linked_hash_map_test.LinkedHashMapTest = class LinkedHashMapTest extends core.Object {
    static testMain() {
      let map = collection.LinkedHashMap.new();
      map[dartx.set]("a", 1);
      map[dartx.set]("b", 2);
      map[dartx.set]("c", 3);
      map[dartx.set]("d", 4);
      map[dartx.set]("e", 5);
      let keys = ListOfString().new(5);
      let values = ListOfint().new(5);
      let index = null;
      function clear() {
        index = 0;
        for (let i = 0; i < dart.notNull(keys[dartx.length]); i++) {
          keys[dartx.set](i, null);
          values[dartx.set](i, null);
        }
      }
      dart.fn(clear, VoidTodynamic());
      function verifyKeys(correctKeys) {
        for (let i = 0; i < dart.notNull(correctKeys[dartx.length]); i++) {
          expect$.Expect.equals(correctKeys[dartx.get](i), keys[dartx.get](i));
        }
      }
      dart.fn(verifyKeys, ListOfStringTodynamic());
      function verifyValues(correctValues) {
        for (let i = 0; i < dart.notNull(correctValues[dartx.length]); i++) {
          expect$.Expect.equals(correctValues[dartx.get](i), values[dartx.get](i));
        }
      }
      dart.fn(verifyValues, ListOfintTodynamic());
      function testForEachMap(key, value) {
        expect$.Expect.equals(map[dartx.get](key), value);
        keys[dartx.set](index, core.String._check(key));
        values[dartx.set](index, core.int._check(value));
        index = dart.notNull(index) + 1;
      }
      dart.fn(testForEachMap, ObjectAndObjectTodynamic());
      function testForEachValue(v) {
        values[dartx.set]((() => {
          let x = index;
          index = dart.notNull(x) + 1;
          return x;
        })(), core.int._check(v));
      }
      dart.fn(testForEachValue, ObjectTodynamic());
      function testForEachKey(v) {
        keys[dartx.set]((() => {
          let x = index;
          index = dart.notNull(x) + 1;
          return x;
        })(), core.String._check(v));
      }
      dart.fn(testForEachKey, ObjectTodynamic());
      let keysInOrder = const$ || (const$ = dart.constList(["a", "b", "c", "d", "e"], core.String));
      let valuesInOrder = const$0 || (const$0 = dart.constList([1, 2, 3, 4, 5], core.int));
      clear();
      map[dartx.forEach](testForEachMap);
      verifyKeys(keysInOrder);
      verifyValues(valuesInOrder);
      clear();
      map[dartx.keys][dartx.forEach](testForEachKey);
      verifyKeys(keysInOrder);
      clear();
      map[dartx.values][dartx.forEach](testForEachValue);
      verifyValues(valuesInOrder);
      map[dartx.remove]("b");
      map[dartx.set]("b", 6);
      let keysAfterBMove = const$1 || (const$1 = dart.constList(["a", "c", "d", "e", "b"], core.String));
      let valuesAfterBMove = const$2 || (const$2 = dart.constList([1, 3, 4, 5, 6], core.int));
      clear();
      map[dartx.forEach](testForEachMap);
      verifyKeys(keysAfterBMove);
      verifyValues(valuesAfterBMove);
      clear();
      map[dartx.keys][dartx.forEach](testForEachKey);
      verifyKeys(keysAfterBMove);
      clear();
      map[dartx.values][dartx.forEach](testForEachValue);
      verifyValues(valuesAfterBMove);
      map[dartx.set]("a", 0);
      let valuesAfterAUpdate = const$3 || (const$3 = dart.constList([0, 3, 4, 5, 6], core.int));
      clear();
      map[dartx.forEach](testForEachMap);
      verifyKeys(keysAfterBMove);
      verifyValues(valuesAfterAUpdate);
      clear();
      map[dartx.keys][dartx.forEach](testForEachKey);
      verifyKeys(keysAfterBMove);
      clear();
      map[dartx.values][dartx.forEach](testForEachValue);
      verifyValues(valuesAfterAUpdate);
    }
  };
  dart.setSignature(linked_hash_map_test.LinkedHashMapTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  linked_hash_map_test.main = function() {
    linked_hash_map_test.LinkedHashMapTest.testMain();
  };
  dart.fn(linked_hash_map_test.main, VoidTodynamic());
  // Exports:
  exports.linked_hash_map_test = linked_hash_map_test;
});
