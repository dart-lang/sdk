// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for [minArgs] and [maxArgs].
library smoke.test.args_test;

import 'package:smoke/smoke.dart' show minArgs, maxArgs, SUPPORTED_ARGS;
import 'package:unittest/unittest.dart';

main() {
  var a = new A();
  var instanceMethods = [ a.m1, a.m2, a.m3, a.m4, a.m5, a.m6, a.m7, a.m8, a.m9,
      a.m10, a.m11, a.m12, a.m13, a.m14, a.m15, a.m16, a.m17, a.m18, a.m19,
      a.m20, a.m21];
  group('instance methods', () => checkMethods(instanceMethods));
  group('static methods', () => checkMethods(staticMethods));
  group('closures', () => checkMethods(closures));
  group('top level methods', () => checkMethods(topLevelMethods));
}

checkMethods(List methods) {
  test('min args', () {
    expect(methods.map((m) => minArgs(m)), expectedMin);
  });

  test('max args', () {
    expect(methods.map((m) => maxArgs(m)), expectedMax);
  });
}

class A {
  // required args only
  static s1() {}
  static s2(p1) {}
  static s3(p1, p2) {}
  static s4(p1, p2, p3) {}
  static s5(p1, p2, p3, p4) {}
  static s6(p1, p2, p3, p4, p5) {}

  // optional args only
  static s7([o1]) {}
  static s8([o1, o2]) {}
  static s9([o1, o2, o3]) {}
  static s10([o1, o2, o3, o4]) {}
  static s11([o1, o2, o3, o4, o5]) {}

  // 1 required, some optional
  static s12(p1, [o2]) {}
  static s13(p1, [o2, o3]) {}
  static s14(p1, [o2, o3, o4]) {}
  static s15(p1, [o2, o3, o4, o5]) {}

  // 2 required, some optional
  static s16(p1, p2, [o3]) {}
  static s17(p1, p2, [o3, o4]) {}
  static s18(p1, p2, [o3, o4, o5]) {}

  // 3 required, some optional
  static s19(p1, p2, p3, [o4]) {}
  static s20(p1, p2, p3, [o4, o5]) {}

  // 4 required, some optional
  static s21(p1, p2, p3, p4, [o5]) {}

  m1() {}
  m2(p1) {}
  m3(p1, p2) {}
  m4(p1, p2, p3) {}
  m5(p1, p2, p3, p4) {}
  m6(p1, p2, p3, p4, p5) {}
  m7([o1]) {}
  m8([o1, o2]) {}
  m9([o1, o2, o3]) {}
  m10([o1, o2, o3, o4]) {}
  m11([o1, o2, o3, o4, o5]) {}
  m12(p1, [o2]) {}
  m13(p1, [o2, o3]) {}
  m14(p1, [o2, o3, o4]) {}
  m15(p1, [o2, o3, o4, o5]) {}
  m16(p1, p2, [o3]) {}
  m17(p1, p2, [o3, o4]) {}
  m18(p1, p2, [o3, o4, o5]) {}
  m19(p1, p2, p3, [o4]) {}
  m20(p1, p2, p3, [o4, o5]) {}
  m21(p1, p2, p3, p4, [o5]) {}
}

t1() {}
t2(p1) {}
t3(p1, p2) {}
t4(p1, p2, p3) {}
t5(p1, p2, p3, p4) {}
t6(p1, p2, p3, p4, p5) {}
t7([o1]) {}
t8([o1, o2]) {}
t9([o1, o2, o3]) {}
t10([o1, o2, o3, o4]) {}
t11([o1, o2, o3, o4, o5]) {}
t12(p1, [o2]) {}
t13(p1, [o2, o3]) {}
t14(p1, [o2, o3, o4]) {}
t15(p1, [o2, o3, o4, o5]) {}
t16(p1, p2, [o3]) {}
t17(p1, p2, [o3, o4]) {}
t18(p1, p2, [o3, o4, o5]) {}
t19(p1, p2, p3, [o4]) {}
t20(p1, p2, p3, [o4, o5]) {}
t21(p1, p2, p3, p4, [o5]) {}

List closures = [
  () {},
  (p1) {},
  (p1, p2) {},
  (p1, p2, p3) {},
  (p1, p2, p3, p4) {},
  (p1, p2, p3, p4, p5) {},
  ([o1]) {},
  ([o1, o2]) {},
  ([o1, o2, o3]) {},
  ([o1, o2, o3, o4]) {},
  ([o1, o2, o3, o4, o5]) {},
  (p1, [o2]) {},
  (p1, [o2, o3]) {},
  (p1, [o2, o3, o4]) {},
  (p1, [o2, o3, o4, o5]) {},
  (p1, p2, [o3]) {},
  (p1, p2, [o3, o4]) {},
  (p1, p2, [o3, o4, o5]) {},
  (p1, p2, p3, [o4]) {},
  (p1, p2, p3, [o4, o5]) {},
  (p1, p2, p3, p4, [o5]) {},
];

List staticMethods = [ A.s1, A.s2, A.s3, A.s4, A.s5, A.s6, A.s7, A.s8, A.s9,
     A.s10, A.s11, A.s12, A.s13, A.s14, A.s15, A.s16, A.s17, A.s18, A.s19,
     A.s20, A.s21];

List topLevelMethods = [ t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12,
    t13, t14, t15, t16, t17, t18, t19, t20, t21];

const MIN_NOT_KNOWN = SUPPORTED_ARGS + 1;
List expectedMin = const [
  0, 1, 2, 3, MIN_NOT_KNOWN, MIN_NOT_KNOWN, // required only
  0, 0, 0, 0, 0, // optional only
  1, 1, 1, 1, // 1 required
  2, 2, 2, // 2 required
  3, 3, // 3 required
  MIN_NOT_KNOWN // 4 required
];

const MAX_NOT_KNOWN = -1;
List expectedMax = const [
  0, 1, 2, 3, MAX_NOT_KNOWN, MAX_NOT_KNOWN, // required only
  1, 2, 3, 3, 3, // optional only
  2, 3, 3, 3, // 1 required
  3, 3, 3, // 2 required
  3, 3, // 3 required
  MAX_NOT_KNOWN // 4 required
];
