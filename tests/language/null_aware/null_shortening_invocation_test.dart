// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check null-shortening semantics of `?.` and `?[]` when they appear as the
// target of a function invocation.

import "package:expect/expect.dart";

import "package:expect/static_type_helper.dart";

Never get unreachable => Expect.fail("Unreachable") as Never;

class A {
  int Function(Object?) getFn1() => (x) {
    Expect.fail('Should never be called');
    return 0;
  };
  int Function(Object?) Function() get getFn2 =>
      () => (x) {
        Expect.fail('Should never be called');
        return 0;
      };
  int Function(Object?) operator [](int i) => (x) {
    Expect.fail('Should never be called');
    return 0;
  };
}

main() {
  A? a = null;
  Expect.equals(
    (a?.getFn1()(unreachable))..expectStaticType<Exactly<int?>>(),
    null,
  );
  Expect.equals(
    (a?.getFn2()(unreachable))..expectStaticType<Exactly<int?>>(),
    null,
  );
  Expect.equals((a?[0](unreachable))..expectStaticType<Exactly<int?>>(), null);
}
