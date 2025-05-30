// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final F0 = 42;
const C0 = F0;
//         ^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.

main() {
  Expect.equals(42, F0);
  Expect.equals(42, C0);
}
