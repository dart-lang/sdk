// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check compile-time constant library references with prefixes

library CTConst4Test;

import "package:expect/expect.dart";
import "ct_const4_lib.dart" as mylib;

const A = mylib.B;

main() {
  Expect.equals(1, A);
}
