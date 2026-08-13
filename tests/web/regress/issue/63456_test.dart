// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

@pragma('dart2js:never-inline')
List<List<int>> getPolys() => [
  [1, 3],
  [3, 4],
  [5],
];

@pragma('dart2js:prefer-inline')
int nextP(int p) {
  if (p < 0) print(p);
  return p + 1;
}

void main() {
  var polys = getPolys();
  int count = 0;
  for (int iter = 0; iter < 2; iter++) {
    bool removedAny = false;
    outer:
    for (int p = 0; p < polys.length; p = nextP(p)) {
      final poly = polys[p];
      if (poly.length <= 1) continue outer;
      for (int i = 0; i < poly.length; i++) {
        if (poly[i] == 2) {
          removedAny = true;
          break outer;
        }
      }
    }
    count++;
  }
  Expect.equals(2, count);
}
