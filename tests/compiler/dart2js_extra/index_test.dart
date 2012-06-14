// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var a = [0];
  Expect.equals(0, a[0]);

  a = [1, 2];
  Expect.equals(1, a[0]);
  Expect.equals(2, a[1]);

  a[0] = 42;
  Expect.equals(42, a[0]);
  Expect.equals(2, a[1]);

  a[1] = 43;
  Expect.equals(42, a[0]);
  Expect.equals(43, a[1]);

  a[1] += 2;
  Expect.equals(45, a[1]);
  a[1] -= a[1];
  Expect.equals(0, a[1]);

  var b = a[1]++;
  Expect.equals(1, a[1]);
  Expect.equals(0, b);

  b = ++a[1];
  Expect.equals(2, a[1]);
  Expect.equals(2, b);

  b = a[1]--;
  Expect.equals(1, a[1]);
  Expect.equals(2, b);

  b = --a[1];
  Expect.equals(0, a[1]);
  Expect.equals(0, b);
}
