dart_library.library('corelib/set_iterator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__set_iterator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const set_iterator_test = Object.create(null);
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let SetOfString = () => (SetOfString = dart.constFn(core.Set$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _hashCode = Symbol('_hashCode');
  set_iterator_test.FixedHashCode = class FixedHashCode extends core.Object {
    new(hashCode) {
      this[_hashCode] = hashCode;
    }
    get hashCode() {
      return this[_hashCode];
    }
  };
  dart.setSignature(set_iterator_test.FixedHashCode, {
    constructors: () => ({new: dart.definiteFunctionType(set_iterator_test.FixedHashCode, [core.int])})
  });
  set_iterator_test.SetIteratorTest = class SetIteratorTest extends core.Object {
    static testMain() {
      set_iterator_test.SetIteratorTest.testSmallSet();
      set_iterator_test.SetIteratorTest.testLargeSet();
      set_iterator_test.SetIteratorTest.testEmptySet();
      set_iterator_test.SetIteratorTest.testSetWithDeletedEntries();
      set_iterator_test.SetIteratorTest.testBug5116829();
      set_iterator_test.SetIteratorTest.testDifferentSizes();
      set_iterator_test.SetIteratorTest.testDifferentHashCodes();
    }
    static sum(expected, it) {
      let count = 0;
      while (dart.test(it.moveNext())) {
        count = dart.notNull(count) + dart.notNull(it.current);
      }
      expect$.Expect.equals(expected, count);
    }
    static testSmallSet() {
      let set = SetOfint().new();
      set.add(1);
      set.add(2);
      set.add(3);
      let it = set.iterator;
      set_iterator_test.SetIteratorTest.sum(6, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
    static testLargeSet() {
      let set = SetOfint().new();
      let count = 0;
      for (let i = 0; i < 100; i++) {
        count = count + i;
        set.add(i);
      }
      let it = set.iterator;
      set_iterator_test.SetIteratorTest.sum(count, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
    static testEmptySet() {
      let set = SetOfint().new();
      let it = set.iterator;
      set_iterator_test.SetIteratorTest.sum(0, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
    static testSetWithDeletedEntries() {
      let set = SetOfint().new();
      for (let i = 0; i < 100; i++) {
        set.add(i);
      }
      for (let i = 0; i < 100; i++) {
        set.remove(i);
      }
      let it = set.iterator;
      expect$.Expect.isFalse(it.moveNext());
      it = set.iterator;
      set_iterator_test.SetIteratorTest.sum(0, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
      let count = 0;
      for (let i = 0; i < 100; i++) {
        set.add(i);
        if (i[dartx['%']](2) == 0)
          set.remove(i);
        else {
          count = count + i;
        }
      }
      it = set.iterator;
      set_iterator_test.SetIteratorTest.sum(count, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
    static testBug5116829() {
      let mystrs = SetOfString().new();
      mystrs.add("A");
      let seen = 0;
      for (let elt of mystrs) {
        seen++;
        expect$.Expect.equals("A", elt);
      }
      expect$.Expect.equals(1, seen);
    }
    static testDifferentSizes() {
      for (let i = 1; i < 20; i++) {
        let set = core.Set.new();
        let sum = 0;
        for (let j = 0; j < i; j++) {
          set.add(j);
          sum = sum + j;
        }
        let count = 0;
        let controlSum = 0;
        for (let x of set) {
          core.int._check(x);
          controlSum = controlSum + dart.notNull(x);
          count++;
        }
        expect$.Expect.equals(i, count);
        expect$.Expect.equals(sum, controlSum);
      }
    }
    static testDifferentHashCodes() {
      for (let i = -20; i < 20; i++) {
        let set = core.Set.new();
        let element = new set_iterator_test.FixedHashCode(i);
        set.add(element);
        expect$.Expect.equals(1, set.length);
        let foundIt = false;
        for (let x of set) {
          foundIt = true;
          expect$.Expect.equals(true, core.identical(x, element));
        }
        expect$.Expect.equals(true, foundIt);
      }
    }
  };
  dart.setSignature(set_iterator_test.SetIteratorTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      sum: dart.definiteFunctionType(core.int, [core.int, core.Iterator$(core.int)]),
      testSmallSet: dart.definiteFunctionType(dart.void, []),
      testLargeSet: dart.definiteFunctionType(dart.void, []),
      testEmptySet: dart.definiteFunctionType(dart.void, []),
      testSetWithDeletedEntries: dart.definiteFunctionType(dart.void, []),
      testBug5116829: dart.definiteFunctionType(dart.void, []),
      testDifferentSizes: dart.definiteFunctionType(dart.void, []),
      testDifferentHashCodes: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testMain', 'sum', 'testSmallSet', 'testLargeSet', 'testEmptySet', 'testSetWithDeletedEntries', 'testBug5116829', 'testDifferentSizes', 'testDifferentHashCodes']
  });
  set_iterator_test.main = function() {
    set_iterator_test.SetIteratorTest.testMain();
  };
  dart.fn(set_iterator_test.main, VoidTodynamic());
  // Exports:
  exports.set_iterator_test = set_iterator_test;
});
