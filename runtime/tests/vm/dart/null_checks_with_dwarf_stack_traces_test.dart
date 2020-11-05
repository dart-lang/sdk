// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--dwarf-stack-traces

// This test verifies that null checks are handled correctly
// with --dwarf-stack-traces option (dartbug.com/35851).

import "package:expect/expect.dart";

class A {
  void foo() {
    Expect.fail('A.foo should not be reachable');
  }

  dynamic get bar {
    Expect.fail('A.bar should not be reachable');
  }

  set bazz(int x) {
    Expect.fail('A.bazz should not be reachable');
  }
}

dynamic myNull;
dynamic doubleNull;
dynamic intNull;

main(List<String> args) {
  // Make sure value of `myNull` is not a compile-time null and
  // devirtualization happens.
  if (args.length > 42) {
    myNull = new A();
    doubleNull = 3.14;
    intNull = 2;
  }

  Expect.throws(() => myNull!, (e) => e is TypeError);

  Expect.throws(() => myNull.foo(), (e) => e is NoSuchMethodError);

  Expect.throws(() => myNull.foo, (e) => e is NoSuchMethodError);

  Expect.throws(() => myNull.bar, (e) => e is NoSuchMethodError);

  Expect.throws(() => myNull.bar(), (e) => e is NoSuchMethodError);

  Expect.throws(() {
    myNull.bazz = 3;
  }, (e) => e is NoSuchMethodError);

  Expect.throws(() => doubleNull + 2.17, (e) => e is NoSuchMethodError);

  Expect.throws(
      () => 9.81 - doubleNull,
      (e) =>
          hasUnsoundNullSafety ? (e is NoSuchMethodError) : (e is TypeError));

  Expect.throws(() => intNull * 7, (e) => e is NoSuchMethodError);
}
