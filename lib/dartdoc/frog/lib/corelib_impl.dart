// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("dart:coreimpl");

#source("../../../../corelib/src/implementation/dual_pivot_quicksort.dart");
#source("../../../../corelib/src/implementation/duration_implementation.dart");
#source("../../../../corelib/src/implementation/exceptions.dart");
#source("../../../../corelib/src/implementation/collections.dart");
#source("../../../../corelib/src/implementation/future_implementation.dart");
#source("../../../../corelib/src/implementation/hash_map_set.dart");
// TODO(jimhug): Re-explore tradeoffs with using builtin JS maps.
#source("../../../../corelib/src/implementation/linked_hash_map.dart");
#source("../../../../corelib/src/implementation/maps.dart");
#source("../../../../corelib/src/implementation/options.dart");
#source("../../../../corelib/src/implementation/queue.dart");
#source("../../../../corelib/src/implementation/stopwatch_implementation.dart");
#source("../../../../corelib/src/implementation/splay_tree.dart");

#source("string_buffer.dart");
#source("string_base.dart");
#source("string_implementation.dart");
#source("arrays.dart");
#source("date_implementation.dart");

#source("function_implementation.dart");

/**
 * The default implementation of the [List<E>] interface. Essentially a growable
 * array that will expand automatically as more elements are added.
 */
class ListFactory<E> implements List<E> native "Array" {
  ListFactory([int length]) native;

  // TODO(jmesserly): type parameters aren't working here
  factory ListFactory.from(Iterable other) {
    final list = [];
    for (final e in other) {
      list.add(e);
    }
    return list;
  }

  // TODO(jimhug): Only works for Arrays.
  factory ListFactory.fromList(List other, int startIndex, int endIndex)
    native 'return other.slice(startIndex, endIndex);';

  int length; // all fields on natives are implied native.

  // List<E> members:
  E operator [](int index) native;
  void operator []=(int index, E value) native;
  void add(E value) native "this.push(value);";
  void addLast(E value) native "this.push(value);";
  void addAll(Collection<E> collection) {
    for (E item in collection) add(item);
  }
  void sort(int compare(E a, E b)) native;
  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) native;
  int indexOf(E element, [int start]) native;
  int lastIndexOf(E element, [int start]) native;
  void clear() { length = 0; }

  E removeLast() native "return this.pop();";

  E last() => this[this.length-1];

  ListFactory<E> getRange(int start, int rangeLength) {
    if (rangeLength == 0) return [];
    if (rangeLength < 0) throw new IllegalArgumentException('length');
    if (start < 0 || start + rangeLength > this.length)
      throw new IndexOutOfRangeException(start);
    return this._slice(start, start + rangeLength);
  }

  void setRange(int start, int rangeLength, List<E> from, [int startFrom = 0]) {
    // length of 0 prevails and should not throw exceptions.
    if (rangeLength == 0) return;
    if (rangeLength < 0) {
      throw new IllegalArgumentException('length is negative');
    }

    if (start < 0) throw new IndexOutOfRangeException(start);

    int end = start + rangeLength;
    if (end > this.length) throw new IndexOutOfRangeException(end);

    if (startFrom < 0) throw new IndexOutOfRangeException(startFrom);

    int endFrom = startFrom + rangeLength;
    if (endFrom > from.length) throw new IndexOutOfRangeException(endFrom);

    for (var i = 0; i < rangeLength; ++i)
      this[start + i] = from[startFrom + i];
  }

  void removeRange(int start, int rangeLength) {
    if (rangeLength == 0) return;
    if (rangeLength < 0) throw new IllegalArgumentException('length');
    if (start < 0 || start + rangeLength > this.length)
      throw new IndexOutOfRangeException(start);
    this._splice(start, rangeLength);
  }

  void insertRange(int start, int rangeLength, [E initialValue]) {
    if (rangeLength == 0) return;
    if (rangeLength < 0) throw new IllegalArgumentException('length');
    if (start < 0 || start > this.length)
      throw new IndexOutOfRangeException(start);

    // Splice in the values with a minimum of array allocations.
    var args = new ListFactory(rangeLength + 2);
    args[0] = start;
    args[1] = 0;
    for (var i = 0; i < rangeLength; i++) {
      args[i + 2] = initialValue;
    }
    this._splice_apply(args);
  }

  // Collection<E> members:
  void forEach(void f(E element)) native;
  ListFactory<E> filter(bool f(E element)) native;
  ListFactory map(f(E element)) native;
  bool every(bool f(E element)) native;
  bool some(bool f(E element)) native;
  bool isEmpty() => length == 0;

  // Iterable<E> members:
  Iterator<E> iterator() => new ListIterator(this);

  String toString() => Collections.collectionToString(this);

  // Native methods.
  ListFactory<E> _slice(start, end) native 'slice';
  void _splice(start, length) native 'splice';
  void _splice_apply(args) native 'this.splice.apply(this, args)';
}

