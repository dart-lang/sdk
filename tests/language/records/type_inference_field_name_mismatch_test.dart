// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that when type inference tries to match two record types, it detects
/// whether they have mismatched field names.

import '../static_type_helper.dart';

({T foo}) f<T>(T x) => (foo: x);

g(Object y) {
  if (y is ({double foo})) {
    // The context `({double foo})` should cause `f` to be inferred as
    // `f<double>`, so `1` should be inferred with context `double` (and thus
    // should be interpreted as `1.0`).
    y = f(1..expectStaticType<Exactly<double>>());
    // `y` should not have been demoted, since the return type of `f<double>` is
    // `({double foo})`.
    y.expectStaticType<Exactly<({double foo})>>();
  }
  if (y is ({double bar})) {
    // The context `({double bar})` should NOT cause `f` to be inferred as
    // `f<double>`, so `1` should be inferred with context `_` (and thus should
    // be interpreted as `1`).
    y = f(1..expectStaticType<Exactly<int>>());
    // `y` should have been demoted, since the return type of `f` is
    // incompatible with `({double bar})`.
    y.expectStaticType<Exactly<Object>>();
  }
}

main() {
  g((foo: 0.5));
  g((bar: 0.5));
}
