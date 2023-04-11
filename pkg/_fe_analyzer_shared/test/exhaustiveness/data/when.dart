// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {
  int get field;
}

class B extends A {
  final int field;
  B(this.field);
}

class C extends A {
  final int field;

  C(this.field);
}

method(A a) {
  /*
   checkingOrder={A,B,C},
   subtypes={B,C},
   type=A
  */
  switch (a) {
    /*space=B*/ case B():
    /*space=C*/ case C():
  }
  /*
   checkingOrder={A,B,C},
   fields={field:int},
   subtypes={B,C},
   type=A
  */
  switch (a) {
    /*space=B(field: int)*/ case B(:var field):
    /*space=C(field: int)*/ case C(:var field):
  }
  /*
   checkingOrder={A,B,C},
   error=non-exhaustive:B(),
   fields={field:int},
   subtypes={B,C},
   type=A
  */
  switch (a) {
    /*space=?*/ case B(:var field) when field > 0:
    /*space=C(field: int)*/ case C(:var field):
  }
  /*
   checkingOrder={A,B,C},
   error=non-exhaustive:C(),
   fields={field:int},
   subtypes={B,C},
   type=A
  */
  switch (a) {
    /*space=B(field: int)*/ case B(:var field):
    /*space=?*/ case C(:var field) when field > 0:
  }
}
