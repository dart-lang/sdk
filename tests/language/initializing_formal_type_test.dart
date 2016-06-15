// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// DartOptions=--initializing-formal-access

import "package:expect/expect.dart";

class A {
  int x;
  String y;
  A(this.x) : y = x { y = x; }
}

main() {
  A a = new A(null);
  Expect.equals(a.x, null);
  Expect.equals(a.y, null);
}
