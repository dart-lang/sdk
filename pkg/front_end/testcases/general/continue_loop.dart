// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int i = 0;
  OUTER:
  while (i++ < 10) {
    if (i < 5) continue OUTER;
    break OUTER;
  }
  if (i != 5) throw 'Expected 5, actual $i';
}
