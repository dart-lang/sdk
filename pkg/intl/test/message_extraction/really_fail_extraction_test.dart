// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library really_fail_extraction_test;

import "failed_extraction_test.dart";
import "package:unittest/unittest.dart";

main() {
  test("Expect failure because warnings are errors", () {
    runTestWithWarnings(warningsAreErrors: true, expectedExitCode: 1);
  });
}
