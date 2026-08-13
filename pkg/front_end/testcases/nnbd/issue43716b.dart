// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool b = true;

void f(Object o) {}

class C<X extends void Function(X)?> {
  X x;
  C(this.x);
  void m() {
    // UP(X extends void Function(X)?, void Function(Object)) ==
    // void Function(Object)?.
    var z = b ? x : f;
    if (z == null) return;
    z(42); // Error.
  }
}

main() {}
