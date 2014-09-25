// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/**
 * Marker interface for [Iterable] subclasses that have an efficient
 * [length] implementation.
 */
abstract class EfficientLength {
  /**
   * Returns the number of elements in the iterable.
   *
   * This is an efficient operation that doesn't require iterating through
   * the elements.
   */
  int get length;
}

/**
 * An [Iterable] for classes that have efficient [length] and [elementAt].
 *
 * All other methods are implemented in terms of [length] and [elementAt],
 * including [iterator].
 */
abstract class ListIterable<E> extends IterableBase<E>
                               implements EfficientLength {
  int get length;
  E elementAt(int i);

  const ListIterable();

  Iterator<E> get iterator => new ListIterator<E>(this);

  void forEach(void action(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      action(elementAt(i));
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
  }

  bool get isEmpty => length == 0;

  E get first {
    if (length == 0) throw IterableElementError.noElement();
    return elementAt(0);
  }

  E get last {
    if (length == 0) throw IterableElementError.noElement();
    return elementAt(length - 1);
  }

  E get single {
    if (length == 0) throw IterableElementError.noElement();
    if (length > 1) throw IterableElementError.tooMany();
    return elementAt(0);
  }

  bool contains(Object element) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (elementAt(i) == element) return true;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return false;
  }

  bool every(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (!test(elementAt(i))) return false;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return true;
  }

  bool any(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (test(elementAt(i))) return true;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return false;
  }

  dynamic firstWhere(bool test(E element), { Object orElse() }) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      E element = elementAt(i);
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  dynamic lastWhere(bool test(E element), { Object orElse() }) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      E element = elementAt(i);
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E element)) {
    int length = this.length;
    E match = null;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      E element = elementAt(i);
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match;
    throw IterableElementError.noElement();
  }

  String join([String separator = ""]) {
    int length = this.length;
    if (!separator.isEmpty) {
      if (length == 0) return "";
      String first = "${elementAt(0)}";
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
      StringBuffer buffer = new StringBuffer(first);
      for (int i = 1; i < length; i++) {
        buffer.write(separator);
        buffer.write(elementAt(i));
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    } else {
      StringBuffer buffer = new StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write(elementAt(i));
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    }
  }

  Iterable<E> where(bool test(E element)) => super.where(test);

  Iterable map(f(E element)) => new MappedListIterable(this, f);

  E reduce(E combine(var value, E element)) {
    if (length == 0) throw IterableElementError.noElement();
    E value = elementAt(0);
    for (int i = 1; i < length; i++) {
      value = combine(value, elementAt(i));
    }
    return value;
  }

  fold(var initialValue, combine(var previousValue, E element)) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      value = combine(value, elementAt(i));
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return value;
  }

  Iterable<E> skip(int count) => new SubListIterable<E>(this, count, null);

  Iterable<E> skipWhile(bool test(E element)) => super.skipWhile(test);

  Iterable<E> take(int count) => new SubListIterable<E>(this, 0, count);

  Iterable<E> takeWhile(bool test(E element)) => super.takeWhile(test);

  List<E> toList({ bool growable: true }) {
    List<E> result;
    if (growable) {
      result = new List<E>()..length = length;
    } else {
      result = new List<E>(length);
    }
    for (int i = 0; i < length; i++) {
      result[i] = elementAt(i);
    }
    return result;
  }

  Set<E> toSet() {
    Set<E> result = new Set<E>();
    for (int i = 0; i < length; i++) {
      result.add(elementAt(i));
    }
    return result;
  }
}

class SubListIterable<E> extends ListIterable<E> {
  final Iterable<E> _iterable;  // Has efficient length and elementAt.
  final int _start;
  /** If null, represents the length of the iterable. */
  final int _endOrLength;

  SubListIterable(this._iterable, this._start, this._endOrLength) {
    if (_start < 0) {
      throw new RangeError.value(_start);
    }
    if (_endOrLength != null) {
      if (_endOrLength < 0) {
        throw new RangeError.value(_endOrLength);
      }
      if (_start > _endOrLength) {
        throw new RangeError.range(_start, 0, _endOrLength);
      }
    }
  }

  int get _endIndex {
    int length = _iterable.length;
    if (_endOrLength == null || _endOrLength > length) return length;
    return _endOrLength;
  }

  int get _startIndex {
    int length = _iterable.length;
    if (_start > length) return length;
    return _start;
  }

