// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

class CustomMap with MapMixin<int, String> {
  Iterable<int> get keys => [];
  String? operator [](Object? key) => "";
  operator []=(int key, String value) {}
  String remove(Object? key) => throw UnsupportedError("unsupported");
  void clear() => throw UnsupportedError("unsupported");
}

class CustomSet extends SetBase<int> {
  bool add(int value) => throw UnsupportedError("unsupported");
  bool contains(Object? value) => throw UnsupportedError("unsupported");
  Iterator<int> get iterator => <int>[].iterator;
  int get length => 0;
  int? lookup(Object? value) => throw UnsupportedError("unsupported");
  bool remove(Object? value) => throw UnsupportedError("unsupported");
  Set<int> toSet() => this;
}

class Equality {
  final int id;
  final String name;
  const Equality(this.id, this.name);
  int get hashCode => id;
  bool operator ==(Object other) => other is Equality && id == other.id;
  String toString() => "$id:$name";
}

T expectDynamic<T>(dynamic value) {
  Expect.equals(dynamic, T);
  return value;
}

T expectInt<T>(dynamic value) {
  Expect.equals(int, T);
  return value;
}

T expectString<T>(dynamic value) {
  Expect.equals(String, T);
  return value;
}

Iterable<T> expectIntIterable<T>(dynamic value) {
  Expect.equals(int, T);
  return value;
}

Set<T> expectIntSet<T>() {
  Expect.equals(int, T);
  return Set();
}

Stream<T> expectIntStream<T>(dynamic elements) {
  Expect.equals(int, T);
  return Stream<T>.fromIterable(elements);
}

Set<T> expectDynamicSet<T>() {
  Expect.equals(dynamic, T);
  return Set();
}

/// Hacky way of testing the inferred generic type arguments of [object].
///
/// [Expect.type()] only performs a subtype test, which means that it will
/// return `true` when asked if a `List<int>` is a `List<num>` or
/// `List<dynamic>`. For inference, we want to test the type more precisely.
///
/// There isn't a good way to do that in tests yet so, for now, we just see if
/// the runtime type contains the given type argument string.
// TODO(rnystrom): Do something less horribly brittle.
void _expectTypeArguments(String typeArguments, Object object) {
  var typeName = object.runtimeType.toString();

  // If an implementation prints dynamic instantiations like a raw type,
  // handle that.
  if (!typeName.contains("<") &&
      (typeArguments == "dynamic" || typeArguments == "dynamic, dynamic")) {
    return;
  }

  if (!typeName.contains("<$typeArguments>")) {
    Expect.fail("Object should have had generic type '<$typeArguments>', "
        "but was '$typeName'.");
  }
}

void expectListOf<T>(Object object) {
  Expect.type<List>(object);
  _expectTypeArguments(T.toString(), object);
}

void expectSetOf<T>(Object object) {
  Expect.type<Set>(object);
  _expectTypeArguments(T.toString(), object);
}

void expectMapOf<K, V>(Object object) {
  Expect.type<Map>(object);
  _expectTypeArguments("$K, $V", object);
}
