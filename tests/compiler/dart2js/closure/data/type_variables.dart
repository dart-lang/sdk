// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class1<T> {
  /*member: Class1.field:hasThis*/
  var field = /*fields=[T],free=[T],hasThis*/ () => T;

  /*member: Class1.funcField:hasThis*/
  Function funcField;

  /*member: Class1.:hasThis*/
  Class1() {
    field = /*fields=[T],free=[T],hasThis*/ () => T;
  }

  /*member: Class1.setFunc:hasThis*/
  Class1.setFunc(this.funcField);

  /*member: Class1.fact:*/
  factory Class1.fact() => new Class1<T>();

  /*member: Class1.fact2:*/
  factory Class1.fact2() =>
      new Class1.setFunc(/*fields=[T],free=[T]*/ () => new Set<T>());

  /*member: Class1.method1:hasThis*/
  method1() => T;

  /*member: Class1.method2:hasThis*/
  method2() {
    return /*fields=[this],free=[this],hasThis*/ () => T;
  }
}

/*member: main:*/
main() {
  new Class1<int>().method1();
  new Class1<int>.fact().method2();
  new Class1<int>.fact2().funcField() is Set;
}
