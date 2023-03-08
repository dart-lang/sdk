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
class E extends B {}

simpleCast(o1, o2) {
  var a = /*
   subtypes={Object,Null},
   type=Object?
  */switch (o1) {
    _ as A /*space=()*/=> 0,
    _ /*
     error=unreachable,
     space=()
    */=> 1
  };

  var b = /*
   subtypes={Object,Null},
   type=Object?
  */switch (o2) {
    _ as A /*space=()*/=> 0,
  };
}

restrictedCase(o1, o2) {
  // Cast shouldn't match everything, because even though it doesn't throw,
  // it might not match.
  var a = /*
   fields={field:-},
   subtypes={Object,Null},
   type=Object?
  */switch (o1) {
    A(field: 42) as A /*space=A(field: 42)*/=> 0,
    _ /*space=()*/=> 1
  };

  var b = /*
   error=non-exhaustive:Object,
   fields={field:-},
   subtypes={Object,Null},
   type=Object?
  */switch (o2) {
    A(field: 42) as A /*space=A(field: 42)*/=> 0,
  };
}

sealedCast(B b1, B b2) {
  /*
   subtypes={C,D,E},
   type=B
  */switch (b1) {
    /*space=C*/case C():
    /*space=()*/case _ as D:
  }
  /*
   error=non-exhaustive:E,
   subtypes={C,D,E},
   type=B
  */switch (b2) {
    /*space=D*/case D():
    /*space=C*/case var c as C:
  }
}