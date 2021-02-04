// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var a;
  A() {
    a = 2;
  }
}

main() {
  Expect.equals(2, new A().a);
}
