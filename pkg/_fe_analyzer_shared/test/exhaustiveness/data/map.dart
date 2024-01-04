// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

untypedMap(Map map) {
  var a = /*
   fields={isEmpty:bool},
   type=Map<dynamic, dynamic>
  */
      switch (map) {
    Map(isEmpty: true) /*space=Map<dynamic, dynamic>(isEmpty: true)*/ => 0,
    {1: _, 2: _, 3: _} /*space={1: (), 2: (), 3: ()}*/ => 3,
    {1: _, 2: _} /*space={1: (), 2: ()}*/ => 2,
    {1: _} /*space={1: ()}*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 4,
  };
  var b = /*type=Map<dynamic, dynamic>*/ switch (map) {
    Map() /*space=Map<dynamic, dynamic>*/ => 0,
  };
}

sealed class A {}

class B extends A {}

class C extends A {}

extension type ExtensionTypeMap<K, V>(Map<K, V> it) implements Map<K, V> {
  V method(K key) => it[key]!;
  V get getter => it.values.first;
  void genericMethod<T>(K key, V value, void Function(T) f) {}
}

typedMap(Map<int, A> map) {
  var a = /*
   error=non-exhaustive:Map<int, A>(isEmpty: false),
   fields={isEmpty:bool},
   type=Map<int, A>
  */
      switch (map) {
    Map(isEmpty: true) /*space=Map<int, A>(isEmpty: true)*/ => 0,
    {0: B b, 1: _} /*space={0: B, 1: A}*/ => 4,
    {0: C c, 1: _} /*space={0: C, 1: A}*/ => 5,
    {0: _, 1: _} /*
     error=unreachable,
     space={0: A, 1: A}
    */
      =>
      3,
    {0: B b} /*space={0: B}*/ => 1,
    {0: C c} /*space={0: C}*/ => 2,
  };

  var b = /*type=Map<int, A>*/ switch (map) {
    Map() /*space=Map<int, A>*/ => 0,
  };
  var c = /*
   error=non-exhaustive:Map<int, A>(),
   type=Map<int, A>
  */
      switch (map) {
    Map<int, B>() /*space=Map<int, B>*/ => 0,
  };
  var d = /*type=Map<int, B>*/ switch (map) {
    Map() /*space=Map<int, B>*/ => 0,
    {1: _} /*
     error=unreachable,
     space={1: B}
    */
      =>
      1,
    {2: _} /*
     error=unreachable,
     space={2: B}
    */
      =>
      2,
  };
}

typedMapExtensionType(ExtensionTypeMap<int, A> map) {
  var a = /*
   error=non-exhaustive:Map<int, A>(isEmpty: false),
   fields={isEmpty:bool},
   type=Map<int, A>
  */
  switch (map) {
    Map(isEmpty: true) /*space=Map<int, A>(isEmpty: true)*/ => 0,
    {0: B b, 1: _} /*space={0: B, 1: A}*/ => 4,
    {0: C c, 1: _} /*space={0: C, 1: A}*/ => 5,
    {0: _, 1: _} /*
     error=unreachable,
     space={0: A, 1: A}
    */
    =>
    3,
    {0: B b} /*space={0: B}*/ => 1,
    {0: C c} /*space={0: C}*/ => 2,
  };

  var b = /*type=Map<int, A>*/ switch (map) {
    Map() /*space=Map<int, A>*/ => 0,
  };
  var c = /*
   error=non-exhaustive:Map<int, A>(),
   type=Map<int, A>
  */
  switch (map) {
    Map<int, B>() /*space=Map<int, B>*/ => 0,
  };
  var d = /*type=Map<int, A>*/ switch (map) {
    Map() /*space=Map<int, A>*/ => 0,
    {1: _} /*
     error=unreachable,
     space={1: A}
    */
    =>
    1,
    {2: _} /*
     error=unreachable,
     space={2: A}
    */
    =>
    2,
  };
}

exhaustiveRestOnly(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    Map() /*space=Map<dynamic, dynamic>*/ => 0,
  };
}

unreachableAfterRestOnly(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    Map() /*space=Map<dynamic, dynamic>*/ => 0,
    {0: _} /*
     error=unreachable,
     space={0: ()}
    */
      =>
      1,
  };
}

unreachableAfterRestOnlyTyped(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    Map() /*space=Map<dynamic, dynamic>*/ => 0,
    <int, String>{
      0: _
    } /*
     error=unreachable,
     space=<int, String>{0: String}
    */
      =>
      1,
  };
}

unreachableAfterRestOnlyEmpty(Map o) {
  return /*
   fields={isEmpty:bool},
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    Map() /*space=Map<dynamic, dynamic>*/ => 0,
    Map(
      isEmpty: true
    ) /*
     error=unreachable,
     space=Map<dynamic, dynamic>(isEmpty: true)
    */
      =>
      1,
  };
}

unreachableAfterRestSameKeys(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {0: _} /*
     error=unreachable,
     space={0: ()}
    */
      =>
      1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterRestSameKeys(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {0: _} /*
     error=unreachable,
     space={0: ()}
    */
      =>
      1,
  };
}

unreachableAfterRestMoreKeys(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {0: _, 1: _} /*
     error=unreachable,
     space={0: (), 1: ()}
    */
      =>
      1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterRestMoreKeys(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {0: _, 1: _} /*
     error=unreachable,
     space={0: (), 1: ()}
    */
      =>
      1,
  };
}

