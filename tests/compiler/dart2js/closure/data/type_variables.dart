// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1<T> {
  /*element: Class1.field:hasThis*/
  var field = /*fields=[T],free=[T],hasThis*/ () => T;

  /*element: Class1.:hasThis*/
  Class1() {
    field = /*fields=[T],free=[T],hasThis*/ () => T;
  }

  /*element: Class1.fact:*/
  factory Class1.fact() => new Class1<T>();

  /*element: Class1.method1:hasThis*/
  method1() => T;

  /*element: Class1.method2:hasThis*/
  method2() {
    return /*fields=[this],free=[this],hasThis*/ () => T;
  }
}

/*element: main:*/
main() {
  new Class1<int>().method1();
  new Class1<int>.fact().method2();
}
