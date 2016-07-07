dart_library.library('corelib/queue_iterator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__queue_iterator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const queue_iterator_test = Object.create(null);
  let QueueOfint = () => (QueueOfint = dart.constFn(collection.Queue$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  queue_iterator_test.QueueIteratorTest = class QueueIteratorTest extends core.Object {
    static testMain() {
      queue_iterator_test.QueueIteratorTest.testSmallQueue();
      queue_iterator_test.QueueIteratorTest.testLargeQueue();
      queue_iterator_test.QueueIteratorTest.testEmptyQueue();
    }
    static sum(expected, it) {
      let count = 0;
      while (dart.test(it.moveNext())) {
        count = dart.notNull(count) + dart.notNull(it.current);
      }
      expect$.Expect.equals(expected, count);
    }
    static testSmallQueue() {
      let queue = QueueOfint().new();
      queue.addLast(1);
      queue.addLast(2);
      queue.addLast(3);
      let it = queue.iterator;
      queue_iterator_test.QueueIteratorTest.sum(6, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
    static testLargeQueue() {
      let queue = QueueOfint().new();
      let count = 0;
      for (let i = 0; i < 100; i++) {
        count = count + i;
        queue.addLast(i);
      }
      let it = queue.iterator;
      queue_iterator_test.QueueIteratorTest.sum(count, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
    static testEmptyQueue() {
      let queue = QueueOfint().new();
      let it = queue.iterator;
      queue_iterator_test.QueueIteratorTest.sum(0, it);
      expect$.Expect.isFalse(it.moveNext());
      expect$.Expect.isNull(it.current);
    }
  };
  dart.setSignature(queue_iterator_test.QueueIteratorTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      sum: dart.definiteFunctionType(core.int, [core.int, core.Iterator$(core.int)]),
      testSmallQueue: dart.definiteFunctionType(dart.void, []),
      testLargeQueue: dart.definiteFunctionType(dart.void, []),
      testEmptyQueue: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testMain', 'sum', 'testSmallQueue', 'testLargeQueue', 'testEmptyQueue']
  });
  queue_iterator_test.main = function() {
    queue_iterator_test.QueueIteratorTest.testMain();
  };
  dart.fn(queue_iterator_test.main, VoidTodynamic());
  // Exports:
  exports.queue_iterator_test = queue_iterator_test;
});
