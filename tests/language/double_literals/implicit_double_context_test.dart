// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async" show FutureOr;

import "package:expect/expect.dart";

// Check that integer literals in a double context are allowed
// for various double context.

main() {
  // Variable initializer context.
  double v1 = 0;
  Expect.identical(0.0, v1);
  double v2 = 1;
  Expect.identical(1.0, v2);
  double v3 = -0;
  Expect.identical(-0.0, v3);
  double v4 = -1;
  Expect.identical(-1.0, v4);
  double v5 = 9223372036854775808; // 2^63, not valid signed 64-bit integer.
  Expect.identical(9223372036854775808.0, v5);
  double v6 = 18446744073709551616; // 2^64.
  Expect.identical(18446744073709551616.0, v6);
  double v7 = 0x02; // Hex literal.
  Expect.identical(2.0, v7);
  double v8 = -0x02; // Hex literal.
  Expect.identical(-2.0, v8);

  // Const variable initializer context.
  const double c1 = 0;
  Expect.identical(0.0, c1);
  const double c2 = 1;
  Expect.identical(1.0, c2);
  const double c3 = -0;
  Expect.identical(-0.0, c3);
  const double c4 = -1;
  Expect.identical(-1.0, c4);
  const double c5 = 9223372036854775808;
  Expect.identical(9223372036854775808.0, c5);
  const double c6 = 18446744073709551616;
  Expect.identical(18446744073709551616.0, c6);
  const double c7 = 0x02; // Hex literal.
  Expect.identical(2.0, c7);
  const double c8 = -0x02; // Hex literal.
  Expect.identical(-2.0, c8);

  // Assignment context, variable.
  double value;
  value = 0;
  Expect.identical(0.0, value);
  value = 1;
  Expect.identical(1.0, value);
  value = -0;
  Expect.identical(-0.0, value);
  value = -1;
  Expect.identical(-1.0, value);
  value = 9223372036854775808;
  Expect.identical(9223372036854775808.0, value);
  value = 18446744073709551616;
  Expect.identical(18446744073709551616.0, value);
  value = 0x02;
  Expect.identical(2.0, value);
  value = -0x02;
  Expect.identical(-2.0, value);

  // Assignment context, setter.
  setter = 0;
  Expect.identical(0.0, lastSetValue);
  setter = 1;
  Expect.identical(1.0, lastSetValue);
  setter = -0;
  Expect.identical(-0.0, lastSetValue);
  setter = -1;
  Expect.identical(-1.0, lastSetValue);
  setter = 9223372036854775808;
  Expect.identical(9223372036854775808.0, lastSetValue);
  setter = 18446744073709551616;
  Expect.identical(18446744073709551616.0, lastSetValue);
  setter = 0x02;
  Expect.identical(2.0, lastSetValue);
  setter = -0x02;
  Expect.identical(-2.0, lastSetValue);

  // Argument context.
  test(0.0, 0);
  test(1.0, 1);
  test(-0.0, -0);
  test(-1.0, -1);
  test(9223372036854775808.0, 9223372036854775808);
  test(18446744073709551616.0, 18446744073709551616);
  test(2.0, 0x02);
  test(-2.0, -0x02);

  // Argument context, operator setter.
  List<double> box = [0.5];
  box[0] = 0;
  Expect.identical(0.0, box[0]);
  box[0] = 1;
  Expect.identical(1.0, box[0]);
  box[0] = -0;
  Expect.identical(-0.0, box[0]);
  box[0] = -1;
  Expect.identical(-1.0, box[0]);
  box[0] = 9223372036854775808;
  Expect.identical(9223372036854775808.0, box[0]);
  box[0] = 18446744073709551616;
  Expect.identical(18446744073709551616.0, box[0]);
  box[0] = 0x02;
  Expect.identical(2.0, box[0]);
  box[0] = -0x02;
  Expect.identical(-2.0, box[0]);

  // Argument context, custom operators.
  var oper = Oper();
  Expect.identical(0.0, oper + 0);
  Expect.identical(1.0, oper + 1);
  Expect.identical(-0.0, oper + -0);
  Expect.identical(-1.0, oper + -1);
  Expect.identical(9223372036854775808.0, oper + 9223372036854775808);
  Expect.identical(18446744073709551616.0, oper + 18446744073709551616);
  Expect.identical(2.0, oper + 0x02);
  Expect.identical(-2.0, oper + -0x02);

  Expect.identical(0.0, oper >> 0);
  Expect.identical(1.0, oper >> 1);
  Expect.identical(-0.0, oper >> -0);
  Expect.identical(-1.0, oper >> -1);
  Expect.identical(9223372036854775808.0, oper >> 9223372036854775808);
  Expect.identical(18446744073709551616.0, oper >> 18446744073709551616);
  Expect.identical(2.0, oper >> 0x02);
  Expect.identical(-2.0, oper >> -0x02);

  Expect.identical(0.0, oper[0]);
  Expect.identical(1.0, oper[1]);
  Expect.identical(-0.0, oper[-0]);
  Expect.identical(-1.0, oper[-1]);
  Expect.identical(9223372036854775808.0, oper[9223372036854775808]);
  Expect.identical(18446744073709551616.0, oper[18446744073709551616]);
  Expect.identical(2.0, oper[0x02]);
  Expect.identical(-2.0, oper[-0x02]);

  // Explicit return context.
  double fun1() => 0;
  Expect.identical(0.0, fun1());
  double fun2() => 1;
  Expect.identical(1.0, fun2());
  double fun3() => -0;
  Expect.identical(-0.0, fun3());
  double fun4() => -1;
  Expect.identical(-1.0, fun4());
  double fun5() => 9223372036854775808;
  Expect.identical(9223372036854775808.0, fun5());
  double fun6() => 18446744073709551616;
  Expect.identical(18446744073709551616.0, fun6());
  double fun7() => 0x02;
  Expect.identical(2.0, fun7());
  double fun8() => -0x02;
  Expect.identical(-2.0, fun8());

  // Inferred return context.
  testFun(0.0, () => 0);
  testFun(1.0, () => 1);
  testFun(-0.0, () => -0);
  testFun(-1.0, () => -1);
  testFun(9223372036854775808.0, () => 9223372036854775808);
  testFun(18446744073709551616.0, () => 18446744073709551616);
  testFun(2.0, () => 0x02);
  testFun(-2.0, () => -0x02);

  // Function default value context.
  Object deffun1([double v = 0]) => v;
  Expect.identical(0.0, deffun1());
  Object deffun2([double v = 1]) => v;
  Expect.identical(1.0, deffun2());
  Object deffun3([double v = -0]) => v;
  Expect.identical(-0.0, deffun3());
  Object deffun4([double v = -1]) => v;
  Expect.identical(-1.0, deffun4());
  Object deffun5([double v = 9223372036854775808]) => v;
  Expect.identical(9223372036854775808.0, deffun5());
  Object deffun6([double v = 18446744073709551616]) => v;
  Expect.identical(18446744073709551616.0, deffun6());
  Object deffun7([double v = 0x02]) => v;
  Expect.identical(2.0, deffun7());
  Object deffun8([double v = -0x02]) => v;
  Expect.identical(-2.0, deffun8());

  // Explicit collection literal context.
  box = <double>[0];
  Expect.identical(0.0, box[0]);
  box = <double>[1];
  Expect.identical(1.0, box[0]);
  box = <double>[-0];
  Expect.identical(-0.0, box[0]);
  box = <double>[-1];
  Expect.identical(-1.0, box[0]);
  box = <double>[9223372036854775808];
  Expect.identical(9223372036854775808.0, box[0]);
  box = <double>[18446744073709551616];
  Expect.identical(18446744073709551616.0, box[0]);
  box = <double>[0x02];
  Expect.identical(2.0, box[0]);
  box = <double>[-0x02];
  Expect.identical(-2.0, box[0]);

  // Implicit collection literal context.
  box = [0];
  Expect.identical(0.0, box[0]);
  box = [1];
  Expect.identical(1.0, box[0]);
  box = [-0];
  Expect.identical(-0.0, box[0]);
  box = [-1];
  Expect.identical(-1.0, box[0]);
  box = [9223372036854775808];
  Expect.identical(9223372036854775808.0, box[0]);
  box = [18446744073709551616];
  Expect.identical(18446744073709551616.0, box[0]);
  box = [0x02];
  Expect.identical(2.0, box[0]);
  box = [-0x02];
  Expect.identical(-2.0, box[0]);

  Map<double?, double?> map;
  // Explicit map key context.
  map = <double, Null>{0: null};
  Expect.identical(0.0, map.keys.first);
  map = <double, Null>{1: null};
  Expect.identical(1.0, map.keys.first);
  map = <double, Null>{-0: null};
  Expect.identical(-0.0, map.keys.first);
  map = <double, Null>{-1: null};
  Expect.identical(-1.0, map.keys.first);
  map = <double, Null>{9223372036854775808: null};
  Expect.identical(9223372036854775808.0, map.keys.first);
  map = <double, Null>{18446744073709551616: null};
  Expect.identical(18446744073709551616.0, map.keys.first);
  map = <double, Null>{0x02: null};
  Expect.identical(2.0, map.keys.first);
  map = <double, Null>{-0x02: null};
  Expect.identical(-2.0, map.keys.first);

  // Implicit map key context.
  map = {0: null};
  Expect.identical(0.0, map.keys.first);
  map = {1: null};
  Expect.identical(1.0, map.keys.first);
  map = {-0: null};
  Expect.identical(-0.0, map.keys.first);
  map = {-1: null};
  Expect.identical(-1.0, map.keys.first);
  map = {9223372036854775808: null};
  Expect.identical(9223372036854775808.0, map.keys.first);
  map = {18446744073709551616: null};
  Expect.identical(18446744073709551616.0, map.keys.first);
  map = {0x02: null};
  Expect.identical(2.0, map.keys.first);
  map = {-0x02: null};
  Expect.identical(-2.0, map.keys.first);

  // Explicit map value context.
  map = <Null, double>{null: 0};
  Expect.identical(0.0, map.values.first);
  map = <Null, double>{null: 1};
  Expect.identical(1.0, map.values.first);
  map = <Null, double>{null: -0};
  Expect.identical(-0.0, map.values.first);
  map = <Null, double>{null: -1};
  Expect.identical(-1.0, map.values.first);
  map = <Null, double>{null: 9223372036854775808};
  Expect.identical(9223372036854775808.0, map.values.first);
  map = <Null, double>{null: 18446744073709551616};
  Expect.identical(18446744073709551616.0, map.values.first);
  map = <Null, double>{null: 0x02};
  Expect.identical(2.0, map.values.first);
  map = <Null, double>{null: -0x02};
  Expect.identical(-2.0, map.values.first);

  // Implicit map value context.
  map = {null: 0};
  Expect.identical(0.0, map.values.first);
  map = {null: 1};
  Expect.identical(1.0, map.values.first);
  map = {null: -0};
  Expect.identical(-0.0, map.values.first);
  map = {null: -1};
  Expect.identical(-1.0, map.values.first);
  map = {null: 9223372036854775808};
  Expect.identical(9223372036854775808.0, map.values.first);
  map = {null: 18446744073709551616};
  Expect.identical(18446744073709551616.0, map.values.first);
  map = {null: 0x02};
  Expect.identical(2.0, map.values.first);
  map = {null: -0x02};
  Expect.identical(-2.0, map.values.first);

  // Top-level contexts
  Expect.identical(0.0, ts1);
  Expect.identical(1.0, ts2);
  Expect.identical(-0.0, ts3);
  Expect.identical(-1.0, ts4);
  Expect.identical(9223372036854775808.0, ts5);
  Expect.identical(18446744073709551616.0, ts6);
  Expect.identical(2.0, ts7);
  Expect.identical(-2.0, ts8);

  Expect.identical(0.0, tc1);
  Expect.identical(1.0, tc2);
  Expect.identical(-0.0, tc3);
  Expect.identical(-1.0, tc4);
  Expect.identical(9223372036854775808.0, tc5);
  Expect.identical(18446744073709551616.0, tc6);
  Expect.identical(2.0, tc7);
  Expect.identical(-2.0, tc8);

  Expect.identical(0.0, tg1);
  Expect.identical(1.0, tg2);
  Expect.identical(-0.0, tg3);
  Expect.identical(-1.0, tg4);
  Expect.identical(9223372036854775808.0, tg5);
  Expect.identical(18446744073709551616.0, tg6);
  Expect.identical(2.0, tg7);
  Expect.identical(-2.0, tg8);

  // Class contexts
  var c = new C.ci1();
  Expect.identical(0.0, c.v1);
  Expect.identical(1.0, c.v2);
  Expect.identical(-0.0, c.v3);
  Expect.identical(-1.0, c.v4);
  Expect.identical(9223372036854775808.0, c.v5);
  Expect.identical(18446744073709551616.0, c.v6);
  Expect.identical(2.0, c.v7);
  Expect.identical(-2.0, c.v8);

  Expect.identical(0.0, C.s1);
  Expect.identical(1.0, C.s2);
  Expect.identical(-0.0, C.s3);
  Expect.identical(-1.0, C.s4);
  Expect.identical(9223372036854775808.0, C.s5);
  Expect.identical(18446744073709551616.0, C.s6);
  Expect.identical(2.0, C.s7);
  Expect.identical(-2.0, C.s8);

  Expect.identical(0.0, C.c1);
  Expect.identical(1.0, C.c2);
  Expect.identical(-0.0, C.c3);
  Expect.identical(-1.0, C.c4);
  Expect.identical(9223372036854775808.0, C.c5);
  Expect.identical(18446744073709551616.0, C.c6);
  Expect.identical(2.0, C.c7);
  Expect.identical(-2.0, C.c8);

  Expect.identical(0.0, new C.cc1().d);
  Expect.identical(1.0, new C.cc2().d);
  Expect.identical(-0.0, new C.cc3().d);
  Expect.identical(-1.0, new C.cc4().d);
  Expect.identical(9223372036854775808.0, new C.cc5().d);
  Expect.identical(18446744073709551616.0, new C.cc6().d);
  Expect.identical(2.0, new C.cc7().d);
  Expect.identical(-2.0, new C.cc8().d);

  Expect.identical(0.0, const C.cc1().d);
  Expect.identical(1.0, const C.cc2().d);
  Expect.identical(-0.0, const C.cc3().d);
  Expect.identical(-1.0, const C.cc4().d);
  Expect.identical(9223372036854775808.0, const C.cc5().d);
  Expect.identical(18446744073709551616.0, const C.cc6().d);
  Expect.identical(2.0, const C.cc7().d);
  Expect.identical(-2.0, const C.cc8().d);

  Expect.identical(0.0, new C.ci1().d);
  Expect.identical(1.0, new C.ci2().d);
  Expect.identical(-0.0, new C.ci3().d);
  Expect.identical(-1.0, new C.ci4().d);
  Expect.identical(9223372036854775808.0, new C.ci5().d);
  Expect.identical(18446744073709551616.0, new C.ci6().d);
  Expect.identical(2.0, new C.ci7().d);
  Expect.identical(-2.0, new C.ci8().d);

  Expect.identical(0.0, const C.ci1().d);
  Expect.identical(1.0, const C.ci2().d);
  Expect.identical(-0.0, const C.ci3().d);
  Expect.identical(-1.0, const C.ci4().d);
  Expect.identical(9223372036854775808.0, const C.ci5().d);
  Expect.identical(18446744073709551616.0, const C.ci6().d);
  Expect.identical(2.0, const C.ci7().d);
  Expect.identical(-2.0, const C.ci8().d);

  // Nested context, `?:`.
  v1 = false ? 42.0 : 0;
  Expect.identical(0.0, v1);
  v2 = false ? 42.0 : 1;
  Expect.identical(1.0, v2);
  v3 = false ? 42.0 : -0;
  Expect.identical(-0.0, v3);
  v4 = false ? 42.0 : -1;
  Expect.identical(-1.0, v4);
  v5 = false ? 42.0 : 9223372036854775808;
  Expect.identical(9223372036854775808.0, v5);
  v6 = false ? 42.0 : 18446744073709551616;
  Expect.identical(18446744073709551616.0, v6);
  v7 = false ? 42.0 : 0x02; // Hex literal.
  Expect.identical(2.0, v7);
  v8 = false ? 42.0 : -0x02; // Hex literal.
  Expect.identical(-2.0, v8);

  // Nested context, `??`.
  double? nl = double.tryParse("not a double"); // Returns null typed as double.
  v1 = nl ?? 0;
  Expect.identical(0.0, v1);
  v2 = nl ?? 1;
  Expect.identical(1.0, v2);
  v3 = nl ?? -0;
  Expect.identical(-0.0, v3);
  v4 = nl ?? -1;
  Expect.identical(-1.0, v4);
  v5 = nl ?? 9223372036854775808;
  Expect.identical(9223372036854775808.0, v5);
  v6 = nl ?? 18446744073709551616;
  Expect.identical(18446744073709551616.0, v6);
  v7 = nl ?? 0x02; // Hex literal.
  Expect.identical(2.0, v7);
  v8 = nl ?? -0x02; // Hex literal.
  Expect.identical(-2.0, v8);

  // Nested context, `..`.
  v1 = 0..toString();
  Expect.identical(0.0, v1);
  v2 = 1..toString();
  Expect.identical(1.0, v2);
  v3 = -0
    ..toString();
  Expect.identical(-0.0, v3);
  v4 = -1
    ..toString();
  Expect.identical(-1.0, v4);
  v5 = 9223372036854775808..toString();
  Expect.identical(9223372036854775808.0, v5);
  v6 = 18446744073709551616..toString();
  Expect.identical(18446744073709551616.0, v6);
  v7 = 0x02..toString(); // Hex literal.
  Expect.identical(2.0, v7);
  v8 = -0x02
    ..toString(); // Hex literal.
  Expect.identical(-2.0, v8);

  // Nexted context, double assignment.
  Object object;
  object = value = 0;
  Expect.identical(0.0, value);
  object = value = 1;
  Expect.identical(1.0, value);
  object = value = -0;
  Expect.identical(-0.0, value);
  object = value = -1;
  Expect.identical(-1.0, value);
  object = value = 9223372036854775808;
  Expect.identical(9223372036854775808.0, value);
  object = value = 18446744073709551616;
  Expect.identical(18446744073709551616.0, value);
  object = value = 0x02;
  Expect.identical(2.0, value);
  object = value = -0x02;
  Expect.identical(-2.0, value);

  // Nested context, value of assignment.
  Expect.identical(0.0, value = 0);
  Expect.identical(1.0, value = 1);
  Expect.identical(-0.0, value = -0);
  Expect.identical(-1.0, value = -1);
  Expect.identical(9223372036854775808.0, value = 9223372036854775808);
  Expect.identical(18446744073709551616.0, value = 18446744073709551616);
  Expect.identical(2.0, value = 0x02);
  Expect.identical(-2.0, value = -0x02);

  // JavaScript platforms represent integers as doubles, so negating them will
  // result in negative zero, unfortunately.
  int zero = 0;
  bool platformHasNegativeZeroInts = (-zero).isNegative;

  // Not promoted without a double context.
  num x = -0;
  Expect.identical(0, x);
  Expect.equals(x.isNegative, platformHasNegativeZeroInts);

  var list = [3.14, 2.17, -0];
  Expect.notType<List<double>>(list);
  Expect.identical(0, list[2]);
  Expect.equals(list[2].isNegative, platformHasNegativeZeroInts);

  // FutureOr<double> also forces double.
  // "Type that int is not assignable to, but double is."
  FutureOr<double> fo1 = 0;
  Expect.identical(0.0, fo1);
  FutureOr<double> fo2 = 1;
  Expect.identical(1.0, fo2);
  FutureOr<double> fo3 = -0;
  Expect.identical(-0.0, fo3);
  FutureOr<double> fo4 = -1;
  Expect.identical(-1.0, fo4);
  FutureOr<double> fo5 = 9223372036854775808;
  Expect.identical(9223372036854775808.0, fo5);
  FutureOr<double> fo6 = 18446744073709551616;
  Expect.identical(18446744073709551616.0, fo6);
  FutureOr<double> fo7 = 0x02; // Hex literal.
  Expect.identical(2.0, fo7);
  FutureOr<double> fo8 = -0x02; // Hex literal.
  Expect.identical(-2.0, fo8);

  // Some other FutureOr cases, without being exhaustive.
  {
    Object func([FutureOr<double> x = 9223372036854775808]) => x;
    Expect.identical(9223372036854775808.0, func(9223372036854775808));
    Expect.identical(9223372036854775808.0, func());
    FutureOr<double> func2() => 9223372036854775808;
    Expect.identical(9223372036854775808.0, func2());
    testGeneric<FutureOr<double>>(9223372036854775808.0, 9223372036854775808);
    List<FutureOr<double>> l = [9223372036854775808];
    testGeneric<FutureOr<double>>(9223372036854775808.0, l[0]);
    l.add(9223372036854775808);
    testGeneric<FutureOr<double>>(9223372036854775808.0, l[1]);
    l.add(0.0);
    l[2] = 9223372036854775808;
    testGeneric<FutureOr<double>>(9223372036854775808.0, l[2]);
  }

  // Type variables statically bound to double also force doubles:
  testGeneric<double>(0.0, 0);
  testGeneric<double>(1.0, 1);
  testGeneric<double>(-0.0, -0);
  testGeneric<double>(-1.0, -1);
  testGeneric<double>(9223372036854775808.0, 9223372036854775808);
  testGeneric<double>(18446744073709551616.0, 18446744073709551616);
  testGeneric<double>(2.0, 0x02);
  testGeneric<double>(-2.0, -0x02);

  // Uses static type, not run-time type.
  Super sub = Sub();
  Expect.identical(0.0, sub.method(0));
  Expect.identical(1.0, sub.method(1));
  Expect.identical(-0.0, sub.method(-0));
  Expect.identical(-1.0, sub.method(-1));
  Expect.identical(9223372036854775808.0, sub.method(9223372036854775808));
  Expect.identical(18446744073709551616.0, sub.method(18446744073709551616));
  Expect.identical(2.0, sub.method(0x02));
  Expect.identical(-2.0, sub.method(-0x02));

  {
    // Check that the correct value is used as receiver for the cascade.
    var collector = StringBuffer();
    double tricky = -42
      ..toString().codeUnits.forEach(collector.writeCharCode);
    Expect.equals("${-42.0}", collector.toString());
  }

  bool isDigit(int charCode) => (charCode ^ 0x30) <= 9;
  // Throws because double context does not affect "4", so the toString does
  // not contain any non-digit (like ".", which it would if 4 was a double).
  // The context type of "4.toString..." is not double, and the `-`
  // is not having a literal as operand.
  Expect.throws(() {
    double tricky =
        -4.toString().codeUnits.firstWhere((c) => !isDigit(c)).toDouble();
  });
}

