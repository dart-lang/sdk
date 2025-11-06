// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invariance optimizations benchmark based on adding and removing from a copy
// of the default implementation of Queue.
//
// This benchmark incurs type checks due to parametric subtype covariance.  Many
// of these type checks can be optimized away by invariance analysis to discover
// which types are invariant.
//
// Some compilers already optimize '`this`-calls`, where the receiver is
// `this`. `this`-calls are a trivial kind of invariance since the caller and
// callee share the same receiver, so share the same class type variables. An
// example of this is when `ListQueue.add` calls `ListQueue._add`. There is no
// need to check `value as E` again.
//
// One example that is not well optimized at the time of writing is when type
// variables of related collections are invariant. The Queue implementation
// uses, as a backing store, a fixed length list that has a type invariant with
// respect to the `Queue<E>`, constructed via `List<E?>.filled(...)`.
//
// There are two axes of benchmark variation:
//   1. The queue element type (`int`, `int?`, `List<int>`, records)
//   2. Adding elements via `Queue.add` and `Queue.addAll`.
//
// The first axis exercises a variety of covariance checks. More complex checks
// tend to be slower, magnifying the benefit of invariance analysis.
//
// The second axis, using `add` and `addAll`, adds more opportunities for
// invariances to be detected (`_queue` and `_items` are separate collections
// that have the same value of the type variable).
//
// All benchmarks use the workload defined in `Benchmark<T>` so that the
// compilers don't achieve optimizations by flowing constant types. We avoid
// mixins because some implementations expand mixins, which could result in the
// expanded code having non-parametric types, e.g. `Queue<int>`.

// ignore_for_file: prefer_final_locals

import 'dart:typed_data';
import 'package:benchmark_harness/benchmark_harness.dart';

abstract class Benchmark<T> extends BenchmarkBase {
  final int _iterations;
  final Queue<T> _queue = Queue<T>();

  final bool _runAddAll;

  Benchmark(String name, String type, this._iterations)
    : _runAddAll = name.startsWith('addAll'),
      super('InvarianceQueue.$name.$type');

  // For the add/remove benchmarks, values are copied through this field. `T` is
  // invariant with respect to the Queue element type.
  T? _item;

  // For the addAll/remove benchmarks, values are copied through this second
  // Queue which contains one element at the time of copy.
  final Queue<T> _items = Queue<T>();

  @override
  void run() {
    if (_runAddAll) {
      runAddAllRemove();
    } else {
      runAddRemove();
    }
  }

  void check() {
    if (_runAddAll) {
      checkAddAllRemove();
    } else {
      checkAddRemove();
    }
  }

  void runAddRemove() {
    for (int i = 0; i < _iterations; i++) {
      _item = _queue.removeFirst();
      _queue.add(_item as T);
    }
  }

  void checkAddRemove() {
    if (_item == _queue.first) throw StateError('bad');
  }

  void runAddAllRemove() {
    for (int i = 0; i < _iterations; i++) {
      _items
        ..clear()
        ..add(_queue.removeFirst());
      _queue.addAll(_items);
    }
  }

  void checkAddAllRemove() {
    if (_items.single == _queue.first) throw StateError('bad');
  }
}

abstract class QueueInt extends Benchmark<int> {
  QueueInt(String name, int count) : super(name, 'int', count);
  @override
  void setup() {
    _queue
      ..clear()
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(4);
  }
}

abstract class QueueIntQ extends Benchmark<int?> {
  QueueIntQ(String name, int count) : super(name, 'intQ', count);
  @override
  void setup() {
    _queue
      ..clear()
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(null);
  }
}

abstract class QueueListInt extends Benchmark<List<int>> {
  QueueListInt(String name, int count) : super(name, 'List.int', count);
  @override
  void setup() {
    _queue
      ..clear()
      ..add('1'.codeUnits)
      ..add([2])
      ..add(Uint8List(3))
      ..add(Int16List(4));
  }
}

typedef SimpleRecord = (int, int);
typedef ComplexRecord = (num, num Function(num), {Comparable z});

abstract class QueueSimpleRecord extends Benchmark<SimpleRecord> {
  QueueSimpleRecord(String name, int count)
    : super(name, 'simple-record', count);
  @override
  void setup() {
    _queue
      ..clear()
      ..add((0, 1))
      ..add((1, 2))
      ..add((2, 3))
      ..add((3, 0));
  }
}

