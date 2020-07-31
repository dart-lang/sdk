// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// [NNBD non-migrated]: This file is migrated to check_strong_test.dart and
// check_weak_test.dart.
import "package:expect/expect.dart";

main() {
  Expect.throwsAssertionError(() {
    if (null) {}
  });

  Expect.throwsTypeError(() {
    if ("true" as dynamic) {}
  });
}
