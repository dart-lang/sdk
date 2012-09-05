// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = foo(499);
final y = foo(41) + 1;

final t = bar(499);
final u = bar(41) + 1;
final v = bar("some string");

foo(x) => x; // The return type will always be integer.
bar(x) => x; // The return type varies and can be integer or String.

main() {
  Expect.equals(499, x);
  Expect.equals(42, y);
  Expect.equals(499, t);
  Expect.equals(42, u);
  Expect.equals("some string", v);
}
