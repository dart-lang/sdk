// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Second dart test program.

import "package:expect/expect.dart";

// Magic incantation to avoid the compiler recognizing the constant values
// at compile time. If the result is computed at compile time, the dynamic code
// will not be tested.
confuse(x) {
  try {
    if (new DateTime.now().millisecondsSinceEpoch == 42) x = 42;
    throw [x];
  } on dynamic catch (e) {
    return e[0];
  }
  return 42;
}

main() {
  Expect.equals("Null", null.runtimeType.toString());
  Expect.equals("Null", confuse(null).runtimeType.toString());
}
