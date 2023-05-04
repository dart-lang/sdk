// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}

sealed class B extends A {}

sealed class C extends A {}

sealed class D extends A {}

class B1 extends B {}

class B2 extends B {}

class C1 extends C {}

class C2 extends C {}

class D1 extends D {}

class D2 extends D {}

exhaustiveLevel0(A a) {
  /*
   checkingOrder={A,B,C,D,B1,B2,C1,C2,D1,D2},
   expandedSubtypes={B1,B2,C1,C2,D1,D2},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=A*/
    case A _:
      print('_');
      break;
  }
}

exhaustiveLevel0_1(A a) {
  /*
   checkingOrder={A,B,C,D,B1,B2,C1,C2,D1,D2},
   expandedSubtypes={B1,B2,C1,C2,D1,D2},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('b');
      break;
    /*space=D*/
    case D d:
      print('d');
      break;
    /*space=A*/
    case A _:
      print('_');
      break;
  }
}

exhaustiveLevel1(A a) {
  /*
   checkingOrder={A,B,C,D,B1,B2,C1,C2,D1,D2},
   expandedSubtypes={B1,B2,C1,C2,D1,D2},
   subtypes={B,C,D},
   type=A
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
    /*space=D*/
    case D d:
      print('d');
      break;
  }
}

exhaustiveLevel2(A a) {
  /*
   checkingOrder={A,B,C,D,B1,B2,C1,C2,D1,D2},
   expandedSubtypes={B1,B2,C1,C2,D1,D2},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B1*/
    case B1 b1:
      print('b1');
      break;
    /*space=B2*/
    case B2 b2:
      print('b2');
      break;
    /*space=C1*/
    case C1 c1:
      print('c1');
      break;
    /*space=C2*/
    case C2 c2:
      print('c2');
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
}

exhaustiveLevel0_1_2(A a) {
  /*
   checkingOrder={A,B,C,D,B1,B2,C1,C2,D1,D2},
   expandedSubtypes={B1,B2,C1,C2,D1,D2},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('b');
      break;
    /*space=C1*/
    case C1 c1:
      print('c1');
      break;
    /*space=C2*/
    case C2 c2:
      print('c2');
      break;
    /*space=A*/
    case A _:
      print('_');
      break;
  }
}
