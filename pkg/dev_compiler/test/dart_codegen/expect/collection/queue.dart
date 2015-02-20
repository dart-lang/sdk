part of dart.collection;

abstract class Queue<E> implements Iterable<E>, EfficientLength {
  factory Queue() = ListQueue<E>;
  factory Queue.from(Iterable elements) = ListQueue<E>.from;
  E removeFirst();
  E removeLast();
  void addFirst(E value);
  void addLast(E value);
  void add(E value);
  bool remove(Object object);
  void addAll(Iterable<E> iterable);
  void removeWhere(bool test(E element));
  void retainWhere(bool test(E element));
  void clear();
}
class DoubleLinkedQueueEntry<E> {
  DoubleLinkedQueueEntry<E> _previous;
  DoubleLinkedQueueEntry<E> _next;
  E _element;
  DoubleLinkedQueueEntry(E e) : _element = e;
  void _link(
      DoubleLinkedQueueEntry<E> previous, DoubleLinkedQueueEntry<E> next) {
    _next = next;
    _previous = previous;
    previous._next = this;
    next._previous = this;
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
class _DoubleLinkedQueueEntrySentinel<E> extends DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueEntrySentinel() : super(((__x32) => DDC$RT.cast(__x32, Null,
          E, "CastLiteral",
          """line 164, column 45 of dart:collection/queue.dart: """, __x32 is E,
          false))(null)) {
    _link(this, this);
  }
  E remove() {
    throw IterableElementError.noElement();
  }
  DoubleLinkedQueueEntry<E> _asNonSentinelEntry() {
    return null;
  }
  void set element(E e) {
    assert(false);
  }
  E get element {
    throw IterableElementError.noElement();
  }
}
class DoubleLinkedQueue<E> extends IterableBase<E> implements Queue<E> {
  _DoubleLinkedQueueEntrySentinel<E> _sentinel;
  int _elementCount = 0;
  DoubleLinkedQueue() {
    _sentinel = new _DoubleLinkedQueueEntrySentinel<E>();
  }
  factory DoubleLinkedQueue.from(Iterable elements) {
    Queue<E> list = ((__x33) => DDC$RT.cast(__x33,
        DDC$RT.type((DoubleLinkedQueue<dynamic> _) {}),
        DDC$RT.type((Queue<E> _) {}), "CastExact",
        """line 207, column 21 of dart:collection/queue.dart: """,
        __x33 is Queue<E>, false))(new DoubleLinkedQueue());
    for (final E e in elements) {
      list.addLast(e);
    }
    return DDC$RT.cast(list, DDC$RT.type((Queue<E> _) {}),
        DDC$RT.type((DoubleLinkedQueue<E> _) {}), "CastGeneral",
        """line 211, column 12 of dart:collection/queue.dart: """,
        list is DoubleLinkedQueue<E>, false);
  }
  int get length => _elementCount;
  void addLast(E value) {
    _sentinel.prepend(value);
    _elementCount++;
  }
  void addFirst(E value) {
    _sentinel.append(value);
    _elementCount++;
  }
  void add(E value) {
    _sentinel.prepend(value);
    _elementCount++;
  }
  void addAll(Iterable<E> iterable) {
    for (final E value in iterable) {
      _sentinel.prepend(value);
      _elementCount++;
    }
  }
  E removeLast() {
    E result = _sentinel._previous.remove();
    _elementCount--;
    return result;
  }
  E removeFirst() {
    E result = _sentinel._next.remove();
    _elementCount--;
    return result;
  }
  bool remove(Object o) {
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (!identical(entry, _sentinel)) {
      if (entry.element == o) {
        entry.remove();
        _elementCount--;
        return true;
      }
      entry = entry._next;
    }
    return false;
  }
  void _filter(bool test(E element), bool removeMatching) {
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (!identical(entry, _sentinel)) {
      DoubleLinkedQueueEntry<E> next = entry._next;
      if (identical(removeMatching, test(entry.element))) {
        entry.remove();
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
    return _sentinel._next.element;
  }
  E get last {
    return _sentinel._previous.element;
  }
  E get single {
    if (identical(_sentinel._next, _sentinel._previous)) {
      return _sentinel._next.element;
    }
    throw IterableElementError.tooMany();
  }
  DoubleLinkedQueueEntry<E> lastEntry() {
    return _sentinel.previousEntry();
  }
  DoubleLinkedQueueEntry<E> firstEntry() {
    return _sentinel.nextEntry();
  }
  bool get isEmpty {
    return (identical(_sentinel._next, _sentinel));
  }
  void clear() {
    _sentinel._next = _sentinel;
    _sentinel._previous = _sentinel;
    _elementCount = 0;
  }
  void forEachEntry(void f(DoubleLinkedQueueEntry<E> element)) {
    DoubleLinkedQueueEntry<E> entry = _sentinel._next;
    while (!identical(entry, _sentinel)) {
      DoubleLinkedQueueEntry<E> nextEntry = entry._next;
      f(entry);
      entry = nextEntry;
    }
  }
  _DoubleLinkedQueueIterator<E> get iterator {
    return new _DoubleLinkedQueueIterator<E>(_sentinel);
  }
  String toString() => IterableBase.iterableToFullString(this, '{', '}');
}
class _DoubleLinkedQueueIterator<E> implements Iterator<E> {
  _DoubleLinkedQueueEntrySentinel<E> _sentinel;
  DoubleLinkedQueueEntry<E> _nextEntry = null;
  E _current;
  _DoubleLinkedQueueIterator(_DoubleLinkedQueueEntrySentinel<E> sentinel)
      : _sentinel = sentinel,
        _nextEntry = sentinel._next;
  bool moveNext() {
    if (!identical(_nextEntry, _sentinel)) {
      _current = _nextEntry._element;
      _nextEntry = _nextEntry._next;
      return true;
    }
    _current = ((__x34) => DDC$RT.cast(__x34, Null, E, "CastLiteral",
        """line 348, column 16 of dart:collection/queue.dart: """, __x34 is E,
        false))(null);
    _nextEntry = _sentinel = null;
    return false;
  }
  E get current => _current;
}
class ListQueue<E> extends IterableBase<E> implements Queue<E> {
  static const int _INITIAL_CAPACITY = 8;
  List<E> _table;
  int _head;
  int _tail;
  int _modificationCount = 0;
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
  factory ListQueue.from(Iterable elements) {
    if (elements is List) {
      int length = elements.length;
      ListQueue<E> queue = ((__x35) => DDC$RT.cast(__x35,
          DDC$RT.type((ListQueue<dynamic> _) {}),
          DDC$RT.type((ListQueue<E> _) {}), "CastExact",
          """line 399, column 28 of dart:collection/queue.dart: """,
          __x35 is ListQueue<E>, false))(new ListQueue(length + 1));
      assert(queue._table.length > length);
      List sourceList = elements;
      queue._table.setRange(0, length, DDC$RT.cast(sourceList,
          DDC$RT.type((List<dynamic> _) {}), DDC$RT.type((Iterable<E> _) {}),
          "CastDynamic",
          """line 402, column 40 of dart:collection/queue.dart: """,
          sourceList is Iterable<E>, false), 0);
      queue._tail = length;
      return queue;
    } else {
      int capacity = _INITIAL_CAPACITY;
      if (elements is EfficientLength) {
        capacity = elements.length;
      }
      ListQueue<E> result = new ListQueue<E>(capacity);
      for (final E element in elements) {
        result.addLast(element);
      }
      return result;
    }
  }
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
  void add(E element) {
    _add(element);
  }
  void addAll(Iterable<E> elements) {
    if (elements is List) {
      List list = DDC$RT.cast(elements, DDC$RT.type((Iterable<E> _) {}),
          DDC$RT.type((List<dynamic> _) {}), "CastGeneral",
          """line 474, column 19 of dart:collection/queue.dart: """,
          elements is List<dynamic>, true);
      int addCount = list.length;
      int length = this.length;
      if (length + addCount >= _table.length) {
        _preGrow(length + addCount);
        _table.setRange(length, length + addCount, DDC$RT.cast(list,
            DDC$RT.type((List<dynamic> _) {}), DDC$RT.type((Iterable<E> _) {}),
            "CastDynamic",
            """line 480, column 52 of dart:collection/queue.dart: """,
            list is Iterable<E>, false), 0);
        _tail += addCount;
      } else {
        int endSpace = _table.length - _tail;
        if (addCount < endSpace) {
          _table.setRange(_tail, _tail + addCount, DDC$RT.cast(list,
              DDC$RT.type((List<dynamic> _) {}),
              DDC$RT.type((Iterable<E> _) {}), "CastDynamic",
              """line 486, column 52 of dart:collection/queue.dart: """,
              list is Iterable<E>, false), 0);
          _tail += addCount;
        } else {
          int preSpace = addCount - endSpace;
          _table.setRange(_tail, _tail + endSpace, DDC$RT.cast(list,
              DDC$RT.type((List<dynamic> _) {}),
              DDC$RT.type((Iterable<E> _) {}), "CastDynamic",
              """line 490, column 52 of dart:collection/queue.dart: """,
              list is Iterable<E>, false), 0);
          _table.setRange(0, preSpace, DDC$RT.cast(list,
              DDC$RT.type((List<dynamic> _) {}),
              DDC$RT.type((Iterable<E> _) {}), "CastDynamic",
              """line 491, column 40 of dart:collection/queue.dart: """,
              list is Iterable<E>, false), endSpace);
          _tail = preSpace;
        }
      }
      _modificationCount++;
    } else {
      for (E element in elements) _add(element);
    }
  }
  bool remove(Object object) {
    for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
      E element = _table[i];
      if (element == object) {
        _remove(i);
        _modificationCount++;
        return true;
      }
    }
    return false;
  }
  void _filterWhere(bool test(E element), bool removeMatching) {
    int index = _head;
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
  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }
  void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }
  void clear() {
    if (_head != _tail) {
      for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
        _table[i] = ((__x36) => DDC$RT.cast(__x36, Null, E, "CastLiteral",
            """line 553, column 21 of dart:collection/queue.dart: """,
            __x36 is E, false))(null);
      }
      _head = _tail = 0;
      _modificationCount++;
    }
  }
  String toString() => IterableBase.iterableToFullString(this, "{", "}");
  void addLast(E element) {
    _add(element);
  }
  void addFirst(E element) {
    _head = (_head - 1) & (_table.length - 1);
    _table[_head] = element;
    if (_head == _tail) _grow();
    _modificationCount++;
  }
  E removeFirst() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    E result = _table[_head];
    _table[_head] = ((__x37) => DDC$RT.cast(__x37, Null, E, "CastLiteral",
        """line 577, column 21 of dart:collection/queue.dart: """, __x37 is E,
        false))(null);
    _head = (_head + 1) & (_table.length - 1);
    return result;
  }
  E removeLast() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    _tail = (_tail - 1) & (_table.length - 1);
    E result = _table[_tail];
    _table[_tail] = ((__x38) => DDC$RT.cast(__x38, Null, E, "CastLiteral",
        """line 587, column 21 of dart:collection/queue.dart: """, __x38 is E,
        false))(null);
    return result;
  }
  static bool _isPowerOf2(int number) => (number & (number - 1)) == 0;
  static int _nextPowerOf2(int number) {
    assert(number > 0);
    number = (number << 1) - 1;
    for (;;) {
      int nextNumber = number & (number - 1);
      if (nextNumber == 0) return number;
      number = nextNumber;
    }
  }
  void _checkModification(int expectedModificationCount) {
    if (expectedModificationCount != _modificationCount) {
      throw new ConcurrentModificationError(this);
    }
  }
  void _add(E element) {
    _table[_tail] = element;
    _tail = (_tail + 1) & (_table.length - 1);
    if (_head == _tail) _grow();
    _modificationCount++;
  }
  int _remove(int offset) {
    int mask = _table.length - 1;
    int startDistance = (offset - _head) & mask;
    int endDistance = (_tail - offset) & mask;
    if (startDistance < endDistance) {
      int i = offset;
      while (i != _head) {
        int prevOffset = (i - 1) & mask;
        _table[i] = _table[prevOffset];
        i = prevOffset;
      }
      _table[_head] = ((__x39) => DDC$RT.cast(__x39, Null, E, "CastLiteral",
          """line 654, column 23 of dart:collection/queue.dart: """, __x39 is E,
          false))(null);
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
      _table[_tail] = ((__x40) => DDC$RT.cast(__x40, Null, E, "CastLiteral",
          """line 665, column 23 of dart:collection/queue.dart: """, __x40 is E,
          false))(null);
      return offset;
    }
  }
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
  void _preGrow(int newElementCount) {
    assert(newElementCount >= length);
    newElementCount += newElementCount >> 1;
    int newCapacity = _nextPowerOf2(newElementCount);
    List<E> newTable = new List<E>(newCapacity);
    _tail = _writeToList(newTable);
    _table = newTable;
    _head = 0;
  }
}
class _ListQueueIterator<E> implements Iterator<E> {
  final ListQueue _queue;
  final int _end;
  final int _modificationCount;
  int _position;
  E _current;
  _ListQueueIterator(ListQueue queue)
      : _queue = queue,
        _end = queue._tail,
        _modificationCount = queue._modificationCount,
        _position = queue._head;
  E get current => _current;
  bool moveNext() {
    _queue._checkModification(_modificationCount);
    if (_position == _end) {
      _current = ((__x41) => DDC$RT.cast(__x41, Null, E, "CastLiteral",
          """line 735, column 18 of dart:collection/queue.dart: """, __x41 is E,
          false))(null);
      return false;
    }
    _current = ((__x42) => DDC$RT.cast(__x42, dynamic, E, "CastGeneral",
        """line 738, column 16 of dart:collection/queue.dart: """, __x42 is E,
        false))(_queue._table[_position]);
    _position = (_position + 1) & (_queue._table.length - 1);
    return true;
  }
}
