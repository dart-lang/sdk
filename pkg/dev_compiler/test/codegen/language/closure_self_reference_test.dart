// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Tests a self-reference of a closure inside a try/catch.
// Dart2js must not try to box the closure-reference.

main() {
  var counter = 0;
  inner(value) {
    if (value == 0) return 0;
    try {
      return inner(value - 1);
    } finally {
      counter++;
    }
  }

  Expect.equals(0, inner(199));
  Expect.equals(199, counter);
}
