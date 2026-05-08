// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int test1(int a, int b) => a + b;

int test2(int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += i;
  }
  return sum;
}

int test3(int a1, int a2, bool c1, bool c2) {
  int b;
  if (c1) {
    b = a1 + 1;
  } else {
    if (c2) {
      b = 5;
    } else {
      b = a2;
    }
  }
  return b * 2;
}

void main() {}
