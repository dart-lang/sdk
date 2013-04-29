// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  call(a) => a is num;
}

main() {
  Expect.isTrue(new A().call(42));
  Expect.isFalse(new A()('foo'));
}
