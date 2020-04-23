// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests the (probably temporary) API for extracting reified type arguments
/// from an object.

import "package:expect/expect.dart";

// It's weird that a language test is testing code defined in a package. The
// rationale for putting this test here is:
//
// * This package is special and "built-in" to Dart in that the various
//   compilers give it the special privilege of importing "dart:_internal"
//   without error.
//
// * Eventually, the API being tested here may be replaced with an actual
//   language feature, in which case this test will become an actual language
//   test.
//
// * Placing the test here ensures it is tested on all of the various platforms
//   and configurations where we need the API to work.
import "package:dart_internal/extract_type_arguments.dart";

main() {
  testExtractIterableTypeArgument();
  testExtractMapTypeArguments();
}

testExtractIterableTypeArgument() {
  Object object = <int>[];

  // Invokes function with iterable's type argument.
  var called = false;
  extractIterableTypeArgument(object, <T>() {
    Expect.equals(T, int);
    called = true;
  });
  Expect.isTrue(called);

  // Returns result of function.
  Object result = extractIterableTypeArgument(object, <T>() => new Set<T>());
  Expect.isTrue(result is Set<int>);
  Expect.isFalse(result is Set<bool>);

  // Accepts user-defined implementations of Iterable.
  object = new CustomIterable();
  result = extractIterableTypeArgument(object, <T>() => new Set<T>());
  Expect.isTrue(result is Set<String>);
  Expect.isFalse(result is Set<bool>);
}

testExtractMapTypeArguments() {
  Object object = <String, int>{};

  // Invokes function with map's type arguments.
  var called = false;
  extractMapTypeArguments(object, <K, V>() {
    Expect.equals(K, String);
    Expect.equals(V, int);
    called = true;
  });
  Expect.isTrue(called);

  // Returns result of function.
  Object result = extractMapTypeArguments(object, <K, V>() => new Two<K, V>());
  Expect.isTrue(result is Two<String, int>);
  Expect.isFalse(result is Two<int, String>);

  // Accepts user-defined implementations of Map.
  object = new CustomMap();
  result = extractMapTypeArguments(object, <K, V>() => new Two<K, V>());
  Expect.isTrue(result is Two<int, bool>);
  Expect.isFalse(result is Two<bool, int>);

  // Uses the type parameter order of Map, not any other type in the hierarchy.
  object = new FlippedMap<double, Null>();
  result = extractMapTypeArguments(object, <K, V>() => new Two<K, V>());
  // Order is reversed here:
  Expect.isTrue(result is Two<Null, double>);
  Expect.isFalse(result is Two<double, Null>);
}

class Two<A, B> {}

class CustomIterable implements Iterable<String> {
  noSuchMethod(i) => throw new UnimplementedError();
}

class CustomMap implements Map<int, bool> {
  noSuchMethod(i) => throw new UnimplementedError();
}

// Note: Flips order of type parameters.
class FlippedMap<V, K> implements Map<K, V> {
  noSuchMethod(i) => throw new UnimplementedError();
}
