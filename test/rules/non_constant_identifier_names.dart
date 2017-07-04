// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N non_constant_identifier_names`

String YO = ''; //LINT
const Z = 4; //OK

abstract class A {
  int _x; //OK
  int __x; //OK
  int X; //OK
  static const Y = 3; // OK

  final String bar_bar; //LINT

  A(this.bar_bar); //OK
  A.N(this.bar_bar); //OK
  A.Named(this.bar_bar); //LINT
  factory A.Named2(a) = A; //LINT
  A._Named(this.bar_bar); //LINT
  A.named_bar(this.bar_bar); //LINT
  A.namedBar(this.bar_bar); //OK
  A._N(this.bar_bar); //LINT
  A._named(this.bar_bar); //OK
  A.$Named(this.bar_bar); //OK

  String foo_bar(); //LINT

  baz(var Boo); //LINT

  bar({String Name}); //LINT

  foo([String Name]); //LINT

  static Foo() => null; //LINT

  bool operator >(other); //OK
  bool operator <(other); //OK

  void f() {
    foo(YO); //OK
  }
}

foo() {
  listen((_) {}); // OK!
  listen((__) {}); // OK!
  listen((_____) {}); // OK!
}

Main() => null; //LINT

listen(void onData(Object event)) {}
