// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `Random.secure()` throws `UnsupportedError` each time it fails.

import "package:expect/expect.dart";
import 'dart:math';

main() {
  var result1 = getRandom();
  var result2 = getRandom();

  Expect.isNotNull(result1);
  Expect.isNotNull(result2); // This fired for http://dartbug.com/36206

  Expect.equals(result1 is Random, result2 is Random);
  Expect.equals(result1 is UnsupportedError, result2 is UnsupportedError);
}

dynamic getRandom() {
  try {
    return Random.secure();
  } catch (e) {
    return e;
  }
}
