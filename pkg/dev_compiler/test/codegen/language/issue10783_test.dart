// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  foo(int y) { return y; }
}

main() {
  for (var b in [[false, 'pig']]) {
    var c;
    if (b[0]) c = new C();
    Expect.throws(() => print(c.foo(b[1])), (e) => e is NoSuchMethodError);
  }
}
