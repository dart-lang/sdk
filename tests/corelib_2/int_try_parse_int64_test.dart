// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:math" show pow, log;

void main() {
  // Big numbers (representable as both Int64 and double).
  Expect.equals(9223372036854774784, int.tryParse("9223372036854774784"));
  Expect.equals(-9223372036854775808, int.tryParse("-9223372036854775808"));
}
