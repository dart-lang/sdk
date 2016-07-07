dart_library.library('corelib/list_as_map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_as_map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_as_map_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let ListAndMapTovoid = () => (ListAndMapTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List, core.Map])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_as_map_test.testListMapCorrespondence = function(list, map) {
    expect$.Expect.equals(list[dartx.length], map[dartx.length]);
    for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
      expect$.Expect.equals(list[dartx.get](i), map[dartx.get](i));
    }
    expect$.Expect.isNull(map[dartx.get](list[dartx.length]));
    expect$.Expect.isNull(map[dartx.get](-1));
    let keys = map[dartx.keys];
    let values = map[dartx.values];
    expect$.Expect.isFalse(core.List.is(keys));
    expect$.Expect.isFalse(core.List.is(values));
    expect$.Expect.equals(list[dartx.length], keys[dartx.length]);
    expect$.Expect.equals(list[dartx.length], values[dartx.length]);
    for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
      expect$.Expect.equals(i, keys[dartx.elementAt](i));
      expect$.Expect.equals(list[dartx.get](i), values[dartx.elementAt](i));
    }
    let forEachCount = 0;
    map[dartx.forEach](dart.fn((key, value) => {
      expect$.Expect.equals(forEachCount, key);
      expect$.Expect.equals(list[dartx.get](core.int._check(key)), value);
      forEachCount++;
    }, dynamicAnddynamicTovoid()));
    for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
      expect$.Expect.isTrue(map[dartx.containsKey](i));
      expect$.Expect.isTrue(map[dartx.containsValue](list[dartx.get](i)));
    }
    expect$.Expect.isFalse(map[dartx.containsKey](-1));
    expect$.Expect.isFalse(map[dartx.containsKey](list[dartx.length]));
    expect$.Expect.equals(list[dartx.length], forEachCount);
    expect$.Expect.equals(list[dartx.isEmpty], map[dartx.isEmpty]);
  };
  dart.fn(list_as_map_test.testListMapCorrespondence, ListAndMapTovoid());
  list_as_map_test.testConstAsMap = function(list) {
    let map = list[dartx.asMap]();
    list_as_map_test.testListMapCorrespondence(list, map);
    expect$.Expect.throws(dart.fn(() => map[dartx.set](0, 499), VoidToint()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => map[dartx.putIfAbsent](0, dart.fn(() => 499, VoidToint())), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => map[dartx.clear](), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(list_as_map_test.testConstAsMap, ListTovoid());
  list_as_map_test.testFixedAsMap = function(list) {
    list_as_map_test.testConstAsMap(list);
    let map = list[dartx.asMap]();
    if (!dart.test(list[dartx.isEmpty])) {
      list[dartx.set](0, 499);
      list_as_map_test.testListMapCorrespondence(list, map);
    }
  };
  dart.fn(list_as_map_test.testFixedAsMap, ListTovoid());
  list_as_map_test.testAsMap = function(list) {
    list_as_map_test.testFixedAsMap(list);
    let map = list[dartx.asMap]();
    let keys = map[dartx.keys];
    let values = map[dartx.values];
    list[dartx.add](42);
    list_as_map_test.testListMapCorrespondence(list, map);
    expect$.Expect.equals(list[dartx.length], keys[dartx.length]);
    expect$.Expect.equals(values[dartx.length], values[dartx.length]);
  };
  dart.fn(list_as_map_test.testAsMap, ListTovoid());
  let const$;
  let const$0;
  list_as_map_test.main = function() {
    list_as_map_test.testConstAsMap(const$ || (const$ = dart.constList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], core.int)));
    list_as_map_test.testAsMap(JSArrayOfint().of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    let list = core.List.new(10);
    for (let i = 0; i < 10; i++)
      list[dartx.set](i, i + 1);
    list_as_map_test.testFixedAsMap(list);
    list_as_map_test.testConstAsMap(const$0 || (const$0 = dart.constList([], dart.dynamic)));
    list_as_map_test.testAsMap([]);
    list_as_map_test.testFixedAsMap(core.List.new(0));
  };
  dart.fn(list_as_map_test.main, VoidTodynamic());
  // Exports:
  exports.list_as_map_test = list_as_map_test;
});
