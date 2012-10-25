// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * An entry in a doubly linked list. It contains a pointer to the next
 * entry, the previous entry, and the boxed element.
 */
class DoubleLinkedQueueEntry<E> {
  DoubleLinkedQueueEntry<E> _previous;
  DoubleLinkedQueueEntry<E> _next;
  E _element;

  DoubleLinkedQueueEntry(E e) {
    _element = e;
  }

  void _link(DoubleLinkedQueueEntry<E> p,
             DoubleLinkedQueueEntry<E> n) {
    _next = n;
    _previous = p;
    p._next = this;
    n._previous = this;
  }

  void append(E e) {
    new DoubleLinkedQueueEntry<E>(e)._link(this, _next);
  }

  void prepend(E e) {
    new DoubleLinkedQueueEntry<E>(e)._link(_previous, this);
  }

  E remove() {
    _previous._next = _next;
    _next._previous = _previous;
    _next = null;
    _previous = null;
    return _element;
  }

  DoubleLinkedQueueEntry<E> _asNonSentinelEntry() {
    return this;
  }

  DoubleLinkedQueueEntry<E> previousEntry() {
    return _previous._asNonSentinelEntry();
  }

  DoubleLinkedQueueEntry<E> nextEntry() {
    return _next._asNonSentinelEntry();
  }

  E get element {
    return _element;
  }

  void set element(E e) {
    _element = e;
  }
}

/**
 * A sentinel in a double linked list is used to manipulate the list
 * at both ends. A double linked list has exactly one sentinel, which
 * is the only entry when the list is constructed. Initially, a
 * sentinel has its next and previous entry point to itself. A
 * sentinel does not box any user element.
 */
class _DoubleLinkedQueueEntrySentinel<E> extends DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueEntrySentinel() : super(null) {
    _link(this, this);
  }

  E remove() {
    throw const EmptyQueueException();
  }

  DoubleLinkedQueueEntry<E> _asNonSentinelEntry() {
    return null;
  }

  void set element(E e) {
    // This setter is unreachable.
    assert(false);
  }

  E get element {
    throw const EmptyQueueException();
  }
}

/**
 * Implementation of a double linked list that box list elements into
 * DoubleLinkedQueueEntry objects.
 */
class DoubleLinkedQueue<E> implements Queue<E> {
  _DoubleLinkedQueueEntrySentinel<E> _sentinel;

  DoubleLinkedQueue() {
    _sentinel = new _DoubleLinkedQueueEntrySentinel<E>();
  }

  factory DoubleLinkedQueue.from(Iterable<E> other) {
    Queue<E> list = new DoubleLinkedQueue();
    for (final e in other) {
      list.addLast(e);
    }
    return list;
  }

  void addLast(E value) {
    _sentinel.prepend(value);
  }

  void addFirst(E value) {
    _sentinel.append(value);
  }

  void add(E value) {
    addLast(value);
  }

  void addAll(Collection<E> collection) {
    for (final e in collection) {
      add(e);
    }
  }

  E removeLast() {
    return _sentinel._previous.remove();
  }

  E removeFirst() {
    return _sentinel._next.remove();
  }

  E get first {
    return _sentinel._next.element;
  }

  E get last {
    return _sentinel._previous.element;
  }

  DoubleLinkedQueueEntry<E> lastEntry() {
    return _sentinel.previousEntry();
  }

  DoubleLinkedQueueEntry<E> firstEntry() {
    return _sentinel.nextEntry();
  }

  int get length {
    int counter = 0;
    forEach(void _(E element) { counter++; });
    return counter;
  }

  bool get isEmpty {
    return (_sentinel._next === _sentinel);
  }

  void clear() {
    _sentinel._next = _sentinel;
    _sentinel._previous = _sentinel;
  }

  void forEach(void f(E element)) {
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (entry !== _sentinel) {
      DoubleLinkedQueueEntry<E> nextEntry = entry._next;
      f(entry._element);
      entry = nextEntry;
    }
  }

  void forEachEntry(void f(DoubleLinkedQueueEntry<E> element)) {
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (entry !== _sentinel) {
      DoubleLinkedQueueEntry<E> nextEntry = entry._next;
      f(entry);
      entry = nextEntry;
    }
  }

  bool every(bool f(E element)) {
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (entry !== _sentinel) {
      DoubleLinkedQueueEntry<E> nextEntry = entry._next;
      if (!f(entry._element)) return false;
      entry = nextEntry;
    }
    return true;
  }

  bool some(bool f(E element)) {
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (entry !== _sentinel) {
      DoubleLinkedQueueEntry<E> nextEntry = entry._next;
      if (f(entry._element)) return true;
      entry = nextEntry;
    }
    return false;
  }

  Queue map(f(E element)) {
    Queue other = new Queue();
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (entry !== _sentinel) {
      DoubleLinkedQueueEntry<E> nextEntry = entry._next;
      other.addLast(f(entry._element));
      entry = nextEntry;
    }
    return other;
  }

  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic previousValue, E element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Queue<E> filter(bool f(E element)) {
    Queue<E> other = new Queue<E>();
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (entry !== _sentinel) {
      DoubleLinkedQueueEntry<E> nextEntry = entry._next;
      if (f(entry._element)) other.addLast(entry._element);
      entry = nextEntry;
    }
    return other;
  }

  _DoubleLinkedQueueIterator<E> iterator() {
    return new _DoubleLinkedQueueIterator<E>(_sentinel);
  }

  String toString() {
    return Collections.collectionToString(this);
  }
}

class _DoubleLinkedQueueIterator<E> implements Iterator<E> {
  final _DoubleLinkedQueueEntrySentinel<E> _sentinel;
  DoubleLinkedQueueEntry<E> _currentEntry;

  _DoubleLinkedQueueIterator(_DoubleLinkedQueueEntrySentinel this._sentinel) {
    _currentEntry = _sentinel;
  }

  bool get hasNext {
    return _currentEntry._next !== _sentinel;
  }

  E next() {
    if (!hasNext) {
      throw const NoMoreElementsException();
    }
    _currentEntry = _currentEntry._next;
    return _currentEntry.element;
  }
}
