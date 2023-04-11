// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a, b }

sealed class A {
  final Enum a;
  bool get b;
  A(this.a);
}

class B extends A {
  final bool b;
  B(super.a, this.b);
}

void exhaustiveSwitch1(A r) {
  /*
   checkingOrder={A,B},
   fields={a:Enum,b:bool},
   subtypes={B},
   type=A
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void exhaustiveSwitch2(A r) {
  /*
   checkingOrder={A,B},
   fields={a:Enum,b:bool},
   subtypes={B},
   type=A
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1(A r) {
  /*
   checkingOrder={A,B},
   error=non-exhaustive:B(a: Enum.b, b: false),
   fields={a:Enum,b:bool},
   subtypes={B},
   type=A
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2(A r) {
  /*
   checkingOrder={A,B},
   error=non-exhaustive:B(a: Enum.a, b: false),
   fields={a:Enum,b:bool},
   subtypes={B},
   type=A
  */
  switch (r) {
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A r) {
  /*
   checkingOrder={A,B},
   fields={a:Enum,b:bool},
   subtypes={B},
   type=A
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? r) {
  /*
   checkingOrder={A?,A,Null,B},
   expandedSubtypes={B,Null},
   fields={a:-,b:-},
   subtypes={A,Null},
   type=A?
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? r) {
  /*
   checkingOrder={A?,A,Null,B},
   error=non-exhaustive:null,
   expandedSubtypes={B,Null},
   fields={a:-,b:-},
   subtypes={A,Null},
   type=A?
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? r) {
  /*
   checkingOrder={A?,A,Null,B},
   error=non-exhaustive:B(a: Enum.b, b: false),
   expandedSubtypes={B,Null},
   fields={a:-,b:-},
   subtypes={A,Null},
   type=A?
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(A r) {
  /*
   checkingOrder={A,B},
   fields={a:Enum,b:bool},
   subtypes={B},
   type=A
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false) #1');
      break;
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*
     error=unreachable,
     space=A(a: Enum.a, b: false)
    */
    case A(a: Enum.a, b: false):
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2(A r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   checkingOrder={A,B},
   fields={a:Enum,b:bool},
   subtypes={B},
   type=A
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase3(A? r) {
  /*
   checkingOrder={A?,A,Null,B},
   expandedSubtypes={B,Null},
   fields={a:-,b:-},
   subtypes={A,Null},
   type=A?
  */
  switch (r) {
    /*space=A(a: Enum.a, b: false)*/
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*space=Null*/ case null:
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
