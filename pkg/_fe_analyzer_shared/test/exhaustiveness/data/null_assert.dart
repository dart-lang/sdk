// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int field;

  A(this.field);
}

sealed class B {}

class C extends B {}

class D extends B {}

simpleAssert(o1, o2) {
  var a = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o1) {
    _! /*space=()*/ => 0,
    _ /*
     error=unreachable,
     space=()
    */
      =>
      1
  };

  var b = /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o2) {
    _! /*space=()*/ => 0,
  };
}

restrictedCase(o1, o2) {
  // Null assert shouldn't match everything, because even though it doesn't
  // throw, it might not match.
  var a = /*
   checkingOrder={Object?,Object,Null},
   fields={field:-},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o1) {
    A(field: 42)! /*space=A(field: 42)|Null*/ => 0,
    _ /*space=()*/ => 1
  };

  var b = /*
   checkingOrder={Object?,Object,Null},
   error=non-exhaustive:Object(),
   fields={field:-},
   subtypes={Object,Null},
   type=Object?
  */
      switch (o2) {
    A(field: 42)! /*space=A(field: 42)|Null*/ => 0,
  };
}

nullableBool(bool? b1, bool? b2) {
  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b1) {
    /*space=true?*/
    case true!:
      break;
    /*space=false*/
    case false:
      break;
  }
  /*
   checkingOrder={bool?,bool,Null,true,false},
   error=non-exhaustive:false,
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (b2) {
    /*space=true?*/
    case true!:
      break;
  }
}

nullableA(A? a1, A? a2, A? a3) {
  var a = /*
   checkingOrder={A?,A,Null},
   subtypes={A,Null},
   type=A?
  */
      switch (a1) {
    A()! /*space=A?*/ => 0,
  };
  var b = /*
   checkingOrder={A?,A,Null},
   fields={field:-},
   subtypes={A,Null},
   type=A?
  */
      switch (a2) {
    A(:var field)! /*space=A(field: int)|Null*/ => 0,
  };
  var c = /*
   checkingOrder={A?,A,Null},
   error=non-exhaustive:A(field: int())/A(),
   fields={field:-},
   subtypes={A,Null},
   type=A?
  */
      switch (a3) {
    A(field: 42)!
      /*space=A(field: 42)|Null*/
      =>
      0,
  };
}

nullableB(B? b1, B? b2, B? b3) {
  /*
   checkingOrder={B?,B,Null,C,D},
   expandedSubtypes={C,D,Null},
   subtypes={B,Null},
   type=B?
  */
  switch (b1) {
    /*space=B?*/
    case B()!:
      break;
  }
  /*
   checkingOrder={B?,B,Null,C,D},
   expandedSubtypes={C,D,Null},
   subtypes={B,Null},
   type=B?
  */
  switch (b2) {
    /*space=C?*/
    case C()!:
      break;
    /*space=D*/
    case D():
      break;
  }
  /*
   checkingOrder={B?,B,Null,C,D},
   error=non-exhaustive:D(),
   expandedSubtypes={C,D,Null},
   subtypes={B,Null},
   type=B?
  */
  switch (b3) {
    /*space=C?*/
    case C()!:
      break;
  }
}
