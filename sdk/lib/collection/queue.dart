// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * A [Queue] is a collection that can be manipulated at both ends. One
 * can iterate over the elements of a queue through [forEach] or with
 * an [Iterator].
 *
 * It is generally not allowed to modify the queue (add or remove entries) while
 * an operation on the queue is being performed, for example during a call to
 * [forEach].
 * Modifying the queue while it is being iterated will most likely break the
 * iteration.
 * This goes both for using the [iterator] directly, or for iterating an
 * `Iterable` returned by a method like [map] or [where].
 */
abstract class Queue<E> implements EfficientLengthIterable<E> {
  /**
   * Creates a queue.
   */
  factory Queue() = ListQueue<E>;

  /**
   * Creates a queue containing all [elements].
   *
   * The element order in the queue is as if the elements were added using
   * [addLast] in the order provided by [elements.iterator].
   */
  factory Queue.from(Iterable elements) = ListQueue<E>.from;

  /**
   * Removes and returns the first element of this queue.
   *
   * The queue must not be empty when this method is called.
   */
  E removeFirst();

  /**
   * Removes and returns the last element of the queue.
   *
   * The queue must not be empty when this method is called.
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
   * Remove a single instance of [value] from the queue.
   *
   * Returns `true` if a value was removed, or `false` if the queue
   * contained no element equal to [value].
   */
  bool remove(Object value);

  /**
   * Adds all elements of [iterable] at the end of the queue. The
   * length of the queue is extended by the length of [iterable].
   */
  void addAll(Iterable<E> iterable);

  /**
   * Removes all elements matched by [test] from the queue.
   *
   * The `test` function must not throw or modify the queue.
   */
  void removeWhere(bool test(E element));

  /**
   * Removes all elements not matched by [test] from the queue.
   *
   * The `test` function must not throw or modify the queue.
   */
  void retainWhere(bool test(E element));

  /**
   * Removes all elements in the queue. The size of the queue becomes zero.
   */
  void clear();
}

class _DoubleLink<Link extends _DoubleLink<Link>> {
  Link _previousLink;
  Link _nextLink;

  void _link(Link previous, Link next) {
    _nextLink = next;
    _previousLink = previous;
    if (previous != null) previous._nextLink = this;
    if (next != null) next._previousLink = this;
  }

  void _unlink() {
    if (_previousLink != null) _previousLink._nextLink = _nextLink;
    if (_nextLink != null) _nextLink._previousLink = _previousLink;
    _nextLink = null;
    _previousLink = null;
  }
}

/**
 * An entry in a doubly linked list. It contains a pointer to the next
 * entry, the previous entry, and the boxed element.
 */
class DoubleLinkedQueueEntry<E> extends _DoubleLink<DoubleLinkedQueueEntry<E>> {
  /// The element in the queue.
  E element;

  DoubleLinkedQueueEntry(this.element);

  /// Appends the given [e] as entry just after this entry.
  void append(E e) {
    new DoubleLinkedQueueEntry<E>(e)._link(this, _nextLink);
  }

  /// Prepends the given [e] as entry just before this entry.
  void prepend(E e) {
    new DoubleLinkedQueueEntry<E>(e)._link(_previousLink, this);
  }

  E remove() {
    _unlink();
    return element;
  }

  /// Returns the previous entry or `null` if there is none.
  DoubleLinkedQueueEntry<E> previousEntry() => _previousLink;

  /// Returns the next entry or `null` if there is none.
  DoubleLinkedQueueEntry<E> nextEntry() => _nextLink;
}

/**
 * Interface for the link classes used by [DoubleLinkedQueue].
 *
 * Both the [_DoubleLinkedQueueElement] and [_DoubleLinkedQueueSentinel]
 * implement this interface.
 * The entry contains a link back to the queue, so calling `append`
 * or `prepend` can correctly update the element count.
 */
abstract class _DoubleLinkedQueueEntry<E> extends DoubleLinkedQueueEntry<E> {
  DoubleLinkedQueue<E> _queue;
  _DoubleLinkedQueueEntry(E element, this._queue) : super(element);

