// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  return /*
   checkingOrder={List<A>,<A>[],<A>[()],<A>[(), (), ...]},
   subtypes={<A>[],<A>[()],<A>[(), (), ...]},
   type=List<A>
  */switch (list) {
    [] /*space=<[]>*/=> 0,
    [B()] /*space=<[B]>*/=> 1,
    [C()] /*space=<[C]>*/=> 2,
    [_, _, ...]/*space=<[A, A, ...List<A>]>*/=> 3,
  };
}

exhaustiveMapExtensionType1(ExtensionTypeMap<int, A> map) {
  return /*type=Map<int, A>*/switch (map) {
    Map() /*space=Map<int, A>*/=> 0,
  };
}

exhaustiveMapExtensionType2(ExtensionTypeMap<int, A> map) {
  return /*
   fields={isEmpty:bool},
   type=Map<int, A>
  */switch (map) {
    Map(isEmpty: true) /*space=Map<int, A>(isEmpty: true)*/=> 0,
    Map(isEmpty: false) /*space=Map<int, A>(isEmpty: false)*/=> 1,
  };
}

exhaustiveMapExtensionType3(ExtensionTypeMap<int, A> map) {
  return /*type=Map<int, A>*/switch (map) {
    Map() /*space=Map<int, A>*/=> 0,
    {1: _} /*
     error=unreachable,
     space={1: A}
    */=> 1,
    {2: _} /*
     error=unreachable,
     space={2: A}
    */=> 2,
  };
}

exhaustiveMapMethod(ExtensionTypeMap<int, A> map) {
  return /*
   fields={Map<int, A>.method:A Function(int)},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(:A Function(int) method) /*space=Map<int, A>(Map<int, A>.method: A Function(int) (A Function(int)))*/=> 0,
  };
}

exhaustiveMapGetter(ExtensionTypeMap<int, A> map) {
  return /*
   fields={Map<int, A>.getter:A},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(:B getter) /*space=Map<int, A>(Map<int, A>.getter: B (A))*/=> 0,
    ExtensionTypeMap(:C getter) /*space=Map<int, A>(Map<int, A>.getter: C (A))*/=> 1,
  };
}

exhaustiveMapGenericMethod(ExtensionTypeMap<int, A> map) {
  return /*
   fields={Map<int, A>.genericMethod:void Function<T>(int, A, void Function(T))},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(
        :void Function<X>(int, A, void Function(X)) genericMethod) /*space=Map<int, A>(Map<int, A>.genericMethod: void Function<T>(int, A, void Function(T)) (void Function<T>(int, A, void Function(T))))*/=> 0,
  };
}

exhaustiveMapField(ExtensionTypeMap<int, A> map) {
  return /*
   fields={Map<int, A>.it:Map<int, A>},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(:Map<int, A> it) /*space=Map<int, A>(Map<int, A>.it: Map<int, A> (Map<int, A>))*/=> 0,
  };
}