// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping.

import 'package:expect/expect.dart';

class C<T> {}

typedef void void_();
typedef void void__int(int i);
typedef void void___a_int({int a});
typedef void void___a_int2({int a});
typedef void void___b_int({int b});
typedef void void___a_Object({Object a});
typedef void void__int__a_int(int i1, {int a});
typedef void void__int__a_int2(int i1, {int a});
typedef void void___a_double({double a});
typedef void void___a_int_b_int({int a, int b});
typedef void void___a_int_b_int_c_int({int a, int b, int c});
typedef void void___a_int_c_int({int a, int c});
typedef void void___b_int_c_int({int b, int c});
typedef void void___c_int({int c});

main() {
  // Test ({int a})->void <: ()->void.
  Expect.isTrue(new C<void___a_int>() is C<void_>);
  // Test ({int a})->void <: (int)->void.
  Expect.isFalse(new C<void___a_int>() is C<void__int>);
  // Test (int)->void <: ({int a})->void.
  Expect.isFalse(new C<void__int>() is C<void___a_int>);
  // Test ({int a})->void <: ({int a})->void.
  Expect.isTrue(new C<void___a_int>() is C<void___a_int2>);
  // Test ({int a})->void <: ({int b})->void.
  Expect.isFalse(new C<void___a_int>() is C<void___b_int>);
  // Test ({Object a})->void <: ({int a})->void.
  Expect.isTrue(new C<void___a_Object>() is C<void___a_int>);
  // Test ({int a})->void <: ({Object a})->void.
  Expect.isTrue(new C<void___a_int>() is C<void___a_Object>);
  // Test (int,{int a})->void <: (int,{int a})->void.
  Expect.isTrue(new C<void__int__a_int>() is C<void__int__a_int2>);
  // Test ({int a})->void <: ({double a})->void.
  Expect.isFalse(new C<void___a_int>() is C<void___a_double>);
  // Test ({int a})->void <: ({int a,int b})->void.
  Expect.isFalse(new C<void___a_int>() is C<void___a_int_b_int>);
  // Test ({int a,int b})->void <: ({int a})->void.
  Expect.isTrue(new C<void___a_int_b_int>() is C<void___a_int>);
  // Test ({int a,int b,int c})->void <: ({int a,int c})->void.
  Expect.isTrue(new C<void___a_int_b_int_c_int>() is C<void___a_int_c_int>);
  // Test ({int a,int b,int c})->void <: ({int b,int c})->void.
  Expect.isTrue(new C<void___a_int_b_int_c_int>() is C<void___b_int_c_int>);
  // Test ({int a,int b,int c})->void <: ({int c})->void.
  Expect.isTrue(new C<void___a_int_b_int_c_int>() is C<void___c_int>);
}
