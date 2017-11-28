// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library Prefix21;

import "package:expect/expect.dart";
import "prefix21_good_lib.dart" as good;
import "prefix21_bad_lib.dart" as bad;

main() {
  Expect.equals(good.getValue(42), 42);
  Expect.equals(bad.getValue(42), 84);
}
