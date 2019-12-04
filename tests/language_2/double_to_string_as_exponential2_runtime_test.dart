// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  var v = 1.0;
  Expect.throwsRangeError(() => v.toStringAsExponential(-1));
  Expect.throwsRangeError(() => v.toStringAsExponential(21));



}