void test(double expect, double value) {
  Expect.identical(expect, value);
}

void testFun(double expect, double f()) {
  Expect.identical(expect, f());
}

void testGeneric<T>(double expect, T value) {
  Expect.identical(expect, value);
}

class Oper {
  Object operator +(double value) => value;
  Object operator >>(double value) => value;
  Object operator [](double value) => value;
}

class C {
  // Instance variable initializer
  final double v1 = 0;
  final double v2 = 1;
  final double v3 = -0;
  final double v4 = -1;
  final double v5 = 9223372036854775808;
  final double v6 = 18446744073709551616;
  final double v7 = 0x02; // Hex literal.
  final double v8 = -0x02; // Hex literal.

  // Static class variable initializer
  static double s1 = 0;
  static double s2 = 1;
  static double s3 = -0;
  static double s4 = -1;
  static double s5 = 9223372036854775808;
  static double s6 = 18446744073709551616;
  static double s7 = 0x02; // Hex literal.
  static double s8 = -0x02; // Hex literal.

  // Const class variable initializer context.
  static const double c1 = 0;
  static const double c2 = 1;
  static const double c3 = -0;
  static const double c4 = -1;
  static const double c5 = 9223372036854775808;
  static const double c6 = 18446744073709551616;
  static const double c7 = 0x02; // Hex literal.
  static const double c8 = -0x02; // Hex literal.

