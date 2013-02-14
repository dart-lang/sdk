// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._collection.dev;


/**
 * An [Iterable] for classes that have efficient [length] and [elementAt].
 *
 * All other methods are implemented in terms of [length] and [elementAt],
 * including [iterator].
 */
abstract class ListIterable<E> extends Iterable<E> {
  int get length;
  E elementAt(int i);

  Iterator<E> get iterator => new ListIterableIterator<E>(this);

  void forEach(void action(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      action(elementAt(i));
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
  }

  bool get isEmpty => length != 0;

  E get first {
    if (length == 0) throw new StateError("No elements");
    return elementAt(0);
  }

  E get last {
    if (length == 0) throw new StateError("No elements");
    return elementAt(length - 1);
  }

  E get single {
    if (length == 0) throw new StateError("No elements");
    if (length > 1) throw new StateError("Too many elements");
    return elementAt(0);
  }

  bool contains(E element) {
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

  E firstMatching(bool test(E element), { E orElse() }) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      E element = elementAt(i);
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E lastMatching(bool test(E element), { E orElse() }) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i++) {
      E element = elementAt(i);
      if (test(element)) return element;
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E singleMatching(bool test(E element)) {
    int length = this.length;
    E match = null;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      E element = elementAt(i);
      if (test(element)) {
        if (matchFound) {
          throw new StateError("More than one matching element");
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match;
    throw new StateError("No matching element");
  }

  E min([int compare(E a, E b)]) {
    if (length == 0) return null;
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    E min = elementAt(0);
    int length = this.length;
    for (int i = 1; i < length; i++) {
      E element = elementAt(i);
      if (compare(min, element) > 0) {
        min = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return min;
  }

  E max([int compare(E a, E b)]) {
    if (length == 0) return null;
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    E max = elementAt(0);
    int length = this.length;
    for (int i = 1; i < length; i++) {
      E element = elementAt(i);
      if (compare(max, element) < 0) {
        max = element;
      }
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return max;
  }

  String join([String separator]) {
    int length = this.length;
    if (separator != null && !separator.isEmpty) {
      if (length == 0) return "";
      String first = "${elementAt(0)}";
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
      StringBuffer buffer = new StringBuffer(first);
      for (int i = 1; i < length; i++) {
        buffer.add(separator);
        buffer.add("${elementAt(i)}");
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    } else {
      StringBuffer buffer = new StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.add("${elementAt(i)}");
        if (length != this.length) {
          throw new ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    }
  }

  Iterable<E> where(bool test(E element)) => super.where(test);

  Iterable map(f(E element)) => new MappedIterable(this, f);

  Iterable mappedBy(f(E element)) => super.mappedBy(f);

  reduce(var initialValue, combine(var previousValue, E element)) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      value = reduce(value, elementAt(i));
      if (length != this.length) {
        throw new ConcurrentModificationError(this);
      }
    }
    return value;
  }

  Iterable<E> skip(int count) => new SubListIterable(this, count, null);

  Iterable<E> skipWhile(bool test(E element)) => super.skipWhile(test);

  Iterable<E> take(int count) => new SubListIterable(this, 0, count);

  Iterable<E> takeWhile(bool test(E element)) => super.takeWhile(test);

  List<E> toList() {
    List<E> result = new List(length);
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

abstract class SubListIterable<E> extends ListIterable<E> {
  final Iterable<E> _iterable;
  final int _start;
  /** If null, represents the length of the iterable. */
  final int _endOrLength;

  SubListIterable(this._iterable, this._start, this._endOrLength);

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
    if (count < 0) throw new ArgumentError(count);
    return new SubListIterable(_iterable, _start + count, _endOrLength);
  }

  Iterable<E> take(int count) {
    if (count < 0) throw new ArgumentError(count);
    if (_endOrLength == null) {
      return new SubListIterable(_iterable, _start, _start + count);
    } else {
      newEnd = _start + count;
      if (_endOrLength < newEnd) return this;
      return new SubListIterable(_iterable, _start, newEnd);
    }
  }
}

class ListIterableIterator<E> implements Iterator<E> {
  final Iterable<E> _iterable;
  final int _length;
  int _index;
  E _current;
  ListIterableIterator(Iterable<E> iterable)
      : _iterable = iterable, _length = iterable.length, _index = 0;

  E get current => _current;

  bool moveNext() {
    if (_length != _iterable.length) {
      throw new ConcurrentModificationError(_iterable);
    }
    if (_index == _length) {
      _current = null;
      return false;
    }
    _current = _iterable.elementAt(_index);
    _index++;
    return true;
  }
}

typedef T _Transformation<S, T>(S value);

class MappedIterable<S, T> extends Iterable<T> {
  final Iterable<S> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;

  MappedIterable(this._iterable, T this._f(S element));

  Iterator<T> get iterator => new MappedIterator<S, T>(_iterable.iterator, _f);

  // Length related functions are independent of the mapping.
  int get length => _iterable.length;
  bool get isEmpty => _iterable.isEmpty;
}


class MappedIterator<S, T> extends Iterator<T> {
  T _current;
  final Iterator<S> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;

  MappedIterator(this._iterator, T this._f(S element));

  bool moveNext() {
    if (_iterator.moveNext()) {
      _current = _f(_iterator.current);
      return true;
    } else {
      _current = null;
      return false;
    }
  }

  T get current => _current;
}

/** Specialized alternative to [MappedIterable] for mapped [List]s. */
class MappedListIterable<S, T> extends Iterable<T> {
  final List<S> _list;
  /**
   * Start index of the part of the list to map.
   *
   * Allows mapping only a sub-list of an existing list.
   *
   * Used to implement lazy skip/take on a [MappedListIterable].
   */
  final int _start;

  /**
   * End index of the part of the list to map.
   *
   * If null, always use the length of the list.
   */
  final int _end;

  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;

  MappedListIterable(this._list, T this._f(S element), this._start, this._end) {
    if (_end != null && _end < _start) {
      throw new ArgumentError("End ($_end) before start ($_start)");
    }
  }

  /** The start index, limited to the current length of the list. */
  int get _startIndex {
    if (_start <= _list.length) return _start;
    return _list.length;
  }

  /** The end index, if given, limited to the current length of the list. */
  int get _endIndex {
    if (_end == null || _end > _list.length) return _list.length;
    return _end;
  }

  Iterator<T> get iterator =>
      new MappedListIterator<S, T>(_list, _f, _startIndex, _endIndex);

  void forEach(void action(T element)) {
    int length = _list.length;
    for (int i = _startIndex, n = _endIndex; i < n; i++) {
      action(_f(_list[i]));
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
  }

  bool get isEmpty => _startIndex == _endIndex;

  int get length => _endIndex - _startIndex;

  T get first {
    int start = _startIndex;
    if (start == _endIndex) {
      throw new StateError("No elements");
    }
    return _f(_list.elementAt(start));
  }

  T get last {
    int end = _endIndex;
    if (end == _startIndex) {
      throw new StateError("No elements");
    }
    return _f(_list.elementAt(end - 1));
  }

  T get single {
    int start = _startIndex;
    int end = _endIndex;
    if (start != end - 1) {
      if (start == end) {
        throw new StateError("No elements");
      }
      throw new StateError("Too many elements");
    }
    return _f(_list[start]);
  }

  T elementAt(int index) {
    index += _startIndex;
    if (index >= _endIndex) {
      throw new StateError("No matching element");
    }
    return _f(_list.elementAt(index));
  }

  bool contains(T element) {
    int length = _list.length;
    for (int i = _startIndex, n = _endIndex; i < n; i++) {
      if (_f(_list[i]) == element) {
        return true;
      }
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    return false;
  }

  bool every(bool test(T element)) {
    int length = _list.length;
    for (int i = _startIndex, n = _endIndex; i < n; i++) {
      if (!test(_f(_list[i]))) return false;
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    return true;
  }

  bool any(bool test(T element)) {
    int length = _list.length;
    for (int i = _startIndex, n = _endIndex; i < n; i++) {
      if (test(_f(_list[i]))) return true;
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    return false;
  }

  T firstMatching(bool test(T element), { T orElse() }) {
    int length = _list.length;
    for (int i = _startIndex, n = _endIndex; i < n; i++) {
      T value = _f(_list[i]);
      if (test(value)) return value;
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  T lastMatching(bool test(T element), { T orElse() }) {
    int length = _list.length;
    for (int i = _endIndex - 1, start = _startIndex; i >= start; i++) {
      T value = _f(_list[i]);
      if (test(value)) return value;
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  T singleMatching(bool test(T element)) {
    int length = _list.length;
    T match;
    bool matchFound = false;
    for (int i = _startIndex, n = _endIndex; i < n; i++) {
      T value = _f(_list[i]);
      if (test(value)) {
        if (matchFound) {
          throw new StateError("More than one matching element");
        }
        matchFound = true;
        match = value;
      }
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    if (matchFound) return match;
    throw new StateError("No matching element");
  }

  T min([int compare(T a, T b)]) {
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    int length = _list.length;
    int start = _startIndex;
    int end = _endIndex;
    if (start == end) return null;
    T value = _f(_list[start]);
    if (_list.length != length) {
      throw new ConcurrentModificationError(_list);
    }
    for (int i = start + 1; i < end; i++) {
      T nextValue = _f(_list[i]);
      if (compare(value, nextValue) > 0) {
        value = nextValue;
      }
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    return value;
  }

  T max([int compare(T a, T b)]) {
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    int length = _list.length;
    int start = _startIndex;
    int end = _endIndex;
    if (start == end) return null;
    T value = _f(_list[start]);
    if (_list.length != length) {
      throw new ConcurrentModificationError(_list);
    }
    for (int i = start + 1; i < end; i++) {
      T nextValue = _f(_list[i]);
      if (compare(value, nextValue) < 0) {
        value = nextValue;
      }
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    return value;
  }

  String join([String separator]) {
    int start = _startIndex;
    int end = _endIndex;
    if (start == end) return "";
    StringBuffer buffer = new StringBuffer("${_f(_list[start])}");
    if (_list.length != length) {
      throw new ConcurrentModificationError(_list);
    }
    for (int i = start + 1; i < end; i++) {
      if (separator != null && separator != "") {
        buffer.add(separator);
      }
      buffer.add("${_f(_list[i])}");
      if (_list.length != length) {
        throw new ConcurrentModificationError(_list);
      }
    }
    return buffer.toString();
  }

  Iterable<T> where(bool test(T element)) => super.where(test);

  Iterable map(f(T element)) {
    return new MappedListIterable(_list, (S v) => f(_f(v)), _start, _end);
  }

  Iterable mappedBy(f(T element)) => map(f);

  reduce(var initialValue, combine(var previousValue, T element)) {
    return _list.reduce(initialValue, (v, S e) => combine(v, _f(e)));
  }

  Iterable<T> skip(int count) {
    int start = _startIndex + count;
    if (_end != null && start >= _end) {
      return new EmptyIterable<T>();
    }
    return new MappedListIterable(_list, _f, start, _end);
  }

  Iterable<T> skipWhile(bool test(T element)) => super.skipWhile(test);

  Iterable<T> take(int count)  {
    int newEnd = _start + count;
    if (_end == null || newEnd < _end)  {
      return new MappedListIterable(_list, _f, _start, newEnd);
    }
    // Equivalent to "this".
    return new MappedListIterable(_list, _f, _start, _end);
  }

  Iterable<T> takeWhile(bool test(T element)) => super.takeWhile(test);

  List<T> toList() {
    List<T> result = new List<T>();
    forEach(result.add);
    return result;
  }

  Set<T> toSet() {
    Set<T> result = new Set<T>();
    forEach(result.add);
    return result;
  }
}

/**
 * Iterator for [MappedListIterable].
 *
 * A list iterator that iterates over (a sublist of) a list and
 * returns the values transformed by a function.
 *
 * As a list iterator, it throws if the length of the list has
 * changed during iteration.
 */
class MappedListIterator<S, T> implements Iterator<T> {
  List<S> _list;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;
  final int _endIndex;
  final int _length;
  int _index;
  T _current;

  MappedListIterator(List<S> list, this._f, int start, this._endIndex)
      : _list = list, _length = list.length, _index = start;

  T get current => _current;

  bool moveNext() {
    if (_list.length != _length) {
      throw new ConcurrentModificationError(_list);
    }
    if (_index >= _endIndex) {
      _current = null;
      return false;
    }
    _current = _f(_list[_index]);
    _index++;
    return true;
  }
}

typedef bool _ElementPredicate<E>(E element);

class WhereIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

  WhereIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator => new WhereIterator<E>(_iterable.iterator, _f);
}

class WhereIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

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

class ExpandIterable<S, T> extends Iterable<T> {
  final Iterable<S> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ExpandFunction */ _f;

  ExpandIterable(this._iterable, Iterable<T> this._f(S element));

  Iterator<T> get iterator => new ExpandIterator<S, T>(_iterable.iterator, _f);
}

class ExpandIterator<S, T> implements Iterator<T> {
  final Iterator<S> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ExpandFunction */ _f;
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

class TakeIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final int _takeCount;

  TakeIterable(this._iterable, this._takeCount) {
    if (_takeCount is! int || _takeCount < 0) {
      throw new ArgumentError(_takeCount);
    }
  }

  Iterator<E> get iterator {
    return new TakeIterator<E>(_iterable.iterator, _takeCount);
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

class TakeWhileIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

  TakeWhileIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator {
    return new TakeWhileIterator<E>(_iterable.iterator, _f);
  }
}

class TakeWhileIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;
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

class SkipIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final int _skipCount;

  SkipIterable(this._iterable, this._skipCount) {
    if (_skipCount is! int || _skipCount < 0) {
      throw new ArgumentError(_skipCount);
    }
  }

  Iterable<E> skip(int n) {
    if (n is! int || n < 0) {
      throw new ArgumentError(n);
    }
    return new SkipIterable<E>(_iterable, _skipCount + n);
  }

  Iterator<E> get iterator {
    return new SkipIterator<E>(_iterable.iterator, _skipCount);
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

class SkipWhileIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

  SkipWhileIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator {
    return new SkipWhileIterator<E>(_iterable.iterator, _f);
  }
}

class SkipWhileIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;
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
class EmptyIterable<E> extends Iterable<E> {
  const EmptyIterable();

  Iterator<E> get iterator => const EmptyIterator();

  void forEach(void action(E element)) {}

  bool get isEmpty => true;

  int get length => 0;

  E get first { throw new StateError("No elements"); }

  E get last { throw new StateError("No elements"); }

  E get single { throw new StateError("No elements"); }

  E elementAt(int index) { throw new RangeError.value(index); }

  bool contains(E element) => false;

  bool every(bool test(E element)) => true;

  bool any(bool test(E element)) => false;

  E firstMatching(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E lastMatching(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E singleMatching(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E min([int compare(E a, E b)]) => null;

  E max([int compare(E a, E b)]) => null;

  String join([String separator]) => "";

  Iterable<E> where(bool test(E element)) => this;

  Iterable map(f(E element)) => const EmptyIterable();

  Iterable mappedBy(f(E element)) => const EmptyIterable();

  reduce(var initialValue, combine(var previousValue, E element)) {
    return initialValue;
  }

  Iterable<E> skip(int count) => this;

  Iterable<E> skipWhile(bool test(E element)) => this;

  Iterable<E> take(int count) => this;

  Iterable<E> takeWhile(bool test(E element)) => this;

  List toList() => <E>[];

  Set toSet() => new Set<E>();
}

/** The always empty iterator. */
class EmptyIterator<E> implements Iterator<E> {
  const EmptyIterator();
  bool moveNext() => false;
  E get current => null;
}

/** An [Iterator] that can move in both directions. */
abstract class BiDirectionalIterator<T> implements Iterator<T> {
  bool movePrevious();
}
