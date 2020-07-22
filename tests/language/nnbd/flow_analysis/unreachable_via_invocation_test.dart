// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that if a method is invoked whose return type is `Never`,
// the resulting code block is considered unreachable by flow analysis.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

Never neverFunction() => throw 'x';

void explicitNeverType(Object x, bool b) {
  if (x is! int) {
    if (b) {
      neverFunction(); // Unreachable
    } else {
      return;
    }
  }
  // Since completion of `neverFunction` was unreachable, `x` is now promoted to
  // `int`.
  Expect.isTrue(x.isEven);
}

class TypeVarExtendsNever<T extends Never> {
  T tMethod() => throw 'x';

  void test(Object x, bool b) {
    if (x is! int) {
      if (b) {
        tMethod(); // Unreachable
      } else {
        return;
      }
    }
    // Since completion of `tMethod` was unreachable, `x` is now promoted to
    // `int`.
    Expect.isTrue(x.isEven);
  }
}

main() {
  explicitNeverType(0, false);
  TypeVarExtendsNever<Never>().test(0, false);
}
