// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

untypedList(List list) {
  var a = /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, ..., _] /*space=<[(), ...List<dynamic>, ()]>*/ => 3,
  };
}

sealed class A {}

class B extends A {}

class C extends A {}

typedList(List<A> list) {
  var a = /*
   checkingOrder={List<A>,<A>[],<A>[()],<A>[(), ()],<A>[(), (), (), ...]},
   subtypes={<A>[],<A>[()],<A>[(), ()],<A>[(), (), (), ...]},
   type=List<A>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [B b] /*space=<[B]>*/ => 1,
    [C c] /*space=<[C]>*/ => 2,
    [_, _] /*space=<[A, A]>*/ => 3,
    [B b, ..., _] /*space=<[B, ...List<A>, A]>*/ => 4,
    [C c, ..., _] /*space=<[C, ...List<A>, A]>*/ => 5,
  };
}

restWithSubpattern(List list) {
  var a = /*
   checkingOrder={List<dynamic>,[...]},
   subtypes={[...]},
   type=List<dynamic>
  */
      switch (list) {
    [...var l] /*space=<[...List<dynamic>]>*/ => l.length,
  };
  var b = /*
   checkingOrder={List<dynamic>,[...]},
   error=non-exhaustive:[...[...]]/[...],
   subtypes={[...]},
   type=List<dynamic>
  */
      switch (list) {
    [...List<String> l] /*space=<[...List<String>]>*/ => l.length,
  };
}

exhaustive0(List list) {
  return /*
   checkingOrder={List<dynamic>,[...]},
   subtypes={[...]},
   type=List<dynamic>
  */
      switch (list) {
    [...] /*space=<[...List<dynamic>]>*/ => 0,
  };
}

exhaustive1(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[(), ...]},
   subtypes={[],[(), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, ...] /*space=<[(), ...List<dynamic>]>*/ => 2,
  };
}

exhaustive2(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), (), ...]},
   subtypes={[],[()],[(), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, ...] /*space=<[(), (), ...List<dynamic>]>*/ => 3,
  };
}

exhaustive3(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, ...] /*space=<[(), (), (), ...List<dynamic>]>*/ => 4,
  };
}

exhaustive4(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, _] /*space=<[(), (), (), ()]>*/ => 4,
    [_, _, _, _, ...] /*space=<[(), (), (), (), ...List<dynamic>]>*/ => 5,
  };
}

exhaustive5(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, _] /*space=<[(), (), (), ()]>*/ => 4,
    [_, _, _, _, _] /*space=<[(), (), (), (), ()]>*/ => 5,
    [_, _, _, _, _, ...] /*space=<[(), (), (), (), (), ...List<dynamic>]>*/ =>
      6,
  };
}

exhaustive6(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), ()],[(), (), (), (), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), ()],[(), (), (), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, _] /*space=<[(), (), (), ()]>*/ => 4,
    [_, _, _, _, _] /*space=<[(), (), (), (), ()]>*/ => 5,
    [_, _, _, _, _, _] /*space=<[(), (), (), (), (), ()]>*/ => 6,
    [
      _,
      _,
      _,
      _,
      _,
      _,
      ...
    ] /*space=<[(), (), (), (), (), (), ...List<dynamic>]>*/ =>
      7,
  };
}

exhaustive7(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), ()],[(), (), (), (), (), ()],[(), (), (), (), (), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), ()],[(), (), (), (), (), ()],[(), (), (), (), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, _] /*space=<[(), (), (), ()]>*/ => 4,
    [_, _, _, _, _] /*space=<[(), (), (), (), ()]>*/ => 5,
    [_, _, _, _, _, _] /*space=<[(), (), (), (), (), ()]>*/ => 6,
    [_, _, _, _, _, _, _] /*space=<[(), (), (), (), (), (), ()]>*/ => 7,
    [
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      ...
    ] /*space=<[(), (), (), (), (), (), (), ...List<dynamic>]>*/ =>
      8,
  };
}

