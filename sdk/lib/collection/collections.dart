// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  static bool some(Iterable iterable, bool f(o)) {
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

  static List map(Iterable source, List destination, f(o)) {
    for (final e in source) {
      destination.add(f(e));
    }
    return destination;
  }

  static dynamic reduce(Iterable iterable,
                        dynamic initialValue,
                        dynamic combine(dynamic previousValue, element)) {
    for (final element in iterable) {
      initialValue = combine(initialValue, element);
    }
    return initialValue;
  }

  static List filter(Iterable source, List destination, bool f(o)) {
    for (final e in source) {
      if (f(e)) destination.add(e);
    }
    return destination;
  }

  static bool isEmpty(Iterable iterable) {
    return !iterable.iterator().hasNext;
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
