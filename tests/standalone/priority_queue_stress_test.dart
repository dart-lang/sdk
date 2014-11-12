// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library priority_queue;

import 'dart:collection';
import 'dart:math';

/**
 * A priority used for the priority queue. Subclasses only need to implement
 * the compareTo function.
 */
abstract class Priority implements Comparable {
  /**
   * Return < 0 if other is bigger, >0 if other is smaller, 0 if they are equal.
   */
  int compareTo(Priority other);
  bool operator<(Priority other) => compareTo(other) < 0;
  bool operator>(Priority other) => compareTo(other) > 0;
  bool operator==(Priority other) => compareTo(other) == 0;
}

/**
 * Priority based on integers.
 */
class IntPriority extends Priority {
  int priority;
  IntPriority(int this.priority);

  int compareTo(IntPriority other) {
    return priority - other.priority;
  }
  String toString() => "$priority";
}

/**
 * An element of a priority queue. The type is used restriction based
 * querying of the queues.
 */
abstract class TypedElement<V> {
  bool typeEquals(var other);
}

class StringTypedElement<V> extends TypedElement{
  String type;
  V value;
  StringTypedElement(String this.type, V this.value);
  bool typeEquals(String otherType) => otherType == type;
  String toString() => "<Type: $type, Value: $value>";
}


/**
 * A priority node in a priority queue. A priority node contains all of the
 * values for a given priority in a given queue. It is part of a linked
 * list of nodes, with prev and next pointers.
 */
class PriorityNode<N extends TypedElement, T extends Priority> {
  T priority;
  Queue<N> values;
  PriorityNode prev;
  PriorityNode next;
  PriorityNode(N initialNode, T this.priority)
    : values = new Queue<N>() {
    add(initialNode);
  }

  void add(N n) => values.add(n);

  bool remove(N n) => values.remove(n);

  N removeFirst() => values.removeFirst();

  bool get isEmpty => values.isEmpty;

  N get first => values.first;

  String toString() => "Priority: $priority $values";
}

/**
 * A priority queue with a FIFO property for nodes with same priority.
 * The queue guarantees that nodes are returned in the same order they
 * are added for a given priority.
 * For type safety this queue is guarded by the elements being subclasses of
 * TypedElement - this is not strictly neccesary since we never actually
 * use the value or type of the nodes.
 */
class PriorityQueue<N extends TypedElement, P extends Priority> {
  PriorityNode<N, P> head;
  int length = 0;

  void add(N value, P priority) {
    length++;
    if (head == null) {
      head = new PriorityNode<N, P>(value, priority);
      return;
    }
    assert(head.next == null);
    var node = head;
    while (node.prev != null && node.priority > priority) {
      node = node.prev;
    }
    if (node.priority == priority) {
      node.add(value);
    } else if (node.priority < priority) {
      var newNode = new PriorityNode<N, P>(value, priority);
      newNode.next = node.next;
      if (node.next != null) node.next.prev = newNode;
      newNode.prev = node;
      node.next = newNode;
      if (node == head) head = newNode;
    } else {
      var newNode = new PriorityNode<N, P>(value, priority);
      node.prev = newNode;
      newNode.next = node;
    }
  }

  N get first => head.first;

  Priority get firstPriority => head.priority;

  bool get isEmpty => head == null;

  N removeFirst() {
    if (isEmpty) throw "Can't get element from empty queue";
    var value = head.removeFirst();
    if (head.isEmpty) {
      if (head.prev != null) {
        head.prev.next = null;
      }
      head = head.prev;
    }
    length--;
    assert(head == null || head.next == null);
    return value;
  }

  String toString() {
    if (head == null) return "Empty priority queue";
    var node = head;
    var buffer = new StringBuffer();
    while (node.prev != null) {
      buffer.writeln(node);
      node = node.prev;
    }
    buffer.writeln(node);
    return buffer.toString();
  }
}

/**
 * Implements a specialized priority queue that efficiently allows getting
 * the highest priorized node that adheres to a set of restrictions.
 * Most notably it allows to get the highest priority node where the node's
 * type is not in an exclude list.
 * In addition, the queue has a number of properties:
 *   The queue has fifo semantics for nodes with the same priority and type,
 *   i.e., if nodes a and b are added to the queue with priority x and type z
 *   then a is returned first iff a was added before b
 * For different types with the same priority no guarantees are given, but
 * the returned values try to be fair by returning from the biggest list of
 * tasks in case of priority clash. (This could be fixed by adding timestamps
 * to every node, that is _only_ used when collisions occur, not for
 * insertions)
 */
class RestrictViewPriorityQueue<N extends TypedElement, P extends Priority> {
  // We can't use the basic dart priority queue since it does not guarantee
  // FIFO for items with the same order. This is currently not uptimized for
  // different N, if many different N is expected here we should have a
  // priority queue instead of a list.
  List<PriorityQueue<N, P>> restrictedQueues = new List<PriorityQueue<N, P>>();
  PriorityQueue<N, P> mainQueue = new PriorityQueue<N, P>();

