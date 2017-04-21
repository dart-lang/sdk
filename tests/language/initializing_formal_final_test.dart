// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var x, y;
  // This should cause a warning because `x` is final when
  // accessed as an initializing formal.
  A(this.x)
      : y = (() {
          x = 3;
        });
}

main() {
  A a = new A(2);
  Expect.equals(a.x, 2);
  Expect.throws(() => a.y(), (e) => e is NoSuchMethodError);
}
