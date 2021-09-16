// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E on double show num {}

expectIdentical(dynamic a, dynamic b) {
  if (!identical(a, b)) {
    throw "Expected '${a}' and '${b}' to be identical.";
  }
}

test(E e, int value) {
  expectIdentical(e.ceil(), value);
}

main() {
  test(3.14, 4);
}
