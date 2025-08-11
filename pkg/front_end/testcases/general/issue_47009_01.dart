// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int b = 1;
  int c = 2;
  int as = 3;
  a(b < c, as > (1));
}

void a(bool x, bool y) {
  print("$x $y");
}