abstract class QueueComplexRecord extends Benchmark<ComplexRecord> {
  QueueComplexRecord(String name, int count)
    : super(name, 'complex-record', count);
  @override
  void setup() {
    _queue
      ..clear()
      ..add((1.2, 1.2.compareTo, z: 'x'))
      ..add((0, (x) => x + 1, z: 123))
      // Type depends on class type variable:
      ..add((1, Env<num>().foo, z: BigInt.parse('42')))
      // Type depends on function type variable:
      ..add((1, Env<num>().bar<int>(), z: DateTime.now()));
  }
}

class Env<T> {
  T foo(T x) => x;

  S Function(T) bar<S extends T>() {
    S localFunction(T x) {
      if (x is S) return x;
      throw 'bad';
    }

    return localFunction;
  }
}

class QueueAddRemoveInt extends QueueInt {
  QueueAddRemoveInt(int count) : super('add-remove', count);
}

class QueueAddRemoveIntQ extends QueueIntQ {
  QueueAddRemoveIntQ(int count) : super('add-remove', count);
}

class QueueAddRemoveListInt extends QueueListInt {
  QueueAddRemoveListInt(int count) : super('add-remove', count);
}

class QueueAddRemoveSimpleRecord extends QueueSimpleRecord {
  QueueAddRemoveSimpleRecord(int count) : super('add-remove', count);
}

class QueueAddRemoveComplexRecord extends QueueComplexRecord {
  QueueAddRemoveComplexRecord(int count) : super('add-remove', count);
}

class QueueAddAllRemoveInt extends QueueInt {
  QueueAddAllRemoveInt(int count) : super('addAll-remove', count);
}

class QueueAddAllRemoveIntQ extends QueueIntQ {
  QueueAddAllRemoveIntQ(int count) : super('addAll-remove', count);
}

class QueueAddAllRemoveListInt extends QueueListInt {
  QueueAddAllRemoveListInt(int count) : super('addAll-remove', count);
}

class QueueAddAllRemoveSimpleRecord extends QueueSimpleRecord {
  QueueAddAllRemoveSimpleRecord(int count) : super('addAll-remove', count);
}

class QueueAddAllRemoveComplexRecord extends QueueComplexRecord {
  QueueAddAllRemoveComplexRecord(int count) : super('addAll-remove', count);
}

void pollute() {
  // Pollute run size.
  QueueAddRemoveInt(0)
    ..setup()
    ..run();
  QueueAddRemoveIntQ(1)
    ..setup()
    ..run();
  QueueAddRemoveListInt(2)
    ..setup()
    ..run();
  // Further pollute type.
  Queue<String>()
    ..add('a')
    ..add('b')
    ..addAll({'a', 'b'})
    ..addAll(['a', 'b'])
    ..toString();
  Queue<Pattern>()
    ..add('a')
    ..add(RegExp('b'))
    ..toString();
  Queue<String Function(String)>()..add(Env<String>().foo);
  Queue<num>()
    ..addAll(<int>[1])
    ..addAll(<double>[2.3]);
}

void main() {
  final benchmarks = <Benchmark>[
    QueueAddRemoveInt(1000),
    QueueAddRemoveIntQ(1000),
    QueueAddRemoveListInt(1000),
    QueueAddRemoveSimpleRecord(1000),
    QueueAddRemoveComplexRecord(1000),
    QueueAddAllRemoveInt(1000),
    QueueAddAllRemoveIntQ(1000),
    QueueAddAllRemoveListInt(1000),
    QueueAddAllRemoveSimpleRecord(1000),
    QueueAddAllRemoveComplexRecord(1000),
  ];

  // Warmup all benchmarks to ensure JIT compilers see full polymorphism.
  for (final benchmark in benchmarks) {
    pollute();
    benchmark.setup();
  }

  for (final benchmark in benchmarks) {
    pollute();
    benchmark.warmup();
  }

  for (final benchmark in benchmarks) {
    // `report` calls `setup`, but `setup` is idempotent.
    benchmark.report();
    benchmark.check();
  }
}

/// What follows is a copy of the SDK Queue implementation, cut down to remove
/// methods that are unused in this benchmark.

/// A [Queue] is a collection that can be manipulated at both ends.
abstract interface class Queue<E> implements Iterable<E> {
  /// Creates a queue.
  factory Queue() = ListQueue<E>;