unreachableAfterSameKeys(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {0: 1} /*
     error=unreachable,
     space={0: 1}
    */
      =>
      1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterSameKeys(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {0: 1} /*
     error=unreachable,
     space={0: 1}
    */
      =>
      1,
  };
}

reachableAfterRestOnlyDifferentTypes(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    Map<int, String>() /*space=Map<int, String>*/ => 0,
    <int, bool>{0: _} /*space=<int, bool>{0: bool}*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterRestOnlyDifferentTypes(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    Map<int, String>() /*space=Map<int, String>*/ => 0,
    <int, bool>{0: _} /*space=<int, bool>{0: bool}*/ => 1,
  };
}

reachableAfterRestOnlyEmptyDifferentTypes(Map o) {
  return /*
   fields={isEmpty:bool},
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    Map<int, String>() /*space=Map<int, String>*/ => 0,
    Map<int, bool>(isEmpty: true) /*space=Map<int, bool>(isEmpty: true)*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterRestOnlyEmptyDifferentTypes(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   fields={isEmpty:bool},
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    Map<int, String>() /*space=Map<int, String>*/ => 0,
    Map<int, bool>(isEmpty: true) /*space=Map<int, bool>(isEmpty: true)*/ => 1,
  };
}

reachableAfterRestDifferentTypes(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    <int, String>{0: _} /*space=<int, String>{0: String}*/ => 0,
    <int, bool>{0: _} /*space=<int, bool>{0: bool}*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterRestDifferentTypes(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    <int, String>{0: _} /*space=<int, String>{0: String}*/ => 0,
    <int, bool>{0: _} /*space=<int, bool>{0: bool}*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

reachableAfterRestDifferentKeys(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {1: _} /*space={1: ()}*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterRestDifferentKeys(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {1: _} /*space={1: ()}*/ => 1,
  };
}

reachableAfterDifferentKeys(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {1: _} /*space={1: ()}*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterDifferentKeys(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    {0: _} /*space={0: ()}*/ => 0,
    {1: _} /*space={1: ()}*/ => 1,
  };
}

reachableAfterDifferentTypes(Map o) {
  return /*type=Map<dynamic, dynamic>*/ switch (o) {
    <int, String>{0: _} /*space=<int, String>{0: String}*/ => 0,
    <int, bool>{0: _} /*space=<int, bool>{0: bool}*/ => 1,
    Map() /*space=Map<dynamic, dynamic>*/ => 2,
  };
}

nonExhaustiveAfterDifferentTypes(Map o) {
  return /*
   error=non-exhaustive:Map<dynamic, dynamic>(),
   type=Map<dynamic, dynamic>
  */
      switch (o) {
    <int, String>{0: _} /*space=<int, String>{0: String}*/ => 0,
    <int, bool>{0: _} /*space=<int, bool>{0: bool}*/ => 1,
  };
}

exhaustiveMapExtensionType(ExtensionTypeMap<int, A> map) {
  return /*
   fields={isEmpty:bool},
   type=Map<int, A>
  */switch (map) {
    Map(isEmpty: true) /*space=Map<int, A>(isEmpty: true)*/=> 0,
    Map(isEmpty: false) /*space=Map<int, A>(isEmpty: false)*/=> 0,
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

nonExhaustiveMapMethod(ExtensionTypeMap<int, A> map) {
  return /*
   error=non-exhaustive:Map<int, A>(method: A Function(int) _)/Map<int, A>(),
   fields={Map<int, A>.method:A Function(int)},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(:B Function(int) method) /*space=Map<int, A>(Map<int, A>.method: B Function(int) (A Function(int)))*/=> 0,
  };
}

exhaustiveMapGetter(ExtensionTypeMap<int, A> map) {
  return /*
   fields={Map<int, A>.getter:A},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(:B getter) /*space=Map<int, A>(Map<int, A>.getter: B (A))*/=> 0,
    ExtensionTypeMap(:C getter) /*space=Map<int, A>(Map<int, A>.getter: C (A))*/=> 0,
  };
}

nonExhaustiveMapGetter(ExtensionTypeMap<int, A> map) {
  return /*
   error=non-exhaustive:Map<int, A>(getter: C()),
   fields={Map<int, A>.getter:A},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(:B getter) /*space=Map<int, A>(Map<int, A>.getter: B (A))*/=> 0,
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

nonExhaustiveMapGenericMethod(ExtensionTypeMap<int, A> map) {
  return /*
   fields={Map<int, A>.genericMethod:void Function<T>(int, A, void Function(T))},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(
        :void Function<X>(int, B, void Function(X)) genericMethod)
        /*space=Map<int, A>(Map<int, A>.genericMethod: void Function<T>(int, A, void Function(T)) (void Function<T>(int, A, void Function(T))))*/
        => 0,
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

nonExhaustiveMapField(ExtensionTypeMap<int, A> map) {
  return /*
   error=non-exhaustive:Map<int, A>(it: Map<int, A>())/Map<int, A>(),
   fields={Map<int, A>.it:Map<int, A>},
   type=Map<int, A>
  */switch (map) {
    ExtensionTypeMap(:Map<int, B> it) /*space=Map<int, A>(Map<int, A>.it: Map<int, B> (Map<int, A>))*/=> 0,
  };
}
