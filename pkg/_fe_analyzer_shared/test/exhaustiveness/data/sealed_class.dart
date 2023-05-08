// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}

class B extends A {}

class C extends A {}

class D extends A {}

enum Enum { a, b }

void exhaustiveSwitch1(A a) {
  /*
   checkingOrder={A,B,C,D},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D*/
    case D d:
      print('D');
      break;
  }
}

void exhaustiveSwitch2(A a) {
  /*
   checkingOrder={A,B,C,D},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    /*space=A*/
    case A a:
      print('A');
      break;
  }
}

void nonExhaustiveSwitch1(A a) {
  /*
   checkingOrder={A,B,C,D},
   error=non-exhaustive:D(),
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
  }
}

void nonExhaustiveSwitch2(A a) {
  /*
   checkingOrder={A,B,C,D},
   error=non-exhaustive:B(),
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D*/
    case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitch3(A a) {
  /*
   checkingOrder={A,B,C,D},
   error=non-exhaustive:C(),
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    /*space=D*/
    case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A a) {
  /*
   checkingOrder={A,B,C,D},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? a) {
  /*
   checkingOrder={A?,A,Null,B,C,D},
   expandedSubtypes={B,C,D,Null},
   subtypes={A,Null},
   type=A?
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D*/
    case D d:
      print('D');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? a) {
  /*
   checkingOrder={A?,A,Null,B,C,D},
   error=non-exhaustive:null,
   expandedSubtypes={B,C,D,Null},
   subtypes={A,Null},
   type=A?
  */
  switch (a) {
    /*space=A*/
    case A a:
      print('A');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? a) {
  /*
   checkingOrder={A?,A,Null,B,C,D},
   error=non-exhaustive:D(),
   expandedSubtypes={B,C,D,Null},
   subtypes={A,Null},
   type=A?
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(A a) {
  /*
   checkingOrder={A,B,C,D},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B*/
    case B b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D*/
    case D d:
      print('D');
      break;
    /*
     error=unreachable,
     space=A
    */
    case A a:
      print('A');
      break;
  }
}

void unreachableCase2(A a) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   checkingOrder={A,B,C,D},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=A*/
    case A a:
      print('A');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase3(A? a) {
  /*
   checkingOrder={A?,A,Null,B,C,D},
   expandedSubtypes={B,C,D,Null},
   subtypes={A,Null},
   type=A?
  */
  switch (a) {
    /*space=A*/
    case A a:
      print('A');
      break;
    /*space=Null*/
    case null:
      print('null #1');
      break;
    /*
     error=unreachable,
     space=Null
    */
    case null:
      print('null #2');
      break;
  }
}

exhaustiveNullableByNullability(
        A? a) => /*
 checkingOrder={A?,A,Null,B,C,D},
 expandedSubtypes={B,C,D,Null},
 subtypes={A,Null},
 type=A?
*/
    switch (a) {
      A() /*space=A*/ => 0,
      null /*space=Null*/ => 1,
    };
