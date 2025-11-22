// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void example1(bool c1, bool c2, bool c3, bool c4, bool c5) {
  int x = 0;
  if (c1) {
    if (c2) {
      print(x);
      x = 1;
    } else if (c3) {
      print(x);
      x = 2;
    }
  }
  print(x);
  x = 3;
  if (c4) {
    while (x < 4) {
      while (x % 2 == 0) {
        print(x);
        x += 2;
        if (c5) {
          print(x);
          return;
        }
      }
      x += 3;
    }
  }
}

void example2(int i, int j) {
  do {
    ++i;
    do {
      ++j;
      print(i);
      if (j % 2 == 0) {
        print(j);
        return;
      }
    } while (j < i);
  } while (i + j < 10);
}

void example3() {
  print(1);
  try {
    print(2);
  } finally {
    print(3);
    try {
      print(4);
    } catch (e, st) {
      print(e);
      print(st);
    }
    print(5);
  }
  print(6);
}

void main() {}