  /// Removes and returns the first element of this queue.
  E removeFirst();

  /// Removes and returns the last element of the queue.
  E removeLast();

  /// Adds [value] at the beginning of the queue.
  void addFirst(E value);

  /// Adds [value] at the end of the queue.
  void addLast(E value);

  /// Adds [value] at the end of the queue.
  void add(E value);

  /// Removes a single instance of [value] from the queue.
  ///
  /// Returns `true` if a value was removed, or `false` if the queue
  /// contained no element equal to [value].
  bool remove(Object? value);

  /// Adds all elements of [iterable] at the end of the queue. The
  /// length of the queue is extended by the length of [iterable].
  void addAll(Iterable<E> iterable);

  /// Removes all elements in the queue. The size of the queue becomes zero.
  void clear();
}

/// List based [Queue].
final class ListQueue<E> implements Queue<E> {
  static const int _INITIAL_CAPACITY = 8;
  List<E?> _table;
  int _head;
  int _tail;
  int _modificationCount = 0;

  /// Create an empty queue.
  ///
  /// If [initialCapacity] is given, prepare the queue for at least that many
  /// elements.
  ListQueue([int? initialCapacity])
    : _head = 0,
      _tail = 0,
      _table = List<E?>.filled(_calculateCapacity(initialCapacity), null);

  static int _calculateCapacity(int? initialCapacity) {
    if (initialCapacity == null || initialCapacity < _INITIAL_CAPACITY) {
      return _INITIAL_CAPACITY;
    } else if (!_isPowerOf2(initialCapacity)) {
      return _nextPowerOf2(initialCapacity);
    }
    assert(_isPowerOf2(initialCapacity));
    return initialCapacity;
  }

  // Iterable interface.

  @override
  Queue<R> cast<R>() => throw UnimplementedError('Iterable.cast');

  @override
  Iterator<E> get iterator => _ListQueueIterator<E>(this);