  final double d;

  // Default value context for a double initializing formal.
  const C.cc1([this.d = 0]);
  const C.cc2([this.d = 1]);
  const C.cc3([this.d = -0]);
  const C.cc4([this.d = -1]);
  const C.cc5([this.d = 9223372036854775808]);
  const C.cc6([this.d = 18446744073709551616]);
  const C.cc7([this.d = 0x02]);
  const C.cc8([this.d = -0x02]);

  // Initializer list expressions context.
  const C.ci1() : this.d = 0;
  const C.ci2() : this.d = 1;
  const C.ci3() : this.d = -0;
  const C.ci4() : this.d = -1;
  const C.ci5() : this.d = 9223372036854775808;
  const C.ci6() : this.d = 18446744073709551616;
  const C.ci7() : this.d = 0x02;
  const C.ci8() : this.d = -0x02;
}

// Top-level lazy variable initializer
double ts1 = 0;
double ts2 = 1;
double ts3 = -0;
double ts4 = -1;
double ts5 = 9223372036854775808;
double ts6 = 18446744073709551616;
double ts7 = 0x02; // Hex literal.
double ts8 = -0x02; // Hex literal.

// Top-level const variable initializer.
const double tc1 = 0;
const double tc2 = 1;
const double tc3 = -0;
const double tc4 = -1;
const double tc5 = 9223372036854775808; // 2^63, invalid signed 64-bit integer.
const double tc6 = 18446744073709551616;
const double tc7 = 0x02; // Hex literal.
const double tc8 = -0x02; // Hex literal.

// Top-level getter return context.
double get tg1 => 0;
double get tg2 => 1;
double get tg3 => -0;
double get tg4 => -1;
double get tg5 => 9223372036854775808;
double get tg6 => 18446744073709551616;
double get tg7 => 0x02; // Hex literal.
double get tg8 => -0x02; // Hex literal.

Object? lastSetValue = null;
void set setter(double v) {
  lastSetValue = v;
}

abstract class Super {
  Object method(double v);
}

class Sub implements Super {
  Object method(Object o) => o;
}
