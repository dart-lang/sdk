// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  x(p1, p2) {
    print(p1 * p2);
    if (p1 * p2 == 12) return;
    x("3", "4");
  }
}

main() => Expect.throws(() => new A().x(1, 2),
                        (e) => e is NoSuchMethodError);
