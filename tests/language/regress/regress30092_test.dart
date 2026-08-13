// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BigInt {}

main() {
  void foo(void Function(BigInt, BigInt) f) {
    f(new BigInt(), new BigInt());
  }

  foo((x, y) {});
}
