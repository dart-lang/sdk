dart_library.library('corelib/has_next_iterator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__has_next_iterator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const has_next_iterator_test = Object.create(null);
  let HasNextIteratorOfint = () => (HasNextIteratorOfint = dart.constFn(collection.HasNextIterator$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  has_next_iterator_test.main = function() {
    let it = new collection.HasNextIterator([][dartx.iterator]);
    expect$.Expect.isFalse(it.hasNext);
    expect$.Expect.isFalse(it.hasNext);
    expect$.Expect.throws(dart.fn(() => it.next(), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.isFalse(it.hasNext);
    it = new (HasNextIteratorOfint())(JSArrayOfint().of([1])[dartx.iterator]);
    expect$.Expect.isTrue(it.hasNext);
    expect$.Expect.isTrue(it.hasNext);
    expect$.Expect.equals(1, it.next());
    expect$.Expect.isFalse(it.hasNext);
    expect$.Expect.isFalse(it.hasNext);
    expect$.Expect.throws(dart.fn(() => it.next(), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.isFalse(it.hasNext);
    it = new (HasNextIteratorOfint())(JSArrayOfint().of([1, 2])[dartx.iterator]);
    expect$.Expect.isTrue(it.hasNext);
    expect$.Expect.isTrue(it.hasNext);
    expect$.Expect.equals(1, it.next());
    expect$.Expect.isTrue(it.hasNext);
    expect$.Expect.isTrue(it.hasNext);
    expect$.Expect.equals(2, it.next());
    expect$.Expect.isFalse(it.hasNext);
    expect$.Expect.isFalse(it.hasNext);
    expect$.Expect.throws(dart.fn(() => it.next(), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.isFalse(it.hasNext);
  };
  dart.fn(has_next_iterator_test.main, VoidTodynamic());
  // Exports:
  exports.has_next_iterator_test = has_next_iterator_test;
});
