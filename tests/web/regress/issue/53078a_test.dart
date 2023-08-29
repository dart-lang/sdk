// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 53078.

void main() {
  const int y = 3;
  int x = y;
  for (int i = 0; i < 3; i++) {
    final v = x >= y;
    print('$x >= $y is ${v}');
    if (i != 0 && v) throw 'Something is wrong';
    if (v) {
      x = 0;
    }
    x++;
  }
}
