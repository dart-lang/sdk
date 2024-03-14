// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A<X extends A<X>> {}

class B extends A<B> {} // E{T=B, B <: A<T>}

class C extends A<C> {} // E{T=C, C <: A<T>}

sealed class D<Y extends D<Y>> extends A<Y> {} // E{T<:D<T>, D<T> <: A<T>}

class D1 extends D<D1> {} // E{T=D1, D1 <: D<T>}

class D2 extends D<D2> {} // E{T=D2, D2 <: D<T>}

enum Enum<Z extends A<Z>> {
  b<B>(),
  c<C>(),
  d1<D1>(),
  d2<D2>(),
}

exhaustiveSwitchDynamic(A<dynamic> a, Enum<dynamic> e) {
  /*
   checkingOrder={A<dynamic>,B,C,D<D<dynamic>>,D1,D2},
   expandedSubtypes={B,C,D1,D2},
   subtypes={B,C,D<D<dynamic>>},
   type=A<dynamic>
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('b');
      break;
    /*space=C*/
    case C c:
      print('c');
      break;
    /*space=D1*/
    case D1 d1:
      print('d1');
      break;
    /*space=D2*/
    case D2 d2:
      print('d2');
      break;
  }
  /*
   checkingOrder={Enum<dynamic>,Enum.b,Enum.c,Enum.d1,Enum.d2},
   subtypes={Enum.b,Enum.c,Enum.d1,Enum.d2},
   type=Enum<dynamic>
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Enum.d1*/
    case Enum.d1:
      print('d1');
      break;
    /*space=Enum.d2*/
    case Enum.d2:
      print('d2');
      break;
  }
}

exhaustiveSwitchGeneric<T extends A<T>>(A<T> a, Enum<T> e) {
  /*
   checkingOrder={A<T>,B,C,D<D<dynamic>>,D1,D2},
   expandedSubtypes={B,C,D1,D2},
   subtypes={B,C,D<D<dynamic>>},
   type=A<T>
  */
  switch (a) {
    /*space=B*/ case B b:
      print('b');
      break;
    /*space=C*/ case C c:
      print('c');
      break;
    /*space=D1*/ case D1 d1:
      print('d1');
      break;
    /*space=D2*/ case D2 d2:
      print('d2');
      break;
  }
  /*
   checkingOrder={Enum<T>,Enum.b,Enum.c,Enum.d1,Enum.d2},
   subtypes={Enum.b,Enum.c,Enum.d1,Enum.d2},
   type=Enum<T>
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Enum.d1*/
    case Enum.d1:
      print('d1');
      break;
    /*space=Enum.d2*/
    case Enum.d2:
      print('d2');
      break;
  }
}

exhaustiveSwitchBounded<T extends D<T>>(A<T> a, Enum<T> e) {
  /*
   checkingOrder={A<T>,D<T>,D1,D2},
   expandedSubtypes={D1,D2},
   subtypes={D<T>},
   type=A<T>
  */
  switch (a) {
    /*space=D1*/
    case D1 d1:
      print('d1');
      break;
    /*space=D2*/
    case D2 d2:
      print('d2');
      break;
  }
  /*
   checkingOrder={Enum<T>,Enum.d1,Enum.d2},
   subtypes={Enum.d1,Enum.d2},
   type=Enum<T>
  */
  switch (e) {
    /*space=Enum.d1*/
    case Enum.d1:
      print('d1');
      break;
    /*space=Enum.d2*/
    case Enum.d2:
      print('d2');
      break;
  }
}

exhaustiveSwitchCatchAll<T extends A<T>>(A<T> a, Enum<T> e) {
  /*
   checkingOrder={A<T>,B,C,D<D<dynamic>>,D1,D2},
   expandedSubtypes={B,C,D1,D2},
   subtypes={B,C,D<D<dynamic>>},
   type=A<T>
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('b');
      break;
    /*space=C*/
    case C c:
      print('c');
      break;
    /*space=A<T>*/
    case A<T> d:
      print('_');
      break;
  }
  /*
   checkingOrder={Enum<T>,Enum.b,Enum.c,Enum.d1,Enum.d2},
   subtypes={Enum.b,Enum.c,Enum.d1,Enum.d2},
   type=Enum<T>
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Enum<T>*/
    case Enum<A<T>> d:
      print('_');
      break;
  }
}

