// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library exception_implementation_test;

import "package:expect/expect.dart";

main() {
  final msg = 1;
  try {
    throw new Exception(msg);
    Expect.fail("Unreachable");
  } on Exception catch (e) {
    Expect.isTrue(e is Exception);
    Expect.equals("Exception: $msg", e.toString());
  }
}
