// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._collection.dev;


// This is a hack to make @deprecated work in dart:io. Don't remove or use this,
// unless coordinated with either me or the core library team. Thanks!
// TODO(ajohnsen): Remove at the 11th of August 2013.
// TODO(ajohnsen): Remove hide in:
//    tools/dom/templates/html/dart2js/html_dart2js.darttemplate
//    tools/dom/templates/html/dart2js/svg_dart2js.darttemplate
//    tools/dom/templates/html/dart2js/web_audio_dart2js.darttemplate
//    tools/dom/templates/html/dart2js/web_gl_dart2js.darttemplate
//    tools/dom/templates/html/dart2js/web_sql_dart2js.darttemplate
//    tools/dom/templates/html/dartium/html_dartium.darttemplate
//    tools/dom/templates/html/dartium/svg_dartium.darttemplate
//    tools/dom/templates/html/dartium/web_audio_dartium.darttemplate
//    tools/dom/templates/html/dartium/web_gl_dartium.darttemplate
//    tools/dom/templates/html/dartium/web_sql_dartium.darttemplate
//    sdk/lib/core/regexp.dart
// TODO(floitsch): also used in dart:async until end of September for
//    deprecation of runZonedExperimental.
// TODO(floitsch): also used in dart:json and dart:utf until middle of October
//    for deprecation of json and utf libraries.

// We use a random string constant to avoid it clashing with other constants.
// This is, because we have a test that verifies that no metadata is included
// in the output, when no mirrors need them.
const deprecated = "qB2n4PYM";

/**
 * An [Iterable] for classes that have efficient [length] and [elementAt].
 *
 * All other methods are implemented in terms of [length] and [elementAt],
 * including [iterator].
 */
abstract class ListIterable<E> extends IterableBase<E> {
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
    throw new StateError("No matching element");
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
    throw new StateError("No matching element");
  }

  E singleWhere(bool test(E element)) {
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
    if (length == 0) throw new StateError("No elements");
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

  Iterable<E> skip(int count) => new SubListIterable(this, count, null);

  Iterable<E> skipWhile(bool test(E element)) => super.skipWhile(test);

  Iterable<E> take(int count) => new SubListIterable(this, 0, count);

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
  final Iterable<E> _iterable;
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
    return new SubListIterable(_iterable, _start + count, _endOrLength);
  }

  Iterable<E> take(int count) {
    if (count < 0) throw new RangeError.value(count);
    if (_endOrLength == null) {
      return new SubListIterable(_iterable, _start, _start + count);
    } else {
      int newEnd = _start + count;
      if (_endOrLength < newEnd) return this;
      return new SubListIterable(_iterable, _start, newEnd);
    }
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

  MappedIterable(this._iterable, T this._f(S element));

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

/** Specialized alternative to [MappedIterable] for mapped [List]s. */
class MappedListIterable<S, T> extends ListIterable<T> {
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

  SkipIterable(this._iterable, this._skipCount) {
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
class EmptyIterable<E> extends IterableBase<E> {
  const EmptyIterable();

  Iterator<E> get iterator => const EmptyIterator();

  void forEach(void action(E element)) {}

  bool get isEmpty => true;

  int get length => 0;

  E get first { throw new StateError("No elements"); }

  E get last { throw new StateError("No elements"); }

  E get single { throw new StateError("No elements"); }

  E elementAt(int index) { throw new RangeError.value(index); }

  bool contains(Object element) => false;

  bool every(bool test(E element)) => true;

  bool any(bool test(E element)) => false;

  E firstWhere(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E lastWhere(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  E singleWhere(bool test(E element), { E orElse() }) {
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  String join([String separator = ""]) => "";

  Iterable<E> where(bool test(E element)) => this;

  Iterable map(f(E element)) => const EmptyIterable();

  E reduce(E combine(E value, E element)) {
    throw new StateError("No elements");
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
    this;
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
class IterableMixinWorkaround {
  // A list to identify cyclic collections during toString() calls.
  static List _toStringList = new List();

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
    if (!iterator.moveNext()) throw new StateError("No elements");
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
      throw new StateError("No elements");
    }
    return it.current;
  }

  static dynamic last(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    dynamic result;
    do {
      result = it.current;
    } while(it.moveNext());
    return result;
  }

  static dynamic single(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) throw new StateError("No elements");
    dynamic result = it.current;
    if (it.moveNext()) throw new StateError("More than one element");
    return result;
  }

  static dynamic firstWhere(Iterable iterable,
                            bool test(dynamic value),
                            dynamic orElse()) {
    for (dynamic element in iterable) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
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
    throw new StateError("No matching element");
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
    throw new StateError("No matching element");
  }

  static dynamic singleWhere(Iterable iterable, bool test(dynamic value)) {
    dynamic result = null;
    bool foundMatching = false;
    for (dynamic element in iterable) {
      if (test(element)) {
        if (foundMatching) {
          throw new StateError("More than one matching element");
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    throw new StateError("No matching element");
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

  static String toStringIterable(Iterable iterable, String leftDelimiter,
                                 String rightDelimiter) {
    for (int i = 0; i < _toStringList.length; i++) {
      if (identical(_toStringList[i], iterable)) {
        return '$leftDelimiter...$rightDelimiter';
        }
    }

    StringBuffer result = new StringBuffer();
    try {
      _toStringList.add(iterable);
      result.write(leftDelimiter);
      result.writeAll(iterable, ', ');
      result.write(rightDelimiter);
    } finally {
      assert(identical(_toStringList.last, iterable));
      _toStringList.removeLast();
    }
    return result.toString();
  }

  static Iterable where(Iterable iterable, bool f(var element)) {
    return new WhereIterable(iterable, f);
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

  static Iterable takeList(List list, int n) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new SubListIterable(list, 0, n);
  }

  static Iterable takeWhile(Iterable iterable, bool test(var value)) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new TakeWhileIterable(iterable, test);
  }

  static Iterable skipList(List list, int n) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new SubListIterable(list, n, null);
  }

  static Iterable skipWhile(Iterable iterable, bool test(var value)) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new SkipWhileIterable(iterable, test);
  }

  static Iterable reversedList(List list) {
    return new ReversedListIterable(list);
  }

  static void sortList(List list, int compare(a, b)) {
    if (compare == null) compare = Comparable.compare;
    Sort.sort(list, compare);
  }

  static void shuffleList(List list) {
    Random random = new Random();
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
    return Arrays.indexOf(list, element, start, list.length);
  }

  static int lastIndexOfList(List list, var element, int start) {
    if (start == null) start = list.length - 1;
    return Arrays.lastIndexOf(list, element, start);
  }

  static void _rangeCheck(List list, int start, int end) {
    if (start < 0 || start > list.length) {
      throw new RangeError.range(start, 0, list.length);
    }
    if (end < start || end > list.length) {
      throw new RangeError.range(end, start, list.length);
    }
  }

  static Iterable getRangeList(List list, int start, int end) {
    _rangeCheck(list, start, end);
    // The generic type is currently lost. It will be fixed with mixins.
    return new SubListIterable(list, start, end);
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
      throw new StateError("Not enough elements");
    }
    Arrays.copy(otherList, otherStart, list, start, length);
  }

  static void replaceRangeList(List list, int start, int end,
                               Iterable iterable) {
    _rangeCheck(list, start, end);
    // TODO(floitsch): optimize this.
    list.removeRange(start, end);
    list.insertAll(start, iterable);
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
    if (iterable is! List && iterable is! Set) {
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

  static Map<int, dynamic> asMapList(List l) {
    return new ListMapView(l);
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
