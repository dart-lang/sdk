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

// Implementing Iterable from scratch is kind of a chore, but ensures the API
// works even if the class never bottoms out on a concrete class defining in a
// "dart:" library.
class CustomIterable implements Iterable<String> {
  bool any(Function test) => throw new UnimplementedError();
  bool contains(Object element) => throw new UnimplementedError();
  String elementAt(int index) => throw new UnimplementedError();
  bool every(Function test) => throw new UnimplementedError();
  Iterable<T> expand<T>(Function f) => throw new UnimplementedError();
  String get first => throw new UnimplementedError();
  String firstWhere(Function test, {Function orElse}) =>
      throw new UnimplementedError();
  T fold<T>(T initialValue, Function combine) => throw new UnimplementedError();
  void forEach(Function f) => throw new UnimplementedError();
  bool get isEmpty => throw new UnimplementedError();
  bool get isNotEmpty => throw new UnimplementedError();
  Iterator<String> get iterator => throw new UnimplementedError();
  String join([String separator = ""]) => throw new UnimplementedError();
  String get last => throw new UnimplementedError();
  String lastWhere(Function test, {Function orElse}) =>
      throw new UnimplementedError();
  int get length => throw new UnimplementedError();
  Iterable<T> map<T>(Function f) => throw new UnimplementedError();
  String reduce(Function combine) => throw new UnimplementedError();
  String get single => throw new UnimplementedError();
  String singleWhere(Function test) => throw new UnimplementedError();
  Iterable<String> skip(int count) => throw new UnimplementedError();
  Iterable<String> skipWhile(Function test) => throw new UnimplementedError();
  Iterable<String> take(int count) => throw new UnimplementedError();
  Iterable<String> takeWhile(Function test) => throw new UnimplementedError();
  List<String> toList({bool growable: true}) => throw new UnimplementedError();
  Set<String> toSet() => throw new UnimplementedError();
  Iterable<String> where(Function test) => throw new UnimplementedError();
}

class CustomMap implements Map<int, bool> {
  bool operator [](Object key) => throw new UnimplementedError();
  void operator []=(int key, bool value) => throw new UnimplementedError();
  void addAll(Map<int, bool> other) => throw new UnimplementedError();
  void clear() => throw new UnimplementedError();
  bool containsKey(Object key) => throw new UnimplementedError();
  bool containsValue(Object value) => throw new UnimplementedError();
  void forEach(Function f) => throw new UnimplementedError();
  bool get isEmpty => throw new UnimplementedError();
  bool get isNotEmpty => throw new UnimplementedError();
  Iterable<int> get keys => throw new UnimplementedError();
  int get length => throw new UnimplementedError();
  bool putIfAbsent(int key, Function ifAbsent) =>
      throw new UnimplementedError();
  bool remove(Object key) => throw new UnimplementedError();
  Iterable<bool> get values => throw new UnimplementedError();
}

// Note: Flips order of type parameters.
class FlippedMap<V, K> implements Map<K, V> {
  V operator [](Object key) => throw new UnimplementedError();
  void operator []=(K key, V value) => throw new UnimplementedError();
  void addAll(Map<K, V> other) => throw new UnimplementedError();
  void clear() => throw new UnimplementedError();
  bool containsKey(Object key) => throw new UnimplementedError();
  bool containsValue(Object value) => throw new UnimplementedError();
  void forEach(Function f) => throw new UnimplementedError();
  bool get isEmpty => throw new UnimplementedError();
  bool get isNotEmpty => throw new UnimplementedError();
  Iterable<K> get keys => throw new UnimplementedError();
  int get length => throw new UnimplementedError();
  V putIfAbsent(K key, Function ifAbsent) => throw new UnimplementedError();
  V remove(Object key) => throw new UnimplementedError();
  Iterable<V> get values => throw new UnimplementedError();
}
