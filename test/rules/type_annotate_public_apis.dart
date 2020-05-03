// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N type_annotate_public_apis`

class AA {
  final a = AA(); //OK
  static final aa = AA(); //OK
  final i = 0; //OK
  static final ii = 0; //OK
  final d = dyn(); //LINT
  static final dd = dyn(); //LINT
  final n = null; //LINT
  static final nn = null; //LINT
}

dynamic dyn() => null;

const X = ''; //OK

f() {} //LINT

void g(x) {} //LINT

void h() {
  void i(x) {} // OK
  j() {} // OK
}

typedef Foo(x); //LINT

typedef void Bar(int x);

int get xxx => 42; //OK: #151

get xxxx => 42; //LINT

set x(x) {} // LINT

set xx(int x) {} // OK

_f() {}
const _X = '';

class A {
  var x; // LINT
  static const y = ''; //OK
  static final z = 3; //OK

  int get xxx => 42; //OK: #151

  set xxxxx(x) {} // LINT

  set xx(int x) {} // OK

  get xxxx => 42; //LINT

  var zzz, //LINT
      _zzz;

  f() {} //LINT
  void g(x) {} //LINT
  static h() {} //LINT
  static void j(x) {} //LINT
  static void k(var v) {} //LINT

  void l(_) {} // OK!
  void ll(__) {} // OK!

  var _x;
  final _xx = 1;
  static const _y = '';
  static final _z = 3;

  void m() {}

  _f() {}
  void _g(x) {}
  static _h() {}
  static _j(x) {}
  static _k(var x) {}
}

typedef _PrivateMethod(int value); //OK
typedef void _PrivateMethod2(value); //OK

extension Ext on A {
  set x(x) { }  // LINT
  set _x(x) { } // OK
  get x => 0; // LINT

  f() {} // LINT
  void j(j) { } // LINT
}