nonExhaustiveSwitchDynamic(A<dynamic> a, Enum<dynamic> e) {
  /*
   checkingOrder={A<dynamic>,B,C,D<D<dynamic>>,D1,D2},
   error=non-exhaustive:D1(),
   expandedSubtypes={B,C,D1,D2},
   subtypes={B,C,D<D<dynamic>>},
   type=A<dynamic>
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('b');
      break;
    /*space=C*/
    case C c:
      print('c');
      break;
    /*space=D2*/
    case D2 d2:
      print('d2');
      break;
  }
  /*
   checkingOrder={Enum<dynamic>,Enum.b,Enum.c,Enum.d1,Enum.d2},
   error=non-exhaustive:Enum.c,
   subtypes={Enum.b,Enum.c,Enum.d1,Enum.d2},
   type=Enum<dynamic>
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.d1*/
    case Enum.d1:
      print('d1');
      break;
    /*space=Enum.d2*/
    case Enum.d2:
      print('d2');
      break;
  }
}

nonExhaustiveSwitchGeneric<T1 extends A<T1>>(A<T1> a, Enum<T1> e) {
  /*
   checkingOrder={A<T1>,B,C,D<D<dynamic>>,D1,D2},
   error=non-exhaustive:D1(),
   expandedSubtypes={B,C,D1,D2},
   subtypes={B,C,D<D<dynamic>>},
   type=A<T1>
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('b');
      break;
    /*space=C*/
    case C c:
      print('c');
      break;
    /*space=D2*/
    case D2 d2:
      print('d2');
      break;
  }
  /*
   checkingOrder={Enum<T1>,Enum.b,Enum.c,Enum.d1,Enum.d2},
   error=non-exhaustive:Enum.d1,
   subtypes={Enum.b,Enum.c,Enum.d1,Enum.d2},
   type=Enum<T1>
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Enum.d2*/
    case Enum.d2:
      print('d2');
      break;
  }
}

nonExhaustiveSwitchBounded<T2 extends D<T2>>(A<T2> a, Enum<T2> e) {
  /*
   checkingOrder={A<T2>,D<T2>,D1,D2},
   error=non-exhaustive:D1(),
   expandedSubtypes={D1,D2},
   subtypes={D<T2>},
   type=A<T2>
  */
  switch (a) {
    /*space=D2*/
    case D2 d2:
      print('d2');
      break;
  }
  /*
   checkingOrder={Enum<T2>,Enum.d1,Enum.d2},
   error=non-exhaustive:Enum.d2,
   subtypes={Enum.d1,Enum.d2},
   type=Enum<T2>
  */
  switch (e) {
    /*space=Enum.d1*/
    case Enum.d1:
      print('d1');
      break;
  }
}

nonExhaustiveSwitchCatchAll<T3 extends A<T3>>(A<T3> a, Enum<T3> e) {
  /*
   checkingOrder={A<T3>,B,C,D<D<dynamic>>,D1,D2},
   error=non-exhaustive:D1();D2(),
   expandedSubtypes={B,C,D1,D2},
   subtypes={B,C,D<D<dynamic>>},
   type=A<T3>
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('b');
      break;
    /*space=C*/
    case C cb:
      print('c');
      break;
  }
  /*
   checkingOrder={Enum<T3>,Enum.b,Enum.c,Enum.d1,Enum.d2},
   error=non-exhaustive:Enum.b,
   subtypes={Enum.b,Enum.c,Enum.d1,Enum.d2},
   type=Enum<T3>
  */
  switch (e) {
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Enum<D<D<dynamic>>>*/
    case Enum<D> d:
      print('d');
      break;
  }
}
