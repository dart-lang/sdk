// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for optional parameters.

import 'package:expect/expect.dart';

typedef void T1(int a, int b);
typedef void T2(int a, [int b]);
typedef void T3([int a, int b]);
typedef void T4(int a, [int b, int c]);
typedef void T5([int a, int b, int c]);

class C<T, S, U> {
  get m1 => (T a, S b) {};
  get m2 => (T a, [S b]) {};
  get m3 => ([T a, S b]) {};
  get m4 => (T a, [S b, U c]) {};
  get m5 => ([T a, S b, U c]) {};
}

main() {
  var c1 = new C<int, int, int>();
  Expect.isTrue(c1.m1 is T1, "(int,int)->void is (int,int)->void");
  Expect.isFalse(c1.m1 is T2, "(int,int)->void is not (int,[int])->void");
  Expect.isFalse(c1.m1 is T3, "(int,int)->void is not ([int,int])->void");
  Expect.isFalse(c1.m1 is T4, "(int,int)->void is not (int,[int,int])->void");
  Expect.isFalse(c1.m1 is T5, "(int,int)->void is not ([int,int,int])->void");

  Expect.isTrue(c1.m2 is T1, "(int,[int])->void is (int,int)->void");
  Expect.isTrue(c1.m2 is T2, "(int,[int])->void is (int,[int])->void");
  Expect.isFalse(c1.m2 is T3, "(int,[int])->void is not ([int,int])->void");
  Expect.isFalse(c1.m2 is T4, "(int,[int])->void is not (int,[int,int])->void");
  Expect.isFalse(c1.m2 is T5, "(int,[int])->void is not ([int,int,int])->void");

  Expect.isTrue(c1.m3 is T1, "([int,int])->void is (int,int)->void");
  Expect.isTrue(c1.m3 is T2, "([int,int])->void is (int,[int])->void");
  Expect.isTrue(c1.m3 is T3, "([int,int])->void is ([int,int])->void");
  Expect.isFalse(c1.m3 is T4, "([int,int])->void is not (int,[int,int])->void");
  Expect.isFalse(c1.m3 is T5, "([int,int])->void is not ([int,int,int])->void");

  Expect.isTrue(c1.m4 is T1, "(int,[int,int])->void is (int,int)->void");
  Expect.isTrue(c1.m4 is T2, "(int,[int,int])->void is (int,[int])->void");
  Expect.isFalse(c1.m4 is T3, "(int,[int,int])->void is not ([int,int])->void");
  Expect.isTrue(c1.m4 is T4, "(int,[int,int])->void is (int,[int,int])->void");
  Expect.isFalse(
      c1.m4 is T5, "(int,[int,int])->void is not ([int,int,int])->void");

  Expect.isTrue(c1.m5 is T1, "([int,int,int])->void is (int,int)->void");
  Expect.isTrue(c1.m5 is T2, "([int,int,int])->void is (int,[int])->void");
  Expect.isTrue(c1.m5 is T3, "([int,int,int])->void is ([int,int])->void");
  Expect.isTrue(c1.m5 is T4, "([int,int,int])->void is (int,[int,int])->void");
  Expect.isTrue(c1.m5 is T5, "([int,int,int])->void is ([int,int,int])->void");

  var c2 = new C<int, double, int>();
  Expect.isFalse(c2.m1 is T1, "(int,double)->void is not (int,int)->void");
  Expect.isFalse(
      c2.m1 is T2, "(int,double)->void is not not (int,[int])->void");
  Expect.isFalse(c2.m1 is T3, "(int,double)->void is not ([int,int])->void");
  Expect.isFalse(
      c2.m1 is T4, "(int,double)->void is not (int,[int,int])->void");
  Expect.isFalse(
      c2.m1 is T5, "(int,double)->void is not ([int,int,int])->void");

  Expect.isFalse(c2.m2 is T1, "(int,[double])->void is not (int,int)->void");
  Expect.isFalse(c2.m2 is T2, "(int,[double])->void is not (int,[int])->void");
  Expect.isFalse(c2.m2 is T3, "(int,[double])->void is not ([int,int])->void");
  Expect.isFalse(
      c2.m2 is T4, "(int,[double])->void is not (int,[int,int])->void");
  Expect.isFalse(
      c2.m2 is T5, "(int,[double])->void is not ([int,int,int])->void");

  Expect.isFalse(c2.m3 is T1, "([int,double])->void is not (int,int)->void");
  Expect.isFalse(c2.m3 is T2, "([int,double])->void is not (int,[int])->void");
  Expect.isFalse(c2.m3 is T3, "([int,double])->void is not ([int,int])->void");
  Expect.isFalse(
      c2.m3 is T4, "([int,double])->void is not (int,[int,int])->void");
  Expect.isFalse(
      c2.m3 is T5, "([int,double])->void is not ([int,int,int])->void");

  Expect.isFalse(
      c2.m4 is T1, "(int,[double,int])->void is not (int,int)->void");
  Expect.isFalse(
      c2.m4 is T2, "(int,[double,int])->void is not (int,[int])->void");
  Expect.isFalse(
      c2.m4 is T3, "(int,[double,int])->void is not ([int,int])->void");
  Expect.isFalse(
      c2.m4 is T4, "(int,[double,int])->void is (int,[int,int])->void");
  Expect.isFalse(
      c2.m4 is T5, "(int,[double,int])->void is ([int,int,int])->void");

  Expect.isFalse(
      c2.m5 is T1, "([int,double,int])->void is not (int,int)->void");
  Expect.isFalse(
      c2.m5 is T2, "([int,double,int])->void is not (int,[int])->void");
  Expect.isFalse(
      c2.m5 is T3, "([int,double,int])->void is not ([int,int])->void");
  Expect.isFalse(
      c2.m5 is T4, "([int,double,int])->void is (int,[int,int])->void");
  Expect.isFalse(
      c2.m5 is T5, "([int,double,int])->void is ([int,int,int])->void");

  var c3 = new C<int, int, double>();
  Expect.isTrue(c3.m1 is T1, "(int,int)->void is (int,int)->void");
  Expect.isFalse(c3.m1 is T2, "(int,int)->void is not (int,[int])->void");
  Expect.isFalse(c3.m1 is T3, "(int,int)->void is not ([int,int])->void");
  Expect.isFalse(c3.m1 is T4, "(int,int)->void is not (int,[int,int])->void");
  Expect.isFalse(c3.m1 is T5, "(int,int)->void is not ([int,int,int])->void");

  Expect.isTrue(c3.m2 is T1, "(int,[int])->void is (int,int)->void");
  Expect.isTrue(c3.m2 is T2, "(int,[int])->void is (int,[int])->void");
  Expect.isFalse(c3.m2 is T3, "(int,[int])->void is not ([int,int])->void");
  Expect.isFalse(c3.m2 is T4, "(int,[int])->void is not (int,[int,int])->void");
  Expect.isFalse(c3.m2 is T5, "(int,[int])->void is not ([int,int,int])->void");

  Expect.isTrue(c3.m3 is T1, "([int,int])->void is (int,int)->void");
  Expect.isTrue(c3.m3 is T2, "([int,int])->void is (int,[int])->void");
  Expect.isTrue(c3.m3 is T3, "([int,int])->void is ([int,int])->void");
  Expect.isFalse(c3.m3 is T4, "([int,int])->void is not (int,[int,int])->void");
  Expect.isFalse(c3.m3 is T5, "([int,int])->void is not ([int,int,int])->void");

  Expect.isTrue(c3.m4 is T1, "(int,[int,double])->void is (int,int)->void");
  Expect.isTrue(c3.m4 is T2, "(int,[int,double])->void is (int,[int])->void");
  Expect.isFalse(
      c3.m4 is T3, "(int,[int,double])->void is not ([int,int])->void");
  Expect.isFalse(
      c3.m4 is T4, "(int,[int,double])->void is (int,[int,int])->void");
  Expect.isFalse(
      c3.m4 is T5, "(int,[int,double])->void is ([int,int,int])->void");

  Expect.isTrue(c3.m5 is T1, "([int,int,double])->void is (int,int)->void");
  Expect.isTrue(c3.m5 is T2, "([int,int,double])->void is (int,[int])->void");
  Expect.isTrue(c3.m5 is T3, "([int,int,double])->void is ([int,int])->void");
  Expect.isFalse(
      c3.m5 is T4, "([int,int,double])->void is (int,[int,int])->void");
  Expect.isFalse(
      c3.m5 is T5, "([int,int,double])->void is ([int,int,int])->void");
}
