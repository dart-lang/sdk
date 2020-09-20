// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when a variable's type is promoted to `Never` (either
// via an explicit `is` check or a comparison to `null`), the resulting code
// block is considered unreachable by flow analysis.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

void promoteViaIsCheck(Object x, Object? y) {
  if (x is! int) {
    if (y is Never) {
      // Unreachable
    } else {
      return;
    }
  }
  // Since the `y is Never` branch was unreachable, `x` is now promoted to
  // `int`.
  Expect.isTrue(x.isEven);
}

void promoteViaIsCheck_typeVarExtendsNever<T extends Never>(
    Object x, Object? y) {
  if (x is! int) {
    if (y is T) {
      // Unreachable
    } else {
      return;
    }
  }
  // Since the `y is Never` branch was unreachable, `x` is now promoted to
  // `int`.
  Expect.isTrue(x.isEven);
}

void promoteViaIsCheck_typeVarPromotedToNever<T>(Object x, T y) {
  if (x is! int) {
    if (y is Never) {
      // Unreachable
    } else {
      return;
    }
  }
  // Since the `y is Never` branch was unreachable, `x` is now promoted to
  // `int`.
  Expect.isTrue(x.isEven);
}

void promoteViaNullCheck(Object x, Null y) {
  if (x is! int) {
    if (y != null) {
      // Unreachable
    } else {
      return;
    }
  }
  // Since the `y != null` branch was unreachable, `x` is now promoted to
  // `int`.
  Expect.isTrue(x.isEven);
}

main() {
  promoteViaIsCheck(0, 'foo');
  promoteViaIsCheck_typeVarExtendsNever<Never>(0, 'foo');
  promoteViaIsCheck_typeVarPromotedToNever<Object?>(0, 'foo');
  promoteViaNullCheck(0, null);
}
