// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping.

import 'package:expect/expect.dart';

class C<T> {}

typedef _();
typedef void void_();
typedef void void_2();
typedef int int_();
typedef int int_2();
typedef Object Object_();
typedef double double_();
typedef void void__int(int i);
typedef int int__int(int i);
typedef int int__int2(int i);
typedef int int__Object(Object o);
typedef Object Object__int(int i);
typedef int int__double(double d);
typedef int int__int_int(int i1, int i2);
typedef void inline_void_(void f());
typedef void inline_void__int(void f(int i));

main() {
  // () -> int <: Function
  Expect.isTrue(new C<int_>() is C<Function>);
  // Function <: () -> int
  Expect.isFalse(new C<Function>() is C<int_>);
  // () -> dynamic <: () -> dynamic
  Expect.isTrue(new C<_>() is C<_>);
  // () -> dynamic <: () -> void
  Expect.isTrue(new C<_>() is C<void_>);
  // () -> void <: () -> dynamic
  Expect.isTrue(new C<void_>() is C<_>);
  // () -> int <: () -> void
  Expect.isTrue(new C<int_>() is C<void_>);
  // () -> void <: () -> int
  Expect.isFalse(new C<void_>() is C<int_>);
  // () -> void <: () -> void
  Expect.isTrue(new C<void_>() is C<void_2>);
  // () -> int <: () -> int
  Expect.isTrue(new C<int_>() is C<int_2>);
  // () -> int <: () -> Object
  Expect.isTrue(new C<int_>() is C<Object_>);
  // () -> int <: () -> double
  Expect.isFalse(new C<int_>() is C<double_>);
  // () -> int <: (int) -> void
  Expect.isFalse(new C<int_>() is C<void__int>);
  // () -> void <: (int) -> int
  Expect.isFalse(new C<void_>() is C<int__int>);
  // () -> void <: (int) -> void
  Expect.isFalse(new C<void_>() is C<void__int>);
  // (int) -> int <: (int) -> int
  Expect.isTrue(new C<int__int>() is C<int__int2>);
  // (Object) -> int <: (int) -> Object
  Expect.isTrue(new C<int__Object>() is C<Object__int>);
  // (int) -> int <: (double) -> int
  Expect.isFalse(new C<int__int>() is C<int__double>);
  // () -> int <: (int) -> int
  Expect.isFalse(new C<int_>() is C<int__int>);
  // (int) -> int <: (int,int) -> int
  Expect.isFalse(new C<int__int>() is C<int__int_int>);
  // (int,int) -> int <: (int) -> int
  Expect.isFalse(new C<int__int_int>() is C<int__int>);
  // (()->void) -> void <: ((int)->void) -> void
  Expect.isFalse(new C<inline_void_>() is C<inline_void__int>);
  // ((int)->void) -> void <: (()->void) -> void
  Expect.isFalse(new C<inline_void__int>() is C<inline_void_>);
}
