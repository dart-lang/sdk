// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This contains extra functions and classes useful for implementing
 * serialiation. Some or all of these will be removed once the functionality is
 * available in the core library.
 */
library serialization_helpers;

/**
 * A named function of one argument that just returns it. Useful for using
 * as a default value for a function parameter or other places where you want
 * to concisely provide a function that just returns its argument.
 */
doNothing(x) => x;

/** Concatenate two lists. Handle the case where one or both might be null. */
// TODO(alanknight): Remove once issue 5342 is resolved.
Iterable append(Iterable a, Iterable b) {
  if (a == null) {
    return (b == null) ? [] : new List.from(b);
  }
  if (b == null) return new List.from(a);
  var result = new List.from(a);
  result.addAll(b);
  return result;
}

/**
 * Return a sorted version of [anIterable], using the default sort criterion.
 * Always returns a List, regardless of the type of [anIterable].
 */
List sorted(anIterable) {
  var result = new List.from(anIterable);
  result.sort();
  return result;
}

/** Helper function for PrimitiveRule to tell which objects it applies to. */
bool isPrimitive(object) {
  return identical(object, null) || object is num || object is String ||
      identical(object, true) || identical(object, false);
}

/**
 * Be able to iterate polymorphically between List-like and Map-like things.
 * For example, keysAndValues(["a", "b", "c"]).forEach((key, value) => ...);
 * will loop over the key/value pairs 1/"a", 2/"b", 3/"c", as if the argument
 * was a Map from integer keys to string values.
 * Only supports forEach() and map() operations because that was all the code
 * needed for the moment.
 */
MapLikeIterable keysAndValues(x) {
  if (x is Map) return new MapLikeIterableForMap(x);
  if (x is Iterable) return new MapLikeIterableForList(x);
  throw new ArgumentError("Invalid argument");
}

/**
 * A class for iterating over things as if they were Maps, which primarily
 * means that forEach() and map() pass two arguments, and map() returns a new
 * Map with the same keys as [collection] and values which have been transformed
 * by the argument to map().
 */
abstract class MapLikeIterable {
  MapLikeIterable(this.collection);
  final collection;

  /** Iterate over the collection, passing both key and value parameters. */
  void forEach(Function f);

  /**
   * Return a new collection whose keys are the same as [collection], but whose
   * values are the result of applying [f] to the key/value pairs. So, if
   * [collection] is a List, it will be the same as the map() method if the
   * [key] parameter wasn't passed.
   */
  mappedBy(Function f) {
    var result = copyEmpty();
    forEach((key, value) {
       result[key] = f(key, value);
    });
    return result;
  }

  /**
   * Return an empty copy of our collection. Very limited, only knows enough
   * to return a Map or List as appropriate.
   */
  copyEmpty();
}



class MapLikeIterableForMap extends MapLikeIterable {
  MapLikeIterableForMap(collection) : super(collection);

  void forEach(Function f) { collection.forEach(f);}
  Map copyEmpty() => new Map();
}

class MapLikeIterableForList extends MapLikeIterable {
  MapLikeIterableForList(collection) : super(collection);

  void forEach(f) {
    Iterator iterator = collection.iterator;
    for (var i = 0; i < collection.length; i++) {
      iterator.moveNext();
      f(i, iterator.current);
    }
  }

  List copyEmpty() => new List(collection.length);
}

/**
 * An inverse of MapLikeIterable. Lets you iterate polymorphically between
 * List-like and Map-like things, but making them behave like Lists, instead
 * of behaving like Maps.
 * So values(["a", "b", "c"]).forEach((value) => ...);
 * will loop over the values "a", "b", "c", as if it were a List of values.
 * Only supports forEach() and map() operations because that was all I needed
 * for the moment.
 */
values(x) {
  if (x is Iterable) return x;
  if (x is Map) return new ListLikeIterable(x);
  throw new ArgumentError("Invalid argument");
}

mapValues(x, f) {
  if (x is Set) return x.mappedBy(f).toSet();
  if (x is Iterable) return x.mappedBy(f).toList();
  if (x is Map) return new ListLikeIterable(x).mappedBy(f);
  throw new ArgumentError("Invalid argument");
}

/**
 * A class for iterating over things as if they were Lists, which primarily
 * means that forEach passes one argument, and map() returns a new Map
 * with the same keys as [collection] and values which haev been transformed
 * by the argument to map().
 */
class ListLikeIterable {
  ListLikeIterable(this.collection);
  final Map collection;

  /** Iterate over the collection, passing just the value parameters. */
  forEach(f) {
      collection.forEach((key, value) => f(value));
  }

  /**
   * Return a new collection whose keys are the same as [collection], but whose
   * values are the result of applying [f] to the key/value pairs. So, if
   * [collection] is a List, it will be the same as if map() had been called
   * directly on [collection].
   */
  mappedBy(Function f) {
      var result = new Map();
      collection.forEach((key, value) => result[key] = f(value));
      return result;
  }

  /**
   * Return an iterator that behaves like a List iterator, taking one parameter.
   */
  Iterator get iterator => collection.values.iterator;
}

/**
 * This acts as a stand-in for some value that cannot be hashed. We can't
 * just use const Object() because the compiler will fold them together.
 */
class _Sentinel {
  final _wrappedObject;
  const _Sentinel(this._wrappedObject);
}

/**
 * This provides an identity map which also allows true, false, and null
 * as valid keys. In the interests of avoiding duplicating map code, and
 * because hashCode for arbitrary objects is currently very slow on the VM,
 * just do a linear lookup.
 */
class IdentityMap<K, V> implements Map<K, V> {

  final List<K> keys = <K>[];
  final List<V> values = <V>[];

  V operator [](K key) {
    var index =  _indexOf(key);
    return (index == -1) ? null : values[index];
  }

  void operator []=(K key, V value) {
    var index = _indexOf(key);
    if (index == -1) {
      keys.add(key);
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  putIfAbsent(K key, Function ifAbsent) {
    var index = _indexOf(key);
    if (index == -1) {
      keys.add(key);
      values.add(ifAbsent());
      return values.last;
    } else {
      return values[index];
    }
  }

  _indexOf(K key) {
    // Go backwards on the guess that we are most likely to access the most
    // recently added.
    // Make strings and primitives unique
    var compareEquality = isPrimitive(key);
    for (var i = keys.length - 1; i >= 0; i--) {
      var equal = compareEquality ? key == keys[i] : identical(key, keys[i]);
      if (equal) return i;
    }
    return -1;
  }

  bool containsKey(K key) => _indexOf(key) != -1;
  void forEach(f(K key, V value)) {
    for (var i = 0; i < keys.length; i++) {
      f(keys[i], values[i]);
    }
  }

  V remove(K key) {
    var index = _indexOf(key);
    if (index == -1) return null;
    keys.removeAt(index);
    return values.removeAt(index);
  }

  int get length => keys.length;
  void clear() {
    keys.clear();
    values.clear();
  }
  bool get isEmpty => keys.isEmpty;

  // Note that this is doing an equality comparison.
  bool containsValue(x) => values.contains(x);
}