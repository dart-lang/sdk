// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Check proper canonicalization (fields must be canonicalized as well).

import "package:expect/expect.dart";

main() {
  Expect.isFalse(identical(new Duration(days: 1), new Duration(days: 1)));
  Expect.isTrue(identical(const Duration(days: 2), const Duration(days: 2)));
  Expect.isTrue(identical(const B(3.0), const B(3.0)));
  Expect.isTrue(identical(const F(main), const F(main)));
}

class A {
  final a;
  const A(v) : a = v + 3.4;
}

class B extends A {
  final b;
  const B(v)
      : b = v + 1.0,
        super(v);
}

class F {
  final f;
  const F(v) : f = v;
}
