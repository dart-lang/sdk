dart_library.library('corelib/iterable_length_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_length_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_length_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  iterable_length_test.A = class A extends collection.IterableBase {
    new(count) {
      this.count = count;
      super.new();
    }
    get iterator() {
      return new iterable_length_test.AIterator(this.count);
    }
  };
  dart.addSimpleTypeTests(iterable_length_test.A);
  dart.setSignature(iterable_length_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(iterable_length_test.A, [core.int])})
  });
  dart.defineExtensionMembers(iterable_length_test.A, ['iterator']);
  const _count = Symbol('_count');
  const _current = Symbol('_current');
  iterable_length_test.AIterator = class AIterator extends core.Object {
    new(count) {
      this[_count] = count;
      this[_current] = null;
    }
    moveNext() {
      if (dart.notNull(this[_count]) > 0) {
        this[_current] = this[_count];
        this[_count] = dart.notNull(this[_count]) - 1;
        return true;
      }
      this[_current] = null;
      return false;
    }
    get current() {
      return this[_current];
    }
  };
  iterable_length_test.AIterator[dart.implements] = () => [core.Iterator];
  dart.setSignature(iterable_length_test.AIterator, {
    constructors: () => ({new: dart.definiteFunctionType(iterable_length_test.AIterator, [core.int])}),
    methods: () => ({moveNext: dart.definiteFunctionType(core.bool, [])})
  });
  iterable_length_test.main = function() {
    let a = new iterable_length_test.A(10);
    expect$.Expect.equals(10, a.length);
    a = new iterable_length_test.A(0);
    expect$.Expect.equals(0, a.length);
    a = new iterable_length_test.A(5);
    expect$.Expect.equals(5, a.map(dart.dynamic)(dart.fn(e => dart.dsend(e, '+', 1), dynamicTodynamic()))[dartx.length]);
    expect$.Expect.equals(3, a.where(dart.fn(e => core.bool._check(dart.dsend(e, '>=', 3)), dynamicTobool()))[dartx.length]);
  };
  dart.fn(iterable_length_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_length_test = iterable_length_test;
});
