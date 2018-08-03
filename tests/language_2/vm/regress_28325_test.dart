// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test source positions in async errors.

import "package:expect/expect.dart";
import "dart:io";

main() async {
  try {
    await Socket.connect("localhost", 0);
    Expect.isTrue(false); // Unreachable.
  } catch (e, s) {
    Expect.isTrue(e is SocketException);
    Expect.isTrue(s.toString().contains("regress_28325_test.dart"));
    print(s);
    Expect.isTrue(s.toString().contains(":12")); // Line number of "await".
  }
}
