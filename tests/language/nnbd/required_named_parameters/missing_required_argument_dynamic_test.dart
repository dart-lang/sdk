// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'package:expect/expect.dart';

// Test that it is an error if a named parameter that is part of a required
// group is not bound to an argument at a call site.
typedef String F({required String x});

class A {
  A() {}
  int m1({required int a}) => 1;

  F m2() => ({required String x}) => 'm2: $x';

  // Check a mix of required and optional.
  int m3(
          {required int p1,
          int p2 = 2,
          int p3 = 3,
          int p4 = 4,
          int p5 = 5,
          required int p6,
          int p7 = 7,
          required int p8,
          int p9 = 9,
          int p10 = 10}) =>
      p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9 + p10;

  // Check a case where at least one of the VM required flag packed entries
  // should be represented by the null Smi. (Need at least 32 optional
  // parameters on 64-bit architectures for this.)
  int m4(
          {int p1 = 1,
          int p2 = 2,
          int p3 = 3,
          int p4 = 4,
          int p5 = 5,
          int p6 = 6,
          int p7 = 7,
          int p8 = 8,
          int p9 = 9,
          int p10 = 10,
          int p11 = 11,
          int p12 = 12,
          int p13 = 13,
          int p14 = 14,
          int p15 = 15,
          int p16 = 16,
          int p17 = 17,
          int p18 = 18,
          int p19 = 19,
          int p20 = 20,
          int p21 = 21,
          int p22 = 22,
          int p23 = 23,
          int p24 = 24,
          int p25 = 25,
          int p26 = 26,
          int p27 = 27,
          int p28 = 28,
          int p29 = 29,
          int p30 = 30,
          int p31 = 31,
          int p32 = 32,
          int p33 = 33,
          int p34 = 34,
          int p35 = 35,
          required int p36}) =>
      p1 +
      p2 +
      p3 +
      p4 +
      p5 +
      p6 +
      p7 +
      p8 +
      p9 +
      p10 +
      p11 +
      p12 +
      p13 +
      p14 +
      p15 +
      p16 +
      p17 +
      p18 +
      p19 +
      p20 +
      p21 +
      p22 +
      p23 +
      p24 +
      p25 +
      p26 +
      p27 +
      p28 +
      p29 +
      p30 +
      p31 +
      p32 +
      p33 +
      p34 +
      p35 +
      p36;
}

int f({required int a}) => 2;

String Function({required int a}) g() => ({required int a}) => 'g';

// Check a mix of required and optional.
int h(
        {required int p1,
        int p2 = 2,
        int p3 = 3,
        int p4 = 4,
        int p5 = 5,
        int p6 = 6,
        int p7 = 7,
        required int p8,
        int p9 = 9,
        required int p10}) =>
    p1 + p2 - p3 + p4 - p5 + p6 - p7 + p8 - p9 + p10;

// Check a case where at least one of the VM required flag packed entries
// should be represented by the null Smi. (Need at least 32 optional
// parameters on 64-bit architectures for this.)
int i(
        {int p1 = 1,
        int p2 = 2,
        int p3 = 3,
        int p4 = 4,
        int p5 = 5,
        int p6 = 6,
        int p7 = 7,
        int p8 = 8,
        int p9 = 9,
        int p10 = 10,
        int p11 = 11,
        int p12 = 12,
        int p13 = 13,
        int p14 = 14,
        int p15 = 15,
        int p16 = 16,
        int p17 = 17,
        int p18 = 18,
        int p19 = 19,
        int p20 = 20,
        int p21 = 21,
        int p22 = 22,
        int p23 = 23,
        int p24 = 24,
        int p25 = 25,
        int p26 = 26,
        int p27 = 27,
        int p28 = 28,
        int p29 = 29,
        int p30 = 30,
        int p31 = 31,
        int p32 = 32,
        int p33 = 33,
        required int p34,
        int p35 = 35,
        int p36 = 36}) =>
    p1 +
    p2 -
    p3 +
    p4 -
    p5 +
    p6 -
    p7 +
    p8 -
    p9 +
    p10 -
    p11 +
    p12 -
    p13 +
    p14 -
    p15 +
    p16 -
    p17 +
    p18 -
    p19 +
    p20 -
    p21 +
    p22 -
    p23 +
    p24 -
    p25 +
    p26 -
    p27 +
    p28 -
    p29 +
    p30 -
    p31 +
    p32 -
    p33 +
    p34 -
    p35 +
    p36;

main() {
  A a = A();
  dynamic b = a as dynamic;
  Expect.equals(1, (a.m1 as dynamic)(a: 5));
  Expect.throwsNoSuchMethodError(() => (a.m1 as dynamic)());
  Expect.equals(1, b.m1(a: 5));
  Expect.throwsNoSuchMethodError(() => b.m1());
  Expect.equals(2, (f as dynamic)(a: 3));
  Expect.throwsNoSuchMethodError(() => (f as dynamic)());

  Expect.equals('g', (g() as dynamic)(a: 4));
  Expect.throwsNoSuchMethodError(() => (g() as dynamic)());
  Expect.equals('g', (g as dynamic)()(a: 4));
  Expect.throwsNoSuchMethodError(() => (g as dynamic)()());
  Expect.equals('m2: check', (a.m2() as dynamic)(x: 'check'));
  Expect.throwsNoSuchMethodError(() => (a.m2() as dynamic)());
  Expect.equals('m2: check', b.m2()(x: 'check'));
  Expect.throwsNoSuchMethodError(() => b.m2()());

  Expect.equals(7, (h as dynamic)(p1: 1, p8: 8, p10: 10));
  Expect.throwsNoSuchMethodError(() => (h as dynamic)(p1: 1, p6: 6, p10: 10));
  Expect.equals(55, (a.m3 as dynamic)(p1: 1, p6: 6, p8: 8));
  Expect.throwsNoSuchMethodError(
      () => (a.m3 as dynamic)(p1: 1, p8: 8, p10: 10));
  Expect.equals(55, b.m3(p1: 1, p6: 6, p8: 8));
  Expect.throwsNoSuchMethodError(() => b.m3(p1: 1, p8: 8, p10: 10));

  Expect.equals(20, (i as dynamic)(p34: 34));
  Expect.throwsNoSuchMethodError(() => (i as dynamic)(p36: 36));
  Expect.equals(666, (a.m4 as dynamic)(p36: 36));
  Expect.throwsNoSuchMethodError(() => (a.m4 as dynamic)(p34: 34));
  Expect.equals(666, b.m4(p36: 36));
  Expect.throwsNoSuchMethodError(() => b.m4(p34: 34));
}
