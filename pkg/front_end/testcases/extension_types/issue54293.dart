// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Int(int i) implements int {
  Int operator +(int other) {
    return Int(i + other);
  }
}

void test() {
  int a = 2;
  Int b = Int(8); /* Ok */

  b = b + a; /* Ok */
  b = a + b; /* Error */
  a = a + b; /* Ok */
  print(a + b); /* Ok */
}
