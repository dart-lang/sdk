// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * This [Iterable] mixin implements all [Iterable] members except `iterator`.
 *
 * All other methods are implemented in terms of `iterator`.
 */
abstract class IterableMixin<E> implements Iterable<E> {
  // This class has methods copied verbatim into:
  // - IterableBase
  // - SetMixin
  // If changing a method here, also change the other copies.

  Iterable/*<T>*/ map/*<T>*/(/*=T*/ f(E element)) =>
      new MappedIterable<E, dynamic/*=T*/>(this, f);

  Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);

  Iterable/*<T>*/ expand/*<T>*/(Iterable/*<T>*/ f(E element)) =>
      new ExpandIterable<E, dynamic/*=T*/>(this, f);

  bool contains(Object element) {
    for (E e in this) {
      if (e == element) return true;
    }
    return false;
  }

  void forEach(void f(E element)) {
    for (E element in this) f(element);
  }

  E reduce(E combine(E value, E element)) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw IterableElementError.noElement();
    }
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  dynamic/*=T*/ fold/*<T>*/(var/*=T*/ initialValue,
               dynamic/*=T*/ combine(var/*=T*/ previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  bool every(bool f(E element)) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  String join([String separator = ""]) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.write("${iterator.current}");
      } while (iterator.moveNext());
    } else {
      buffer.write("${iterator.current}");
      while (iterator.moveNext()) {
        buffer.write(separator);
        buffer.write("${iterator.current}");
      }
    }
    return buffer.toString();
  }

  bool any(bool f(E element)) {
    for (E element in this) {
      if (f(element)) return true;
    }
    return false;
  }

  List<E> toList({ bool growable: true }) =>
      new List<E>.from(this, growable: growable);

  Set<E> toSet() => new Set<E>.from(this);

  int get length {
    assert(this is! EfficientLength);
    int count = 0;
    Iterator it = iterator;
    while (it.moveNext()) {
      count++;
    }
    return count;
  }

  bool get isEmpty => !iterator.moveNext();

  bool get isNotEmpty => !isEmpty;

  Iterable<E> take(int count) {
    return new TakeIterable<E>(this, count);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return new TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int count) {
    return new SkipIterable<E>(this, count);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return new SkipWhileIterable<E>(this, test);
  }

  E get first {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  E get last {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    E result;
    do {
      result = it.current;
    } while(it.moveNext());
    return result;
  }

  E get single {
    Iterator<E> it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = it.current;
    if (it.moveNext()) throw IterableElementError.tooMany();
    return result;
  }

  E firstWhere(bool test(E value), { E orElse() }) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E value), { E orElse() }) {
    E result = null;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E value)) {
    E result = null;
    bool foundMatching = false;
    for (E element in this) {
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

  E elementAt(int index) {
    if (index is! int) throw new ArgumentError.notNull("index");
    RangeError.checkNotNegative(index, "index");
    int elementIndex = 0;
    for (E element in this) {
      if (index == elementIndex) return element;
      elementIndex++;
    }
    throw new RangeError.index(index, this, "index", null, elementIndex);
  }


  String toString() => IterableBase.iterableToShortString(this, '(', ')');
}

/**
 * Base class for implementing [Iterable].
 *
 * This class implements all methods of [Iterable] except [Iterable.iterator]
 * in terms of `iterator`.
 */
abstract class IterableBase<E> extends Iterable<E> {
  const IterableBase();

  /**
   * Convert an `Iterable` to a string like [IterableBase.toString].
   *
   * Allows using other delimiters than '(' and ')'.
   *
   * Handles circular references where converting one of the elements
   * to a string ends up converting [iterable] to a string again.
   */
  static String iterableToShortString(Iterable iterable,
                                      [String leftDelimiter = '(',
                                       String rightDelimiter = ')']) {
    if (_isToStringVisiting(iterable)) {
      if (leftDelimiter == "(" && rightDelimiter == ")") {
        // Avoid creating a new string in the "common" case.
        return "(...)";
      }
      return "$leftDelimiter...$rightDelimiter";
    }
    List parts = [];
    _toStringVisiting.add(iterable);
    try {
      _iterablePartsToStrings(iterable, parts);
    } finally {
      assert(identical(_toStringVisiting.last, iterable));
      _toStringVisiting.removeLast();
    }
    return (new StringBuffer(leftDelimiter)
                ..writeAll(parts, ", ")
                ..write(rightDelimiter)).toString();
  }

  /**
   * Converts an `Iterable` to a string.
   *
   * Converts each elements to a string, and separates the results by ", ".
   * Then wraps the result in [leftDelimiter] and [rightDelimiter].
   *
   * Unlike [iterableToShortString], this conversion doesn't omit any
   * elements or puts any limit on the size of the result.
   *
   * Handles circular references where converting one of the elements
   * to a string ends up converting [iterable] to a string again.
   */
  static String iterableToFullString(Iterable iterable,
                                     [String leftDelimiter = '(',
                                      String rightDelimiter = ')']) {
    if (_isToStringVisiting(iterable)) {
      return "$leftDelimiter...$rightDelimiter";
    }
    StringBuffer buffer = new StringBuffer(leftDelimiter);
    _toStringVisiting.add(iterable);
    try {
      buffer.writeAll(iterable, ", ");
    } finally {
      assert(identical(_toStringVisiting.last, iterable));
      _toStringVisiting.removeLast();
    }
    buffer.write(rightDelimiter);
    return buffer.toString();
  }
}

/** A set used to identify cyclic lists during toString() calls. */
final List _toStringVisiting = [];

/** Check if we are currently visiting `o` in a toString call. */
bool _isToStringVisiting(Object o) {
  for (int i = 0; i < _toStringVisiting.length; i++) {
    if (identical(o, _toStringVisiting[i])) return true;
  }
  return false;
}

/**
 * Convert elments of [iterable] to strings and store them in [parts].
 */
void _iterablePartsToStrings(Iterable iterable, List parts) {
  /*
   * This is the complicated part of [iterableToShortString].
   * It is extracted as a separate function to avoid having too much code
   * inside the try/finally.
   */
  /// Try to stay below this many characters.
  const int LENGTH_LIMIT = 80;
  /// Always at least this many elements at the start.
  const int HEAD_COUNT = 3;
  /// Always at least this many elements at the end.
  const int TAIL_COUNT = 2;
  /// Stop iterating after this many elements. Iterables can be infinite.
  const int MAX_COUNT = 100;
  // Per entry length overhead. It's for ", " for all after the first entry,
  // and for "(" and ")" for the initial entry. By pure luck, that's the same
  // number.
  const int OVERHEAD = 2;
  const int ELLIPSIS_SIZE = 3;  // "...".length.

  int length = 0;
  int count = 0;
  Iterator it = iterable.iterator;
  // Initial run of elements, at least HEAD_COUNT, and then continue until
  // passing at most LENGTH_LIMIT characters.
  while (length < LENGTH_LIMIT || count < HEAD_COUNT) {
    if (!it.moveNext()) return;
    String next = "${it.current}";
    parts.add(next);
    length += next.length + OVERHEAD;
    count++;
  }

  String penultimateString;
  String ultimateString;

  // Find last two elements. One or more of them may already be in the
  // parts array. Include their length in `length`.
  var penultimate = null;
  var ultimate = null;
  if (!it.moveNext()) {
    if (count <= HEAD_COUNT + TAIL_COUNT) return;
    ultimateString = parts.removeLast();
    penultimateString = parts.removeLast();
  } else {
    penultimate = it.current;
    count++;
    if (!it.moveNext()) {
      if (count <= HEAD_COUNT + 1) {
        parts.add("$penultimate");
        return;
      }
      ultimateString = "$penultimate";
      penultimateString = parts.removeLast();
      length += ultimateString.length + OVERHEAD;
    } else {
      ultimate = it.current;
      count++;
      // Then keep looping, keeping the last two elements in variables.
      assert(count < MAX_COUNT);
      while (it.moveNext()) {
        penultimate = ultimate;
        ultimate = it.current;
        count++;
        if (count > MAX_COUNT) {
          // If we haven't found the end before MAX_COUNT, give up.
          // This cannot happen in the code above because each entry
          // increases length by at least two, so there is no way to
          // visit more than ~40 elements before this loop.

          // Remove any surplus elements until length, including ", ...)",
          // is at most LENGTH_LIMIT.
          while (length > LENGTH_LIMIT - ELLIPSIS_SIZE - OVERHEAD &&
                 count > HEAD_COUNT) {
            length -= parts.removeLast().length + OVERHEAD;
            count--;
          }
          parts.add("...");
          return;
        }
      }
      penultimateString = "$penultimate";
      ultimateString = "$ultimate";
      length +=
          ultimateString.length + penultimateString.length + 2 * OVERHEAD;
    }
  }

  // If there is a gap between the initial run and the last two,
  // prepare to add an ellipsis.
  String elision = null;
  if (count > parts.length + TAIL_COUNT) {
    elision = "...";
    length += ELLIPSIS_SIZE + OVERHEAD;
  }

  // If the last two elements were very long, and we have more than
  // HEAD_COUNT elements in the initial run, drop some to make room for
  // the last two.
  while (length > LENGTH_LIMIT && parts.length > HEAD_COUNT) {
    length -= parts.removeLast().length + OVERHEAD;
    if (elision == null) {
      elision = "...";
      length += ELLIPSIS_SIZE + OVERHEAD;
    }
  }
  if (elision != null) {
    parts.add(elision);
  }
  parts.add(penultimateString);
  parts.add(ultimateString);
}
