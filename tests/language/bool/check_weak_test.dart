// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import "package:expect/expect.dart";

main() {
  Expect.throwsAssertionError(() {
    if (null as dynamic) {}
  });

  Expect.throwsTypeError(() {
    if ("true" as dynamic) {}
  });
}