exhaustive8(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), ()],[(), (), (), (), (), ()],[(), (), (), (), (), (), ()],[(), (), (), (), (), (), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), ()],[(), (), (), (), (), ()],[(), (), (), (), (), (), ()],[(), (), (), (), (), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, _] /*space=<[(), (), (), ()]>*/ => 4,
    [_, _, _, _, _] /*space=<[(), (), (), (), ()]>*/ => 5,
    [_, _, _, _, _, _] /*space=<[(), (), (), (), (), ()]>*/ => 6,
    [_, _, _, _, _, _, _] /*space=<[(), (), (), (), (), (), ()]>*/ => 7,
    [_, _, _, _, _, _, _, _] /*space=<[(), (), (), (), (), (), (), ()]>*/ => 8,
    [
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      ...
    ] /*space=<[(), (), (), (), (), (), (), (), ...List<dynamic>]>*/ =>
      9,
  };
}

exhaustive2Mid(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, ..., _] /*space=<[(), ...List<dynamic>, ()]>*/ => 3,
  };
}

exhaustive2End(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [..., _, _] /*space=<[...List<dynamic>, (), ()]>*/ => 3,
  };
}

exhaustiveRestWithExtraElement(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), (), ...]},
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, _, ...] /*space=<[(), (), (), (), ...List<dynamic>]>*/ => 4,
  };
}

nonExhaustiveNoRest(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   error=non-exhaustive:[_, _, _, ...],
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
  };
}

nonExhaustiveTyped(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   error=non-exhaustive:[_, _],
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    <int>[_, _] /*space=<int>[int, int]*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, ...] /*space=<[(), (), (), ...List<dynamic>]>*/ => 7,
  };
}

nonExhaustiveRestrictedHeadElement(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   error=non-exhaustive:[Object(), Object()],
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, 1] /*space=<[(), 1]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, ...] /*space=<[(), (), (), ...List<dynamic>]>*/ => 8,
  };
}

nonExhaustiveRestrictedTailElement(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), (), ...]},
   error=non-exhaustive:[Object(), _, Object(), Object()],
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, ..., 1, _] /*space=<[(), ...List<dynamic>, (), 1]>*/ => 8,
  };
}

nonExhaustiveRestrictedRest(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   error=non-exhaustive:[Object(), Object(), Object(), ...[...]]/[Object(), Object(), Object(), ...],
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, ...List<int> rest] /*space=<[(), (), (), ...List<int>]>*/ => 8,
  };
}

nonExhaustiveRestrictedRestWithTail(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), (), ...]},
   error=non-exhaustive:[Object(), _, Object(), Object()],
   subtypes={[],[()],[(), ()],[(), (), ()],[(), (), (), ()],[(), (), (), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _] /*space=<[(), ()]>*/ => 2,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, ...List<int> rest, _, _] /*space=<[(), ...List<int>, (), ()]>*/ => 8,
  };
}

nonExhaustiveMissingCount(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[()],[(), ()],[(), (), (), ...]},
   error=non-exhaustive:[_, _],
   subtypes={[],[()],[(), ()],[(), (), (), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[()]>*/ => 1,
    [_, _, _] /*space=<[(), (), ()]>*/ => 3,
    [_, _, _, ...] /*space=<[(), (), (), ...List<dynamic>]>*/ => 9,
  };
}

unreachableAfterRestOnly(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[(), ...]},
   subtypes={[],[(), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [...] /*space=<[...List<dynamic>]>*/ => 0,
    [_] /*
     error=unreachable,
     space=<[()]>
    */
      =>
      1,
  };
}

unreachableAfterRest(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[(), ...]},
   subtypes={[],[(), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [_, ...] /*space=<[(), ...List<dynamic>]>*/ => 0,
    [_] /*
     error=unreachable,
     space=<[()]>
    */
      =>
      1,
    [...] /*space=<[...List<dynamic>]>*/ => 2,
  };
}

