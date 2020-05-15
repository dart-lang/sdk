// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

R constFunction<T, R>(T _) => throw "uncalled";

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
  // An exact type test would be better, but since `Never` is a subtype of all
  // types that can be written in Dart, it should not matter in practice.
  //
  // (`obj.runtimeType == T` does not work for List/Map/Sets because the runtime
  // type is an implementation-specific subtype of those interfaces.)
  Expect.isTrue(obj is T, "`$obj` should be of type `$T`");
}

testClassInstance() {
  expectOfType<C<Never>>(getC<int>());
  expectOfType<C<Never>>(getC<String>());
  expectOfType<C<Never>>(getC());
}

testImplicitConstClassInstance() {
  expectOfType<C<Never>>(getImplicitConstC<int>());
  expectOfType<C<Never>>(getImplicitConstC<String>());
  expectOfType<C<Never>>(getImplicitConstC());
}

testDownwardsClassInference() {
  expectOfType<Never Function(Never)>(getC<int>().fn);
  expectOfType<Never Function(Never)>(getC<String>().fn);
  expectOfType<Never Function(Never)>(getC().fn);
}

testList() {
  expectOfType<List<Never>>(getList<int>());
  expectOfType<List<Never>>(getList<String>());
  expectOfType<List<Never>>(getList());
}

testImplicitConstList() {
  expectOfType<List<Never>>(getImplicitConstList<int>());
  expectOfType<List<Never>>(getImplicitConstList<String>());
  expectOfType<List<Never>>(getImplicitConstList());
}

testImplicitConstSet() {
  expectOfType<Set<Never>>(getImplicitConstSet<int>());
  expectOfType<Set<Never>>(getImplicitConstSet<String>());
  expectOfType<Set<Never>>(getImplicitConstSet());
}

testSet() {
  expectOfType<Set<Never>>(getSet<int>());
  expectOfType<Set<Never>>(getSet<String>());
  expectOfType<Set<Never>>(getSet());
}

testMap() {
  expectOfType<Map<Never, Never>>(getMap<int, int>());
  expectOfType<Map<Never, Never>>(getMap<int, String>());
  expectOfType<Map<Never, Never>>(getMap<String, int>());
  expectOfType<Map<Never, Never>>(getMap<String, String>());
  expectOfType<Map<Never, Never>>(getMap<Never, Never>());
  expectOfType<Map<Never, Never>>(getMap());
}

testImplicitConstMap() {
  expectOfType<Map<Never, Never>>(getImplicitConstMap<int, int>());
  expectOfType<Map<Never, Never>>(getImplicitConstMap<int, String>());
  expectOfType<Map<Never, Never>>(getImplicitConstMap<String, int>());
  expectOfType<Map<Never, Never>>(getImplicitConstMap<String, String>());
  expectOfType<Map<Never, Never>>(getImplicitConstMap<Never, Never>());
  expectOfType<Map<Never, Never>>(getImplicitConstMap());
}

testFunction() {
  expectOfType<Never Function(Object?)>(getFunction<int, int>());
  expectOfType<Never Function(Object?)>(getFunction<int, String>());
  expectOfType<Never Function(Object?)>(getFunction<String, int>());
  expectOfType<Never Function(Object?)>(getFunction<String, String>());
  expectOfType<Never Function(Object?)>(getFunction<Never, Never>());
  expectOfType<Never Function(Object?)>(getFunction());
}

/// Tests that use type inference for constants do not reference the type
/// parameter. Instead, free type parameters are substituted to obtain the
/// least closure (e.g. `List<T>` becomes `List<Never>` and `R Function(T)`
/// becomes `Never Function(Object)`).
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
