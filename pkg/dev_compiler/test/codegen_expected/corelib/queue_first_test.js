dart_library.library('corelib/queue_first_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__queue_first_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const queue_first_test = Object.create(null);
  let QueueOfint = () => (QueueOfint = dart.constFn(collection.Queue$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  queue_first_test.main = function() {
    let queue1 = QueueOfint().new();
    queue1.add(11);
    queue1.add(12);
    queue1.add(13);
    let queue2 = collection.Queue.new();
    expect$.Expect.equals(11, queue1.first);
    expect$.Expect.throws(dart.fn(() => queue2.first, VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
  };
  dart.fn(queue_first_test.main, VoidTodynamic());
  // Exports:
  exports.queue_first_test = queue_first_test;
});
