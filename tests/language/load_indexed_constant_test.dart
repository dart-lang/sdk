// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant propagation of load-indexed operations
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

main() {
  Expect.equals(101, stringIndexedLoad());
  Expect.equals(102, arrayIndexedLoad());
  for (int i = 0; i < 20; i++) {
    stringIndexedLoad();
    arrayIndexedLoad();
  }
  Expect.equals(101, stringIndexedLoad());
  Expect.equals(102, arrayIndexedLoad());
}

stringIndexedLoad() => ("Hello").codeUnitAt(1);
arrayIndexedLoad() => (const [101, 102, 103])[1];
