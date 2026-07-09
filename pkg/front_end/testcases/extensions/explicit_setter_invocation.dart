// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E on int {
  void set g(_) {}

  m() {
    g(0); // Error
  }
}

test(int i1, int? i2) {
  E(i1).g(0); // Error
  E(i2)?.g(0); // Error
}

method() {
  0.m();
  test(0, 0);
}
