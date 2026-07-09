// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '' deferred as D0;
import '' deferred as D1;
import '' deferred as D2;
import '' deferred as D1_3;
import '' deferred as D2_3;

void main() async {
  print('main ${int.parse('2') == 2}');
  await D0.loadLibrary();
  await D0.d0();
}

Future d0() async {
  print('d0');
  final base = int.parse('1') == 1 ? Sub1() : Sub2();
  final dynamic dynObject = int.parse('1') == 1 ? base : 1;

  await D1.loadLibrary();
  await D1.d1(base, dynObject);

  await D2.loadLibrary();
  await D2.d2(base, dynObject);

  base.selMethodD0();
  dynObject.dynMethodD0();

  sink(base.selGetterD0);
  base.selSetterD0 = 0;
  sink(dynObject.dynGetterD0);
  dynObject.dynSetterD0 = 0;
}

Future d1(Base base, dynamic dynObject) async {
  print('d1');

  await D1_3.loadLibrary();
  D1_3.d3(base, dynObject);
  D1_3.d13only(base, dynObject);

  base.selMethodD1();
  base.dynMethodD1();

  sink(base.selGetterD1);
  base.selSetterD1 = 1;
  sink(dynObject.dynGetterD1);
  dynObject.dynSetterD1 = 1;

  // Case: Dynamic in dominator (D1), Static in dominated (D1_3)
  dynObject.mixedDynD1StatD1_3();

  // Case: Static in dominator (D1), Dynamic in dominated (D1_3)
  base.mixedStatD1DynD1_3();

  // Case: Dynamic in dominator (D1), Static in shared dominated (d3)
  dynObject.mixedDynD1StatD3();

  // Case: Static in dominator (D1), Dynamic in shared dominated (d3)
  base.mixedStatD1DynD3();

  // Static tear-offs
  sink(base.tearOffStatD1);
  sink(base.tearOffStatD1CallStatD2);
  base.callStatD1TearOffStatD2();

  // Dynamic tear-offs
  sink(dynObject.tearOffDynD1);
  sink(dynObject.tearOffDynD1CallDynD2);
  dynObject.callDynD1TearOffDynD2();
}

Future d2(Base base, dynamic dynObject) async {
  print('d2');

  await D2_3.loadLibrary();
  D2_3.d3(base, dynObject);

  base.selMethodD2();
  base.dynMethodD2();

  sink(base.selGetterD2);
  base.selSetterD2 = 2;
  sink(dynObject.dynGetterD2);
  dynObject.dynSetterD2 = 2;

  // Static tear-offs
  sink(base.tearOffStatD2);
  base.tearOffStatD1CallStatD2();
  sink(base.callStatD1TearOffStatD2);

  // Dynamic tear-offs
  sink(dynObject.tearOffDynD2);
  dynObject.tearOffDynD1CallDynD2();
  sink(dynObject.callDynD1TearOffDynD2);
}

void d13only(Base base, dynamic dynObject) {
  print('d1_3_only');
  base.mixedDynD1StatD1_3();
  dynObject.mixedStatD1DynD1_3();
}

void d3(Base base, dynamic dynObject) {
  print('d3');
  base.selMethodD3();
  base.dynMethodD3();

  sink(base.selGetterD3);
  base.selSetterD3 = 3;
  sink(dynObject.dynGetterD3);
  dynObject.dynSetterD3 = 3;

  base.mixedDynD1StatD3();
  dynObject.mixedStatD1DynD3();

  // Static tear-offs
  sink(base.tearOffStatD3);

  // Dynamic tear-offs
  sink(dynObject.tearOffDynD3);
}

abstract class Base {
  void selMethodD0();

  // Tests normal selector use.
  void selMethodD1();
  void selMethodD2();
  void selMethodD3();

  // Tests dynamic call use.
  void dynMethodD0();
  void dynMethodD1();
  void dynMethodD2();
  void dynMethodD3();

  int get selGetterD0;
  set selSetterD0(int value);
  int get selGetterD1;
  set selSetterD1(int value);
  int get selGetterD2;
  set selSetterD2(int value);
  int get selGetterD3;
  set selSetterD3(int value);

  int get dynGetterD0;
  set dynSetterD0(int value);
  int get dynGetterD1;
  set dynSetterD1(int value);
  int get dynGetterD2;
  set dynSetterD2(int value);
  int get dynGetterD3;
  set dynSetterD3(int value);

  void mixedDynD1StatD1_3();
  void mixedStatD1DynD1_3();
  void mixedDynD1StatD3();
  void mixedStatD1DynD3();

  void tearOffStatD1();
  void tearOffStatD2();
  void tearOffStatD3();
  void tearOffStatD1CallStatD2();
  void callStatD1TearOffStatD2();

  void tearOffDynD1();
  void tearOffDynD2();
  void tearOffDynD3();
  void tearOffDynD1CallDynD2();
  void callDynD1TearOffDynD2();
}

class Sub1 extends Base {
  @override
  void selMethodD0() => print('Sub1.selMethodD0');
  @override
  void selMethodD1() => print('Sub1.selMethodD1');
  @override
  void selMethodD2() => print('Sub1.selMethodD2');
  @override
  void selMethodD3() => print('Sub1.selMethodD3');
  @override
  void dynMethodD0() => print('Sub1.dynMethodD0');
  @override
  void dynMethodD1() => print('Sub1.dynMethodD1');
  @override
  void dynMethodD2() => print('Sub1.dynMethodD2');
  @override
  void dynMethodD3() => print('Sub1.dynMethodD3');

