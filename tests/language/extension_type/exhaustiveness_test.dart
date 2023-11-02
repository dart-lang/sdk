// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'package:expect/expect.dart';

sealed class A {}

class B extends A {}

class C extends A {}

extension type ExtensionTypeList<T>(List<T> it) implements List<T> {}

extension type ExtensionTypeMap<K, V>(Map<K, V> it) implements Map<K, V> {
  V method(K key) => it[key]!;
  V get getter => it.values.first;
  void genericMethod<T>(K key, V value, void Function(T) f) {}
}

exhaustiveListExtensionType(ExtensionTypeList<A> list) {
  return switch (list) {
      [] => 0,
      [B()] => 1,
      [C()] => 2,
      [_, _, ...]=> 3,
    };
}

exhaustiveMapExtensionType1(ExtensionTypeMap<int, A> map) {
  return switch (map) {
    Map() => 0,
  };
}

exhaustiveMapExtensionType2(ExtensionTypeMap<int, A> map) {
  return switch (map) {
    Map(isEmpty: true) => 0,
    Map(isEmpty: false) => 1,
  };
}

exhaustiveMapExtensionType3(ExtensionTypeMap<int, A> map) {
  return switch (map) {
    Map() => 0,
    {1: _} => 1,
    {2: _} => 2,
  };
}

exhaustiveMapMethod(ExtensionTypeMap<int, A> map) {
  return switch (map) {
    ExtensionTypeMap(:A Function(int) method) => 0,
  };
}

exhaustiveMapGetter(ExtensionTypeMap<int, A> map) {
  return switch (map) {
    ExtensionTypeMap(:B getter) => 0,
    ExtensionTypeMap(:C getter) => 1,
  };
}

exhaustiveMapGenericMethod(ExtensionTypeMap<int, A> map) {
  return switch (map) {
    ExtensionTypeMap(
        :void Function<X>(int, A, void Function(X)) genericMethod) => 0,
  };
}

exhaustiveMapField(ExtensionTypeMap<int, A> map) {
  return switch (map) {
    ExtensionTypeMap(:Map<int, A> it) => 0,
  };
}

main() {
  Expect.equals(0, exhaustiveListExtensionType(ExtensionTypeList([])));
  Expect.equals(2, exhaustiveListExtensionType(ExtensionTypeList([C()])));

  Expect.equals(0, exhaustiveMapExtensionType1(ExtensionTypeMap({0: B()})));

  Expect.equals(0, exhaustiveMapExtensionType2(ExtensionTypeMap({})));
  Expect.equals(1, exhaustiveMapExtensionType2(ExtensionTypeMap({0: B()})));

  Expect.equals(0, exhaustiveMapExtensionType3(ExtensionTypeMap({0: B()})));

  Expect.equals(0, exhaustiveMapMethod(ExtensionTypeMap({0: B()})));

  Expect.equals(0, exhaustiveMapGetter(ExtensionTypeMap({0: B()})));
  Expect.equals(1, exhaustiveMapGetter(ExtensionTypeMap({0: C()})));

  Expect.equals(0, exhaustiveMapGenericMethod(ExtensionTypeMap({0: B()})));

  Expect.equals(0, exhaustiveMapField(ExtensionTypeMap({0: B()})));
}