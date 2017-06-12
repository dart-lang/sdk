// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A queue of operations in an [AnalysisServer].
 */
class ServerOperationQueue {
  final List<Queue<ServerOperation>> _queues = <Queue<ServerOperation>>[];

  ServerOperationQueue() {
    for (int i = 0; i < ServerOperationPriority.COUNT; i++) {
      var queue = new DoubleLinkedQueue<ServerOperation>();
      _queues.add(queue);
    }
  }

  /**
   * Returns `true` if there are no queued [ServerOperation]s.
   */
  bool get isEmpty {
    return _queues.every((queue) => queue.isEmpty);
  }

  /**
   * Adds the given operation to this queue. The exact position in the queue
   * depends on the priority of the given operation relative to the priorities
   * of the other operations in the queue.
   */
  void add(ServerOperation operation) {
    int queueIndex = operation.priority.ordinal;
    Queue<ServerOperation> queue = _queues[queueIndex];
    // try to merge into an existing operation
    for (ServerOperation existingOperation in queue) {
      if (existingOperation is MergeableOperation &&
          existingOperation.merge(operation)) {
        return;
      }
    }
    // add it
    queue.addLast(operation);
  }

  /**
   * Removes all elements in the queue.
   */
  void clear() {
    for (Queue<ServerOperation> queue in _queues) {
      queue.clear();
    }
  }

  /**
   * The given [context] has been removed, so all pending operations that refer
   * to it should be removed from the queue.
   */
  void contextRemoved(AnalysisContext context) {
    for (Queue<ServerOperation> queue in _queues) {
      queue.removeWhere((operation) => operation.context == context);
    }
  }

  /**
   * Return the next operation to perform, or `null` if the queue is empty.
   * This method does not change the queue.
   */
  ServerOperation peek() {
    for (Queue<ServerOperation> queue in _queues) {
      if (!queue.isEmpty) {
        return queue.first;
      }
    }
    return null;
  }

  /**
   * Reschedules queued operations according their current priorities.
   */
  void reschedule() {
    // prepare all operations
    List<ServerOperation> operations = <ServerOperation>[];
    for (Queue<ServerOperation> queue in _queues) {
      operations.addAll(queue);
      queue.clear();
    }
    // add all operations
    operations.forEach(add);
  }

  /**
   * The given [source] if about to changed.
   */
  void sourceAboutToChange(Source source) {
    for (Queue<ServerOperation> queue in _queues) {
      queue.removeWhere((operation) {
        if (operation is SourceSensitiveOperation) {
          return operation.shouldBeDiscardedOnSourceChange(source);
        }
        return false;
      });
    }
  }

  /**
   * Returns the next operation to perform or `null` if empty.
   */
  ServerOperation take() {
    for (Queue<ServerOperation> queue in _queues) {
      if (!queue.isEmpty) {
        return queue.removeFirst();
      }
    }
    return null;
  }

  /**
   * Returns an operation that satisfies the given [test] or `null`.
   */
  ServerOperation takeIf(bool test(ServerOperation operation)) {
    for (Queue<ServerOperation> queue in _queues) {
      for (ServerOperation operation in queue) {
        if (test(operation)) {
          queue.remove(operation);
          return operation;
        }
      }
    }
    return null;
  }
}
