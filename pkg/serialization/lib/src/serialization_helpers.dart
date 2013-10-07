// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This contains extra functions and classes useful for implementing
 * serialiation. Some or all of these will be removed once the functionality is
 * available in the core library.
 */
library serialization_helpers;

import 'dart:collection';

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

/** Helper function for PrimitiveRule to tell which objects it applies to. */
bool isPrimitive(object) {
  return identical(object, null) || object is num || object is String ||
      identical(object, true) || identical(object, false);
}

/**
 * Given either an Iterable or a Map, return a map. For a Map just return it.
 * For an iterable, return a Map from the index to the value at that index.
 *
 * Used to iterate polymorphically between List-like and Map-like things.
 * For example, keysAndValues(["a", "b", "c"]).forEach((key, value) => ...);
 * will loop over the key/value pairs 1/"a", 2/"b", 3/"c", as if the argument
 * was a Map from integer keys to string values.
 */
Map keysAndValues(x) {
  if (x is Map) return x;
  if (x is List) return x.asMap();
  if (x is Iterable) return x.toList().asMap();
  throw new ArgumentError("Invalid argument, expected Map or Iterable, got $x");
}

/**
 * Lets you iterate polymorphically between
 * List-like and Map-like things, but making them behave like Lists, instead
 * of behaving like Maps.
 * So values(["a", "b", "c"]).forEach((value) => ...);
 * will loop over the values "a", "b", "c", as if it were a List of values.
 * Only supports forEach() and map() operations because that was all I needed
 * for the moment.
 */
Iterable values(x) {
  if (x is Iterable) return x;
  if (x is Map) return x.values;
  throw new ArgumentError("Invalid argument, expected Map or Iterable, got $x");
}

/**
 * Iterate over [collection] and return a new collection of the same type
 * where each value has been transformed by [f]. For iterables and sets, this
 * is equivalent to [map]. For a Map, it returns a new Map with the same keys
 * and the corresponding values transformed by [f].
 */
mapValues(collection, Function f) {
  if (collection is Set) return collection.map(f).toSet();
  if (collection is Iterable) return collection.map(f).toList();
  if (collection is Map) return new Map.fromIterables(collection.keys,
      collection.values.map(f));
  throw new ArgumentError("Invalid argument, expected Map or Iterable, "
      "got $collection");
}

/**
 * This acts as a stand-in for some value that cannot be hashed. We can't
 * just use const Object() because the compiler will fold them together.
 */
class _Sentinel {
  final _wrappedObject;
  const _Sentinel(this._wrappedObject);
}
