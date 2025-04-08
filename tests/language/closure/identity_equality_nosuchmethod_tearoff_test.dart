// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Test identity and equality of 'noSuchMethod' tearoffs.

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
  noSuchMethod(Invocation i) => 'A';
}

mixin M on A {
  noSuchMethod(Invocation i) => super.noSuchMethod(i) + ' M on A';
}

class AM extends A with M {
  Function(Invocation i) get tearoffSuperMethod => super.noSuchMethod;
}

class AMM extends AM with M {
  // Tear off the second copy of M.noSuchMethod
  // (`tearoffSuperMethod` still tears off the first copy).
  Function(Invocation i) get tearoffSuperMethodSecond => super.noSuchMethod;
  // In this case, `super.` should not make a difference.
  Function(Invocation i) get tearoffSuperMethodSecondNoSuper => noSuchMethod;
}

void main() {
  var amm = AMM();
  Function(Invocation i) vMixedInSuperMethod1 = amm.tearoffSuperMethod;
  Function(Invocation i) vMixedInSuperMethod2 = amm.tearoffSuperMethod;
  Function(Invocation i) vMixedInSuperMethodSecond1 =
      amm.tearoffSuperMethodSecond;
  Function(Invocation i) vMixedInSuperMethodSecond2 =
      amm.tearoffSuperMethodSecond;
  Function(Invocation i) vMixedInSuperMethodSecondNoSuper1 =
      amm.tearoffSuperMethodSecondNoSuper;
  Function(Invocation i) vMixedInSuperMethodSecondNoSuper2 =
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
