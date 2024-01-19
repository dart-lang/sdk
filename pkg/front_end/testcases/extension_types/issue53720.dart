// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type E1(int i) {
  set m(_) {}
}

extension type E2(int i) implements E1 {
  void m() {}
}

void test() {
  E2(1).m = 10; /* Error */
}