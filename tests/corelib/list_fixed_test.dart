// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var a;

  a = new List(42);
  Expect.equals(42, a.length);
  Expect.throwsUnsupportedError(() => a.add(499));
  Expect.equals(42, a.length);
  for (int i = 0; i < 42; i++) {
    Expect.equals(null, a[i]);
  }
  Expect.throwsUnsupportedError(() => a.clear());
  Expect.equals(42, a.length);

  a = new List.filled(42, -2);
  Expect.equals(42, a.length);
  Expect.throwsUnsupportedError(() => a.add(499));
  Expect.equals(42, a.length);
  for (int i = 0; i < 42; i++) {
    Expect.equals(-2, a[i]);
  }
  Expect.throwsUnsupportedError(() => a.clear());
  Expect.equals(42, a.length);
}
