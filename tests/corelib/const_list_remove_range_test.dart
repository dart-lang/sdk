// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testImmutable(const []);
  testImmutable(const [1]);
  testImmutable(const [1, 2]);
}

void expectUOE(Function f) {
  Expect.throws(f, (e) => e is UnsupportedError);
}

testImmutable(var list) {
  expectUOE(() {
    list.removeRange(0, 0);
  });
  expectUOE(() {
    list.removeRange(0, 1);
  });
  expectUOE(() {
    list.removeRange(-1, 1);
  });
}
