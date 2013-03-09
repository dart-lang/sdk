// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing access to super from closure.

class Super {
  var superX = "super";
  get x => superX;
}

class Sub extends Super {
  var subX = "sub";
  get x => subX;

  buildClosures() => [() => x, () => this.x, () => super.x];
}

main() {
  var closures = new Sub().buildClosures();
  Expect.equals(3, closures.length);
  Expect.equals("sub", closures[0]());
  Expect.equals("sub", closures[1]());
  Expect.equals("super", closures[2]());
}
