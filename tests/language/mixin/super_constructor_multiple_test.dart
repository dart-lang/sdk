// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class S {
  int i;
  S.foo() : i = 1742;
}

class M1 {}

class M2 {}

class C extends S with M1, M2 {
  C.foo() : super.foo();
}

main() {
  Expect.equals(1742, new C.foo().i);
}
