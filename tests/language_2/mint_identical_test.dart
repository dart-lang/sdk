// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Smis on 64-bit.
  Expect.isTrue(identical(2305843009213693952, 2305843009213693952));
  Expect.isTrue(identical(2305843009213693953, 2305843009213693953));
  Expect.isTrue(identical(2305843009213693954, 2305843009213693954));
  Expect.isTrue(identical(4611686018427387903, 4611686018427387903));

  // Mints on 64-bit.
  Expect.isTrue(identical(4611686018427387904, 4611686018427387904));
  Expect.isTrue(identical(4611686018427387905, 4611686018427387905));
}