  @override
  void forEach(void Function(E element) f) {
    int modificationCount = _modificationCount;
    for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
      f(_table[i] as E);
      _checkModification(modificationCount);
    }
  }

  @override
  bool get isEmpty => _head == _tail;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  int get length => (_tail - _head) & (_table.length - 1);

  @override
  E get first {
    if (_head == _tail) throw IterableElementError.noElement();
    return _table[_head] as E;
  }

  @override
  E get last {
    if (_head == _tail) throw IterableElementError.noElement();
    return _table[(_tail - 1) & (_table.length - 1)] as E;
  }

  @override
  E get single {
    if (_head == _tail) throw IterableElementError.noElement();
    if (length > 1) throw IterableElementError.tooMany();
    return _table[_head] as E;
  }

  @override
  E elementAt(int index) {
    IndexError.check(index, length, indexable: this);
    return _table[(_head + index) & (_table.length - 1)] as E;
  }

  @override
  List<E> toList({bool growable = true}) {
    int mask = _table.length - 1;
    int length = (_tail - _head) & mask;
    if (length == 0) return List<E>.empty(growable: growable);

    var list = List<E>.filled(length, first, growable: growable);
    for (int i = 0; i < length; i++) {
      list[i] = _table[(_head + i) & mask] as E;
    }
    return list;
  }

  // Collection interface.

  @override
  void add(E value) {
    _add(value);
  }

  @override
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
      for (E element in elements) {
        _add(element);
      }
    }
  }

  @override
  bool remove(Object? value) {
    for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
      E? element = _table[i];
      if (element == value) {
        _remove(i);
        _modificationCount++;
        return true;
      }
    }
    return false;
  }

  @override
  void clear() {
    if (_head != _tail) {
      for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
        _table[i] = null;
      }
      _head = _tail = 0;
      _modificationCount++;
    }
  }

  @override
  String toString() => Iterable.iterableToFullString(this, '{', '}');

  // Queue interface.

  @override
  void addLast(E value) {
    _add(value);
  }

  @override
  void addFirst(E value) {
    _head = (_head - 1) & (_table.length - 1);
    _table[_head] = value;
    if (_head == _tail) _grow();
    _modificationCount++;
  }

  @override
  E removeFirst() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    E result = _table[_head] as E;
    _table[_head] = null;
    _head = (_head + 1) & (_table.length - 1);
    return result;
  }

  @override
  E removeLast() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    _tail = (_tail - 1) & (_table.length - 1);
    E result = _table[_tail] as E;
    _table[_tail] = null;
    return result;
  }

  // Internal helper functions.

  /// Whether [number] is a power of two.
  ///
  /// Only works for positive numbers.
  static bool _isPowerOf2(int number) => (number & (number - 1)) == 0;

  /// Rounds [number] up to the nearest power of 2.
  ///
  /// If [number] is a power of 2 already, it is returned.
  ///
  /// Only works for positive numbers.
  static int _nextPowerOf2(int number) {
    assert(number > 0);
    number = (number << 1) - 1;
    for (;;) {
      int nextNumber = number & (number - 1);
      if (nextNumber == 0) return number;
      number = nextNumber;
    }
  }

  /// Check if the queue has been modified during iteration.
  void _checkModification(int expectedModificationCount) {
    if (expectedModificationCount != _modificationCount) {
      throw ConcurrentModificationError(this);
    }
  }

  /// Adds element at end of queue. Used by both [add] and [addAll].
  void _add(E element) {
    _table[_tail] = element;
    _tail = (_tail + 1) & (_table.length - 1);
    if (_head == _tail) _grow();
    _modificationCount++;
  }

  /// Removes the element at [offset] into [_table].
  ///
  /// Removal is performed by linearly moving elements either before or after
  /// [offset] by one position.
  ///
  /// Returns the new offset of the following element. This may be the same
  /// offset or the following offset depending on how elements are moved
  /// to fill the hole.
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

  /// Grow the table when full.
  void _grow() {
    List<E?> newTable = List<E?>.filled(_table.length * 2, null);
    int split = _table.length - _head;
    newTable.setRange(0, split, _table, _head);
    newTable.setRange(split, split + _head, _table, 0);
    _head = 0;
    _tail = _table.length;
    _table = newTable;
  }

  int _writeToList(List<E?> target) {
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

  /// Grows the table even if it is not full.
  void _preGrow(int newElementCount) {
    assert(newElementCount >= length);

    // Add some extra room to ensure that there's room for more elements after
    // expansion.
    newElementCount += newElementCount >> 1;
    int newCapacity = _nextPowerOf2(newElementCount);
    List<E?> newTable = List<E?>.filled(newCapacity, null);
    _tail = _writeToList(newTable);
    _table = newTable;
    _head = 0;
  }

  /// Unimplemented Iterable methods

  @override
  Never any(_) => throw UnimplementedError();
  @override
  Never contains(_) => throw UnimplementedError();
  @override
  Never every(_) => throw UnimplementedError();
  @override
  Never expand<T>(_) => throw UnimplementedError();
  @override
  Never firstWhere(_, {E Function()? orElse}) => throw UnimplementedError();
  @override
  Never fold<T>(_, _) => throw UnimplementedError();
  @override
  Never followedBy(_) => throw UnimplementedError();
  @override
  Never join([String _ = '']) => throw UnimplementedError();
  @override
  Never lastWhere(_, {E Function()? orElse}) => throw UnimplementedError();
  @override
  Never map<T>(_) => throw UnimplementedError();
  @override
  Never reduce(_) => throw UnimplementedError();
  @override
  Never singleWhere(_, {E Function()? orElse}) => throw UnimplementedError();
  @override
  Never skip(_) => throw UnimplementedError();
  @override
  Never skipWhile(_) => throw UnimplementedError();
  @override
  Never take(_) => throw UnimplementedError();
  @override
  Never takeWhile(_) => throw UnimplementedError();
  @override
  Never toSet() => throw UnimplementedError();
  @override
  Never where(_) => throw UnimplementedError();
  @override
  Never whereType<T>() => throw UnimplementedError();
}

/// Iterator for a [ListQueue].
///
/// Considers any add or remove operation a concurrent modification.
class _ListQueueIterator<E> implements Iterator<E> {
  final ListQueue<E> _queue;
  final int _end;
  final int _modificationCount;
  int _position;
  E? _current;

  _ListQueueIterator(ListQueue<E> queue)
    : _queue = queue,
      _end = queue._tail,
      _modificationCount = queue._modificationCount,
      _position = queue._head;

  @override
  E get current => _current as E;

  @override
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

abstract class IterableElementError {
  static StateError noElement() => StateError('No element');
  static StateError tooMany() => StateError('Too many elements');
}
