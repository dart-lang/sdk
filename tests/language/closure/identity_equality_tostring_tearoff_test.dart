// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Test identity and equality of 'toString' tearoffs.

void checkIdentical(Object o1, Object o2) {
  Expect.isTrue(identical(o1, o2));
  Expect.isTrue(o1 == o2);
  Expect.isTrue(o2 == o1);
}

void checkEqual(Object o1, Object o2) {
  Expect.isTrue(o1 == o2);
  Expect.isTrue(o2 == o1);
  // The behavior of `identical` is unspecified, optimizations could
  // make a difference and should be allowed: Do not expect anything.
}

void checkUnequal(Object o1, Object o2) {
  Expect.isTrue(o1 != o2);
  Expect.isTrue(o2 != o1);
  // We expect that `identical` is never true when `==` yields false.
  Expect.isFalse(identical(o1, o2));
}

class CheckIdentical {
  const CheckIdentical(Object o1, Object o2) : assert(identical(o1, o2));
}

class CheckNotIdentical {
  const CheckNotIdentical(Object o1, Object o2) : assert(!identical(o1, o2));
}

class A {
  // Enable a mixed-in method in `M` that has a superinvocation.
  String toString() => 'A';
}

mixin M on A {
  String toString() => super.toString() + ' M on A';
}

class AM extends A with M {
  String Function() get tearoffSuperMethod => super.toString;
}

class AMM extends AM with M {
  // Tear off the second copy of M.toString
  // (`tearoffSuperMethod` still tears off the first copy).
  String Function() get tearoffSuperMethodSecond => super.toString;
  // In this case, `super.` should not make a difference.
  String Function() get tearoffSuperMethodSecondNoSuper => toString;
}

void main() {
  var amm = AMM();
  String Function() vMixedInSuperMethod1 = amm.tearoffSuperMethod;
  String Function() vMixedInSuperMethod2 = amm.tearoffSuperMethod;
  String Function() vMixedInSuperMethodSecond1 = amm.tearoffSuperMethodSecond;
  String Function() vMixedInSuperMethodSecond2 = amm.tearoffSuperMethodSecond;
  String Function() vMixedInSuperMethodSecondNoSuper1 =
      amm.tearoffSuperMethodSecondNoSuper;
  String Function() vMixedInSuperMethodSecondNoSuper2 =
      amm.tearoffSuperMethodSecondNoSuper;

  checkEqual(amm.tearoffSuperMethod, amm.tearoffSuperMethod);
  checkEqual(vMixedInSuperMethod1, vMixedInSuperMethod2);
  checkEqual(amm.tearoffSuperMethodSecond, amm.tearoffSuperMethodSecond);
  checkEqual(vMixedInSuperMethodSecond1, vMixedInSuperMethodSecond2);
  checkUnequal(amm.tearoffSuperMethod, amm.tearoffSuperMethodSecond);
  checkUnequal(vMixedInSuperMethod1, vMixedInSuperMethodSecond2);
  checkUnequal(amm.tearoffSuperMethodSecond, amm.tearoffSuperMethod);
  checkUnequal(vMixedInSuperMethodSecond1, vMixedInSuperMethod2);

  checkEqual(
    amm.tearoffSuperMethodSecondNoSuper,
    amm.tearoffSuperMethodSecondNoSuper,
  );
  checkEqual(
    vMixedInSuperMethodSecondNoSuper1,
    vMixedInSuperMethodSecondNoSuper2,
  );
  checkUnequal(amm.tearoffSuperMethod, amm.tearoffSuperMethodSecondNoSuper);
  checkUnequal(vMixedInSuperMethod1, vMixedInSuperMethodSecondNoSuper2);
  checkUnequal(amm.tearoffSuperMethodSecondNoSuper, amm.tearoffSuperMethod);
  checkUnequal(vMixedInSuperMethodSecondNoSuper1, vMixedInSuperMethod2);

  checkEqual(amm.tearoffSuperMethodSecond, amm.tearoffSuperMethodSecondNoSuper);
}