  void add(N value, P priority) {
    for (var queue in restrictedQueues) {
      if (queue.first.value == value) {
        queue.add(value, priority);
      }
    }
    mainQueue.add(value, priority);
  }

  bool get isEmpty => restrictedQueues.length + mainQueue.length == 0;

  int get length => restrictedQueues.fold(0, (v, e) => v + e.length) +
                    mainQueue.length;

  PriorityQueue getRestricted(List<N> restrictions) {
    var current = null;
    // Find highest restricted priority.
    for (var queue in restrictedQueues) {
      if (!restrictions.any((e) => queue.head.first.typeEquals(e))) {
        if (current == null || queue.firstPriority > current.firstPriority) {
          current = queue;
        } else if (current.firstPriority == queue.firstPriority) {
          current = queue.length > current.length ? queue : current;
        }
      }
    }
    return current;
  }

  N get first {
    if (isEmpty) throw "Trying to remove node from empty queue";
    var candidate = getRestricted([]);
    if (candidate != null &&
        (mainQueue.isEmpty ||
         mainQueue.firstPriority < candidate.firstPriority)) {
      return candidate.first;
    }
    return mainQueue.isEmpty ? null : mainQueue.first;
  }

  /**
   * Returns the node that under the given set of restrictions.
   * If the queue is empty this function throws.
   * If the queue is not empty, but no node exists that adheres to the
   * restrictions we return null.
   */
  N removeFirst({List restrictions: const []}) {
    if (isEmpty) throw "Trying to remove node from empty queue";
    var candidate = getRestricted(restrictions);

    if (candidate != null &&
        (mainQueue.isEmpty ||
         mainQueue.firstPriority < candidate.firstPriority)) {
      var value = candidate.removeFirst();
      if (candidate.isEmpty) restrictedQueues.remove(candidate);
      return value;
    }
    while (!mainQueue.isEmpty) {
      var currentPriority = mainQueue.firstPriority;
      var current = mainQueue.removeFirst();
      if (!restrictions.any((e) => current.typeEquals(e))) {
        return current;
      } else {
        var restrictedQueue = restrictedQueues
          .firstWhere((e) => current.typeEquals(e.first.type),
                      orElse: () => null);
        if (restrictedQueue == null) {
          restrictedQueue = new PriorityQueue<N, P>();
          restrictedQueues.add(restrictedQueue);
        }
        restrictedQueue.add(current, currentPriority);
      }
    }
    return null;
  }

  String toString() {
    if (isEmpty) return "Empty queue";
    var buffer = new StringBuffer();
    if (!restrictedQueues.isEmpty) {
      buffer.writeln("Restricted queues");
      for (var queue in restrictedQueues) {
        buffer.writeln("$queue");
      }
    }
    buffer.writeln("Main queue:");
    buffer.writeln("$mainQueue");
    return buffer.toString();
  }
}

/// TEMPORARY TESTING AND PERFORMANCE
void main([args]) {
  stress(new RestrictViewPriorityQueue<StringTypedElement, IntPriority>());
}

void stress(queue) {
  final int SIZE = 50000;
  Random random = new Random(29);

  var priorities = [1, 2, 3, 16, 32, 42, 56, 57, 59, 90];
  var values = [new StringTypedElement('safari', 'foo'),
                new StringTypedElement('ie', 'bar'),
                new StringTypedElement('ff', 'foobar'),
                new StringTypedElement('dartium', 'barfoo'),
                new StringTypedElement('chrome', 'hest'),
                new StringTypedElement('drt', 'fisk')];

  var restricted = ['safari', 'chrome'];


  void addRandom() {
    queue.add(values[random.nextInt(values.length)],
              new IntPriority(priorities[random.nextInt(priorities.length)]));
  }

  var stopwatch = new Stopwatch()..start();
  while(queue.length < SIZE) {
    addRandom();
  }

  stopwatch.stop();
  print("Adding took: ${stopwatch.elapsedMilliseconds}");
  print("Queue length: ${queue.length}");

  stopwatch = new Stopwatch()..start();
  while(queue.length > 0) {
    queue.removeFirst();
  }
  stopwatch.stop();
  print("Remowing took: ${stopwatch.elapsedMilliseconds}");
  print("Queue length: ${queue.length}");


  print("Restricted add/remove");
  while(queue.length < SIZE) {
    addRandom();
  }

  for (int i = 0; i < SIZE; i++) {
    if (random.nextDouble() < 0.5) {
      queue.removeFirst(restrictions: restricted);
    } else {
      queue.removeFirst();
    }
    addRandom();
  }
}
