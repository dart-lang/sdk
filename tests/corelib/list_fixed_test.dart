// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var a;

  a = new List.fixedLength(42);
  Expect.equals(42, a.length);
  Expect.throws(() => a.add(499), (e) => e is UnsupportedError);
  Expect.equals(42, a.length);
  for (int i = 0; i < 42; i++) {
    Expect.equals(null, a[i]);
  }
  Expect.throws(() => a.clear(), (e) => e is UnsupportedError);
  Expect.equals(42, a.length);

  a = new List.fixedLength(42, fill: -2);
  Expect.equals(42, a.length);
  Expect.throws(() => a.add(499), (e) => e is UnsupportedError);
  Expect.equals(42, a.length);
  for (int i = 0; i < 42; i++) {
    Expect.equals(-2, a[i]);
  }
  Expect.throws(() => a.clear(), (e) => e is UnsupportedError);
  Expect.equals(42, a.length);
}
