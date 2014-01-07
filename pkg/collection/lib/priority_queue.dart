// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.pkg.collection.priority_queue;

import "dart:collection" show SplayTreeSet;

/**
 * A priority queue is a priority based work-list of elements.
 *
 * The queue allows adding elements, and removing them again in priority order.
 */
abstract class PriorityQueue<E> {
  /**
   * Number of elements in the queue.
   */
  int get length;

  /**
   * Whether the queue is empty.
   */
  bool get isEmpty;

  /**
   * Whether the queue has any elements.
   */
  bool get isNotEmpty;

  /**
   * Checks if [object] is in the queue.
   *
   * Returns true if the element is found.
   */
  bool contains(E object);

  /**
   * Adds element to the queue.
   *
   * The element will become the next to be removed by [removeFirst]
   * when all elements with higher priority have been removed.
   */
  void add(E element);

  /**
   * Adds all [elements] to the queue.
   */
  void addAll(Iterable<E> elements);

  /**
   * Returns the next element that will be returned by [removeFirst].
   *
   * The element is not removed from the queue.
   *
   * The queue must not be empty when this method is called.
   */
  E get first;

  /**
   * Removes and returns the element with the highest priority.
   *
   * Repeatedly calling this method, without adding element in between,
   * is guaranteed to return elements in non-decreasing order as, specified by
   * [comparison].
   *
   * The queue must not be empty when this method is called.
   */
  E removeFirst();

  /**
   * Removes an element that compares equal to [element] in the queue.
   *
   * Returns true if an element is found and removed,
   * and false if no equal element is found.
   */
  bool remove(E element);

  /**
   * Removes all the elements from this queue and returns them.
   *
   * The returned iterable has no specified order.
   */
  Iterable<E> removeAll();

  /**
   * Removes all the elements from this queue.
   */
  void clear();

  /**
   * Returns a list of the elements of this queue in priority order.
   *
   * The queue is not modified.
   *
   * The order is the order that the elements would be in if they were
   * removed from this queue using [removeFirst].
   */
  List<E> toList();

  /**
   * Return a comparator based set using the comparator of this queue.
   *
   * The queue is not modified.
   *
   * The returned [Set] is currently a [SplayTreeSet],
   * but this may change as other ordered sets are implemented.
   *
   * The set contains all the elements of this queue.
   * If an element occurs more than once in the queue,
   * the set will contain it only once.
   */
  Set<E> toSet();
}

/**
 * Heap based priority queue.
 *
 * The elements are kept in a heap structure,
 * where the element with the highest priority is immediately accessible,
 * and modifying a single element takes
 * logarithmic time in the number of elements on average.
 *
 * * The [add] and [removeFirst] operations take amortized logarithmic time,
 *   O(log(n)), but may occasionally take linear time when growing the capacity
 *   of the heap.
 * * The [addAll] operation works as doing repeated [add] operations.
 * * The [first] getter takes constant time, O(1).
 * * The [clear] and [removeAll] methods also take constant time, O(1).
 * * The [contains] and [remove] operations may need to search the entire
 *   queue for the elements, taking O(n) time.
 * * The [toList] operation effectively sorts the elements, taking O(n*log(n))
 *   time.
 * * The [toSet] operation effectively adds each element to the new set, taking
 *   an expected O(n*log(n)) time.
 */
class HeapPriorityQueue<E> implements PriorityQueue<E> {
  /**
   * Initial capacity of a queue when created, or when added to after a [clear].
   *
   * Number can be any positive value. Picking a size that gives a whole
   * number of "tree levels" in the heap is only done for aesthetic reasons.
   */
  static const int _INITIAL_CAPACITY = 7;

  /**
   * The comparison being used to compare the priority of elements.
   */
  final Comparator comparison;

  /**
   * List implementation of a heap.
   */
  List<E> _queue = new List<E>(_INITIAL_CAPACITY);

  /**
   * Number of elements in queue.
   *
   * The heap is implemented in the first [_length] entries of [_queue].
   */
  int _length = 0;

  /**
   * Create a new priority queue.
   *
   * The [comparison] is a [Comparator] used to compare the priority of
   * elements. An element that compares as less than another element has
   * a higher priority.
   *
   * If [comparison] is omitted, it defaults to [Comparable.compare].
   */
  HeapPriorityQueue([int comparison(E e1, E e2)])
      : comparison = (comparison != null) ? comparison : Comparable.compare;

