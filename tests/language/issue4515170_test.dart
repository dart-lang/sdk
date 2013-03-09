// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Issue4515170Test {
  static const VAL = 3;
  static int defaultVal([int a = VAL]) {
    return a;
  }
}

main() {
  Expect.equals(3, Issue4515170Test.defaultVal());
}