// Iterator for lists.
class ListIterator<T> implements Iterator<T> {
  ListIterator(List<T> array)
      : _array = array,
        _pos = 0 {
  }

  bool hasNext() {
    return _array.length > _pos;
  }

  T next() {
    // TODO(jmesserly): this check is redundant in a for-in loop
    // Must we do it?
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final List<T> _array;
  int _pos;
}

// TODO(jimhug): Enforce immutability on IE
ImmutableList _constList(List other) native '''
  other.__proto__ = ImmutableList.prototype;
  return other;
'''
{ new ImmutableList(other.length); }


/** An immutable list. Attempting to modify the list will throw an exception. */
class ImmutableList<E> extends ListFactory<E> {
  // TODO(jimhug): Can this go away now?
  int get length() native "return this.length;";

  void set length(int length) {
    throw const IllegalAccessException();
  }

  ImmutableList(int length) : super(length);

  factory ImmutableList.from(List other) {
    return _constList(other);
  }

  void operator []=(int index, E value) {
    throw const IllegalAccessException();
  }

  void copyFrom(List src, int srcStart, int dstStart, int count) {
    throw const IllegalAccessException();
  }

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) {
    throw const IllegalAccessException();
  }

  void removeRange(int start, int length) {
    throw const IllegalAccessException();
  }

  void insertRange(int start, int length, [E initialValue = null]) {
    throw const IllegalAccessException();
  }

  void sort(int compare(E a, E b)) {
    throw const IllegalAccessException();
  }

  void add(E element) {
    throw const IllegalAccessException();
  }

  void addLast(E element) {
    throw const IllegalAccessException();
  }

  void addAll(Collection<E> elements) {
    throw const IllegalAccessException();
  }

  void clear() {
    throw const IllegalAccessException();
  }

  E removeLast() {
    throw const IllegalAccessException();
  }

  String toString() => Collections.collectionToString(this);
}


LinkedHashMapImplementation _map(List itemsAndKeys) {
  LinkedHashMapImplementation ret = new LinkedHashMapImplementation();
  for (int i=0; i < itemsAndKeys.length;) {
    ret[itemsAndKeys[i++]] = itemsAndKeys[i++];
  }
  return ret;
}

ImmutableMap _constMap(List itemsAndKeys) {
  return new ImmutableMap(itemsAndKeys);
}

/** An immutable map. */
class ImmutableMap<K, V> implements Map<K, V> {
  final Map<K, V> _internal;

  ImmutableMap(List keyValuePairs) : _internal = _map(keyValuePairs);

  V operator [](K key) => _internal[key];

  bool isEmpty() => _internal.isEmpty();

  int get length() => _internal.length;

  void forEach(void f(K key, V value)) {
    _internal.forEach(f);
  }

  Collection<K> getKeys() => _internal.getKeys();

  Collection<V> getValues() => _internal.getValues();

  bool containsKey(K key) => _internal.containsKey(key);

  bool containsValue(V value) => _internal.containsValue(value);

  void operator []=(K key, V value) {
    throw const IllegalAccessException();
  }

