dart_library.library('corelib/collection_length_test', null, /* Imports */[
  'dart_sdk'
], function load__collection_length_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const collection_length_test = Object.create(null);
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let MapAndintTovoid = () => (MapAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map, core.int])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let ListAnddynamicTovoid = () => (ListAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List, dart.dynamic])))();
  let dynamicAndintTovoid = () => (dynamicAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  collection_length_test.testString = function(n) {
    let s = "x";
    let string = "";
    let length = n;
    while (true) {
      if ((dart.notNull(length) & 1) == 1) {
        string = string + s;
      }
      length = length[dartx['>>']](1);
      if (length == 0) break;
      s = s + s;
    }
    collection_length_test.testLength(string, n);
    collection_length_test.testLength(string[dartx.codeUnits], n);
  };
  dart.fn(collection_length_test.testString, intTovoid());
  collection_length_test.testMap = function(map, n) {
    for (let i = 0; i < dart.notNull(n); i++) {
      map[dartx.set](i, i);
    }
    collection_length_test.testLength(map, n);
    collection_length_test.testLength(map[dartx.keys], n);
    collection_length_test.testLength(map[dartx.values], n);
  };
  dart.fn(collection_length_test.testMap, MapAndintTovoid());
  collection_length_test.testCollection = function(collection, n) {
    for (let i = 0; i < dart.notNull(core.num._check(n)); i++) {
      dart.dsend(collection, 'add', i);
    }
    collection_length_test.testLength(collection, core.int._check(n));
  };
  dart.fn(collection_length_test.testCollection, dynamicAnddynamicTovoid());
  collection_length_test.testList = function(list, n) {
    for (let i = 0; i < dart.notNull(core.num._check(n)); i++) {
      list[dartx.set](i, i);
    }
    collection_length_test.testLength(list, core.int._check(n));
  };
  dart.fn(collection_length_test.testList, ListAnddynamicTovoid());
  collection_length_test.testLength = function(lengthable, size) {
    core.print(dart.runtimeType(lengthable));
    let length = 0;
    for (let i = 0; i < 100000; i++) {
      if (!dart.test(dart.dload(lengthable, 'isEmpty'))) {
        length = dart.notNull(length) + dart.notNull(core.int._check(dart.dload(lengthable, 'length')));
      }
      if (dart.test(dart.dload(lengthable, 'isNotEmpty'))) {
        length = dart.notNull(length) + dart.notNull(core.int._check(dart.dload(lengthable, 'length')));
      }
    }
    if (length != dart.notNull(size) * 200000) dart.throw(dart.str`Bad length: ${length} / size: ${size}`);
  };
  dart.fn(collection_length_test.testLength, dynamicAndintTovoid());
  collection_length_test.main = function() {
    let N = 100000;
    collection_length_test.testMap(collection.HashMap.new(), N);
    collection_length_test.testMap(collection.LinkedHashMap.new(), N);
    collection_length_test.testMap(new collection.SplayTreeMap(), N);
    collection_length_test.testCollection(collection.HashSet.new(), N);
    collection_length_test.testCollection(collection.LinkedHashSet.new(), N);
    collection_length_test.testCollection(new collection.ListQueue(), N);
    collection_length_test.testCollection(new collection.DoubleLinkedQueue(), N);
    collection_length_test.testList((() => {
      let _ = core.List.new();
      _[dartx.length] = N;
      return _;
    })(), N);
    collection_length_test.testList(core.List.new(N), N);
    collection_length_test.testString(N);
  };
  dart.fn(collection_length_test.main, VoidTodynamic());
  // Exports:
  exports.collection_length_test = collection_length_test;
});
