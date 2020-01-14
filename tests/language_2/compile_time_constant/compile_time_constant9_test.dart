// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class B {
  const B();
}

class A {
  var x = const B();
  A();
}

main() {
  Expect.isTrue(identical(new A().x, new A().x));
}