  int get length {
    int length = _iterable.length;
    if (_start >= length) return 0;
    if (_endOrLength == null || _endOrLength >= length) {
      return length - _start;
    }
    return _endOrLength - _start;
  }

  E elementAt(int index) {
    int realIndex = _startIndex + index;
    if (index < 0 || realIndex >= _endIndex) {
      throw new RangeError.range(index, 0, length);
    }
    return _iterable.elementAt(realIndex);
  }

  Iterable<E> skip(int count) {
    if (count < 0) throw new RangeError.value(count);
    int newStart = _start + count;
    if (_endOrLength != null && newStart >= _endOrLength) {
      return new EmptyIterable<E>();
    }
    return new SubListIterable<E>(_iterable, newStart, _endOrLength);
  }

  Iterable<E> take(int count) {
    if (count < 0) throw new RangeError.value(count);
    if (_endOrLength == null) {
      return new SubListIterable<E>(_iterable, _start, _start + count);
    } else {
      int newEnd = _start + count;
      if (_endOrLength < newEnd) return this;
      return new SubListIterable<E>(_iterable, _start, newEnd);
    }
  }

  List<E> toList({bool growable: false}) {
    int start = _start;
    int end = _iterable.length;
    if (_endOrLength != null && _endOrLength < end) end = _endOrLength;
    int length = end - start;
    if (length < 0) length = 0;
    List result = growable ? (new List<E>()..length = length)
                           : new List<E>(length);
    for (int i = 0; i < length; i++) {
      result[i] = _iterable.elementAt(start + i);
      if (_iterable.length < end) throw new ConcurrentModificationError(this);
    }
    return result;
  }
}

/**
 * An [Iterator] that iterates a list-like [Iterable].
 *
 * All iterations is done in terms of [Iterable.length] and
 * [Iterable.elementAt]. These operations are fast for list-like
 * iterables.
 */
class ListIterator<E> implements Iterator<E> {
  final Iterable<E> _iterable;
  final int _length;
  int _index;
  E _current;

  ListIterator(Iterable<E> iterable)
      : _iterable = iterable, _length = iterable.length, _index = 0;

  E get current => _current;

  bool moveNext() {
    int length = _iterable.length;
    if (_length != length) {
      throw new ConcurrentModificationError(_iterable);
    }
    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable.elementAt(_index);
    _index++;
    return true;
  }
}

typedef T _Transformation<S, T>(S value);

class MappedIterable<S, T> extends IterableBase<T> {
  final Iterable<S> _iterable;
  final _Transformation<S, T> _f;

  factory MappedIterable(Iterable iterable, T function(S value)) {
    if (iterable is EfficientLength) {
      return new EfficientLengthMappedIterable<S, T>(iterable, function);
    }
    return new MappedIterable<S, T>._(iterable, function);
  }

  MappedIterable._(this._iterable, T this._f(S element));

  Iterator<T> get iterator => new MappedIterator<S, T>(_iterable.iterator, _f);

  // Length related functions are independent of the mapping.
  int get length => _iterable.length;
  bool get isEmpty => _iterable.isEmpty;

  // Index based lookup can be done before transforming.
  T get first => _f(_iterable.first);
  T get last => _f(_iterable.last);
  T get single => _f(_iterable.single);
  T elementAt(int index) => _f(_iterable.elementAt(index));
}

class EfficientLengthMappedIterable<S, T> extends MappedIterable<S, T>
                                          implements EfficientLength {
  EfficientLengthMappedIterable(Iterable iterable, T function(S value))
      : super._(iterable, function);
}

class MappedIterator<S, T> extends Iterator<T> {
  T _current;
  final Iterator<S> _iterator;
  final _Transformation<S, T> _f;

  MappedIterator(this._iterator, T this._f(S element));

  bool moveNext() {
    if (_iterator.moveNext()) {
      _current = _f(_iterator.current);
      return true;
    }
    _current = null;
    return false;
  }

  T get current => _current;
}

/**
 * Specialized alternative to [MappedIterable] for mapped [List]s.
 *
 * Expects efficient `length` and `elementAt` on the source iterable.
 */
class MappedListIterable<S, T> extends ListIterable<T>
                               implements EfficientLength {
  final Iterable<S> _source;
  final _Transformation<S, T> _f;

  MappedListIterable(this._source, T this._f(S value));

  int get length => _source.length;
  T elementAt(int index) => _f(_source.elementAt(index));
}


typedef bool _ElementPredicate<E>(E element);

class WhereIterable<E> extends IterableBase<E> {
  final Iterable<E> _iterable;
  final _ElementPredicate _f;

  WhereIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator => new WhereIterator<E>(_iterable.iterator, _f);
}

class WhereIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  final _ElementPredicate _f;

  WhereIterator(this._iterator, bool this._f(E element));

  bool moveNext() {
    while (_iterator.moveNext()) {
      if (_f(_iterator.current)) {
        return true;
      }
    }
    return false;
  }

  E get current => _iterator.current;
}

typedef Iterable<T> _ExpandFunction<S, T>(S sourceElement);

class ExpandIterable<S, T> extends IterableBase<T> {
  final Iterable<S> _iterable;
  final _ExpandFunction _f;

  ExpandIterable(this._iterable, Iterable<T> this._f(S element));

  Iterator<T> get iterator => new ExpandIterator<S, T>(_iterable.iterator, _f);
}

class ExpandIterator<S, T> implements Iterator<T> {
  final Iterator<S> _iterator;
  final _ExpandFunction _f;
  // Initialize _currentExpansion to an empty iterable. A null value
  // marks the end of iteration, and we don't want to call _f before
  // the first moveNext call.
  Iterator<T> _currentExpansion = const EmptyIterator();
  T _current;

  ExpandIterator(this._iterator, Iterable<T> this._f(S element));

  void _nextExpansion() {
  }

  T get current => _current;

  bool moveNext() {
    if (_currentExpansion == null) return false;
    while (!_currentExpansion.moveNext()) {
      _current = null;
      if (_iterator.moveNext()) {
        // If _f throws, this ends iteration. Otherwise _currentExpansion and
        // _current will be set again below.
        _currentExpansion = null;
        _currentExpansion = _f(_iterator.current).iterator;
      } else {
        return false;
      }
    }
    _current = _currentExpansion.current;
    return true;
  }
}

class TakeIterable<E> extends IterableBase<E> {
  final Iterable<E> _iterable;
  final int _takeCount;

  factory TakeIterable(Iterable<E> iterable, int takeCount) {
    if (takeCount is! int || takeCount < 0) {
      throw new ArgumentError(takeCount);
    }
    if (iterable is EfficientLength) {
      return new EfficientLengthTakeIterable<E>(iterable, takeCount);
    }
    return new TakeIterable<E>._(iterable, takeCount);
  }

  TakeIterable._(this._iterable, this._takeCount);

  Iterator<E> get iterator {
    return new TakeIterator<E>(_iterable.iterator, _takeCount);
  }
}

class EfficientLengthTakeIterable<E> extends TakeIterable<E>
                                     implements EfficientLength {
  EfficientLengthTakeIterable(Iterable<E> iterable, int takeCount)
      : super._(iterable, takeCount);

  int get length {
    int iterableLength = _iterable.length;
    if (iterableLength > _takeCount) return _takeCount;
    return iterableLength;
  }
}


class TakeIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  int _remaining;

  TakeIterator(this._iterator, this._remaining) {
    assert(_remaining is int && _remaining >= 0);
  }

  bool moveNext() {
    _remaining--;
    if (_remaining >= 0) {
      return _iterator.moveNext();
    }
    _remaining = -1;
    return false;
  }

  E get current {
    if (_remaining < 0) return null;
    return _iterator.current;
  }
}

class TakeWhileIterable<E> extends IterableBase<E> {
  final Iterable<E> _iterable;
  final _ElementPredicate _f;

  TakeWhileIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator {
    return new TakeWhileIterator<E>(_iterable.iterator, _f);
  }
}

class TakeWhileIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  final _ElementPredicate _f;
  bool _isFinished = false;

  TakeWhileIterator(this._iterator, bool this._f(E element));

  bool moveNext() {
    if (_isFinished) return false;
    if (!_iterator.moveNext() || !_f(_iterator.current)) {
      _isFinished = true;
      return false;
    }
    return true;
  }

  E get current {
    if (_isFinished) return null;
    return _iterator.current;
  }
}

class SkipIterable<E> extends IterableBase<E> {
  final Iterable<E> _iterable;
  final int _skipCount;

  factory SkipIterable(Iterable<E> iterable, int skipCount) {
    if (iterable is EfficientLength) {
      return new EfficientLengthSkipIterable<E>(iterable, skipCount);
    }
    return new SkipIterable<E>._(iterable, skipCount);
  }

  SkipIterable._(this._iterable, this._skipCount) {
    if (_skipCount is! int || _skipCount < 0) {
      throw new RangeError(_skipCount);
    }
  }

