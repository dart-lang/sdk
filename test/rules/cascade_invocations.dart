// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N cascade_invocations`

import 'dart:math' as math;

void noCascade() {
  List<int> list = [];
  list.removeWhere((i) => i % 5 == 0); // LINT
  list.clear(); // LINT
}

int get someThing => 5;

void noCascadeIntermediate() {
  List<int> list = [];
  print(list);
  list.removeWhere((i) => i % 5 == 0);
  list.clear(); // LINT
}

class HasMethodWithNoCascade {
  List<int> list = [];

  void noCascade() {
    list.removeWhere((i) => i % 5 == 0);
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
}

void prefixLibrary() {
  math.sin(0);
  math.cos(0);
}