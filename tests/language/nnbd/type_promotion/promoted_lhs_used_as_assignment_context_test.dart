// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

import 'package:expect/expect.dart';

void f(Object x) {
  if (x is double) {
    // The context for the RHS of the assignment should be `double`, so the `1`
    // should be converted to `1.0`, and thus `x` should remain promoted and
    // the call to `g` should be statically ok.
    x = 1;
    g(x);
    // Furthermore, at runtime, the value of x should be a double.
    Expect.isTrue(x is double);
    // However, the context is only advisory; it is still ok to assign a
    // non-double (un-doing the promotion).
    x = 'foo';
    Expect.isTrue(x is String);
  }
}

void g(double x) {}

main() {
  f(1.0);
}