  DoubleLinkedQueueEntry<E> _asNonSentinelEntry();

  void _append(E e) {
    new _DoubleLinkedQueueElement<E>(e, _queue)._link(this, _nextLink);
  }

  void _prepend(E e) {
    new _DoubleLinkedQueueElement<E>(e, _queue)._link(_previousLink, this);
  }

  E _remove();

  E get _element => element;

  DoubleLinkedQueueEntry<E> nextEntry() {
    _DoubleLinkedQueueEntry<E> entry =
        _nextLink as dynamic/*=DoubleLinkedQueueEntry<E>*/;
    return entry._asNonSentinelEntry();
  }

  DoubleLinkedQueueEntry<E> previousEntry() {
    _DoubleLinkedQueueEntry<E> entry =
        _previousLink as dynamic/*=DoubleLinkedQueueEntry<E>*/;
    return entry._asNonSentinelEntry();
  }
}

/**
 * The actual entry type used by the [DoubleLinkedQueue].
 *
 * The entry contains a reference to the queue, allowing
 * [append]/[prepend] to update the list length.
 */
class _DoubleLinkedQueueElement<E> extends _DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueElement(E element, DoubleLinkedQueue<E> queue)
      : super(element, queue);

  void append(E e) {
    _append(e);
    if (_queue != null) _queue._elementCount++;
  }

  void prepend(E e) {
    _prepend(e);
    if (_queue != null) _queue._elementCount++;
  }

  E _remove() {
    _queue = null;
    _unlink();
    return element;
  }

  E remove() {
    if (_queue != null) _queue._elementCount--;
    return _remove();
  }

  _DoubleLinkedQueueElement<E> _asNonSentinelEntry() {
    return this;
  }
}

/**
 * A sentinel in a double linked list is used to manipulate the list
 * at both ends.
 * A double linked list has exactly one sentinel,
 * which is the only entry when the list is constructed.
 * Initially, a sentinel has its next and previous entry point to itself.
 * A sentinel does not box any user element.
 */
class _DoubleLinkedQueueSentinel<E> extends _DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueSentinel(DoubleLinkedQueue<E> queue) : super(null, queue) {
    _previousLink = this;
    _nextLink = this;
  }

  DoubleLinkedQueueEntry<E> _asNonSentinelEntry() {
    return null;
  }

  /** Hit by, e.g., [DoubleLinkedQueue.removeFirst] if the queue is empty. */
  E _remove() {
    throw IterableElementError.noElement();
  }

  /** Hit by, e.g., [DoubleLinkedQueue.first] if the queue is empty. */
  E get _element {
    throw IterableElementError.noElement();
  }
}

/**
 * A [Queue] implementation based on a double-linked list.
 *
 * Allows constant time add, remove-at-ends and peek operations.
 */
class DoubleLinkedQueue<E> extends Iterable<E> implements Queue<E> {
  _DoubleLinkedQueueSentinel<E> _sentinel;
  int _elementCount = 0;

  DoubleLinkedQueue() {
    _sentinel = new _DoubleLinkedQueueSentinel<E>(this);
  }

  /**
   * Creates a double-linked queue containing all [elements].
   *
   * The element order in the queue is as if the elements were added using
   * [addLast] in the order provided by [elements.iterator].
   */
  factory DoubleLinkedQueue.from(Iterable elements) {
    Queue<E> list = new DoubleLinkedQueue<E>();
    for (final e in elements) {
      E element = e as Object/*=E*/;
      list.addLast(element);
    }
    return list;
  }

  int get length => _elementCount;

  void addLast(E value) {
    _sentinel._prepend(value);
    _elementCount++;
  }

  void addFirst(E value) {
    _sentinel._append(value);
    _elementCount++;
  }

  void add(E value) {
    _sentinel._prepend(value);
    _elementCount++;
  }

  void addAll(Iterable<E> iterable) {
    for (final E value in iterable) {
      _sentinel._prepend(value);
      _elementCount++;
    }
  }