  Iterable<E> skip(int n) {
    if (n is! int || n < 0) {
      throw new RangeError.value(n);
    }
    return new SkipIterable<E>(_iterable, _skipCount + n);
  }

  Iterator<E> get iterator {
    return new SkipIterator<E>(_iterable.iterator, _skipCount);
  }
}

class EfficientLengthSkipIterable<E> extends SkipIterable<E>
                                     implements EfficientLength {
  EfficientLengthSkipIterable(Iterable<E> iterable, int skipCount)
      : super._(iterable, skipCount);

  int get length {
    int length = _iterable.length - _skipCount;
    if (length >= 0) return length;
    return 0;
  }
}

class SkipIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  int _skipCount;

  SkipIterator(this._iterator, this._skipCount) {
    assert(_skipCount is int && _skipCount >= 0);
  }

  bool moveNext() {
    for (int i = 0; i < _skipCount; i++) _iterator.moveNext();
    _skipCount = 0;
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}

class SkipWhileIterable<E> extends IterableBase<E> {
  final Iterable<E> _iterable;
  final _ElementPredicate _f;

  SkipWhileIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator {
    return new SkipWhileIterator<E>(_iterable.iterator, _f);
  }
}

class SkipWhileIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  final _ElementPredicate _f;
  bool _hasSkipped = false;

  SkipWhileIterator(this._iterator, bool this._f(E element));

  bool moveNext() {
    if (!_hasSkipped) {
      _hasSkipped = true;
      while (_iterator.moveNext()) {
        if (!_f(_iterator.current)) return true;
      }
    }
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}

/**
 * The always empty [Iterable].
 */
class EmptyIterable<E> extends IterableBase<E> implements EfficientLength {
  const EmptyIterable();

  Iterator<E> get iterator => const EmptyIterator();

  void forEach(void action(E element)) {}

  bool get isEmpty => true;

  int get length => 0;

  E get first { throw IterableElementError.noElement(); }

  E get last { throw IterableElementError.noElement(); }

  E get single { throw IterableElementError.noElement(); }

  E elementAt(int index) { throw new RangeError.value(index); }

  bool contains(Object element) => false;

  bool every(bool test(E element)) => true;

  bool any(bool test(E element)) => false;

  E firstWhere(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  String join([String separator = ""]) => "";

  Iterable<E> where(bool test(E element)) => this;

  Iterable map(f(E element)) => const EmptyIterable();

  E reduce(E combine(E value, E element)) {
    throw IterableElementError.noElement();
  }

  fold(var initialValue, combine(var previousValue, E element)) {
    return initialValue;
  }

  Iterable<E> skip(int count) {
    if (count < 0) throw new RangeError.value(count);
    return this;
  }

  Iterable<E> skipWhile(bool test(E element)) => this;

  Iterable<E> take(int count) {
    if (count < 0) throw new RangeError.value(count);
    return this;
  }

  Iterable<E> takeWhile(bool test(E element)) => this;

  List toList({ bool growable: true }) => growable ? <E>[] : new List<E>(0);

  Set toSet() => new Set<E>();
}

/** The always empty iterator. */
class EmptyIterator<E> implements Iterator<E> {
  const EmptyIterator();
  bool moveNext() => false;
  E get current => null;
}

/** An [Iterator] that can move in both directions. */
abstract class BidirectionalIterator<T> implements Iterator<T> {
  bool movePrevious();
}

/**
 * This class provides default implementations for Iterables (including Lists).
 *
 * The uses of this class will be replaced by mixins.
 */
class IterableMixinWorkaround<T> {
  static bool contains(Iterable iterable, var element) {
    for (final e in iterable) {
      if (e == element) return true;
    }
    return false;
  }

  static void forEach(Iterable iterable, void f(o)) {
    for (final e in iterable) {
      f(e);
    }
  }

  static bool any(Iterable iterable, bool f(o)) {
    for (final e in iterable) {
      if (f(e)) return true;
    }
    return false;
  }

  static bool every(Iterable iterable, bool f(o)) {
    for (final e in iterable) {
      if (!f(e)) return false;
    }
    return true;
  }