  @override
  int get selGetterD0 => 0;
  @override
  set selSetterD0(int value) => print('Sub1.selSetterD0');
  @override
  int get selGetterD1 => 0;
  @override
  set selSetterD1(int value) => print('Sub1.selSetterD1');
  @override
  int get selGetterD2 => 0;
  @override
  set selSetterD2(int value) => print('Sub1.selSetterD2');
  @override
  int get selGetterD3 => 0;
  @override
  set selSetterD3(int value) => print('Sub1.selSetterD3');

  @override
  int get dynGetterD0 => 0;
  @override
  set dynSetterD0(int value) => print('Sub1.dynSetterD0');
  @override
  int get dynGetterD1 => 0;
  @override
  set dynSetterD1(int value) => print('Sub1.dynSetterD1');
  @override
  int get dynGetterD2 => 0;
  @override
  set dynSetterD2(int value) => print('Sub1.dynSetterD2');
  @override
  int get dynGetterD3 => 0;
  @override
  set dynSetterD3(int value) => print('Sub1.dynSetterD3');

  @override
  void mixedDynD1StatD1_3() => print('Sub1.mixedDynD1StatD1_3');
  @override
  void mixedStatD1DynD1_3() => print('Sub1.mixedStatD1DynD1_3');
  @override
  void mixedDynD1StatD3() => print('Sub1.mixedDynD1StatD3');
  @override
  void mixedStatD1DynD3() => print('Sub1.mixedStatD1DynD3');

  @override
  void tearOffStatD1() => print('Sub1.tearOffStatD1');
  @override
  void tearOffStatD2() => print('Sub1.tearOffStatD2');
  @override
  void tearOffStatD3() => print('Sub1.tearOffStatD3');
  @override
  void tearOffStatD1CallStatD2() => print('Sub1.tearOffStatD1CallStatD2');
  @override
  void callStatD1TearOffStatD2() => print('Sub1.callStatD1TearOffStatD2');

  @override
  void tearOffDynD1() => print('Sub1.tearOffDynD1');
  @override
  void tearOffDynD2() => print('Sub1.tearOffDynD2');
  @override
  void tearOffDynD3() => print('Sub1.tearOffDynD3');
  @override
  void tearOffDynD1CallDynD2() => print('Sub1.tearOffDynD1CallDynD2');
  @override
  void callDynD1TearOffDynD2() => print('Sub1.callDynD1TearOffDynD2');
}

class Sub2 extends Base {
  @override
  void selMethodD0() => print('Sub2.selMethodD0');
  @override
  void selMethodD1() => print('Sub2.selMethodD1');
  @override
  void selMethodD2() => print('Sub2.selMethodD2');
  @override
  void selMethodD3() => print('Sub2.selMethodD3');
  @override
  void dynMethodD0() => print('Sub2.dynMethodD0');
  @override
  void dynMethodD1() => print('Sub2.dynMethodD1');
  @override
  void dynMethodD2() => print('Sub2.dynMethodD2');
  @override
  void dynMethodD3() => print('Sub2.dynMethodD3');

  @override
  int selGetterD0 = 0;
  @override
  int selSetterD0 = 0;
  @override
  int selGetterD1 = 0;
  @override
  int selSetterD1 = 0;
  @override
  int selGetterD2 = 0;
  @override
  int selSetterD2 = 0;
  @override
  int selGetterD3 = 0;
  @override
  int selSetterD3 = 0;

  @override
  int dynGetterD0 = 0;
  @override
  int dynSetterD0 = 0;
  @override
  int dynGetterD1 = 0;
  @override
  int dynSetterD1 = 0;
  @override
  int dynGetterD2 = 0;
  @override
  int dynSetterD2 = 0;
  @override
  int dynGetterD3 = 0;
  @override
  int dynSetterD3 = 0;

  @override
  void mixedDynD1StatD1_3() => print('Sub2.mixedDynD1StatD1_3');
  @override
  void mixedStatD1DynD1_3() => print('Sub2.mixedStatD1DynD1_3');
  @override
  void mixedDynD1StatD3() => print('Sub2.mixedDynD1StatD3');
  @override
  void mixedStatD1DynD3() => print('Sub2.mixedStatD1DynD3');

  @override
  void tearOffStatD1() => print('Sub2.tearOffStatD1');
  @override
  void tearOffStatD2() => print('Sub2.tearOffStatD2');
  @override
  void tearOffStatD3() => print('Sub2.tearOffStatD3');
  @override
  void tearOffStatD1CallStatD2() => print('Sub2.tearOffStatD1CallStatD2');
  @override
  void callStatD1TearOffStatD2() => print('Sub2.callStatD1TearOffStatD2');

  @override
  void tearOffDynD1() => print('Sub2.tearOffDynD1');
  @override
  void tearOffDynD2() => print('Sub2.tearOffDynD2');
  @override
  void tearOffDynD3() => print('Sub2.tearOffDynD3');
  @override
  void tearOffDynD1CallDynD2() => print('Sub2.tearOffDynD1CallDynD2');
  @override
  void callDynD1TearOffDynD2() => print('Sub2.callDynD1TearOffDynD2');
}

external void sink(Object? object);
