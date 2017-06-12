// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int i = 0;

// Tests super calls and constructors.
main() {
  Sub sub = new Sub(1, 2);
  Expect.equals(1, sub.x);
  Expect.equals(2, sub.y);
  Expect.equals(3, sub.z);
  Expect.equals(1, sub.v);
  Expect.equals(2, sub.w);
  Expect.equals(3, sub.u);

  sub = new Sub.stat();
  Expect.equals(0, sub.x);
  Expect.equals(1, sub.y);
  Expect.equals(2, sub.v);
  Expect.equals(3, sub.w);
  Expect.equals(4, sub.z);
  Expect.equals(5, sub.u);
}

class Sup {
  var x, y, z;

  Sup(a, b)
      : this.x = a,
        this.y = b {
    z = a + b;
  }

  Sup.stat()
      : this.x = i++,
        this.y = i++ {
    z = i++;
  }
}

class Sub extends Sup {
  var u, v, w;

  Sub(a, b)
      : super(a, b),
        this.v = a,
        this.w = b {
    u = a + b;
  }

  Sub.stat()
      : super.stat(),
        this.v = i++,
        this.w = i++ {
    u = i++;
  }
}
