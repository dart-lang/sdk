// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This contains extra functions and classes useful for implementing
 * serialiation. Some or all of these will be removed once the functionality is
 * available in the core library.
 */
library serialization_helpers;
import 'polyfill_identity_set.dart';

/**
 * A named function of one argument that just returns it. Useful for using
 * as a default value for a function parameter or other places where you want
 * to concisely provide a function that just returns its argument.
 */
doNothing(x) => x;

/** Concatenate two lists. Handle the case where one or both might be null. */
// TODO(alanknight): Remove once issue 5342 is resolved.
List append(List a, List b) {
  if (a == null) {
    return (b == null) ? [] : new List.from(b);
  }
  if (b == null) return new List.from(a);
  var result = new List.from(a);
  result.addAll(b);
  return result;
}

/**
 * Return a sorted version of [aCollection], using the default sort criterion.
 * Always returns a List, regardless of the type of [aCollection].
 */
List sorted(aCollection) {
  var result = new List.from(aCollection);
  result.sort();
  return result;
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
  map(Function f) {
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
    Iterator iterator = collection.iterator();
    for (var i = 0; i < collection.length; i++) {
      f(i, iterator.next());
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
  map(Function f) {
      var result = new Map();
      collection.forEach((key, value) => result[key] = f(value));
      return result;
  }

  /**
   * Return an iterator that behaves like a List iterator, taking one parameter.
   */
  Iterator iterator() => collection.values.iterator();
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
 * This provides an identity map which allows true, false, and null as
 * valid keys. It does this by special casing them and using some other
 * known object as the key instead.
 */
class IdentityMapPlus<K, V> extends IdentityMap {
  final trueish = const _Sentinel(true);
  final falseish = const _Sentinel(false);
  final nullish = const _Sentinel(null);

  wrap(x) {
    if (x == true) return trueish;
    if (x == false) return falseish;
    if (x == null) return nullish;
    return x;
  }

  unwrap(x) {
    if (x is _Sentinel) return x._wrappedObject;
    return x;
  }

  operator [](key) => super[wrap(key)];
  operator []=(key, value) => super[wrap(key)] = value;

  putIfAbsent(key, ifAbsent) => super.putIfAbsent(wrap(key), ifAbsent);

  containsKey(key) => super.containsKey(wrap(key));
  forEach(f) => super.forEach((key, value) => f(unwrap(key), value));
  remove(key) => super.remove(unwrap(key));
  /**
   * Note that keys is a very inefficient operation for this type. Don't do it.
   */
  get keys => super.keys.map((x) => unwrap(x));
}