  void add(E element) {
    _add(element);
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      _add(element);
    }
  }

  void clear() {
    _queue = const [];
    _length = 0;
  }

  bool contains(E object) {
    return _locate(object) >= 0;
  }

  E get first {
    if (_length == 0) throw new StateError("No such element");
    return _queue[0];
  }

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  int get length => _length;

  bool remove(E element) {
    int index = _locate(element);
    if (index < 0) return false;
    E last = _removeLast();
    if (index < _length) {
      int comp = comparison(last, element);
      if (comp <= 0) {
        _bubbleUp(last, index);
      } else {
        _bubbleDown(last, index);
      }
    }
    return true;
  }

  Iterable<E> removeAll() {
    List<E> result = _queue;
    int length = _length;
    _queue = const [];
    _length = 0;
    return result.take(length);
  }

  E removeFirst() {
    if (_length == 0) throw new StateError("No such element");
    E result = _queue[0];
    E last = _removeLast();
    if (_length > 0) {
      _bubbleDown(last, 0);
    }
    return result;
  }

  List<E> toList() {
    List<E> list = new List<E>()..length = _length;
    list.setRange(0, _length, _queue);
    list.sort(comparison);
    return list;
  }

  Set<E> toSet() {
    Set<E> set = new SplayTreeSet<E>(comparison);
    for (int i = 0; i < _length; i++) {
      set.add(_queue[i]);
    }
    return set;
  }

  /**
   * Returns some representation of the queue.
   *
   * The format isn't significant, and may change in the future.
   */
  String toString() {
    return _queue.take(_length).toString();
  }

  /**
   * Add element to the queue.
   *
   * Grows the capacity if the backing list is full.
   */
  void _add(E element) {
    if (_length == _queue.length) _grow();
    _bubbleUp(element, _length++);
  }

  /**
   * Find the index of an object in the heap.
   *
   * Returns -1 if the object is not found.
   */
  int _locate(E object) {
    if (_length == 0) return -1;
    // Count positions from one instad of zero. This gives the numbers
    // some nice properties. For example, all right children are odd,
    // their left sibling is even, and the parent is found by shifting
    // right by one.
    // Valid range for position is [1.._length], inclusive.
    int position = 1;
    // Pre-order depth first search, omit child nodes if the current
    // node has lower priority than [object], because all nodes lower
    // in the heap will also have lower priority.
    do {
      int index = position - 1;
      E element = _queue[index];
      int comp = comparison(element, object);
      if (comp == 0) return index;
      if (comp < 0) {
        // Element may be in subtree.
        // Continue with the left child, if it is there.
        int leftChildPosition = position * 2;
        if (leftChildPosition <= _length) {
          position = leftChildPosition;
          continue;
        }
      }
      // Find the next right sibling or right ancestor sibling.
      do {
        while (position.isOdd) {
          // While position is a right child, go to the parent.
          position >>= 1;
        }
        // Then go to the right sibling of the left-child.
        position += 1;
      } while (position > _length);  // Happens if last element is a left child.
    } while (position != 1);  // At root again. Happens for right-most element.
    return -1;
  }

  E _removeLast() {
    int newLength = _length - 1;
    E last = _queue[newLength];
    _queue[newLength] = null;
    _length = newLength;
    return last;
  }

  /**
   * Place [element] in heap at [index] or above.
   *
   * Put element into the empty cell at `index`.
   * While the `element` has higher priority than the
   * parent, swap it with the parent.
   */
  void _bubbleUp(E element, int index) {
    while (index > 0) {
      int parentIndex = (index - 1) ~/ 2;
      E parent = _queue[parentIndex];
      if (comparison(element, parent) > 0) break;
      _queue[index] = parent;
      index = parentIndex;
    }
    _queue[index] = element;
  }

  /**
   * Place [element] in heap at [index] or above.
   *
   * Put element into the empty cell at `index`.
   * While the `element` has lower priority than either child,
   * swap it with the highest priority child.
   */
  void _bubbleDown(E element, int index) {
    int rightChildIndex = index * 2 + 2;
    while (rightChildIndex < _length) {
      int leftChildIndex = rightChildIndex - 1;
      E leftChild = _queue[leftChildIndex];
      E rightChild = _queue[rightChildIndex];
      int comp = comparison(leftChild, rightChild);
      int minChildIndex;
      E minChild;
      if (comp < 0) {
        minChild = leftChild;
        minChildIndex = leftChildIndex;
      } else {
        minChild = rightChild;
        minChildIndex = rightChildIndex;
      }
      comp = comparison(element, minChild);
      if (comp <= 0) {
        _queue[index] = element;
        return;
      }
      _queue[index] = minChild;
      index = minChildIndex;
      rightChildIndex = index * 2 + 2;
    }
    int leftChildIndex = rightChildIndex - 1;
    if (leftChildIndex < _length) {
      E child = _queue[leftChildIndex];
      int comp = comparison(element, child);
      if (comp > 0) {
        _queue[index] = child;
        index = leftChildIndex;
      }
    }
    _queue[index] = element;
  }

  /**
   * Grows the capacity of the list holding the heap.
   *
   * Called when the list is full.
   */
  void _grow() {
    int newCapacity = _queue.length * 2 + 1;
    if (newCapacity < _INITIAL_CAPACITY) newCapacity = _INITIAL_CAPACITY;
    List<E> newQueue = new List<E>(newCapacity);
    newQueue.setRange(0, _length, _queue);
    _queue = newQueue;
  }
}
