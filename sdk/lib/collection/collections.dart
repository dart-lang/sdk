// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * The [Collections] class implements static methods useful when
 * writing a class that implements [Collection] and the [iterator]
 * method.
 */
class Collections {
  static bool contains(Iterable iterable, var element) {
    for (final e in iterable) {
      if (element == e) return true;
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
                        dynamic initialValue,
                        dynamic combine(dynamic previousValue, element)) {
    for (final element in iterable) {
      initialValue = combine(initialValue, element);
    }
    return initialValue;
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

  static dynamic min(Iterable iterable, [int compare(var a, var b)]) {
    if (compare == null) compare = Comparable.compare;
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      return null;
    }
    var min = it.current;
    while (it.moveNext()) {
      if (compare(min, it.current) > 0) min = it.current;
    }
    return min;
  }

  static dynamic max(Iterable iterable, [int compare(var a, var b)]) {
    if (compare == null) compare = Comparable.compare;
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      return null;
    }
    var max = it.current;
    while (it.moveNext()) {
      if (compare(max, it.current) < 0) max = it.current;
    }
    return max;
  }

  static dynamic single(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) throw new StateError("No elements");
    dynamic result = it.current;
    if (it.moveNext()) throw new StateError("More than one element");
    return result;
  }

  static dynamic firstMatching(Iterable iterable,
                               bool test(dynamic value),
                               dynamic orElse()) {
    for (dynamic element in iterable) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  static dynamic lastMatching(Iterable iterable,
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

  static dynamic lastMatchingInList(List list,
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

  static dynamic singleMatching(Iterable iterable, bool test(dynamic value)) {
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
    Iterator iterator = iterable.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.add("${iterator.current}");
      } while (iterator.moveNext());
    } else {
      buffer.add("${iterator.current}");
      while (iterator.moveNext()) {
        buffer.add(separator);
        buffer.add("${iterator.current}");
      }
    }
    return buffer.toString();
  }

  static String joinList(List<Object> list, [String separator]) {
    if (list.isEmpty) return "";
    if (list.length == 1) return "${list[0]}";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      for (int i = 0; i < list.length; i++) {
        buffer.add("${list[i]}");
      }
    } else {
      buffer.add("${list[0]}");
      for (int i = 1; i < list.length; i++) {
        buffer.add(separator);
        buffer.add("${list[i]}");
      }
    }
    return buffer.toString();
  }

  // TODO(jjb): visiting list should be an identityHashSet when it exists

  /**
   * Returns a string representing the specified collection. If the
   * collection is a [List], the returned string looks like this:
   * [:'[element0, element1, ... elementN]':]. The value returned by its
   * [toString] method is used to represent each element. If the specified
   * collection is not a list, the returned string looks like this:
   * [:{element0, element1, ... elementN}:]. In other words, the strings
   * returned for lists are surrounded by square brackets, while the strings
   * returned for other collections are surrounded by curly braces.
   *
   * If the specified collection contains a reference to itself, either
   * directly or indirectly through other collections or maps, the contained
   * reference is rendered as [:'[...]':] if it is a list, or [:'{...}':] if
   * it is not. This prevents the infinite regress that would otherwise occur.
   * So, for example, calling this method on a list whose sole element is a
   * reference to itself would return [:'[[...]]':].
   *
   * A typical implementation of a collection's [toString] method will
   * simply return the results of this method applied to the collection.
   */
  static String collectionToString(Collection c) {
    var result = new StringBuffer();
    _emitCollection(c, result, new List());
    return result.toString();
  }

  /**
   * Appends a string representing the specified collection to the specified
   * string buffer. The string is formatted as per [collectionToString].
   * The [:visiting:] list contains references to all of the enclosing
   * collections and maps (which are currently in the process of being
   * emitted into [:result:]). The [:visiting:] parameter allows this method to
   * generate a [:'[...]':] or [:'{...}':] where required. In other words,
   * it allows this method and [_emitMap] to identify recursive collections
   * and maps.
   */
  static void _emitCollection(Collection c,
                              StringBuffer result,
                              List visiting) {
    visiting.add(c);
    bool isList = c is List;
    result.add(isList ? '[' : '{');

    bool first = true;
    for (var e in c) {
      if (!first) {
        result.add(', ');
      }
      first = false;
      _emitObject(e, result, visiting);
    }

    result.add(isList ? ']' : '}');
    visiting.removeLast();
  }

  /**
   * Appends a string representing the specified object to the specified
   * string buffer. If the object is a [Collection] or [Map], it is formatted
   * as per [collectionToString] or [mapToString]; otherwise, it is formatted
   * by invoking its own [toString] method.
   *
   * The [:visiting:] list contains references to all of the enclosing
   * collections and maps (which are currently in the process of being
   * emitted into [:result:]). The [:visiting:] parameter allows this method
   * to generate a [:'[...]':] or [:'{...}':] where required. In other words,
   * it allows this method and [_emitCollection] to identify recursive maps
   * and collections.
   */
  static void _emitObject(Object o, StringBuffer result, List visiting) {
    if (o is Collection) {
      if (_containsRef(visiting, o)) {
        result.add(o is List ? '[...]' : '{...}');
      } else {
        _emitCollection(o, result, visiting);
      }
    } else if (o is Map) {
      if (_containsRef(visiting, o)) {
        result.add('{...}');
      } else {
        Maps._emitMap(o, result, visiting);
      }
    } else { // o is neither a collection nor a map
      result.add(o);
    }
  }

  /**
   * Returns true if the specified collection contains the specified object
   * reference.
   */
  static _containsRef(Collection c, Object ref) {
    for (var e in c) {
      if (identical(e, ref)) return true;
    }
    return false;
  }
}