  E removeLast() {
    _DoubleLinkedQueueEntry<E> lastEntry = _sentinel._previousLink;
    E result = lastEntry._remove();
    _elementCount--;
    return result;
  }

  E removeFirst() {
    _DoubleLinkedQueueEntry<E> firstEntry = _sentinel._nextLink;
    E result = firstEntry._remove();
    _elementCount--;
    return result;
  }

  bool remove(Object o) {
    _DoubleLinkedQueueEntry<E> entry = _sentinel._nextLink;
    while (!identical(entry, _sentinel)) {
      bool equals = (entry._element == o);
      if (!identical(this, entry._queue)) {
        // Entry must still be in the queue.
        throw new ConcurrentModificationError(this);
      }
      if (equals) {
        entry._remove();
        _elementCount--;
        return true;
      }
      entry = entry._nextLink;
    }
    return false;
  }

  void _filter(bool test(E element), bool removeMatching) {
    _DoubleLinkedQueueEntry<E> entry = _sentinel._nextLink;
    while (!identical(entry, _sentinel)) {
      bool matches = test(entry._element);
      if (!identical(this, entry._queue)) {
        // Entry must still be in the queue.
        throw new ConcurrentModificationError(this);
      }
      _DoubleLinkedQueueEntry<E> next = entry._nextLink; // Cannot be null.
      if (identical(removeMatching, matches)) {
        entry._remove();
        _elementCount--;
      }
      entry = next;
    }
  }

  void removeWhere(bool test(E element)) {
    _filter(test, true);
  }

  void retainWhere(bool test(E element)) {
    _filter(test, false);
  }

  E get first {
    _DoubleLinkedQueueEntry<E> firstEntry = _sentinel._nextLink;
    return firstEntry._element;
  }

  E get last {
    _DoubleLinkedQueueEntry<E> lastEntry = _sentinel._previousLink;
    return lastEntry._element;
  }

  E get single {
    // Note that this throws correctly if the queue is empty
    // because reading the element of the sentinel throws.
    if (identical(_sentinel._nextLink, _sentinel._previousLink)) {
      _DoubleLinkedQueueEntry<E> entry = _sentinel._nextLink;
      return entry._element;
    }
    throw IterableElementError.tooMany();
  }

  /**
   * The entry object of the first element in the queue.
   *
   * Each element of the queue has an associated [DoubleLinkedQueueEntry].
   * Returns the entry object corresponding to the first element of the queue.
   *
   * The entry objects can also be accessed using [lastEntry],
   * and they can be iterated using [DoubleLinkedQueueEntry.nextEntry()] and
   * [DoubleLinkedQueueEntry.previousEntry()].
   */
  DoubleLinkedQueueEntry<E> firstEntry() {
    return _sentinel.nextEntry();
  }

  /**
   * The entry object of the last element in the queue.
   *
   * Each element of the queue has an associated [DoubleLinkedQueueEntry].
   * Returns the entry object corresponding to the last element of the queue.
   *
   * The entry objects can also be accessed using [firstEntry],
   * and they can be iterated using [DoubleLinkedQueueEntry.nextEntry()] and
   * [DoubleLinkedQueueEntry.previousEntry()].
   */
  DoubleLinkedQueueEntry<E> lastEntry() {
    return _sentinel.previousEntry();
  }

  bool get isEmpty {
    return (identical(_sentinel._nextLink, _sentinel));
  }

  void clear() {
    _sentinel._nextLink = _sentinel;
    _sentinel._previousLink = _sentinel;
    _elementCount = 0;
  }

