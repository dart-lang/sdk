// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int foo(bool returnA0, List<int> a, [List<int> b = const []]) {
  return returnA0 ? a[0] : b[0];
}

main() {
  Expect.equals(42, foo(true, const [42]));
  Expect.throws(() => foo(false, const [42]), (e) => e is RangeError);
}
