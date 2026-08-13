// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// The JavaScript Date constructor 'corrects' 2-digit years NN to 19NN.
// Verify that a DateTime with year 1 is created correctly.
// Regression test for https://github.com/dart-lang/sdk/issues/42894

main() {
  var d = new DateTime(1, 0, 1, 0, 0, 0, 0);
  var d2 = new DateTime(0, 12, 1, 0, 0, 0, 0);

  Expect.equals(d, d2);
}