  /**
   * Calls [action] for each entry object of this double-linked queue.
   *
   * Each element of the queue has an associated [DoubleLinkedQueueEntry].
   * This method iterates the entry objects from first to last and calls
   * [action] with each object in turn.
   *
   * The entry objects can also be accessed using [firstEntry] and [lastEntry],
   * and iterated using [DoubleLinkedQueueEntry.nextEntry()] and
   * [DoubleLinkedQueueEntry.previousEntry()].
   *
   * The [action] function can use methods on [DoubleLinkedQueueEntry] to remove
   * the entry or it can insert elements before or after then entry.
   * If the current entry is removed, iteration continues with the entry that
   * was following the current entry when [action] was called. Any elements
   * inserted after the current element before it is removed will not be
   * visited by the iteration.
   */
  void forEachEntry(void action(DoubleLinkedQueueEntry<E> element)) {
    _DoubleLinkedQueueEntry<E> entry = _sentinel._nextLink;
    while (!identical(entry, _sentinel)) {
      _DoubleLinkedQueueElement<E> element = entry;
      _DoubleLinkedQueueEntry<E> next = element._nextLink;
      // Remember both entry and entry._nextLink.
      // If someone calls `element.remove()` we continue from `next`.
      // Otherwise we use the value of entry._nextLink which may have been
      // updated.
      action(element);
      if (identical(this, entry._queue)) {
        next = entry._nextLink;
      } else if (!identical(this, next._queue)) {
        throw new ConcurrentModificationError(this);
      }
      entry = next;
    }
  }

  _DoubleLinkedQueueIterator<E> get iterator {
    return new _DoubleLinkedQueueIterator<E>(_sentinel);
  }

  String toString() => IterableBase.iterableToFullString(this, '{', '}');
}

class _DoubleLinkedQueueIterator<E> implements Iterator<E> {
  _DoubleLinkedQueueSentinel<E> _sentinel;
  _DoubleLinkedQueueEntry<E> _nextEntry = null;
  E _current;

  _DoubleLinkedQueueIterator(_DoubleLinkedQueueSentinel<E> sentinel)
      : _sentinel = sentinel,
        _nextEntry = sentinel._nextLink;

  bool moveNext() {
    if (identical(_nextEntry, _sentinel)) {
      _current = null;
      _nextEntry = null;
      _sentinel = null;
      return false;
    }
    _DoubleLinkedQueueElement<E> elementEntry = _nextEntry;
    if (!identical(_sentinel._queue, elementEntry._queue)) {
      throw new ConcurrentModificationError(_sentinel._queue);
    }
    _current = elementEntry._element;
    _nextEntry = elementEntry._nextLink;
    return true;
  }

  E get current => _current;
}

/**
 * List based [Queue].
 *
 * Keeps a cyclic buffer of elements, and grows to a larger buffer when
 * it fills up. This guarantees constant time peek and remove operations, and
 * amortized constant time add operations.
 *
 * The structure is efficient for any queue or stack usage.
 */
class ListQueue<E> extends ListIterable<E> implements Queue<E> {
  static const int _INITIAL_CAPACITY = 8;
  List<E> _table;
  int _head;
  int _tail;
  int _modificationCount = 0;

  /**
   * Create an empty queue.
   *
   * If [initialCapacity] is given, prepare the queue for at least that many
   * elements.
   */
  ListQueue([int initialCapacity])
      : _head = 0,
        _tail = 0 {
    if (initialCapacity == null || initialCapacity < _INITIAL_CAPACITY) {
      initialCapacity = _INITIAL_CAPACITY;
    } else if (!_isPowerOf2(initialCapacity)) {
      initialCapacity = _nextPowerOf2(initialCapacity);
    }
    assert(_isPowerOf2(initialCapacity));
    _table = new List<E>(initialCapacity);
  }

  /**
   * Create a `ListQueue` containing all [elements].
   *
   * The elements are added to the queue, as by [addLast], in the order given by
   * `elements.iterator`.
   *
   * All `elements` should be assignable to [E].
   */
  factory ListQueue.from(Iterable elements) {
    if (elements is List) {
      int length = elements.length;
      ListQueue<E> queue = new ListQueue<E>(length + 1);
      assert(queue._table.length > length);
      for (int i = 0; i < length; i++) {
        queue._table[i] = elements[i] as Object/*=E*/;
      }
      queue._tail = length;
      return queue;
    } else {
      int capacity = _INITIAL_CAPACITY;
      if (elements is EfficientLengthIterable) {
        capacity = elements.length;
      }
      ListQueue<E> result = new ListQueue<E>(capacity);
      for (final element in elements) {
        result.addLast(element as Object/*=E*/);
      }
      return result;
    }
  }