  V putIfAbsent(K key, V ifAbsent()) {
    throw const IllegalAccessException();
  }

  void clear() {
    throw const IllegalAccessException();
  }

  V remove(K key) {
    throw const IllegalAccessException();
  }

  String toString() => Maps.mapToString(this);
}


// TODO(jmesserly): this should wrap real RegExp when we can
// We can't do it yet because we'd need a way to redirect the const
// default constructor.
// TODO(jimhug): One way to resolve this is to make the const constructor
// very special in order for it to generate JS regex literals into the code
// and then treat the constructor as a factory.
class JSSyntaxRegExp implements RegExp {
  final String pattern;
  final bool multiLine;
  final bool ignoreCase;

  const JSSyntaxRegExp(String pattern, [bool multiLine, bool ignoreCase]):
    this._create(pattern,
        (multiLine == true ? 'm' : '') + (ignoreCase == true ? 'i' : ''));

  const JSSyntaxRegExp._create(String pattern, String flags) native
    '''this.re = new RegExp(pattern, flags);
    this.pattern = pattern;
    this.multiLine = this.re.multiline;
    this.ignoreCase = this.re.ignoreCase;''';

  Match firstMatch(String str) {
    List<String> m = _exec(str);
    return m == null ? null
        : new MatchImplementation(pattern, str, _matchStart(m), _lastIndex, m);
  }

  List<String> _exec(String str) native "return this.re.exec(str);" {
    // Note: this code is just a hint to tell the frog compiler the dependencies
    // this native code might have. It is not an implementation.
    return [];
  }
  int _matchStart(m) native "return m.index;";
  int get _lastIndex() native "return this.re.lastIndex;";

  bool hasMatch(String str) native "return this.re.test(str);";

  String stringMatch(String str) {
    var match = firstMatch(str);
    return match === null ? null : match.group(0);
  }

  Iterable<Match> allMatches(String str) => new _AllMatchesIterable(this, str);

  /**
   * Returns a new RegExp with the same pattern as this one and with the
   * "global" flag set. This allows us to match this RegExp against a string
   * multiple times, to support things like [allMatches] and
   * [String.replaceAll].
   *
   * Note that the returned RegExp disobeys the normal API in that it maintains
   * state about the location of the last match.
   */
  JSSyntaxRegExp get _global() => new JSSyntaxRegExp._create(pattern,
      'g' + (multiLine ? 'm' : '') + (ignoreCase ? 'i' : ''));
}

class MatchImplementation implements Match {
  const MatchImplementation(
      String this.pattern,
      String this.str,
      int this._start,
      int this._end,
      List<String> this._groups);

  final String pattern;
  final String str;
  final int _start;
  final int _end;
  final List<String> _groups;

  int start() => _start;
  int end() => _end;
  String group(int groupIndex) => _groups[groupIndex];
  String operator [](int groupIndex) => _groups[groupIndex];
  int groupCount() => _groups.length;

  List<String> groups(List<int> groupIndices) {
    List<String> out = [];
    groupIndices.forEach((int groupIndex) => out.add(_groups[groupIndex]));
    return out;
  }
}

class _AllMatchesIterable implements Iterable<Match> {
  final JSSyntaxRegExp _re;
  final String _str;

  const _AllMatchesIterable(this._re, this._str);

  Iterator<Match> iterator() => new _AllMatchesIterator(_re, _str);
}

class _AllMatchesIterator implements Iterator<Match> {
  final RegExp _re;
  final String _str;
  Match _next;
  bool _done;

  _AllMatchesIterator(JSSyntaxRegExp re, String this._str)
    : _done = false, _re = re._global;

  Match next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }

    // _next is set by #hasNext
    var result = _next;
    _next = null;
    return result;
  }

  bool hasNext() {
    if (_done) {
      return false;
    } else if (_next != null) {
      return true;
    }

    _next = _re.firstMatch(_str);
    if (_next == null) {
      _done = true;
      return false;
    } else {
      return true;
    }
  }
}


