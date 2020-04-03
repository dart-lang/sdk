// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping.

import 'package:expect/expect.dart';

void void_() {}
void void__int(int i) {}
void void___int([int i]) {}
void void___int2([int i]) {}
void void___Object([Object o]) {}
void void__int__int(int i1, [int i2]) {}
void void__int__int2(int i1, [int i2]) {}
void void__int__int_int(int i1, [int i2, int i3]) {}
void void___double(double d) {}
void void___int_int([int i1, int i2]) {}
void void___int_int_int([int i1, int i2, int i3]) {}
void void___Object_int([Object o, int i]) {}

typedef void t_void_();
typedef void t_void__int(int i);
typedef void t_void___int([int i]);
typedef void t_void___int2([int i]);
typedef void t_void___Object([Object o]);
typedef void t_void__int__int(int i1, [int i2]);
typedef void t_void__int__int2(int i1, [int i2]);
typedef void t_void__int__int_int(int i1, [int i2, int i3]);
typedef void t_void___double(double d);
typedef void t_void___int_int([int i1, int i2]);
typedef void t_void___int_int_int([int i1, int i2, int i3]);
typedef void t_void___Object_int([Object o, int i]);

main() {
  // Test ([int])->void <: ()->void.
  Expect.isTrue(void___int is t_void_);
  // Test ([int])->void <: (int)->void.
  Expect.isTrue(void___int is t_void__int);
  // Test (int)->void <: ([int])->void.
  Expect.isFalse(void__int is t_void___int);
  // Test ([int])->void <: ([int])->void.
  Expect.isTrue(void___int is t_void___int2);
  // Test ([Object])->void <: ([int])->void.
  Expect.isTrue(void___Object is t_void___int);
  // Test ([int])->void <: ([Object])->void.
  Expect.isFalse(void___int is t_void___Object);
  // Test (int,[int])->void <: (int)->void.
  Expect.isTrue(void__int__int is t_void__int);
  // Test (int,[int])->void <: (int,[int])->void.
  Expect.isTrue(void__int__int is t_void__int__int2);
  // Test (int)->void <: ([int])->void.
  Expect.isFalse(void__int is t_void___int);
  // Test ([int,int])->void <: (int)->void.
  Expect.isTrue(void___int_int is t_void__int);
  // Test ([int,int])->void <: (int,[int])->void.
  Expect.isTrue(void___int_int is t_void__int__int);
  // Test ([int,int])->void <: (int,[int,int])->void.
  Expect.isFalse(void___int_int is t_void__int__int_int);
  // Test ([int,int,int])->void <: (int,[int,int])->void.
  Expect.isTrue(void___int_int_int is t_void__int__int_int);
  // Test ([int])->void <: ([double])->void.
  Expect.isFalse(void___int is t_void___double);
  // Test ([int])->void <: ([int,int])->void.
  Expect.isFalse(void___int is t_void___int_int);
  // Test ([int,int])->void <: ([int])->void.
  Expect.isTrue(void___int_int is t_void___int);
  // Test ([Object,int])->void <: ([int])->void.
  Expect.isTrue(void___Object_int is t_void___int);
}