  // Iterable interface.

  Iterator<E> get iterator => new _ListQueueIterator<E>(this);

  void forEach(void action(E element)) {
    int modificationCount = _modificationCount;
    for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
      action(_table[i]);
      _checkModification(modificationCount);
    }
  }

  bool get isEmpty => _head == _tail;

  int get length => (_tail - _head) & (_table.length - 1);

  E get first {
    if (_head == _tail) throw IterableElementError.noElement();
    return _table[_head];
  }

  E get last {
    if (_head == _tail) throw IterableElementError.noElement();
    return _table[(_tail - 1) & (_table.length - 1)];
  }

  E get single {
    if (_head == _tail) throw IterableElementError.noElement();
    if (length > 1) throw IterableElementError.tooMany();
    return _table[_head];
  }

  E elementAt(int index) {
    RangeError.checkValidIndex(index, this);
    return _table[(_head + index) & (_table.length - 1)];
  }

  List<E> toList({bool growable: true}) {
    List<E> list;
    if (growable) {
      list = new List<E>()..length = length;
    } else {
      list = new List<E>(length);
    }
    _writeToList(list);
    return list;
  }

  // Collection interface.

  void add(E value) {
    _add(value);
  }

  void addAll(Iterable<E> elements) {
    if (elements is List<E>) {
      List<E> list = elements;
      int addCount = list.length;
      int length = this.length;
      if (length + addCount >= _table.length) {
        _preGrow(length + addCount);
        // After preGrow, all elements are at the start of the list.
        _table.setRange(length, length + addCount, list, 0);
        _tail += addCount;
      } else {
        // Adding addCount elements won't reach _head.
        int endSpace = _table.length - _tail;
        if (addCount < endSpace) {
          _table.setRange(_tail, _tail + addCount, list, 0);
          _tail += addCount;
        } else {
          int preSpace = addCount - endSpace;
          _table.setRange(_tail, _tail + endSpace, list, 0);
          _table.setRange(0, preSpace, list, endSpace);
          _tail = preSpace;
        }
      }
      _modificationCount++;
    } else {
      for (E element in elements) _add(element);
    }
  }

  bool remove(Object value) {
    for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
      E element = _table[i];
      if (element == value) {
        _remove(i);
        _modificationCount++;
        return true;
      }
    }
    return false;
  }

  void _filterWhere(bool test(E element), bool removeMatching) {
    int modificationCount = _modificationCount;
    int i = _head;
    while (i != _tail) {
      E element = _table[i];
      bool remove = identical(removeMatching, test(element));
      _checkModification(modificationCount);
      if (remove) {
        i = _remove(i);
        modificationCount = ++_modificationCount;
      } else {
        i = (i + 1) & (_table.length - 1);
      }
    }
  }

  /**
   * Remove all elements matched by [test].
   *
   * This method is inefficient since it works by repeatedly removing single
   * elements, each of which can take linear time.
   */
  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  /**
   * Remove all elements not matched by [test].
   *
   * This method is inefficient since it works by repeatedly removing single
   * elements, each of which can take linear time.
   */
  void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  void clear() {
    if (_head != _tail) {
      for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
        _table[i] = null;
      }
      _head = _tail = 0;
      _modificationCount++;
    }
  }

  String toString() => IterableBase.iterableToFullString(this, "{", "}");

  // Queue interface.

  void addLast(E value) {
    _add(value);
  }

  void addFirst(E value) {
    _head = (_head - 1) & (_table.length - 1);
    _table[_head] = value;
    if (_head == _tail) _grow();
    _modificationCount++;
  }

  E removeFirst() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    E result = _table[_head];
    _table[_head] = null;
    _head = (_head + 1) & (_table.length - 1);
    return result;
  }

  E removeLast() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    _tail = (_tail - 1) & (_table.length - 1);
    E result = _table[_tail];
    _table[_tail] = null;
    return result;
  }

  // Internal helper functions.

  /**
   * Whether [number] is a power of two.
   *
   * Only works for positive numbers.
   */
  static bool _isPowerOf2(int number) => (number & (number - 1)) == 0;

  /**
   * Rounds [number] up to the nearest power of 2.
   *
   * If [number] is a power of 2 already, it is returned.
   *
   * Only works for positive numbers.
   */
  static int _nextPowerOf2(int number) {
    assert(number > 0);
    number = (number << 1) - 1;
    for (;;) {
      int nextNumber = number & (number - 1);
      if (nextNumber == 0) return number;
      number = nextNumber;
    }
  }

  /** Check if the queue has been modified during iteration. */
  void _checkModification(int expectedModificationCount) {
    if (expectedModificationCount != _modificationCount) {
      throw new ConcurrentModificationError(this);
    }
  }

  /** Adds element at end of queue. Used by both [add] and [addAll]. */
  void _add(E element) {
    _table[_tail] = element;
    _tail = (_tail + 1) & (_table.length - 1);
    if (_head == _tail) _grow();
    _modificationCount++;
  }

  /**
   * Removes the element at [offset] into [_table].
   *
   * Removal is performed by linearly moving elements either before or after
   * [offset] by one position.
   *
   * Returns the new offset of the following element. This may be the same
   * offset or the following offset depending on how elements are moved
   * to fill the hole.
   */
  int _remove(int offset) {
    int mask = _table.length - 1;
    int startDistance = (offset - _head) & mask;
    int endDistance = (_tail - offset) & mask;
    if (startDistance < endDistance) {
      // Closest to start.
      int i = offset;
      while (i != _head) {
        int prevOffset = (i - 1) & mask;
        _table[i] = _table[prevOffset];
        i = prevOffset;
      }
      _table[_head] = null;
      _head = (_head + 1) & mask;
      return (offset + 1) & mask;
    } else {
      _tail = (_tail - 1) & mask;
      int i = offset;
      while (i != _tail) {
        int nextOffset = (i + 1) & mask;
        _table[i] = _table[nextOffset];
        i = nextOffset;
      }
      _table[_tail] = null;
      return offset;
    }
  }

  /**
   * Grow the table when full.
   */
  void _grow() {
    List<E> newTable = new List<E>(_table.length * 2);
    int split = _table.length - _head;
    newTable.setRange(0, split, _table, _head);
    newTable.setRange(split, split + _head, _table, 0);
    _head = 0;
    _tail = _table.length;
    _table = newTable;
  }

  int _writeToList(List<E> target) {
    assert(target.length >= length);
    if (_head <= _tail) {
      int length = _tail - _head;
      target.setRange(0, length, _table, _head);
      return length;
    } else {
      int firstPartSize = _table.length - _head;
      target.setRange(0, firstPartSize, _table, _head);
      target.setRange(firstPartSize, firstPartSize + _tail, _table, 0);
      return _tail + firstPartSize;
    }
  }

  /** Grows the table even if it is not full. */
  void _preGrow(int newElementCount) {
    assert(newElementCount >= length);

    // Add some extra room to ensure that there's room for more elements after
    // expansion.
    newElementCount += newElementCount >> 1;
    int newCapacity = _nextPowerOf2(newElementCount);
    List<E> newTable = new List<E>(newCapacity);
    _tail = _writeToList(newTable);
    _table = newTable;
    _head = 0;
  }
}

/**
 * Iterator for a [ListQueue].
 *
 * Considers any add or remove operation a concurrent modification.
 */
class _ListQueueIterator<E> implements Iterator<E> {
  final ListQueue<E> _queue;
  final int _end;
  final int _modificationCount;
  int _position;
  E _current;

  _ListQueueIterator(ListQueue<E> queue)
      : _queue = queue,
        _end = queue._tail,
        _modificationCount = queue._modificationCount,
        _position = queue._head;

  E get current => _current;

  bool moveNext() {
    _queue._checkModification(_modificationCount);
    if (_position == _end) {
      _current = null;
      return false;
    }
    _current = _queue._table[_position];
    _position = (_position + 1) & (_queue._table.length - 1);
    return true;
  }
}
