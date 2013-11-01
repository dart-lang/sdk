// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to remove bounds checks on
// boxed variables.

import "package:expect/expect.dart";

main() {
  var a = 0;
  var b = [1];
  foo() => b[a--] + b[a];
  Expect.throws(foo, (e) => e is RangeError);
}
