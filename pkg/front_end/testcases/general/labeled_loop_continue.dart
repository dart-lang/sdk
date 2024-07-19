// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int i = 0;
  int j = 0;
  OUTER:
  while (++i < 10) {
    if (i < 4) continue OUTER;
    j++;
  }
  if (i != 10) throw 'Expected i=10, actual $i';
  if (j != 6) throw 'Expected j=6, actual $j';
}
