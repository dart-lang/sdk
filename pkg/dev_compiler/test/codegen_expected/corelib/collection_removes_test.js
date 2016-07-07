dart_library.library('corelib/collection_removes_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__collection_removes_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const collection_removes_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic])))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let MyList = () => (MyList = dart.constFn(collection_removes_test.MyList$()))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAndIterableTodynamic = () => (dynamicAndIterableTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, core.Iterable])))();
  let dynamicAndFnTodynamic = () => (dynamicAndFnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dynamicTobool()])))();
  let dynamicTobool$ = () => (dynamicTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  collection_removes_test.testRemove = function(base) {
    let length = core.int._check(dart.dload(base, 'length'));
    for (let i = 0; i < dart.notNull(length); i++) {
      expect$.Expect.isFalse(dart.dload(base, 'isEmpty'));
      dart.dsend(base, 'remove', dart.dload(base, 'first'));
    }
    expect$.Expect.isTrue(dart.dload(base, 'isEmpty'));
  };
  dart.fn(collection_removes_test.testRemove, dynamicTodynamic());
  collection_removes_test.testRemoveAll = function(base, removes) {
    let retained = core.Set.new();
    for (let element of core.Iterable._check(base)) {
      if (!dart.test(removes[dartx.contains](element))) {
        retained.add(element);
      }
    }
    let name = dart.str`${base}.removeAll(${removes}) -> ${retained}`;
    dart.dsend(base, 'removeAll', removes);
    for (let value of core.Iterable._check(base)) {
      expect$.Expect.isFalse(removes[dartx.contains](value), dart.str`${name}: Found ${value}`);
    }
    for (let value of retained) {
      expect$.Expect.isTrue(dart.dsend(base, 'contains', value), dart.str`${name}: Found ${value}`);
    }
  };
  dart.fn(collection_removes_test.testRemoveAll, dynamicAndIterableTodynamic());
  collection_removes_test.testRetainAll = function(base, retains) {
    let retained = core.Set.new();
    for (let element of core.Iterable._check(base)) {
      if (dart.test(retains[dartx.contains](element))) {
        retained.add(element);
      }
    }
    let name = dart.str`${base}.retainAll(${retains}) -> ${retained}`;
    dart.dsend(base, 'retainAll', retains);
    for (let value of core.Iterable._check(base)) {
      expect$.Expect.isTrue(retains[dartx.contains](value), dart.str`${name}: Found ${value}`);
    }
    for (let value of retained) {
      expect$.Expect.isTrue(dart.dsend(base, 'contains', value), dart.str`${name}: Found ${value}`);
    }
  };
  dart.fn(collection_removes_test.testRetainAll, dynamicAndIterableTodynamic());
  collection_removes_test.testRemoveWhere = function(base, test) {
    let retained = core.Set.new();
    for (let element of core.Iterable._check(base)) {
      if (!dart.test(dart.dcall(test, element))) {
        retained.add(element);
      }
    }
    let name = dart.str`${base}.removeWhere(...) -> ${retained}`;
    dart.dsend(base, 'removeWhere', test);
    for (let value of core.Iterable._check(base)) {
      expect$.Expect.isFalse(dart.dcall(test, value), dart.str`${name}: Found ${value}`);
    }
    for (let value of retained) {
      expect$.Expect.isTrue(dart.dsend(base, 'contains', value), dart.str`${name}: Found ${value}`);
    }
  };
  dart.fn(collection_removes_test.testRemoveWhere, dynamicAndFnTodynamic());
  collection_removes_test.testRetainWhere = function(base, test) {
    let retained = core.Set.new();
    for (let element of core.Iterable._check(base)) {
      if (dart.test(dart.dcall(test, element))) {
        retained.add(element);
      }
    }
    let name = dart.str`${base}.retainWhere(...) -> ${retained}`;
    dart.dsend(base, 'retainWhere', test);
    for (let value of core.Iterable._check(base)) {
      expect$.Expect.isTrue(dart.dcall(test, value), dart.str`${name}: Found ${value}`);
    }
    for (let value of retained) {
      expect$.Expect.isTrue(dart.dsend(base, 'contains', value), dart.str`${name}: Found ${value}`);
    }
  };
  dart.fn(collection_removes_test.testRetainWhere, dynamicAndFnTodynamic());
  collection_removes_test.main = function() {
    let collections = JSArrayOfList().of([[], JSArrayOfint().of([1]), JSArrayOfint().of([2]), JSArrayOfint().of([1, 2]), JSArrayOfint().of([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]), JSArrayOfint().of([1, 3, 5, 7, 9]), JSArrayOfint().of([2, 4, 6, 8, 10])]);
    for (let base of collections) {
      for (let delta of collections) {
        collection_removes_test.testRemove(base[dartx.toList]());
        collection_removes_test.testRemove(base[dartx.toSet]());
        let deltaSet = delta[dartx.toSet]();
        collection_removes_test.testRemoveWhere(base[dartx.toList](), dart.bind(deltaSet, 'contains'));
        collection_removes_test.testRetainWhere(base[dartx.toList](), dart.fn(e => !dart.test(deltaSet.contains(e)), dynamicTobool$()));
        collection_removes_test.testRemoveAll(base[dartx.toSet](), delta);
        collection_removes_test.testRemoveAll(base[dartx.toSet](), deltaSet);
        collection_removes_test.testRetainAll(base[dartx.toSet](), delta);
        collection_removes_test.testRetainAll(base[dartx.toSet](), deltaSet);
        collection_removes_test.testRemoveWhere(base[dartx.toSet](), dart.bind(deltaSet, 'contains'));
        collection_removes_test.testRetainWhere(base[dartx.toSet](), dart.fn(e => !dart.test(deltaSet.contains(e)), dynamicTobool$()));
        collection_removes_test.testRemoveWhere(new collection_removes_test.MyList(base[dartx.toList]()), dart.bind(deltaSet, 'contains'));
        collection_removes_test.testRetainWhere(new collection_removes_test.MyList(base[dartx.toList]()), dart.fn(e => !dart.test(deltaSet.contains(e)), dynamicTobool$()));
      }
    }
  };
  dart.fn(collection_removes_test.main, VoidTovoid());
  const _source = Symbol('_source');
  collection_removes_test.MyList$ = dart.generic(E => {
    class MyList extends collection.ListBase$(E) {
      new(source) {
        this[_source] = source;
      }
      get length() {
        return this[_source][dartx.length];
      }
      set length(length) {
        this[_source][dartx.length] = length;
      }
      get(index) {
        return this[_source][dartx.get](index);
      }
      set(index, value) {
        E._check(value);
        this[_source][dartx.set](index, value);
        return value;
      }
    }
    dart.setSignature(MyList, {
      constructors: () => ({new: dart.definiteFunctionType(collection_removes_test.MyList$(E), [core.List$(E)])}),
      methods: () => ({
        get: dart.definiteFunctionType(E, [core.int]),
        set: dart.definiteFunctionType(dart.void, [core.int, E])
      })
    });
    dart.defineExtensionMembers(MyList, ['get', 'set', 'length', 'length']);
    return MyList;
  });
  collection_removes_test.MyList = MyList();
  // Exports:
  exports.collection_removes_test = collection_removes_test;
});
