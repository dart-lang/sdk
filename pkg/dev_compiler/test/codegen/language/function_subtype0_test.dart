// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping.

import 'package:expect/expect.dart';

typedef t__();
typedef void t_void_();
typedef void t_void_2();
typedef int t_int_();
typedef int t_int_2();
typedef Object t_Object_();
typedef double t_double_();
typedef void t_void__int(int i);
typedef int t_int__int(int i);
typedef int t_int__int2(int i);
typedef int t_int__Object(Object o);
typedef Object t_Object__int(int i);
typedef int t_int__double(double d);
typedef int t_int__int_int(int i1, int i2);
typedef void t_inline_void_(void f());
typedef void t_inline_void__int(void f(int i));

void _() => null;
void void_() {}
void void_2() {}
int int_() => 0;
int int_2() => 0;
Object Object_() => null;
double double_() => 0.0;
void void__int(int i) {}
int int__int(int i) => 0;
int int__int2(int i) => 0;
int int__Object(Object o) => 0;
Object Object__int(int i) => null;
int int__double(double d) => 0;
int int__int_int(int i1, int i2) => 0;
void inline_void_(void f()) {}
void inline_void__int(void f(int i)) {}

main() {
  // () -> int <: Function
  Expect.isTrue(int_ is Function);
  // () -> dynamic <: () -> dynamic
  Expect.isTrue(_ is t__);
  // () -> dynamic <: () -> void
  Expect.isTrue(_ is t_void_);
  // () -> void <: () -> dynamic
  Expect.isTrue(void_ is t__);
  // () -> int <: () -> void
  Expect.isTrue(int_ is t_void_);
  // () -> void <: () -> int
  Expect.isFalse(void_ is t_int_);
  // () -> void <: () -> void
  Expect.isTrue(void_ is t_void_2);
  // () -> int <: () -> int
  Expect.isTrue(int_ is t_int_2);
  // () -> int <: () -> Object
  Expect.isTrue(int_ is t_Object_);
  // () -> int <: () -> double
  Expect.isFalse(int_ is t_double_);
  // () -> int <: (int) -> void
  Expect.isFalse(int_ is t_void__int);
  // () -> void <: (int) -> int
  Expect.isFalse(void_ is t_int__int);
  // () -> void <: (int) -> void
  Expect.isFalse(void_ is t_void__int);
  // (int) -> int <: (int) -> int
  Expect.isTrue(int__int is t_int__int2);
  // (Object) -> int <: (int) -> Object
  Expect.isTrue(int__Object is t_Object__int);
  // (int) -> int <: (double) -> int
  Expect.isFalse(int__int is t_int__double);
  // () -> int <: (int) -> int
  Expect.isFalse(int_ is t_int__int);
  // (int) -> int <: (int,int) -> int
  Expect.isFalse(int__int is t_int__int_int);
  // (int,int) -> int <: (int) -> int
  Expect.isFalse(int__int_int is t_int__int);
  // (()->void) -> void <: ((int)->void) -> void
  Expect.isFalse(inline_void_ is t_inline_void__int);
  // ((int)->void) -> void <: (()->void) -> void
  Expect.isFalse(inline_void__int is t_inline_void_);
}
