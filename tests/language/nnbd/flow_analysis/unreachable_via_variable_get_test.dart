// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that if a read is performed on a variable whose type is
// `Never`, the resulting code block is considered unreachable by flow analysis.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

void explicitNeverType(Never Function() f, Object x, bool b1, bool b2) {
  late Never y;
  // Loop so that flow analysis no longer can tell that y is definitely
  // unassigned
  while (true) {
    if (x is! int) {
      if (b1) {
        y; // Unreachable
      } else {
        return;
      }
    }
    // Since the read of `y` was unreachable, `x` is now promoted to `int`.
    Expect.isTrue(x.isEven);
    if (b2) return;
    y = f();
  }
}

void typeVarExtendsNever<T extends Never>(
    T Function() f, Object x, bool b1, bool b2) {
  late T y;
  // Loop so that flow analysis no longer can tell that y is definitely
  // unassigned
  while (true) {
    if (x is! int) {
      if (b1) {
        y; // Unreachable
      } else {
        return;
      }
    }
    // Since the read of `y` was unreachable, `x` is now promoted to `int`.
    Expect.isTrue(x.isEven);
    if (b2) return;
    y = f();
  }
}

main() {
  explicitNeverType(() => throw 'x', 0, false, true);
  typeVarExtendsNever<Never>(() => throw 'x', 0, false, true);
}
