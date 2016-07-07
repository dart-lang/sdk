dart_library.library('corelib/queue_single_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__queue_single_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const queue_single_test = Object.create(null);
  let QueueOfint = () => (QueueOfint = dart.constFn(collection.Queue$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  queue_single_test.main = function() {
    let queue1 = QueueOfint().new();
    queue1.add(42);
    let queue2 = collection.Queue.new();
    queue2.add(11);
    queue2.add(12);
    queue2.add(13);
    let queue3 = collection.Queue.new();
    expect$.Expect.equals(42, queue1.single);
    expect$.Expect.throws(dart.fn(() => queue2.single, VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => queue3.single, VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
  };
  dart.fn(queue_single_test.main, VoidTodynamic());
  // Exports:
  exports.queue_single_test = queue_single_test;
});
