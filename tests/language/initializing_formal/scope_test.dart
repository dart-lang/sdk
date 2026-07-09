// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Duplicate definition checks for `this.x` will check the scopes associated
// with the constructor, not all enclosing scopes; so this is not a conflict.
var x;

class A {
  var x;
  A(this.x) {
    // In the body the field is in scope, not the initializing formal;
    // so we can use the setter.
    x += 1;
  }
}

main() {
  A a = new A(2);
  Expect.equals(a.x, 3);
}
