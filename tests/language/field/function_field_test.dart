// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int Function(int) f;

  A(this.f);
}

main() {
  A a = A((x) => x + x);
  Expect.equals(a.f(2), 4);
}
