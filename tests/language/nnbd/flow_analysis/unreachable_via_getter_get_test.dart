// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that if a read is performed on a getter whose type is
// `Never`, the resulting code block is considered unreachable by flow analysis.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

Never get neverGetter => throw 'x';

void explicitNeverType(Object x, bool b) {
  if (x is! int) {
    if (b) {
      neverGetter; // Unreachable
    } else {
      return;
    }
  }
  // Since the read of `neverGetter` was unreachable, `x` is now promoted to
  // `int`.
  Expect.isTrue(x.isEven);
}

class TypeVarExtendsNever<T extends Never> {
  T get tGetter => throw 'x';

  void test(Object x, bool b) {
    if (x is! int) {
      if (b) {
        tGetter; // Unreachable
      } else {
        return;
      }
    }
    // Since the read of `tGetter` was unreachable, `x` is now promoted to
    // `int`.
    Expect.isTrue(x.isEven);
  }
}

main() {
  explicitNeverType(0, false);
  TypeVarExtendsNever<Never>().test(0, false);
}
