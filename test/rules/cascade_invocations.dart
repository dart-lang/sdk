// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N cascade_invocations`

import 'dart:math' as math;

void alreadyDeclared() {
  List list;
  print("intermediate statement");
  list = [];
  list.clear(); // LINT
}

void noCascade() {
  List<int> list = [];
  list.clear(); // LINT
  list.clear(); // LINT
}

int get someThing => 5;

void noCascadeIntermediate() {
  List<int> list = [];
  print(list);
  list.clear();
  list.clear(); // LINT
  list.toString(); // LINT
  // toString is not void and it is not a problem.
}

void cascadeIntermediate() {
  List<int> list = [];
  print(list);
  list.clear();
  list.clear(); // LINT
  list..clear(); // LINT
  list..clear(); // LINT
  list..clear(); // LINT
}

class HasMethodWithNoCascade {
  List<int> list = [];

  void noCascade() {
    list.clear();
    list.clear(); // LINT
  }
}

class Foo {
  int get bar => 5;
  set bar(int value) {}
  void baz() {}
  void foo() {}
}

void noCascadeWithGetter() {
  final foo = new Foo();
  foo.baz(); // LINT
  foo.bar; // LINT
  foo.foo(); // LINT
  foo.bar = 8; // LINT
  foo?.bar = 8; // OK
  foo.bar = 0; // OK
  foo?.bar; // OK
}

void alternatingReferences() {
  final foo = new Foo();
  final bar = new Foo();
  foo.baz();
  bar.baz();
  foo.bar;
  bar.bar;
  foo.foo();
  bar.foo();
}

void withDifferentTypes() {
  Foo foo = new Foo();
  String nothing = '';
  foo.baz();
  print(nothing);
  foo.foo();
  if (foo.bar > 5) {}
}

void cascade() {
  final foo = new Foo();
  foo?.baz();
  foo.baz(); // OK
  foo.baz(); // LINT
}

void prefixLibrary() {
  math.sin(0);
  math.cos(0);
}

class StaticFoo {
  static int increment() => 0;
  static int decrement() => 0;
}

void cascadeStatic() {
  StaticFoo.increment();
  StaticFoo.decrement();
}

// https://github.com/dart-lang/linter/issues/339
class Identifier339 {
  String value;
  String system;
}

class Resource339 {
  String id;
  dynamic identifier;
}

class Practitioner339 extends Resource339{
  int foo;

  String build() => null;

  void bar(dynamic) {}
}

class Entry339 {
  Resource339 resource;
}

void main339() {
  final entry = new Entry339();
  final resource = (entry.resource as Practitioner339);
  resource.identifier = [ // OK
    new Identifier339()
      ..system = 'urn:system'
      ..value = 'mdc_${resource.id}'
  ];
}

void otherDependencies1() {
  final entry = new Entry339();
  final resource = (entry.resource as Practitioner339);
  resource.identifier = resource; // OK
}

void otherDependencies2() {
  final entry = new Entry339();
  final resource = (entry.resource as Practitioner339);
  resource.bar(resource); // OK
}

// assignment
void otherDependencies3() {
  var entry, resource;
  entry = new Entry339();
  resource = (entry.resource as Practitioner339);
  resource.bar(resource); // OK
}

class Bug661 {
  Bug661 parent;
  Practitioner339 practitioner;

  void bar() {
    practitioner.bar(1);
    practitioner.bar(2); // LINT
    parent.practitioner.bar(3);
  }
}

class Bug701 {
  int foo;
  int bar;
}

void function701({Bug701 something}) {
  something ??= new Bug701();
  something.foo = 1; // OK
  something.bar = 2; // LINT
}

// https://github.com/dart-lang/linter/issues/694
class Bug694 {
  static int foo = 0;
  static int bar = 1;
}

void function694() {
  Bug694.bar = 2;
  Bug694.foo = 3; // OK
}

class A {
  int f;
  int g;

  int get p => 7;
  int get q => 6;
}

class B {
  final A a = A();

  B operator +(other) {
    return B();
  }
}

// https://github.com/dart-lang/linter/issues/1323
void bug1323() {
  final B b1 = B();
  final B b2 = B();

  b1.a
    ..f = 1
    ..g = 1;
  b2.a.f = 2; // OK

  print('buffer statement.');

  b1.a
    ..p
    ..q;
  b2.a.p; // OK
}

void bug1317() async {
  final list = await Future.value([]);
  list.forEach(print); // OK
}
