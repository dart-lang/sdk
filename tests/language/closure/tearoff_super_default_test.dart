// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A1 {
  final int _i1;
  A1(this._i1);
  toString() => 'A1($_i1)';

  String foo(int i, [String s = 'A1.s']) => '$this.A1.foo($i, $s)';
}

class B1 extends A1 {
  B1() : super(100);
  toString() => 'B1($_i1)';

  String foo(int i, [String s = 'B1.s']) => '$this.B1.foo($i, $s)';

  String Function(int, [String]) getsuperfoo() => super.foo;
  String callsuperfoo1(int i) => super.foo(i);
  String callsuperfoo2(int i, String s) => super.foo(i, s);
}

class A2 {
  final int _i2;
  A2(this._i2);
  toString() => 'A2($_i2)';

  String foo(int i, [String s = 'A2.s']) => '$this.A2.foo($i, $s)';
}

class B2 extends A2 {
  B2() : super(200);
  toString() => 'B2($_i2)';

  String foo(int i, [String s = 'B2.s']) => '$this.B2.foo($i, $s)';

  String Function(int, [String]) getsuperfoo() => super.foo;
  String callsuperfoo1(int i) => super.foo(i);
  String callsuperfoo2(int i, String s) => super.foo(i, s);
}

void main() {
  // The A1/B1 sequence and A2/B2 sequence do similar tests but in a different
  // order. The super-getter is called first in ths A1/B1 sequence, but after
  // the regular getters in the A2/B2 sequence.

  // -------- A1/B1

  final b1superfoo = B1().getsuperfoo();

  Expect.equals('B1(100).A1.foo(50, A1.s)', b1superfoo(50));
  Expect.equals('B1(100).A1.foo(51, xxxx)', b1superfoo(51, 'xxxx'));

  final a1foo = A1(20).foo;
  final b1foo = B1().foo;

  Expect.equals('A1(20).A1.foo(52, A1.s)', a1foo(52));
  Expect.equals('A1(20).A1.foo(53, xxxx)', a1foo(53, 'xxxx'));
  Expect.equals('B1(100).B1.foo(54, B1.s)', b1foo(54));
  Expect.equals('B1(100).B1.foo(55, xxxx)', b1foo(55, 'xxxx'));

  Expect.equals('B1(100).A1.foo(56, A1.s)', B1().callsuperfoo1(56));
  Expect.equals('B1(100).A1.foo(57, xxxx)', B1().callsuperfoo2(57, 'xxxx'));

  // -------- A2/B2

  final a2foo = A2(20).foo;
  final b2foo = B2().foo;

  Expect.equals('A2(20).A2.foo(60, A2.s)', a2foo(60));
  Expect.equals('A2(20).A2.foo(61, xxxx)', a2foo(61, 'xxxx'));
  Expect.equals('B2(200).B2.foo(62, B2.s)', b2foo(62));
  Expect.equals('B2(200).B2.foo(63, xxxx)', b2foo(63, 'xxxx'));

  Expect.equals('B2(200).A2.foo(64, A2.s)', B2().callsuperfoo1(64));
  Expect.equals('B2(200).A2.foo(65, xxxx)', B2().callsuperfoo2(65, 'xxxx'));

  final b2superfoo = B2().getsuperfoo();

  Expect.equals('B2(200).A2.foo(66, A2.s)', b2superfoo(66));
  Expect.equals('B2(200).A2.foo(67, xxxx)', b2superfoo(67, 'xxxx'));
}
