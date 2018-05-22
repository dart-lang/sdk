// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unrelated_type_equality_checks`

import 'package:fixnum/fixnum.dart';

void someFunction() {
  var x = '1';
  if (x == 1) print('someFunction'); // LINT
}

void someFunction1() {
  String x = '1';
  if (x == 1) print('someFunction1'); // LINT
}

void someFunction2() {
  var x = '1';
  var y = '2';
  if (x == y) print(someFunction2); // OK
}

void someFunction3() {
  for (var i = 0; i < 10; i++) {
    if (i == 0) print(someFunction3); // OK
  }
}

void someFunction4() {
  var x = '1';
  if (x == null) print(someFunction4); // OK
}

void someFunction5(Object object) {
  List<ClassBase> someList;

  for (ClassBase someInstance in someList) {
    if (object == someInstance) print('someFunction5'); // OK
  }
}

void someFunction6(Object object) {
  List someList;

  for (var someInstance in someList) {
    if (object == someInstance) print('someFunction6'); // OK
  }
}

void someFunction7() {
  List someList;

  if (someList.length == 0) print('someFunction7'); // OK
}

void someFunction8(ClassBase instance) {
  DerivedClass1 other;

  if (other == instance) print('someFunction8'); // OK
}

void someFunction9(ClassBase instance) {
  var other = new DerivedClass1();

  if (other == instance) print('someFunction9'); // OK
}

void someFunction10(unknown) {
  var what = unknown - 1;
  for (var index = 0; index < unknown; index++) {
    if (what == index) print('someFunction10'); // OK
  }
}

void someFunction11(Mixin instance) {
  var other = new DerivedClass2();

  if (other == instance) print('someFunction11'); // OK
}

void someFunction12(Mixin instance) {
  var other = new DerivedClass3();

  if (other == instance) print('someFunction12'); // OK
}

void someFunction13(DerivedClass2 instance) {
  var other = new DerivedClass3();

  if (other == instance) print('someFunction13'); // OK
}

void someFunction14(DerivedClass4 instance) {
  var other = new DerivedClass5();

  if (other == instance) print('someFunction15'); // LINT
}

void someFunction15() {
  var x = new Int32();

  if (x == 0) print('someFunction15'); // OK
}

void someFunction16() {
  var x = new Int32();

  if (0 == x) print('someFunction16'); // LINT
}

void someFunction17() {
  var x = new Int64();

  if (x == 0) print('someFunction17'); // OK
}

void someFunction18() {
  var x = new Int64();

  if (0 == x) print('someFunction18'); // LINT
}

class ClassBase {}

class DerivedClass1 extends ClassBase {}

abstract class Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}

class DerivedClass3 extends ClassBase implements Mixin {}

class DerivedClass4 extends DerivedClass2 {}

class DerivedClass5 extends DerivedClass3 {}
