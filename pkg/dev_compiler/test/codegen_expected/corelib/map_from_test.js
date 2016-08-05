dart_library.library('corelib/map_from_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_from_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_from_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  map_from_test.main = function() {
    map_from_test.testWithConstMap();
    map_from_test.testWithNonConstMap();
    map_from_test.testWithHashMap();
    map_from_test.testWithLinkedMap();
  };
  dart.fn(map_from_test.main, VoidTodynamic());
  let const$;
  map_from_test.testWithConstMap = function() {
    let map = const$ || (const$ = dart.const(dart.map({b: 42, a: 43}, core.String, core.int)));
    let otherMap = core.Map.from(map);
    expect$.Expect.isTrue(core.Map.is(otherMap));
    expect$.Expect.isTrue(collection.HashMap.is(otherMap));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(otherMap));
    expect$.Expect.equals(2, otherMap[dartx.length]);
    expect$.Expect.equals(2, otherMap[dartx.keys][dartx.length]);
    expect$.Expect.equals(2, otherMap[dartx.values][dartx.length]);
    let count = dart.fn(map => {
      let cnt = 0;
      dart.dsend(map, 'forEach', dart.fn((a, b) => {
        cnt = dart.notNull(cnt) + dart.notNull(core.int._check(b));
      }, dynamicAnddynamicTodynamic()));
      return cnt;
    }, dynamicToint());
    expect$.Expect.equals(42 + 43, dart.dcall(count, map));
    expect$.Expect.equals(dart.dcall(count, map), dart.dcall(count, otherMap));
  };
  dart.fn(map_from_test.testWithConstMap, VoidTodynamic());
  map_from_test.testWithNonConstMap = function() {
    let map = dart.map({b: 42, a: 43}, core.String, core.int);
    let otherMap = core.Map.from(map);
    expect$.Expect.isTrue(core.Map.is(otherMap));
    expect$.Expect.isTrue(collection.HashMap.is(otherMap));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(otherMap));
    expect$.Expect.equals(2, otherMap[dartx.length]);
    expect$.Expect.equals(2, otherMap[dartx.keys][dartx.length]);
    expect$.Expect.equals(2, otherMap[dartx.values][dartx.length]);
    function count(map) {
      let count = 0;
      dart.dsend(map, 'forEach', dart.fn((a, b) => {
        count = dart.notNull(count) + dart.notNull(core.int._check(b));
      }, dynamicAnddynamicTodynamic()));
      return count;
    }
    dart.fn(count, dynamicToint());
    ;
    expect$.Expect.equals(42 + 43, count(map));
    expect$.Expect.equals(count(map), count(otherMap));
    map[dartx.set]('c', 44);
    expect$.Expect.equals(3, map[dartx.length]);
    expect$.Expect.equals(2, otherMap[dartx.length]);
    expect$.Expect.equals(2, otherMap[dartx.keys][dartx.length]);
    expect$.Expect.equals(2, otherMap[dartx.values][dartx.length]);
    otherMap[dartx.set]('c', 44);
    expect$.Expect.equals(3, map[dartx.length]);
    expect$.Expect.equals(3, otherMap[dartx.length]);
    expect$.Expect.equals(3, otherMap[dartx.keys][dartx.length]);
    expect$.Expect.equals(3, otherMap[dartx.values][dartx.length]);
  };
  dart.fn(map_from_test.testWithNonConstMap, VoidTodynamic());
  let const$0;
  map_from_test.testWithHashMap = function() {
    let map = const$0 || (const$0 = dart.const(dart.map({b: 1, a: 2, c: 3}, core.String, core.int)));
    let otherMap = collection.HashMap.from(map);
    expect$.Expect.isTrue(core.Map.is(otherMap));
    expect$.Expect.isTrue(collection.HashMap.is(otherMap));
    expect$.Expect.isTrue(!collection.LinkedHashMap.is(otherMap));
    let i = 1;
    for (let val of map[dartx.values]) {
      expect$.Expect.equals(i++, val);
    }
  };
  dart.fn(map_from_test.testWithHashMap, VoidTodynamic());
  let const$1;
  map_from_test.testWithLinkedMap = function() {
    let map = const$1 || (const$1 = dart.const(dart.map({b: 1, a: 2, c: 3}, core.String, core.int)));
    let otherMap = collection.LinkedHashMap.from(map);
    expect$.Expect.isTrue(core.Map.is(otherMap));
    expect$.Expect.isTrue(collection.HashMap.is(otherMap));
    expect$.Expect.isTrue(collection.LinkedHashMap.is(otherMap));
    let i = 1;
    for (let val of map[dartx.values]) {
      expect$.Expect.equals(i++, val);
    }
  };
  dart.fn(map_from_test.testWithLinkedMap, VoidTodynamic());
  // Exports:
  exports.map_from_test = map_from_test;
});
