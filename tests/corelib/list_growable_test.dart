// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var a;
  a = new List();
  a.add(499);
  Expect.equals(1, a.length);
  Expect.equals(499, a[0]);
  a.clear();
  Expect.equals(0, a.length);
  Expect.throws(() => a[0], (e) => e is RangeError);

  a = new List(42).toList();
  Expect.equals(42, a.length);
  a.add(499);
  Expect.equals(43, a.length);
  Expect.equals(499, a[42]);
  Expect.equals(null, a[23]);
  a.clear();
  Expect.equals(0, a.length);
  Expect.throws(() => a[0], (e) => e is RangeError);

  a = new List<int>(42).toList();
  Expect.equals(42, a.length);
  a.add(499);
  Expect.equals(43, a.length);
  Expect.equals(499, a[42]);
  for (int i = 0; i < 42; i++) {
    Expect.equals(null, a[i]);
  }
  a.clear();
  Expect.equals(0, a.length);
  Expect.throws(() => a[0], (e) => e is RangeError);
}
