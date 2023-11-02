// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

sealed class A {}

class B extends A {}

class C extends A {}

extension type ExtensionTypeList<T>(List<T> it) implements List<T> {}

extension type ExtensionTypeMap<K, V>(Map<K, V> it) implements Map<K, V> {
  V method(K key) => it[key]!;
  V get getter => it.values.first;
  void genericMethod<T>(K key, V value, void Function<T>(T) f) {}
}

nonExhaustiveSealedSubtype(ExtensionTypeList<A> list) {
  return switch (list) {
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //             ^
  // [cfe] The type 'ExtensionTypeList<A>' is not exhaustively matched by the switch cases since it doesn't match '[B(), C()]'.
      [] => 0,
      [_] => 1,
      [_, B()] => 2,
      [_, _, _, ...] => 3,
    };
}

nonExhaustiveMapExtensionType1(ExtensionTypeMap<int, A> map) {
  var a = switch (map) {
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //              ^
  // [cfe] The type 'ExtensionTypeMap<int, A>' is not exhaustively matched by the switch cases since it doesn't match 'ExtensionTypeMap<int, A>(isEmpty: false)'.
    Map(isEmpty: true) => 0,
    {0: B b, 1: _} => 4,
    {0: C c, 1: _} => 5,
    {0: _, 1: _} => 3,
    //           ^^
    // [analyzer] HINT.UNREACHABLE_SWITCH_CASE
    {0: B b} => 1,
    {0: C c} => 2,
  };
}

nonExhaustiveMapExtensionType2(ExtensionTypeMap<int, A> map) {
 var c = switch (map) {
 //      ^^^^^^
 // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
 //              ^
 // [cfe] The type 'ExtensionTypeMap<int, A>' is not exhaustively matched by the switch cases since it doesn't match 'ExtensionTypeMap<int, A>()'.
    Map<int, B>() => 0,
  };
}

nonExhaustiveMapMethod(ExtensionTypeMap<int, A> map) {
  return switch (map) {
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //             ^
  // [cfe] The type 'ExtensionTypeMap<int, A>' is not exhaustively matched by the switch cases since it doesn't match 'ExtensionTypeMap<int, A>(method: A Function(int) _)'.
    ExtensionTypeMap(:B Function(int) method) => 0,
  };
}

nonExhaustiveMapGetter(ExtensionTypeMap<int, A> map) {
  return switch (map) {
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //             ^
  // [cfe] The type 'ExtensionTypeMap<int, A>' is not exhaustively matched by the switch cases since it doesn't match 'ExtensionTypeMap<int, A>(getter: C())'.
    ExtensionTypeMap(:B getter) => 0,
  };
}

nonExhaustiveMapGenericMethod(ExtensionTypeMap<int, A> map) {
  return switch (map) {
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //             ^
  // [cfe] The type 'ExtensionTypeMap<int, A>' is not exhaustively matched by the switch cases since it doesn't match 'ExtensionTypeMap<int, A>(genericMethod: void Function<T>(int, A, void Function<T>(T)) _)'.
    ExtensionTypeMap(
        :void Function<X>(int, B, void Function(X)) genericMethod) => 0,
  };
}

nonExhaustiveMapField(ExtensionTypeMap<int, A> map) {
  return switch (map) {
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //             ^
  // [cfe] The type 'ExtensionTypeMap<int, A>' is not exhaustively matched by the switch cases since it doesn't match 'ExtensionTypeMap<int, A>(it: Map<int, A>())'.
    ExtensionTypeMap(:Map<int, B> it) => 0,
  };
}
