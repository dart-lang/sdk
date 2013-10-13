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
  Iterable map(f(E element)) => new MappedIterable<E, dynamic>(this, f);

  Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);

  Iterable expand(Iterable f(E element)) =>
      new ExpandIterable<E, dynamic>(this, f);

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
      throw new StateError("No elements");
    }
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  dynamic fold(var initialValue,
               dynamic combine(var previousValue, E element)) {
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
    int count = 0;
    Iterator it = iterator;
    while (it.moveNext()) {
      count++;
    }
    return count;
  }

  bool get isEmpty => !iterator.moveNext();

  bool get isNotEmpty => !isEmpty;

  Iterable<E> take(int n) {
    return new TakeIterable<E>(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return new TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int n) {
    return new SkipIterable<E>(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return new SkipWhileIterable<E>(this, test);
  }

  E get first {
    Iterator it = iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    return it.current;
  }

  E get last {
    Iterator it = iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    E result;
    do {
      result = it.current;
    } while(it.moveNext());
    return result;
  }

  E get single {
    Iterator it = iterator;
    if (!it.moveNext()) throw new StateError("No elements");
    E result = it.current;
    if (it.moveNext()) throw new StateError("More than one element");
    return result;
  }

  dynamic firstWhere(bool test(E value), { Object orElse() }) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  dynamic lastWhere(bool test(E value), { Object orElse() }) {
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
    throw new StateError("No matching element");
  }

  E singleWhere(bool test(E value)) {
    E result = null;
    bool foundMatching = false;
    for (E element in this) {
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

  E elementAt(int index) {
    if (index is! int || index < 0) throw new RangeError.value(index);
    int remaining = index;
    for (E element in this) {
      if (remaining == 0) return element;
      remaining--;
    }
    throw new RangeError.value(index);
  }

  String toString() => _iterableToString(this);
}

/**
 * Base class for implementing [Iterable].
 *
 * This class implements all methods of [Iterable] except [Iterable.iterator]
 * in terms of `iterator`.
 */
abstract class IterableBase<E> implements Iterable<E> {
  // TODO(lrn): Base this on IterableMixin if there ever becomes a way
  // to combine const constructors and mixins.
  const IterableBase();

  Iterable map(f(E element)) => new MappedIterable<E, dynamic>(this, f);

  Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);

  Iterable expand(Iterable f(E element)) =>
      new ExpandIterable<E, dynamic>(this, f);

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
      throw new StateError("No elements");
    }
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  dynamic fold(var initialValue,
               dynamic combine(var previousValue, E element)) {
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
    int count = 0;
    Iterator it = iterator;
    while (it.moveNext()) {
      count++;
    }
    return count;
  }

  bool get isEmpty => !iterator.moveNext();

  bool get isNotEmpty => !isEmpty;

  Iterable<E> take(int n) {
    return new TakeIterable<E>(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return new TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int n) {
    return new SkipIterable<E>(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return new SkipWhileIterable<E>(this, test);
  }

  E get first {
    Iterator it = iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    return it.current;
  }

  E get last {
    Iterator it = iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    E result;
    do {
      result = it.current;
    } while(it.moveNext());
    return result;
  }

  E get single {
    Iterator it = iterator;
    if (!it.moveNext()) throw new StateError("No elements");
    E result = it.current;
    if (it.moveNext()) throw new StateError("More than one element");
    return result;
  }

  dynamic firstWhere(bool test(E value), { Object orElse() }) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  dynamic lastWhere(bool test(E value), { Object orElse() }) {
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
    throw new StateError("No matching element");
  }

  E singleWhere(bool test(E value)) {
    E result = null;
    bool foundMatching = false;
    for (E element in this) {
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

  E elementAt(int index) {
    if (index is! int || index < 0) throw new RangeError.value(index);
    int remaining = index;
    for (E element in this) {
      if (remaining == 0) return element;
      remaining--;
    }
    throw new RangeError.value(index);
  }

  /**
   * Returns a string representation of (some of) the elements of `this`.
   *
   * Elements are represented by their own `toString` results.
   *
   * The representation always contains the first three elements.
   * If there are less than a hundred elements in the iterable, it also
   * contains the last two elements.
   *
   * If the resulting string isn't above 80 characters, more elements are
   * included from the start of the iterable.
   *
   * The conversion may omit calling `toString` on some elements if they
   * are known to now occur in the output, and it may stop iterating after
   * a hundred elements.
   */
  String toString() => _iterableToString(this);
}

String _iterableToString(Iterable iterable) {
  const int LENGTH_LIMIT = 80;
  const int MIN_COUNT = 3;  // Always at least this many elements at the start.
  const int MAX_COUNT = 100;
  // Per entry length overhead for ", " (or for "(" and ")" for initial entry)
  const int OVERHEAD = 2;
  const int ELLIPSIS_SIZE = 3;  // "...".length.
  if (_toStringVisiting.contains(iterable)) return "(...)";
  _toStringVisiting.add(iterable);
  List result = [];
  try {
    building: {  // Break this block to complete the toString.
      int length = 0;
      int count = 0;
      Iterator it = iterable.iterator;
      // Initial run of elements, at least MIN_COUNT, and then continue until
      // passing at most LENGTH_LIMIT characters.
      while (count < MIN_COUNT || length < LENGTH_LIMIT) {
        if (!it.moveNext()) break building;
        String next = "${it.current}";
        result.add(next);
        length += next.length + OVERHEAD;  // Includes ")" for the first entry.
        count++;
      }
      String penultimateString;
      String ultimateString;

      // Find last two elements. One or more of them may already be in the
      // result array. Include their length in `length`.
      var penultimate = null;
      var ultimate = null;
      if (!it.moveNext()) {
        if (count <= MIN_COUNT + 2) break building;
        ultimateString = result.removeLast();
        penultimateString = result.removeLast();
      } else {
        penultimate = it.current;
        count++;
        if (!it.moveNext()) {
          if (count <= MIN_COUNT + 1) {
            result.add("$penultimate");
            break building;
          }
          ultimateString = "$penultimate";
          penultimateString = result.removeLast();
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
              // This cannot happen before because each count increases
              // length by at least two, so there is no way to see more
              // than ~40 elements before this loop.

              // Remove any surplus elements until length including ", ...)"
              // is at most LENGTH_LIMIT.
              while (length > LENGTH_LIMIT - ELLIPSIS_SIZE - OVERHEAD &&
                     count > MIN_COUNT) {
                length -= result.removeLast().length + OVERHEAD;
                count--;
              }
              result.add("...");
              break building;
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
      if (count > result.length + 2) {
        elision = "...";
        length += ELLIPSIS_SIZE + OVERHEAD;
      }

      // If the last two elements were very long, and we have more than
      // MIN_COUNT elements in the initial run, drop some to make room for
      // the last two.
      while (length > LENGTH_LIMIT && result.length > MIN_COUNT) {
        length -= result.removeLast().length + OVERHEAD;
        if (elision == null) {
          elision = "...";
          length += ELLIPSIS_SIZE + OVERHEAD;
        }
      }
      if (elision != null) {
        result.add(elision);
      }
      result.add(penultimateString);
      result.add(ultimateString);
    }
  } finally {
    _toStringVisiting.remove(iterable);
  }
  return (new StringBuffer("(")..writeAll(result, ", ")..write(")")).toString();
}
