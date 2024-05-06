// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies different corner cases around calling functions in
// Dart.
import 'package:expect/expect.dart';

import 'calling_conventions_il_test.dart';

class ChildWithBoxedParameterOverride extends Base {
  ChildWithBoxedParameterOverride(super.o);

  @override
  @pragma('vm:never-inline')
  String f([String v = 'ok!']) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  String fOptional([String v = 'ok!']) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  String fNamed({String v = 'ok!'}) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  int fIntInt(dynamic a, [int b = 0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  double fIntDouble(dynamic a, [double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  double fDoubleDouble(dynamic a, [double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  int fIntOptionalInt([dynamic a = 0, int b = 0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  double fIntOptionalDouble([dynamic a = 0, double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  double fDoubleOptionalDouble([dynamic a = 0.0, double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  int fIntNamedInt(dynamic a, {int b = 0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  double fIntNamedDouble(dynamic a, {double b = 0.0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  double fDoubleNamedDouble(dynamic a, {double b = 0.0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }
}

class Wrapper {
  final dynamic val;

  Wrapper(this.val);

  operator +(dynamic arg) {
    return val + arg;
  }
}

void testDirectCalls3(String str, int ia, int ib) {
  final da = ia.toDouble();
  final db = ib.toDouble();
  final child = ChildWithBoxedParameterOverride(str);

  Expect.equals("ok+ok+", child.f(str));
  Expect.equals("ok+ok!", child.fOptional());
  Expect.equals("ok+ok+", child.fOptional(str));
  Expect.equals("ok+ok!", child.fNamed());
  Expect.equals("ok+ok+", child.fNamed(v: str));
  Expect.equals(142, child.fIntInt(Wrapper(ia), ib));
  Expect.equals(142, child.fIntDouble(Wrapper(ia), db));
  Expect.equals(142, child.fDoubleDouble(Wrapper(da), db));
  Expect.equals(42, child.fIntOptionalInt(Wrapper(ia)));
  Expect.equals(142, child.fIntOptionalInt(Wrapper(ia), ib));
  Expect.equals(42, child.fIntOptionalDouble(Wrapper(ia)));
  Expect.equals(142, child.fIntOptionalDouble(Wrapper(ia), db));
  Expect.equals(42, child.fDoubleOptionalDouble(Wrapper(da)));
  Expect.equals(142, child.fDoubleOptionalDouble(Wrapper(da), db));
  Expect.equals(42, child.fIntNamedInt(Wrapper(ia)));
  Expect.equals(142, child.fIntNamedInt(Wrapper(ia), b: ib));
  Expect.equals(42, child.fIntNamedDouble(Wrapper(ia)));
  Expect.equals(142, child.fIntNamedDouble(Wrapper(ia), b: db));
  Expect.equals(42, child.fDoubleNamedDouble(Wrapper(da)));
  Expect.equals(142, child.fDoubleNamedDouble(Wrapper(da), b: db));
}

void main(List<String> args) {
  runTests(args, [
    ...directCallsTests,
    testDirectCalls3,
  ], [
    ...childClassFactories,
    ChildWithBoxedParameterOverride.new,
  ]);
}
