// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for compiling an access on an uninstantiated record shape. Such accesses
// are on infeasible paths, but the code for the access might not be be
// optimized away, or optimized away after it is generated.

import "package:expect/expect.dart";

List log = [];

test(o) {
  if (o is (int, {int oink})) {
    // Infeasible path since record with shape `(_, {oink})` never created.
    log.add(o.$1);
  }
  if (o is (int, {int oink})) {
    log.add(o.oink); // Also try named field.
  }
  if (o is (int, int)) {
    log.add(o.$2);
  }
}

main() {
  test(1);
  test((11, 22));
  Expect.equals('22', log.join(';'));
}
