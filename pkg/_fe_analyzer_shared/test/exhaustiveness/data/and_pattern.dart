// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  B field1;
  B field2;

  A(this.field1, this.field2);
}

sealed class B {}

class C extends B {}

class D extends B {}

class E extends B {}

and(A o1, A o2) {
  var a = /*type=A*/ switch (o1) {
    A() && var a /*space=A*/ => 0,
    _ /*
     error=unreachable,
     space=A
    */
      =>
      1,
  };

  var b = /*type=A*/ switch (o1) {
    A() && var a /*space=A*/ => 0,
  };
}

intersectSameClass(A o1, A o2, A o3) {
  var a = /*type=A*/ switch (o1) {
    A() && A() /*space=A*/ => 0,
  };
  var b = /*
   fields={field1:B,field2:B},
   type=A
  */
      switch (o2) {
    A(:var field1) && A(:var field2) /*space=A(field1: B, field2: B)*/ => [
      field1,
      field2
    ],
  };
  var c = /*
   error=non-exhaustive:A(field1: C(), field2: C()),
   fields={field1:B,field2:B},
   type=A
  */
      switch (o3) {
    A(:var field1, field2: C()) &&
          A(field1: D(), :var field2) /*space=A(field1: D, field2: C)*/ =>
      10,
  };
}

intersectSubClass(A o1, A o2, A o3) {
  var a = /*type=A*/ switch (o1) {
    Object() && A() /*space=A*/ => 0,
  };
  var b = /*
   fields={field1:B,hashCode:int},
   type=A
  */
      switch (o2) {
    A(:var field1) &&
          Object(:var hashCode) /*space=A(field1: B, hashCode: int)*/ =>
      [field1, hashCode],
  };
  var c = /*
   error=non-exhaustive:A(field1: C(), field2: C(), hashCode: int())/A(field1: C(), field2: C()),
   fields={field1:B,field2:B,hashCode:int},
   type=A
  */
      switch (o3) {
    Object(:var hashCode) &&
          A(
            :var field1,
            field2: D()
          ) /*space=A(hashCode: int, field1: B, field2: D)*/ =>
      10,
  };
}

intersectUnion(A o1, A o2, B o3, B o4) {
  var a = /*
   fields={field1:B,field2:B},
   type=A
  */
      switch (o1) {
    A(field1: C() || D()) &&
          A(field2: C() || D()) /*space=A(field1: C|D, field2: C|D)*/ =>
      0,
    A(field1: C() || E()) &&
          A(field2: C() || E()) /*space=A(field1: C|E, field2: C|E)*/ =>
      1,
    A(field1: D() || E()) &&
          A(field2: D() || E()) /*space=A(field1: D|E, field2: D|E)*/ =>
      2,
  };
  var b = /*
   fields={field1:B},
   type=A
  */
      switch (o2) {
    A(field1: C() || D()) && A(field1: D() || E()) /*space=A(field1: D|?)*/ =>
      0,
    A(field1: C() || E()) && A(field1: C() || E()) /*space=A(field1: C|E|?)*/ =>
      1,
  };
  var c = /*
   checkingOrder={B,C,D,E},
   subtypes={C,D,E},
   type=B
  */
      switch (o3) {
    (C() || D()) && B() /*space=C|D*/ => 0,
    B() && (D() || E()) /*space=D|E*/ => 1,
  };
  var d = /*
   checkingOrder={B,C,D,E},
   subtypes={C,D,E},
   type=B
  */
      switch (o3) {
    (C() || D() || E()) && (C() || D() || E()) /*space=C|D|E|?*/ => 0,
  };
}
