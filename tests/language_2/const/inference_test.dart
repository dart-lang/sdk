// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

R constFunction<T, R>(T _) => null;

C<T> getC<T>() => const C(constFunction);

List<T> getList<T>() => const [];

Set<T> getSet<T>() => const {};

Map<K, V> getMap<K, V>() => const {};

R Function(T) getFunction<T, R>() {
  List<R Function(T)> list = const [constFunction];
  return list[0];
}

C<T> getImplicitConstC<T>() {
  List<C<T>> list = const [C(constFunction)];
  return list[0];
}

List<T> getImplicitConstList<T>() {
  List<List<T>> list = const [[]];
  return list[0];
}

Set<T> getImplicitConstSet<T>() {
  List<Set<T>> list = const [{}];
  return list[0];
}

Map<K, V> getImplicitConstMap<K, V>() {
  List<Map<K, V>> list = const [{}];
  return list[0];
}

class C<T> {
  final Object fn;
  const C(T Function(T) this.fn);
}

void expectOfType<T>(Object obj) {
  // An exact type test would be better, but since `Null` is a subtype of all
  // types that can be written in Dart 2.0, it should not matter in practice.
  //
  // (`obj.runtimeType == T` does not work for List/Map/Sets because the runtime
  // type is an implementation-specific subtype of those interfaces.)
  Expect.isTrue(obj is T, "`$obj` should be of type `$T`");
}

testClassInstance() {
  expectOfType<C<Null>>(getC<int>());
  expectOfType<C<Null>>(getC<String>());
  expectOfType<C<Null>>(getC());
}

testImplicitConstClassInstance() {
  expectOfType<C<Null>>(getImplicitConstC<int>());
  expectOfType<C<Null>>(getImplicitConstC<String>());
  expectOfType<C<Null>>(getImplicitConstC());
}

testDownwardsClassInference() {
  expectOfType<Null Function(Null)>(getC<int>().fn);
  expectOfType<Null Function(Null)>(getC<String>().fn);
  expectOfType<Null Function(Null)>(getC().fn);
}

testList() {
  expectOfType<List<Null>>(getList<int>());
  expectOfType<List<Null>>(getList<String>());
  expectOfType<List<Null>>(getList());
}

testImplicitConstList() {
  expectOfType<List<Null>>(getImplicitConstList<int>());
  expectOfType<List<Null>>(getImplicitConstList<String>());
  expectOfType<List<Null>>(getImplicitConstList());
}

testImplicitConstSet() {
  expectOfType<Set<Null>>(getImplicitConstSet<int>());
  expectOfType<Set<Null>>(getImplicitConstSet<String>());
  expectOfType<Set<Null>>(getImplicitConstSet());
}

testSet() {
  expectOfType<Set<Null>>(getSet<int>());
  expectOfType<Set<Null>>(getSet<String>());
  expectOfType<Set<Null>>(getSet());
}

testMap() {
  expectOfType<Map<Null, Null>>(getMap<int, int>());
  expectOfType<Map<Null, Null>>(getMap<int, String>());
  expectOfType<Map<Null, Null>>(getMap<String, int>());
  expectOfType<Map<Null, Null>>(getMap<String, String>());
  expectOfType<Map<Null, Null>>(getMap<Null, Null>());
  expectOfType<Map<Null, Null>>(getMap());
}

testImplicitConstMap() {
  expectOfType<Map<Null, Null>>(getImplicitConstMap<int, int>());
  expectOfType<Map<Null, Null>>(getImplicitConstMap<int, String>());
  expectOfType<Map<Null, Null>>(getImplicitConstMap<String, int>());
  expectOfType<Map<Null, Null>>(getImplicitConstMap<String, String>());
  expectOfType<Map<Null, Null>>(getImplicitConstMap<Null, Null>());
  expectOfType<Map<Null, Null>>(getImplicitConstMap());
}

testFunction() {
  expectOfType<Null Function(Object)>(getFunction<int, int>());
  expectOfType<Null Function(Object)>(getFunction<int, String>());
  expectOfType<Null Function(Object)>(getFunction<String, int>());
  expectOfType<Null Function(Object)>(getFunction<String, String>());
  expectOfType<Null Function(Object)>(getFunction<Null, Null>());
  expectOfType<Null Function(Object)>(getFunction());
}

/// Tests that use type inference for constants do not reference the type
/// parameter. Instead, free type parameters are substituted to obtain the
/// least closure (e.g. `List<T>` becomes `List<Null>` and `R Function(T)`
/// becomes `Null Function(Object?)`).
main() {
  testClassInstance();
  testImplicitConstClassInstance();
  testDownwardsClassInference();
  testList();
  testImplicitConstList();
  testSet();
  testImplicitConstSet();
  testMap();
  testImplicitConstMap();
  testFunction();
}
