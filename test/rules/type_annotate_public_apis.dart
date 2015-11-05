// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const X = ''; //LINT

f() {} //LINT

void g(x) {} //LINT

typedef Foo(x); //LINT

typedef void Bar(int x);

_f() {}
const _X = '';

class A {

  var x; // LINT
  final xx = 1; //LINT
  static const y = ''; //LINT
  static final z = 3; //LINT

  var zzz, //LINT
      _zzz;

  f() {} //LINT
  void g(x) {} //LINT
  static h() {} //LINT
  static void j(x) {} //LINT
  static void k(var v) {} //LINT

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
