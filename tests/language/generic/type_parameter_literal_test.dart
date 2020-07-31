// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test type parameter literal expressions.

class D<T> {
  Type getT() {
    return T;
  }
}

main() {
  Expect.equals(int, new D<int>().getT());
}
