// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  call({a: 42}) {
    return 499 + a;
  }
}

main() {
  Expect.equals(497, Function.apply(new A(), [], {#a: -2}));
}
