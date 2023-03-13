// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N library_private_types_in_public_api`

// Top level functions

String f1(int i) => '';
_Private1 f2(int i) => _Private1.fromInt(0); // LINT
String f3(_Private1 p) => ''; // LINT
_Private1 _f4(_Private1 p) => _Private1.fromInt(0);

// Top level variables

String v1 = '';
_Private1? v2; // LINT
_Private2<String>? v3; // LINT
List<_Private1> v4 = []; // LINT
_Private1 _v5 = _Private1.fromInt(0);

// Top level getters

String get g1 => '';
_Private1 get g2 => _Private1.fromInt(0); // LINT
_Private1 get _g3 => _Private1.fromInt(0);

// Top level setters

set s1(int i) {}
set s2(_Private1 i) {} // LINT
set _s3(_Private1 i) {}

// Type aliases

typedef _Private1 F1(); // LINT
typedef void F2(_Private1 p); // LINT
typedef F3 = _Private1 Function(); // LINT
typedef F4 = void Function(_Private1); // LINT
typedef String F5();
typedef F6 = void Function(int);

// Classes

class Public1 {}

class Public2 extends Public4<_Private1> {}

class Public3 extends Object with _PrivateMixin<int> {}

class Public4<T> implements _Private2<T> {}

class _Private1 {
  _Private1.fromInt(int i);
  _Private1 f = _Private1.fromInt(0);
  _Private1 m1(_Private1 p) => _Private1.fromInt(0);
}

class _Private2<E> {}

mixin _PrivateMixin<E> {}

// Mixins

mixin Public5 on Public1 implements Public6 {}

mixin Public6 on _Private1 {} // LINT

mixin Public7 implements _Private1 {}

mixin _Private3 on _Private1 implements _Private2 {}

// Extensions

extension Public8 on Public1 {}

extension Public9 on _Private1 {} // LINT

extension on String {}

extension _E on int {}

// Class members

class PublicClassWithMembers {
  // Fields

  String f1 = '';
  _Private1 f2 = _Private1.fromInt(0); // LINT
  _Private2<String> f3 = _Private2(); // LINT
  List<_Private1> f4 = []; // LINT
  _Private1 _f5 = _Private1.fromInt(0);

  // Constructors

  PublicClassWithMembers(_Private1 p); // LINT
  PublicClassWithMembers.c1(_Private1 p); // LINT
  PublicClassWithMembers._c2(_Private1 p);

  // Methods

  String m1(int i) => _m4(_Private1.fromInt(i)).toString();
  _Private1 m2(int i) => _Private1.fromInt(0); // LINT
  String m3(_Private1 p) => ''; // LINT
  _Private1 _m4(_Private1 p) => _Private1.fromInt(0);

  // Operators

  int operator+(_Private1 p) => 0; // LINT
  _Private1 operator-(int i) => _Private1.fromInt(i); // LINT

  // Getters

  String get g1 => _g3.toString();
  _Private1 get g2 => _Private1.fromInt(0); // LINT
  _Private1 get _g3 => _f5;

  // Setters

  set s1(int i) {
    _s3 = _Private1.fromInt(i);
  }
  set s2(_Private1 i) {} // LINT
  set _s3(_Private1 p) {}
}
