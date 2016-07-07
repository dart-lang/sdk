dart_library.library('corelib/hash_set_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hash_set_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hash_set_test_none_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidToSet = () => (VoidToSet = dart.constFn(dart.functionType(core.Set, [])))();
  let IterableToSet = () => (IterableToSet = dart.constFn(dart.functionType(core.Set, [core.Iterable])))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfMutable = () => (JSArrayOfMutable = dart.constFn(_interceptors.JSArray$(hash_set_test_none_multi.Mutable)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let intAndintToSet = () => (intAndintToSet = dart.constFn(dart.definiteFunctionType(core.Set, [core.int, core.int])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FnAndFnTodynamic = () => (FnAndFnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidToSet(), IterableToSet()])))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [VoidToSet()])))();
  let VoidToSet$ = () => (VoidToSet$ = dart.constFn(dart.definiteFunctionType(core.Set, [])))();
  let IterableToSet$ = () => (IterableToSet$ = dart.constFn(dart.definiteFunctionType(core.Set, [core.Iterable])))();
  let VoidToHashSet = () => (VoidToHashSet = dart.constFn(dart.definiteFunctionType(collection.HashSet, [])))();
  let IterableToHashSet = () => (IterableToHashSet = dart.constFn(dart.definiteFunctionType(collection.HashSet, [core.Iterable])))();
  let VoidToLinkedHashSet = () => (VoidToLinkedHashSet = dart.constFn(dart.definiteFunctionType(collection.LinkedHashSet, [])))();
  let IterableToLinkedHashSet = () => (IterableToLinkedHashSet = dart.constFn(dart.definiteFunctionType(collection.LinkedHashSet, [core.Iterable])))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  hash_set_test_none_multi.testSet = function(newSet, newSetFrom) {
    function gen(from, to) {
      return core.Set.from(core.Iterable.generate(dart.notNull(to) - dart.notNull(from), dart.fn(n => dart.notNull(n) + dart.notNull(from), intToint())));
    }
    dart.fn(gen, intAndintToSet());
    function odd(n) {
      return (dart.notNull(n) & 1) == 1;
    }
    dart.fn(odd, intTobool());
    function even(n) {
      return (dart.notNull(n) & 1) == 0;
    }
    dart.fn(even, intTobool());
    {
      let set = newSet();
      for (let i = 0; i < 256; i++) {
        set.add(i);
      }
      set.addAll(gen(256, 512));
      set.addAll(newSetFrom(gen(512, 1000)));
      expect$.Expect.equals(1000, set.length);
      for (let i = 0; i < 1000; i = i + 2)
        set.remove(i);
      expect$.Expect.equals(500, set.length);
      expect$.Expect.isFalse(set.any(even));
      expect$.Expect.isTrue(set.every(odd));
      set.addAll(gen(0, 1000));
      expect$.Expect.equals(1000, set.length);
    }
    {
      let set = newSet();
      set.add(0);
      for (let i = 0; i < 1000; i++) {
        set.add(i + 1);
        set.remove(i);
        expect$.Expect.equals(1, set.length);
      }
    }
    {
      let set = newSet();
      for (let i = 0; i < 1000; i++) {
        set.add(new hash_set_test_none_multi.BadHashCode());
      }
      expect$.Expect.equals(1000, set.length);
    }
    {
      let set = newSet();
      set.add(0);
      set.add(1);
      {
        let iter = set.iterator;
        iter.moveNext();
        set.add(1);
        iter.moveNext();
        set.add(2);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = set.iterator;
        expect$.Expect.equals(3, set.length);
        iter.moveNext();
        iter.moveNext();
        iter.moveNext();
        set.add(3);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = set.iterator;
        iter.moveNext();
        set.remove(1000);
        iter.moveNext();
        let n = core.int._check(iter.current);
        set.remove(n);
        expect$.Expect.equals(n, iter.current);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = set.iterator;
        expect$.Expect.equals(3, set.length);
        iter.moveNext();
        iter.moveNext();
        iter.moveNext();
        let n = core.int._check(iter.current);
        set.remove(n);
        expect$.Expect.equals(n, iter.current);
        expect$.Expect.throws(dart.bind(iter, 'moveNext'), dart.fn(e => core.Error.is(e), dynamicTobool()));
      }
      {
        let iter = set.iterator;
        expect$.Expect.equals(2, set.length);
        iter.moveNext();
        let n = core.int._check(iter.current);
        set.add(n);
        iter.moveNext();
        expect$.Expect.isTrue(set.contains(iter.current));
      }
      {
        let set2 = newSet();
        for (let value of set) {
          set2.add(value);
        }
        let iter = set.iterator;
        set.addAll(set2);
        iter.moveNext();
      }
    }
    {
      for (let i = 1; i < 128; i++) {
        let set = newSetFrom(gen(0, i));
        let iter = set.iterator;
        for (let j = 0; j < i; j++) {
          set.add(j);
        }
        iter.moveNext();
        for (let j = 1; j < i; j++) {
          set.remove(j);
        }
        iter = set.iterator;
        set.add(0);
        iter.moveNext();
      }
    }
    {
      let set = newSet();
      set.add(null);
      expect$.Expect.equals(1, set.length);
      expect$.Expect.isTrue(set.contains(null));
      expect$.Expect.isNull(set.first);
      expect$.Expect.isNull(set.last);
      set.add(null);
      expect$.Expect.equals(1, set.length);
      expect$.Expect.isTrue(set.contains(null));
      set.remove(null);
      expect$.Expect.isTrue(set.isEmpty);
      expect$.Expect.isFalse(set.contains(null));
      set = newSetFrom([null]);
      expect$.Expect.equals(1, set.length);
      expect$.Expect.isTrue(set.contains(null));
      expect$.Expect.isNull(set.first);
      expect$.Expect.isNull(set.last);
      set.add(null);
      expect$.Expect.equals(1, set.length);
      expect$.Expect.isTrue(set.contains(null));
      set.remove(null);
      expect$.Expect.isTrue(set.isEmpty);
      expect$.Expect.isFalse(set.contains(null));
      set = newSetFrom(JSArrayOfint().of([1, 2, 3, null, 4, 5, 6]));
      expect$.Expect.equals(7, set.length);
      for (let i = 7; i < 128; i++) {
        set.add(i);
      }
      expect$.Expect.equals(128, set.length);
      expect$.Expect.isTrue(set.contains(null));
      set.add(null);
      expect$.Expect.equals(128, set.length);
      expect$.Expect.isTrue(set.contains(null));
      set.remove(null);
      expect$.Expect.equals(127, set.length);
      expect$.Expect.isFalse(set.contains(null));
    }
    {
      let set = newSet();
      set.addAll([]);
      expect$.Expect.isTrue(set.isEmpty);
      set.addAll(JSArrayOfint().of([1, 3, 2]));
      expect$.Expect.equals(3, set.length);
      expect$.Expect.isTrue(set.contains(1));
      expect$.Expect.isTrue(set.contains(3));
      expect$.Expect.isTrue(set.contains(2));
      expect$.Expect.isFalse(set.contains(4));
      set.clear();
      expect$.Expect.isTrue(set.isEmpty);
    }
    {
      let set = newSetFrom(JSArrayOfint().of([1, 2, 3]));
      set.removeWhere(dart.fn(each => dart.equals(each, 2), dynamicTobool()));
      expect$.Expect.equals(2, set.length);
      expect$.Expect.isTrue(set.contains(1));
      expect$.Expect.isFalse(set.contains(2));
      expect$.Expect.isTrue(set.contains(3));
      set.retainWhere(dart.fn(each => dart.equals(each, 3), dynamicTobool()));
      expect$.Expect.equals(1, set.length);
      expect$.Expect.isFalse(set.contains(1));
      expect$.Expect.isFalse(set.contains(2));
      expect$.Expect.isTrue(set.contains(3));
    }
    {
      let set = newSet();
      let m1a = new hash_set_test_none_multi.Mutable(1);
      let m1b = new hash_set_test_none_multi.Mutable(1);
      let m2a = new hash_set_test_none_multi.Mutable(2);
      let m2b = new hash_set_test_none_multi.Mutable(2);
      expect$.Expect.isNull(set.lookup(m1a));
      expect$.Expect.isNull(set.lookup(m1b));
      set.add(m1a);
      expect$.Expect.identical(m1a, set.lookup(m1a));
      expect$.Expect.identical(m1a, set.lookup(m1b));
      expect$.Expect.isNull(set.lookup(m2a));
      expect$.Expect.isNull(set.lookup(m2b));
      set.add(m2a);
      expect$.Expect.identical(m2a, set.lookup(m2a));
      expect$.Expect.identical(m2a, set.lookup(m2b));
      set.add(m2b);
      expect$.Expect.identical(m2a, set.lookup(m2a));
      expect$.Expect.identical(m2a, set.lookup(m2b));
      set.remove(m1a);
      set.add(m1b);
      expect$.Expect.identical(m1b, set.lookup(m1a));
      expect$.Expect.identical(m1b, set.lookup(m1b));
      set.add(1);
      expect$.Expect.identical(1, set.lookup(1.0));
      set.add(-0.0);
      expect$.Expect.identical(-0.0, set.lookup(0.0));
    }
    {
      let set = newSet();
      let keys = [];
      for (let i = 65; i >= 2; --i) {
        keys[dartx.add](new hash_set_test_none_multi.Mutable(dart.asInt(math.pow(2, i))));
      }
      for (let key of keys) {
        expect$.Expect.isTrue(set.add(key));
      }
      for (let key of keys) {
        expect$.Expect.isTrue(set.contains(key));
      }
    }
  };
  dart.fn(hash_set_test_none_multi.testSet, FnAndFnTodynamic());
  let const$;
  hash_set_test_none_multi.testIdentitySet = function(create) {
    let set = create();
    set.add(1);
    set.add(2);
    set.add(1);
    expect$.Expect.equals(2, set.length);
    let complex = 4;
    complex = set.length == 2 ? (complex / 4)[dartx.truncate]() : 87;
    expect$.Expect.isTrue(set.contains(complex));
    set.clear();
    let constants = JSArrayOfObject().of([core.double.INFINITY, 0.0, 42, "", null, false, true, const$ || (const$ = dart.const(core.Symbol.new('bif'))), hash_set_test_none_multi.testIdentitySet]);
    set.addAll(constants);
    expect$.Expect.equals(constants[dartx.length], set.length);
    for (let c of constants) {
      expect$.Expect.isTrue(set.contains(c), dart.str`constant: ${c}`);
    }
    expect$.Expect.isTrue(set.containsAll(constants), dart.str`constants: ${set}`);
    set.clear();
    let m1 = new hash_set_test_none_multi.Mutable(1);
    let m2 = new hash_set_test_none_multi.Mutable(2);
    let m3 = new hash_set_test_none_multi.Mutable(3);
    let m4 = new hash_set_test_none_multi.Mutable(2);
    set.addAll(JSArrayOfMutable().of([m1, m2, m3, m4]));
    expect$.Expect.equals(4, set.length);
    expect$.Expect.equals(3, m3.hashCode);
    m3.id = 1;
    expect$.Expect.equals(1, m3.hashCode);
    expect$.Expect.isTrue(set.contains(m3));
    expect$.Expect.isTrue(set.contains(m1));
    set.remove(m3);
    expect$.Expect.isFalse(set.contains(m3));
    expect$.Expect.isTrue(set.contains(m1));
    expect$.Expect.identical(m1, set.lookup(m1));
    expect$.Expect.identical(null, set.lookup(m3));
  };
  dart.fn(hash_set_test_none_multi.testIdentitySet, FnTovoid());
  hash_set_test_none_multi.main = function() {
    hash_set_test_none_multi.testSet(dart.fn(() => core.Set.new(), VoidToSet$()), dart.fn(m => core.Set.from(m), IterableToSet$()));
    hash_set_test_none_multi.testSet(dart.fn(() => collection.HashSet.new(), VoidToHashSet()), dart.fn(m => collection.HashSet.from(m), IterableToHashSet()));
    hash_set_test_none_multi.testSet(dart.fn(() => collection.LinkedHashSet.new(), VoidToLinkedHashSet()), dart.fn(m => collection.LinkedHashSet.from(m), IterableToLinkedHashSet()));
    hash_set_test_none_multi.testIdentitySet(dart.fn(() => core.Set.identity(), VoidToSet$()));
    hash_set_test_none_multi.testIdentitySet(dart.fn(() => collection.HashSet.identity(), VoidToHashSet()));
    hash_set_test_none_multi.testIdentitySet(dart.fn(() => collection.LinkedHashSet.identity(), VoidToLinkedHashSet()));
    hash_set_test_none_multi.testIdentitySet(dart.fn(() => collection.HashSet.new({equals: dart.fn((x, y) => core.identical(x, y), dynamicAnddynamicTobool()), hashCode: dart.fn(x => core.identityHashCode(x), dynamicToint())}), VoidToHashSet()));
    hash_set_test_none_multi.testIdentitySet(dart.fn(() => collection.LinkedHashSet.new({equals: dart.fn((x, y) => core.identical(x, y), dynamicAnddynamicTobool()), hashCode: dart.fn(x => core.identityHashCode(x), dynamicToint())}), VoidToLinkedHashSet()));
  };
  dart.fn(hash_set_test_none_multi.main, VoidTovoid());
  hash_set_test_none_multi.BadHashCode = class BadHashCode extends core.Object {
    new() {
      this.id = (() => {
        let x = hash_set_test_none_multi.BadHashCode.idCounter;
        hash_set_test_none_multi.BadHashCode.idCounter = dart.notNull(x) + 1;
        return x;
      })();
    }
    get hashCode() {
      return 42;
    }
    compareTo(other) {
      return dart.notNull(this.id) - dart.notNull(other.id);
    }
  };
  dart.setSignature(hash_set_test_none_multi.BadHashCode, {
    constructors: () => ({new: dart.definiteFunctionType(hash_set_test_none_multi.BadHashCode, [])}),
    methods: () => ({compareTo: dart.definiteFunctionType(core.int, [hash_set_test_none_multi.BadHashCode])})
  });
  hash_set_test_none_multi.BadHashCode.idCounter = 0;
  hash_set_test_none_multi.Mutable = class Mutable extends core.Object {
    new(id) {
      this.id = id;
    }
    get hashCode() {
      return this.id;
    }
    ['=='](other) {
      return hash_set_test_none_multi.Mutable.is(other) && this.id == other.id;
    }
  };
  dart.setSignature(hash_set_test_none_multi.Mutable, {
    constructors: () => ({new: dart.definiteFunctionType(hash_set_test_none_multi.Mutable, [core.int])})
  });
  // Exports:
  exports.hash_set_test_none_multi = hash_set_test_none_multi;
});