  static dynamic reduce(Iterable iterable,
                        dynamic combine(previousValue, element)) {
    Iterator iterator = iterable.iterator;
    if (!iterator.moveNext()) throw IterableElementError.noElement();
    var value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  static dynamic fold(Iterable iterable,
                      dynamic initialValue,
                      dynamic combine(dynamic previousValue, element)) {
    for (final element in iterable) {
      initialValue = combine(initialValue, element);
    }
    return initialValue;
  }

  /**
   * Removes elements matching [test] from [list].
   *
   * This is performed in two steps, to avoid exposing an inconsistent state
   * to the [test] function. First the elements to retain are found, and then
   * the original list is updated to contain those elements.
   */
  static void removeWhereList(List list, bool test(var element)) {
    List retained = [];
    int length = list.length;
    for (int i = 0; i < length; i++) {
      var element = list[i];
      if (!test(element)) {
        retained.add(element);
      }
      if (length != list.length) {
        throw new ConcurrentModificationError(list);
      }
    }
    if (retained.length == length) return;
    list.length = retained.length;
    for (int i = 0; i < retained.length; i++) {
      list[i] = retained[i];
    }
  }

  static bool isEmpty(Iterable iterable) {
    return !iterable.iterator.moveNext();
  }

  static dynamic first(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  static dynamic last(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    dynamic result;
    do {
      result = it.current;
    } while(it.moveNext());
    return result;
  }

  static dynamic single(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    dynamic result = it.current;
    if (it.moveNext()) throw IterableElementError.tooMany();
    return result;
  }

  static dynamic firstWhere(Iterable iterable,
                            bool test(dynamic value),
                            dynamic orElse()) {
    for (dynamic element in iterable) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  static dynamic lastWhere(Iterable iterable,
                           bool test(dynamic value),
                           dynamic orElse()) {
    dynamic result = null;
    bool foundMatching = false;
    for (dynamic element in iterable) {
      if (test(element)) {
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  static dynamic lastWhereList(List list,
                               bool test(dynamic value),
                               dynamic orElse()) {
    // TODO(floitsch): check that arguments are of correct type?
    for (int i = list.length - 1; i >= 0; i--) {
      dynamic element = list[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  static dynamic singleWhere(Iterable iterable, bool test(dynamic value)) {
    dynamic result = null;
    bool foundMatching = false;
    for (dynamic element in iterable) {
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    throw IterableElementError.noElement();
  }

  static dynamic elementAt(Iterable iterable, int index) {
    if (index is! int || index < 0) throw new RangeError.value(index);
    int remaining = index;
    for (dynamic element in iterable) {
      if (remaining == 0) return element;
      remaining--;
    }
    throw new RangeError.value(index);
  }

  static String join(Iterable iterable, [String separator]) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(iterable, separator);
    return buffer.toString();
  }

  static String joinList(List list, [String separator]) {
    if (list.isEmpty) return "";
    if (list.length == 1) return "${list[0]}";
    StringBuffer buffer = new StringBuffer();
    if (separator.isEmpty) {
      for (int i = 0; i < list.length; i++) {
        buffer.write(list[i]);
      }
    } else {
      buffer.write(list[0]);
      for (int i = 1; i < list.length; i++) {
        buffer.write(separator);
        buffer.write(list[i]);
      }
    }
    return buffer.toString();
  }

  Iterable<T> where(Iterable iterable, bool f(var element)) {
    return new WhereIterable<T>(iterable, f);
  }

  static Iterable map(Iterable iterable, f(var element)) {
    return new MappedIterable(iterable, f);
  }

  static Iterable mapList(List list, f(var element)) {
    return new MappedListIterable(list, f);
  }

  static Iterable expand(Iterable iterable, Iterable f(var element)) {
    return new ExpandIterable(iterable, f);
  }

  Iterable<T> takeList(List list, int n) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new SubListIterable<T>(list, 0, n);
  }

  Iterable<T> takeWhile(Iterable iterable, bool test(var value)) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new TakeWhileIterable<T>(iterable, test);
  }

  Iterable<T> skipList(List list, int n) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new SubListIterable<T>(list, n, null);
  }

  Iterable<T> skipWhile(Iterable iterable, bool test(var value)) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new SkipWhileIterable<T>(iterable, test);
  }

  Iterable<T> reversedList(List list) {
    return new ReversedListIterable<T>(list);
  }

  static void sortList(List list, int compare(a, b)) {
    if (compare == null) compare = Comparable.compare;
    Sort.sort(list, compare);
  }

  static void shuffleList(List list, Random random) {
    if (random == null) random = new Random();
    int length = list.length;
    while (length > 1) {
      int pos = random.nextInt(length);
      length -= 1;
      var tmp = list[length];
      list[length] = list[pos];
      list[pos] = tmp;
    }
  }

  static int indexOfList(List list, var element, int start) {
    return Lists.indexOf(list, element, start, list.length);
  }

  static int lastIndexOfList(List list, var element, int start) {
    if (start == null) start = list.length - 1;
    return Lists.lastIndexOf(list, element, start);
  }

  static void _rangeCheck(List list, int start, int end) {
    if (start < 0 || start > list.length) {
      throw new RangeError.range(start, 0, list.length);
    }
    if (end < start || end > list.length) {
      throw new RangeError.range(end, start, list.length);
    }
  }

  Iterable<T> getRangeList(List list, int start, int end) {
    _rangeCheck(list, start, end);
    // The generic type is currently lost. It will be fixed with mixins.
    return new SubListIterable<T>(list, start, end);
  }

  static void setRangeList(List list, int start, int end,
                           Iterable from, int skipCount) {
    _rangeCheck(list, start, end);
    int length = end - start;
    if (length == 0) return;

    if (skipCount < 0) throw new ArgumentError(skipCount);

    // TODO(floitsch): Make this accept more.
    List otherList;
    int otherStart;
    if (from is List) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + length > otherList.length) {
      throw IterableElementError.tooFew();
    }
    Lists.copy(otherList, otherStart, list, start, length);
  }

  static void replaceRangeList(List list, int start, int end,
                               Iterable iterable) {
    _rangeCheck(list, start, end);
    if (iterable is! EfficientLength) {
      iterable = iterable.toList();
    }
    int removeLength = end - start;
    int insertLength = iterable.length;
    if (removeLength >= insertLength) {
      int delta = removeLength - insertLength;
      int insertEnd = start + insertLength;
      int newEnd = list.length - delta;
      list.setRange(start, insertEnd, iterable);
      if (delta != 0) {
        list.setRange(insertEnd, newEnd, list, end);
        list.length = newEnd;
      }
    } else {
      int delta = insertLength - removeLength;
      int newLength = list.length + delta;
      int insertEnd = start + insertLength;  // aka. end + delta.
      list.length = newLength;
      list.setRange(insertEnd, newLength, list, end);
      list.setRange(start, insertEnd, iterable);
    }
  }

  static void fillRangeList(List list, int start, int end, fillValue) {
    _rangeCheck(list, start, end);
    for (int i = start; i < end; i++) {
      list[i] = fillValue;
    }
  }

  static void insertAllList(List list, int index, Iterable iterable) {
    if (index < 0 || index > list.length) {
      throw new RangeError.range(index, 0, list.length);
    }
    if (iterable is! EfficientLength) {
      iterable = iterable.toList(growable: false);
    }
    int insertionLength = iterable.length;
    list.length += insertionLength;
    list.setRange(index + insertionLength, list.length, list, index);
    for (var element in iterable) {
      list[index++] = element;
    }
  }

  static void setAllList(List list, int index, Iterable iterable) {
    if (index < 0 || index > list.length) {
      throw new RangeError.range(index, 0, list.length);
    }
    for (var element in iterable) {
      list[index++] = element;
    }
  }

  Map<int, T> asMapList(List l) {
    return new ListMapView<T>(l);
  }

  static bool setContainsAll(Set set, Iterable other) {
    for (var element in other) {
      if (!set.contains(element)) return false;
    }
    return true;
  }

  static Set setIntersection(Set set, Set other, Set result) {
    Set smaller;
    Set larger;
    if (set.length < other.length) {
      smaller = set;
      larger = other;
    } else {
      smaller = other;
      larger = set;
    }
    for (var element in smaller) {
      if (larger.contains(element)) {
        result.add(element);
      }
    }
    return result;
  }

  static Set setUnion(Set set, Set other, Set result) {
    result.addAll(set);
    result.addAll(other);
    return result;
  }

  static Set setDifference(Set set, Set other, Set result) {
    for (var element in set) {
      if (!other.contains(element)) {
        result.add(element);
      }
    }
    return result;
  }
}

/**
 * Creates errors throw by [Iterable] when the element count is wrong.
 */
abstract class IterableElementError {
  /** Error thrown thrown by, e.g., [Iterable.first] when there is no result. */
  static StateError noElement() => new StateError("No element");
  /** Error thrown by, e.g., [Iterable.single] if there are too many results. */
  static StateError tooMany() => new StateError("Too many elements");
  /** Error thrown by, e.g., [List.setRange] if there are too few elements. */
  static StateError tooFew() => new StateError("Too few elements");
}
