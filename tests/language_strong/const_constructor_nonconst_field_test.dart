// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final int i = f(); /// 01: compile-time error
  final int j = 1;
  const A();
}
int f() {
  return 3;
}
main() {
  Expect.equals(const A().j, 1);
}
