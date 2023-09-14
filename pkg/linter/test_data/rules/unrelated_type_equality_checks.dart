// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N unrelated_type_equality_checks`

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
  List<ClassBase> someList = [];

  for (ClassBase someInstance in someList) {
    if (object == someInstance) print('someFunction5'); // OK
  }
}

void someFunction6(Object object) {
  List someList = [];

  for (var someInstance in someList) {
    if (object == someInstance) print('someFunction6'); // OK
  }
}

void someFunction7() {
  List someList = [];

  if (someList.length == 0) print('someFunction7'); // OK
}

void someFunction8(ClassBase instance) {
  DerivedClass1 other = DerivedClass1();

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

void someFunction19<A, B>(A a, B b) {
  if (a == b) print('someFunction19'); // OK
  if (<A>[a] == <B>[b]) print('someFunction19'); // OK
  if (<String, A>{'a': a} == <String, B>{'b': b}) // OK
    print('someFunction19');
  if (<A, String>{a: 'a'} == <B, String>{b: 'b'}) // OK
    print('someFunction19');
}

void someFunction20<A, B extends A>(A a, B b) {
  if (a == b) print('someFunction19'); // OK
  if (<A>[a] == <B>[b]) print('someFunction19'); // OK
  if (<String, A>{'a': a} == <String, B>{'b': b}) // OK
    print('someFunction20');
  if (<A, String>{a: 'a'} == <B, String>{b: 'b'}) // OK
    print('someFunction20');
}

void someFunction21<A extends num, B extends List>(A a, B b) {
  if (a == b) print('someFunction19'); // LINT
  if (<A>[a] == <B>[b]) print('someFunction19'); // LINT
  if (<String, A>{'a': a} == <String, B>{'b': b}) // LINT
    print('someFunction21');
  if (<A, String>{a: 'a'} == <B, String>{b: 'b'}) // LINT
    print('someFunction21');
}

void someFunction22<A extends num, B extends num>(A a, B b) {
  if (a == b) print('someFunction19'); // OK
  if (<A>[a] == <B>[b]) print('someFunction19'); // OK
  if (<String, A>{'a': a} == <String, B>{'b': b}) // OK
    print('someFunction22');
  if (<A, String>{a: 'a'} == <B, String>{b: 'b'}) // OK
    print('someFunction22');
}

void function23() {
  Future getFuture() => new Future.value();
  Future<void>? aVoidFuture;

  var aFuture = getFuture();
  if (aFuture == aVoidFuture) print('someFunction23'); // OK
}

void function30() {
  ClassWMethod c = ClassWMethod();
  if (c.determinant == 0.0) print('someFunction30'); // LINT
  if (c.determinant == double) print('someFunction30'); // LINT
  if (c.determinant == c.determinspider) print('someFunction30'); // OK
  if (int == double) print('someFunction30'); // OK
  ClassWCall callable = ClassWCall();
  if (c.determinant == callable) print('someFunction30'); // OK
  SubClassWCall callable2 = SubClassWCall();
  if (c.determinant == callable2) print('someFunction30'); // OK
}

void function31() {
  var x = EnumOpKind1.delete;
  if (x == EnumOpKind1.delete) print('delete'); // OK
  if (x == EnumOpKind1.update) print('update'); // OK
  if (x == EnumOpKind2.delete) print('delete'); // LINT
  if (x == 'delete') print('delete'); // LINT
}

void function32() {
  var x = EnumImplements.a;
  if (x == EnumImplements.a) print('a'); // OK
  if (x == EnumImplements.b) print('b'); // OK
  if (x == EnumMixin.b) print('b'); // LINT

  var y = EnumMixin.a;
  if (y == EnumImplements.a) print('a'); // LINT
}

class ClassBase {}

class DerivedClass1 extends ClassBase {}

mixin Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}

class DerivedClass3 extends ClassBase implements Mixin {}

class DerivedClass4 extends DerivedClass2 {}

class DerivedClass5 extends DerivedClass3 {}

class ClassWMethod {
  double determinant() => 7.0;

  String determinspider() => "";
}

class ClassWCall {
  String call() => 'hey';
}

class SubClassWCall extends ClassWCall {}

enum EnumOpKind1 { insert, update, delete }

enum EnumOpKind2 { upsert, delete }

enum EnumImplements implements ClassBase { a, b, c }

enum EnumMixin with Mixin { a, b, c }
