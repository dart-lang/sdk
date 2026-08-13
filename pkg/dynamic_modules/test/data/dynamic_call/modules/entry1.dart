// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import '../shared/lib.dart';

@pragma('dyn-module:entry-point')
Future<bool> dynamicModuleEntrypoint() async {
  dynamic a1 = sharedA1;

  // Dynamic method, getter, and setter calls.
  Expect.equals(a1.m4(14), 4);
  a1.m1();
  a1.s3 = 'hello';
  Expect.equals(a1.g2, 'hello');
  Expect.equals(a1.m4(14), 4);

  // Dynamic use of fields.
  Expect.equals(a1.f1, null);
  a1.f1 = 2;
  Expect.equals(a1.f1, 2);
  Expect.equals(a1.f2, 3);

  if (const String.fromEnvironment('dynamic.modules.test.mode') == 'aot') {
    // TODO(b/448095881): the tearoff operation currently fails in JIT
    // Dynamic call via getter tearoff.
    dynamic m4to = a1.m4;
    Expect.equals(m4to(14), 4);
  }

  // Ensure we don't accidentally call the target without a dynamic forwarder,
  // otherwise parameter checks are omitted accidentally.
  Expect.throws(
    () => a1.m4('str-value'),
    (e) => e is ArgumentError || e is TypeError,
    'missing error in dynamic call to host',
  );

  // Members defined in a dynamic module are dynamically-callable.
  dynamic b = B();
  Expect.equals(b.m4(14), 13);
  Expect.equals(b.m5(14), 16);

  // Members defined in a dynamic module also properly check their parameters.
  Expect.throws(
    () => b.m4('str-value'),
    (e) => e is ArgumentError || e is TypeError,
    'missing error in dynamic call within dynamic module',
  );
  Expect.throws(
    () => b.m5('str-value'),
    (e) => e is ArgumentError || e is TypeError,
    'missing error in dynamic call within dynamic module',
  );

  // A1.m6 was not exposed, even though m6 is an allowed selector.
  Expect.throws(
    () => a1.m6(),
    (e) => e is NoSuchMethodError,
    'missing error in dynamic call to unexposed allowed method m6',
  );

  // A2.m1 was not exposed, but A1.m1 was, so the selector is allowed.
  dynamic a2 = sharedA2;
  Expect.throws(
    () => a2.m1(),
    (e) => e is NoSuchMethodError,
    'missing error in dynamic call to unexposed class C.m1',
  );

  // A1.m7 is exposed in other ways, but not dynamically-callable.
  Expect.throws(
    () => a1.m7(),
    (e) => e is NoSuchMethodError,
    'missing error in dynamic call to callable but not dynamically-callable method m7',
  );

  dynamic a3 = sharedA4;

  // Interface class A3, where A3.m9 is exposed, but A3.m6 is not.
  Expect.equals(a3.m9(1), 11);
  Expect.throws(
    () => a3.m6(),
    (e) => e is NoSuchMethodError,
    'missing error in dynamic call to not dynamically-callable host method',
  );

  // Dynamic module class, base class only partially exposed.
  dynamic b5 = B5();
  Expect.throws(
    () => b5.m10(), // target is unexposed host
    (e) => e is NoSuchMethodError,
    'missing error in dynamic call to not dynamically-callable host method',
  );
  Expect.equals(b5.m11(), 4); // target in dynamic module
  Expect.equals(b5.m12(), 1); // target is exposed in host
  Expect.equals(b5.m13(), 4); // target in dynamic module

  sharedB6 = B6();
  sharedB7 = B7();

  return true;
}

class B {
  // m4 matches an exposed selector name from the host.
  int m4(int value) {
    return value - 1;
  }

  // m5 matches a selector name in the allowlist flag.
  int m5(int value) {
    return value + 2;
  }
}

class B5 extends A5 {
  @override
  int m11() => 4;

  @override
  int m13() => 4;
}

class B6 {
  int m14() => 14;
}

class B7 extends A7 {
  @override
  int m16() => 4;

  @override
  int m18() => 4;
}
