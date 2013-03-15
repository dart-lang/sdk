// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._collection.dev;

/**
 * Temporary move `toString` methods into this class.
 */
class ToString {
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
    result.write(isList ? '[' : '{');

    bool first = true;
    for (var e in c) {
      if (!first) {
        result.write(', ');
      }
      first = false;
      _emitObject(e, result, visiting);
    }

    result.write(isList ? ']' : '}');
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
        result.write(o is List ? '[...]' : '{...}');
      } else {
        _emitCollection(o, result, visiting);
      }
    } else if (o is Map) {
      if (_containsRef(visiting, o)) {
        result.write('{...}');
      } else {
        _emitMap(o, result, visiting);
      }
    } else { // o is neither a collection nor a map
      result.write(o);
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

  /**
   * Returns a string representing the specified map. The returned string
   * looks like this: [:'{key0: value0, key1: value1, ... keyN: valueN}':].
   * The value returned by its [toString] method is used to represent each
   * key or value.
   *
   * If the map collection contains a reference to itself, either
   * directly as a key or value, or indirectly through other collections
   * or maps, the contained reference is rendered as [:'{...}':]. This
   * prevents the infinite regress that would otherwise occur. So, for example,
   * calling this method on a map whose sole entry maps the string key 'me'
   * to a reference to the map would return [:'{me: {...}}':].
   *
   * A typical implementation of a map's [toString] method will
   * simply return the results of this method applied to the collection.
   */
  static String mapToString(Map m) {
    var result = new StringBuffer();
    _emitMap(m, result, new List());
    return result.toString();
  }

  /**
   * Appends a string representing the specified map to the specified
   * string buffer. The string is formatted as per [mapToString].
   * The [:visiting:] list contains references to all of the enclosing
   * collections and maps (which are currently in the process of being
   * emitted into [:result:]). The [:visiting:] parameter allows this method
   * to generate a [:'[...]':] or [:'{...}':] where required. In other words,
   * it allows this method and [_emitCollection] to identify recursive maps
   * and collections.
   */
  static void _emitMap(Map m, StringBuffer result, List visiting) {
    visiting.add(m);
    result.write('{');

    bool first = true;
    m.forEach((k, v) {
      if (!first) {
        result.write(', ');
      }
      first = false;
      _emitObject(k, result, visiting);
      result.write(': ');
      _emitObject(v, result, visiting);
    });

    result.write('}');
    visiting.removeLast();
  }
}