nonExhaustiveAfterRest(List list) {
  return /*
   checkingOrder={List<dynamic>,[],[(), ...]},
   error=non-exhaustive:[],
   subtypes={[],[(), ...]},
   type=List<dynamic>
  */
      switch (list) {
    [_, ...] /*space=<[(), ...List<dynamic>]>*/ => 0,
    [_] /*
     error=unreachable,
     space=<[()]>
    */
      =>
      1,
  };
}

exhaustiveSealed(List<A> list) {
  return /*
   checkingOrder={List<A>,<A>[],<A>[()],<A>[(), (), ...]},
   subtypes={<A>[],<A>[()],<A>[(), (), ...]},
   type=List<A>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [B()] /*space=<[B]>*/ => 1,
    [C()] /*space=<[C]>*/ => 2,
    [_, _, ...] /*space=<[A, A, ...List<A>]>*/ => 3,
  };
}

nonExhaustiveSealedSubtype(List<A> list) {
  return /*
   checkingOrder={List<A>,<A>[],<A>[()],<A>[(), ()],<A>[(), (), (), ...]},
   error=non-exhaustive:[B(), C()],
   subtypes={<A>[],<A>[()],<A>[(), ()],<A>[(), (), (), ...]},
   type=List<A>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[A]>*/ => 1,
    [_, B()] /*space=<[A, B]>*/ => 2,
    [_, _, _, ...] /*space=<[A, A, A, ...List<A>]>*/ => 3,
  };
}

nonExhaustiveSealedCount(List<A> list) {
  return /*
   checkingOrder={List<A>,<A>[],<A>[()],<A>[(), ()],<A>[(), (), (), ...]},
   error=non-exhaustive:[_, _],
   subtypes={<A>[],<A>[()],<A>[(), ()],<A>[(), (), (), ...]},
   type=List<A>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[A]>*/ => 1,
    [_, _, _, ...] /*space=<[A, A, A, ...List<A>]>*/ => 3,
  };
}

reachableRest(List<A> list) {
  return /*
   checkingOrder={List<A>,<A>[],<A>[()],<A>[(), (), ...]},
   subtypes={<A>[],<A>[()],<A>[(), (), ...]},
   type=List<A>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [B(), ...] /*space=<[B, ...List<A>]>*/ => 1,
    [..., B()] /*space=<[...List<A>, B]>*/ => 2,
    [C(), ...] /*space=<[C, ...List<A>]>*/ => 3,
    [..., C()] /*
     error=unreachable,
     space=<[...List<A>, C]>
    */
      =>
      4,
  };
}

nonExhaustiveSubtype(List<Object> list) {
  return /*
   checkingOrder={List<Object>,<Object>[],<Object>[()],<Object>[(), ()],<Object>[(), (), (), ...]},
   error=non-exhaustive:[Object(), Object()]/[_, _],
   subtypes={<Object>[],<Object>[()],<Object>[(), ()],<Object>[(), (), (), ...]},
   type=List<Object>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[Object]>*/ => 1,
    [_, String()] /*space=<[Object, String]>*/ => 2,
    [_, _, _, ...] /*space=<[Object, Object, Object, ...List<Object>]>*/ => 3,
  };
}

nonExhaustiveCount(List<Object> list) {
  return /*
   checkingOrder={List<Object>,<Object>[],<Object>[()],<Object>[(), ()],<Object>[(), (), (), ...]},
   error=non-exhaustive:[_, _],
   subtypes={<Object>[],<Object>[()],<Object>[(), ()],<Object>[(), (), (), ...]},
   type=List<Object>
  */
      switch (list) {
    [] /*space=<[]>*/ => 0,
    [_] /*space=<[Object]>*/ => 1,
    [_, _, _, ...] /*space=<[Object, Object, Object, ...List<Object>]>*/ => 3,
  };
}
