// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js' optimization on list length does not fold a
// length getter to a constant if the receiver can be null.

import "package:expect/expect.dart";

var a = 42;
var b;

main() {
  Expect.throws(() => b.length);
  b = const [42];
}
