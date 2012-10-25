// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [Queue] is a collection that can be manipulated at both ends. One
 * can iterate over the elements of a queue through [forEach] or with
 * an [Iterator].
 */
abstract class Queue<E> extends Collection<E> {

  /**
   * Creates a queue.
   */
  factory Queue() => new DoubleLinkedQueue<E>();

  /**
   * Creates a queue with the elements of [other]. The order in
   * the queue will be the order provided by the iterator of [other].
   */
  factory Queue.from(Iterable<E> other) => new DoubleLinkedQueue<E>.from(other);

  /**
   * Removes and returns the first element of this queue. Throws an
   * [EmptyQueueException] exception if this queue is empty.
   */
  E removeFirst();

  /**
   * Removes and returns the last element of the queue. Throws an
   * [EmptyQueueException] exception if this queue is empty.
   */
  E removeLast();

  /**
   * Adds [value] at the beginning of the queue.
   */
  void addFirst(E value);

  /**
   * Adds [value] at the end of the queue.
   */
  void addLast(E value);

  /**
   * Adds [value] at the end of the queue.
   */
  void add(E value);

  /**
   * Adds all elements of [collection] at the end of the queue. The
   * length of the queue is extended by the length of [collection].
   */
  void addAll(Collection<E> collection);

  /**
   * Returns the first element of the queue. Throws an
   * [EmptyQueueException] exception if this queue is empty.
   */
  E get first;

  /**
   * Returns the last element of the queue. Throws an
   * [EmptyQueueException] exception if this queue is empty.
   */
  E get last;

  /**
   * Removes all elements in the queue. The size of the queue becomes zero.
   */
  void clear();
}
