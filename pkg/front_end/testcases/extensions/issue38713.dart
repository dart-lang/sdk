// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension C on int {
  static int property2;
  static void set property2(int x) {}

  static void set property3(int x) {}
  int get property3 => 1;
}

void main() {
  C.property2;
  C.property2 = 42;
  C.property3 = 42;
  42.property3;
}
