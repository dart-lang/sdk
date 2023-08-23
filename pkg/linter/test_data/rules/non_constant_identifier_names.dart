// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N non_constant_identifier_names`

// ignore_for_file: unused_local_variable, unused_element, unused_field

void main() {
  var XYZ = 1; // LINT
  var ABC = 1, // LINT
      def = 1;

  const ZZZ = 3; //  OK

  try {
    for (var XYZ in []) // LINT
    {
      print(XYZ);
    }
    for (var II = 0; II < [].length; ++II) // LINT
    {
      print(II);
    }
  } on Exception catch (EE) //LINT
  {
    print(EE);
  } on Object catch (_) //OK
  {}
}

String YO = ''; //LINT
const Z = 4; //OK

//OK (#687):
var cell_0_0;
var cell_0_1;
var cell_1_0;
var cell_1_1;
var cell_10_11;

// See: #2378
class _F {
  void _m() {} //OK
  void _mBar() {} //OK
  void _m_bar() {} //LINT
}

void _fun() {} //OK
void _funBar() {} //OK
void _fun_bar() {} //LINT

abstract class A {
  int? _x; //OK
  int? __x; //OK
  int? X; //OK
  static const Y = 3; // OK

  final String bar_bar; //LINT

  A(this.bar_bar); //OK
  A.N(this.bar_bar); //OK
  A.Named(this.bar_bar); //LINT
  A._Named(this.bar_bar); //LINT
  A.named_bar(this.bar_bar); //LINT
  A.namedBar(this.bar_bar); //OK
  A._N(this.bar_bar); //LINT
  A._named(this.bar_bar); //OK
  A.$Named(this.bar_bar); //OK
  A._(this.bar_bar); //OK
  A.__(this.bar_bar); //OK
  A.___(this.bar_bar); //OK

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

class B {
  B(String b);
  factory B.Named2(String b) = B; //LINT
}

foo() {
  listen((_) {}); // OK!
  listen((__) {}); // OK!
  listen((_____) {}); // OK!
}

Main() => null; //LINT

listen(void onData(Object event)) {}

// Generic function syntax should be OK (#805).
T scope<T>(T Function() run) {
  /* ... */
  return run();
}
