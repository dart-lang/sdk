// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bug in unboxed int spilling (https://github.com/flutter/flutter/issues/23879).
//
// VMOptions=--deterministic

import "package:expect/expect.dart";

List<int> list = new List<int>(10);

List<int> expected_values = [null, 152, 168, 184, 200, 216, 232, 248, 264, 280];

int count = 0;

bool getNext() {
  return ++count <= 9;
}

int foo() {
  int a = 1;
  int b = 2;
  int c = 3;
  int d = 4;
  int e = 5;
  int f = 6;
  int g = 7;
  int h = 8;
  int i = 9;
  int j = 10;
  int k = 11;
  int l = 12;
  int m = 13;
  int n = 14;
  int o = 15;
  int p = 16;
  count = 0;
  int componentIndex = 1;
  while (getNext()) {
    // Make spilling likely.
    a++;
    b++;
    c++;
    d++;
    e++;
    f++;
    g++;
    h++;
    i++;
    j++;
    k++;
    l++;
    m++;
    n++;
    o++;
    p++;
    list[componentIndex] =
        a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p;
    componentIndex++;
  }
  return componentIndex;
}

void main() {
  int x = foo();
  Expect.equals(10, x);
  Expect.equals(10, count);
  for (int i = 0; i < 10; i++) {
    Expect.equals(expected_values[i], list[i]);
  }
}
