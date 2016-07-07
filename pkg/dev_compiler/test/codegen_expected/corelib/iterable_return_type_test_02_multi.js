dart_library.library('corelib/iterable_return_type_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_return_type_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const typed_data = dart_sdk.typed_data;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_return_type_test_02_multi = Object.create(null);
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let IterableOfString = () => (IterableOfString = dart.constFn(core.Iterable$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let MapOfint$int = () => (MapOfint$int = dart.constFn(core.Map$(core.int, core.int)))();
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let HashSetOfint = () => (HashSetOfint = dart.constFn(collection.HashSet$(core.int)))();
  let LinkedHashSetOfint = () => (LinkedHashSetOfint = dart.constFn(collection.LinkedHashSet$(core.int)))();
  let SplayTreeSetOfint = () => (SplayTreeSetOfint = dart.constFn(collection.SplayTreeSet$(core.int)))();
  let QueueOfint = () => (QueueOfint = dart.constFn(collection.Queue$(core.int)))();
  let DoubleLinkedQueueOfint = () => (DoubleLinkedQueueOfint = dart.constFn(collection.DoubleLinkedQueue$(core.int)))();
  let ListQueueOfint = () => (ListQueueOfint = dart.constFn(collection.ListQueue$(core.int)))();
  let HashMapOfint$int = () => (HashMapOfint$int = dart.constFn(collection.HashMap$(core.int, core.int)))();
  let LinkedHashMapOfint$int = () => (LinkedHashMapOfint$int = dart.constFn(collection.LinkedHashMap$(core.int, core.int)))();
  let SplayTreeMapOfint$int = () => (SplayTreeMapOfint$int = dart.constFn(collection.SplayTreeMap$(core.int, core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let IterableOfint__Tovoid = () => (IterableOfint__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [IterableOfint()], [core.int])))();
  let ListOfint__Tovoid = () => (ListOfint__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfint()], [core.int])))();
  let MapOfint$int__Tovoid = () => (MapOfint$int__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [MapOfint$int()], [core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  iterable_return_type_test_02_multi.testIntIterable = function(iterable) {
    expect$.Expect.isTrue(IterableOfint().is(iterable));
    expect$.Expect.isFalse(IterableOfString().is(iterable));
  };
  dart.fn(iterable_return_type_test_02_multi.testIntIterable, dynamicTodynamic());
  iterable_return_type_test_02_multi.testIterable = function(iterable, depth) {
    if (depth === void 0) depth = 3;
    iterable_return_type_test_02_multi.testIntIterable(iterable);
    if (dart.notNull(depth) > 0) {
      iterable_return_type_test_02_multi.testIterable(iterable[dartx.where](dart.fn(x => true, intTobool())), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testIterable(iterable[dartx.skip](1), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testIterable(iterable[dartx.take](1), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testIterable(iterable[dartx.skipWhile](dart.fn(x => false, intTobool())), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testIterable(iterable[dartx.takeWhile](dart.fn(x => true, intTobool())), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testList(iterable[dartx.toList]({growable: true}), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testList(iterable[dartx.toList]({growable: false}), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testIterable(iterable[dartx.toSet](), dart.notNull(depth) - 1);
    }
  };
  dart.fn(iterable_return_type_test_02_multi.testIterable, IterableOfint__Tovoid());
  iterable_return_type_test_02_multi.testList = function(list, depth) {
    if (depth === void 0) depth = 3;
    iterable_return_type_test_02_multi.testIterable(list, depth);
    if (dart.notNull(depth) > 0) {
      iterable_return_type_test_02_multi.testIterable(list[dartx.getRange](0, list[dartx.length]), dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testIterable(list[dartx.reversed], dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testMap(list[dartx.asMap](), dart.notNull(depth) - 1);
    }
  };
  dart.fn(iterable_return_type_test_02_multi.testList, ListOfint__Tovoid());
  iterable_return_type_test_02_multi.testMap = function(map, depth) {
    if (depth === void 0) depth = 3;
    expect$.Expect.isTrue(MapOfint$int().is(map));
    expect$.Expect.isFalse(MapOfint$String().is(map));
    expect$.Expect.isFalse(MapOfString$int().is(map));
    if (dart.notNull(depth) > 0) {
      iterable_return_type_test_02_multi.testIterable(map[dartx.keys], dart.notNull(depth) - 1);
      iterable_return_type_test_02_multi.testIterable(map[dartx.values], dart.notNull(depth) - 1);
    }
  };
  dart.fn(iterable_return_type_test_02_multi.testMap, MapOfint$int__Tovoid());
  let const$;
  let const$0;
  let const$1;
  iterable_return_type_test_02_multi.main = function() {
    iterable_return_type_test_02_multi.testList(JSArrayOfint().of([]));
    iterable_return_type_test_02_multi.testList(ListOfint().new(0));
    iterable_return_type_test_02_multi.testList(ListOfint().new());
    iterable_return_type_test_02_multi.testList(const$ || (const$ = dart.constList([], core.int)));
    iterable_return_type_test_02_multi.testList(ListOfint().generate(0, dart.fn(x => dart.notNull(x) + 1, intToint())));
    iterable_return_type_test_02_multi.testList(JSArrayOfint().of([1]));
    iterable_return_type_test_02_multi.testList((() => {
      let _ = ListOfint().new(1);
      _[dartx.set](0, 1);
      return _;
    })());
    iterable_return_type_test_02_multi.testList((() => {
      let _ = ListOfint().new();
      _[dartx.add](1);
      return _;
    })());
    iterable_return_type_test_02_multi.testList(const$0 || (const$0 = dart.constList([1], core.int)));
    iterable_return_type_test_02_multi.testList(ListOfint().generate(1, dart.fn(x => dart.notNull(x) + 1, intToint())));
    iterable_return_type_test_02_multi.testList((() => {
      let _ = typed_data.Uint64List.new(1);
      _.set(0, 1);
      return _;
    })());
    iterable_return_type_test_02_multi.testList((() => {
      let _ = typed_data.Int64List.new(1);
      _.set(0, 1);
      return _;
    })());
    iterable_return_type_test_02_multi.testIterable((() => {
      let _ = SetOfint().new();
      _.add(1);
      return _;
    })());
    iterable_return_type_test_02_multi.testIterable((() => {
      let _ = HashSetOfint().new();
      _.add(1);
      return _;
    })());
    iterable_return_type_test_02_multi.testIterable((() => {
      let _ = LinkedHashSetOfint().new();
      _.add(1);
      return _;
    })());
    iterable_return_type_test_02_multi.testIterable((() => {
      let _ = new (SplayTreeSetOfint())();
      _.add(1);
      return _;
    })());
    iterable_return_type_test_02_multi.testIterable((() => {
      let _ = QueueOfint().new();
      _.add(1);
      return _;
    })());
    iterable_return_type_test_02_multi.testIterable((() => {
      let _ = new (DoubleLinkedQueueOfint())();
      _.add(1);
      return _;
    })());
    iterable_return_type_test_02_multi.testIterable((() => {
      let _ = new (ListQueueOfint())();
      _.add(1);
      return _;
    })());
    iterable_return_type_test_02_multi.testMap((() => {
      let _ = MapOfint$int().new();
      _[dartx.set](1, 1);
      return _;
    })());
    iterable_return_type_test_02_multi.testMap((() => {
      let _ = HashMapOfint$int().new();
      _.set(1, 1);
      return _;
    })());
    iterable_return_type_test_02_multi.testMap((() => {
      let _ = LinkedHashMapOfint$int().new();
      _.set(1, 1);
      return _;
    })());
    iterable_return_type_test_02_multi.testMap((() => {
      let _ = new (SplayTreeMapOfint$int())();
      _.set(1, 1);
      return _;
    })());
    iterable_return_type_test_02_multi.testMap(dart.map([1, 1], core.int, core.int));
    iterable_return_type_test_02_multi.testMap(const$1 || (const$1 = dart.const(dart.map([1, 1], core.int, core.int))));
  };
  dart.fn(iterable_return_type_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.iterable_return_type_test_02_multi = iterable_return_type_test_02_multi;
});