class NumImplementation implements int, double native "Number" {
  // Arithmetic operations.
  num operator +(num other) native;
  num operator -(num other) native;
  num operator *(num other) native;
  num operator %(num other) native;
  num operator /(num other) native;
  // Truncating division.
  // TODO(jimhug): Implement
  num operator ~/(num other) native;
  // The unary '-' operator.
  num operator negate() native "'use strict'; return -this;";

  // Relational operations.
  bool operator <(num other) native;
  bool operator <=(num other) native;
  bool operator >(num other) native;
  bool operator >=(num other) native;

  bool operator ==(var other) native;

  // Bitwise operations
  int operator &(int other) native;
  int operator |(int other) native;
  int operator ^(int other) native;
  int operator ~() native;
  int operator <<(int shiftAmount) native;
  int operator >>(int shiftAmount) native;


  // TODO(jimhug): Move these out of methods to avoid boxing when not needed.
  // TODO(jmesserly): for now I'm avoiding boxing with "use strict", however,
  // we might want to do something better. It would be nice if operators and
  // methods on String/num were handled in a uniform way.
  num remainder(num other) native "'use strict'; return this % other;";

  bool isEven() native "'use strict'; return ((this & 1) == 0);";
  bool isOdd() native "'use strict'; return ((this & 1) == 1);";
  bool isNaN() native "'use strict'; return isNaN(this);";
  bool isNegative() native
    "'use strict'; return this == 0 ? (1 / this) < 0 : this < 0;";
  bool isInfinite() native
    "'use strict'; return (this == Infinity) || (this == -Infinity);";

  num abs() native "'use strict'; return Math.abs(this);";
  num round() native "'use strict'; return Math.round(this);";
  num floor() native "'use strict'; return Math.floor(this);";
  num ceil() native "'use strict'; return Math.ceil(this);";
  num truncate() native
    "'use strict'; return (this < 0) ? Math.ceil(this) : Math.floor(this);";

  int hashCode() native "'use strict'; return this & 0x1FFFFFFF;";

  // If truncated is -0.0 return +0. The test will also trigger for positive
  // 0s but that's not a problem.
  int toInt() native '''
  'use strict';
  if (isNaN(this)) \$throw(new BadNumberFormatException("NaN"));
  if ((this == Infinity) || (this == -Infinity)) {
    \$throw(new BadNumberFormatException("Infinity"));
  }
  var truncated = (this < 0) ? Math.ceil(this) : Math.floor(this);
  if (truncated == -0.0) return 0;
  return truncated;''' { throw new BadNumberFormatException(""); }

  double toDouble() native "'use strict'; return this + 0;";

  String toStringAsFixed(int fractionDigits) native
    "'use strict'; return this.toFixed(fractionDigits);";
  String toStringAsExponential(int fractionDigits) native
    "'use strict'; return this.toExponential(fractionDigits)";
  String toStringAsPrecision(int precision) native
    "'use strict'; return this.toPrecision(precision)";
  String toRadixString(int radix) native
    "'use strict'; return this.toString(radix)";

  // CompareTo has to give a complete order, including -0/+0, NaN and
  // Infinities.
  // Order is: -Inf < .. < -0.0 < 0.0 .. < +inf < NaN.
  int compareTo(NumImplementation other) {
    // Don't use the 'this' object (which is a JS Number object), but get the
    // primitive JS number by invoking toDouble().
    num thisValue = toDouble();
    // Remember that NaN return false for any comparison.
    if (thisValue < other) {
      return -1;
    } else if (thisValue > other) {
      return 1;
    } else if (thisValue == other) {
      if (thisValue == 0) {
        bool thisIsNegative = isNegative();
        bool otherIsNegative = other.isNegative();
        if (thisIsNegative == otherIsNegative) return 0;
        if (thisIsNegative) return -1;
        return 1;
      }
      return 0;
    } else if (isNaN()) {
      if (other.isNaN()) {
        return 0;
      }
      return 1;
    } else {
      return -1;
    }
  }
}
