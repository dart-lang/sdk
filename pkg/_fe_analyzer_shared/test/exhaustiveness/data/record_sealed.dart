// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}

class B extends A {}

class C extends A {}

class Class {
  (A, A) field;
  Class(this.field);
}

method(Class c) {
  /*
   fields={field:(A, A)},
   type=Class
  */
  switch (c) {
    /*space=Class(field: (A, B))*/ case Class(field: (A a, B b)):
      print('1');
    /*space=Class(field: (B, A))*/ case Class(field: (B b, A a)):
      print('2');
    default:
  }
}
