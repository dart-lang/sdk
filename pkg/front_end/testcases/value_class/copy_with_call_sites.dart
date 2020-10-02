// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'value_class_support_lib.dart';

class Animal {
  final int? numberOfLegs;
  Animal({required this.numberOfLegs});
}

@valueClass
class Cat extends Animal {
  final int? numberOfWhiskers;
}

class Foo {
  int? bar, bar2;
  Foo({this.bar, this.bar2});
  Foo copyWith({int bar, int bar2}) {
    return Foo(bar, bar2);
  }
}

@valueClass
class A {}

main() {
 Cat cat = new Cat(numberOfWhiskers: 20, numberOfLegs: 4);
 // positive case
 Cat cat2 = (cat as dynamic).copyWith(numberOfWhiskers: 4) as Cat;
 // nested case
 Cat cat3 = ((((cat as dynamic).copyWith(numberOfWhiskers: 4) as Cat) as dynamic).copyWith(numberOfLegs: 3) as Cat);
 // wrong right hand side
 Cat cat4 = (cat as Object).copyWith(numberOfWhiskers: 4);
 // empty arguments
 Cat cat5 = (cat as dynamic).copyWith() as Cat;
 // Some existing fields, extra arguments.
 Cat cat6 = (cat as dynamic).copyWith(numberOfWhiskers: 4, numberOfHorns: 5) as Cat;

 A a;
 // No fields, extra arguments.
 A a2 = (a as dynamic).copyWith(x: 42, y: 42) as A;


 Foo foo = Foo(bar: 4, bar2: 5);
 // wrong left hand side
 Foo foo2 = (foo as dynamic).copyWith(bar: 4) as Foo;
}



