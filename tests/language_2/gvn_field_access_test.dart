// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var y = 0;
  foo(x) {
    var t = this.y;
    if (t < x) {
      for (int i = this.y; i < x; i++) y++;
    }
    // dart2js was reusing the 't' from above.
    return this.y;
  }
}

void main() {
  Expect.equals(3, new A().foo(3));
}
