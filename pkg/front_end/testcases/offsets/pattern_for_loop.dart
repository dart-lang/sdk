// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method(List list) {
  for (var [a, b] = list; a < 10; a++) {
    print('$a, $b');
  }
  for (var [a, b] in list) {
    print('$a, $b');
  }
}

void withContinue(List<(int, int)> list) {
  for (final (x, y) in list) {
    if (x == 0) continue;
    print(x + y);
  /*end*/}
}

void withLabeledContinue(List<(int, int)> list) {
  outer:
  for (final (x, y) in list) {
    for (final z in list) {
      if (z.$1 == x) continue outer;
    }
    print(y);
  /*end*/}
}

void withoutContinue(List<(int, int)> list) {
  for (final (x, y) in list) {
    print(x + y);
  }
}

void withExpressionBody(List<(int, int)> list) {
  for (final (x, y) in list) print(x + y);
}
