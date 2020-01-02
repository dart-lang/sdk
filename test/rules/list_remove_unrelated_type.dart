// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N list_remove_unrelated_type`

void someFunction() {
  var list = <int>[];
  if (list.remove('1')) print('someFunction'); // LINT
}

void someFunction1() {
  var list = <int>[];
  if (list.remove(1)) print('someFunction1'); // OK
}

void someFunction3() {
  List<int> list = <int>[];
  if (list.remove('1')) print('someFunction3'); // LINT
}

void someFunction4() {
  List<int> list = <int>[];
  if (list.remove(1)) print('someFunction4'); // OK
}

void someFunction4_1() {
  List list;
  if(list.remove(null)) print('someFunction4_1');
}

void someFunction5_1() {
  List<ClassBase> list = <ClassBase>[];
  Object instance;
  if (list.remove(instance)) print('someFunction5_1'); // OK
}

void someFunction5() {
  List<ClassBase> list = <ClassBase>[];
  DerivedClass1 instance;
  if (list.remove(instance)) print('someFunction5'); // OK
}

void someFunction6() {
  List<Mixin> list = <Mixin>[];
  DerivedClass2 instance;
  if (list.remove(instance)) print('someFunction6'); // OK
}

void someFunction6_1() {
  List<DerivedClass2> list = <DerivedClass2>[];
  Mixin instance;
  if (list.remove(instance)) print('someFunction6_1'); // OK
}

void someFunction7() {
  List<Mixin> list = <Mixin>[];
  DerivedClass3 instance;
  if (list.remove(instance)) print('someFunction7'); // OK
}

void someFunction7_1() {
  List<DerivedClass3> list = <DerivedClass3>[];
  Mixin instance;
  if (list.remove(instance)) print('someFunction7_1'); // OK
}

void someFunction8() {
  List<DerivedClass2> list = <DerivedClass2>[];
  DerivedClass3 instance;
  if (list.remove(instance)) print('someFunction8'); // OK
}

void someFunction9() {
  List<Implementation> list = <Implementation>[];
  Abstract instance = new Abstract();
  if (list.remove(instance)) print('someFunction9'); // OK
}

void someFunction10() {
  var list = [];
  if (list.remove(1)) print('someFunction10'); // OK
}

void someFunction11(unknown) {
  var what = unknown - 1;
  List<int> list = <int>[];
  list.forEach((int i) {
    if (what == i) print('someFunction11'); // OK
  });
}

void someFunction12() {
  List<DerivedClass4> list = <DerivedClass4>[];
  DerivedClass5 instance;
  if (list.remove(instance)) print('someFunction12'); // LINT
}

void bug_267(list) {
  if (list.remove('1')) print('someFunction'); // https://github.com/dart-lang/linter/issues/267
}

abstract class ClassBase {}

class DerivedClass1 extends ClassBase {}

abstract class Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}

class DerivedClass3 extends ClassBase implements Mixin {}

abstract class Abstract {
  factory Abstract() {
    return new Implementation();
  }

  Abstract._internal();
}

class Implementation extends Abstract {
  Implementation() : super._internal();
}

class DerivedClass4 extends DerivedClass2 {}

class DerivedClass5 extends DerivedClass3 {}

bool takesList(List<int> list) => list.remove('a'); // LINT

bool takesList2(List<String> list) => list.remove('a'); // OK

bool takesList3(List list) => list.remove('a'); // OK

abstract class A implements List<int> {}
abstract class B extends A {}
bool takesB(B b) => b.remove('a'); // LINT

abstract class A1 implements List<String> {}
abstract class B1 extends A1 {}
bool takesB1(B1 b) => b.remove('a'); // OK

abstract class A3 implements List {}
abstract class B3 extends A3 {}
bool takesB3(B3 b) => b.remove('a'); // OK

abstract class A2 implements List<String> {}
abstract class B2 extends A2 {}
bool takesB2(B2 b) => b.remove('a'); // OK

abstract class SomeList<E> implements List<E> {}

abstract class MyClass implements SomeList<int> {
  bool badMethod(String thing) => this.remove(thing); // LINT
  bool badMethod1(String thing) => remove(thing); // LINT
}

abstract class MyDerivedClass extends MyClass {
  bool myConcreteBadMethod(String thing) => this.remove(thing); // LINT
  bool myConcreteBadMethod1(String thing) => remove(thing); // LINT
}

abstract class MyMixedClass extends Object with MyClass {
  // No lint since is not List.
  bool myConcreteBadMethod(String thing) => this.remove(thing); // OK
  bool myConcreteBadMethod1(String thing) => remove(thing); // OK
}

abstract class MyListMixedClass extends Object
    with MyClass
    implements List<int> {
  bool myConcreteBadMethod(String thing) => this.remove(thing); // LINT
  bool myConcreteBadMethod1(String thing) => remove(thing); // LINT
}
