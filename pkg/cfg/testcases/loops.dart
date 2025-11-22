// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void nested(int i) {
  for (int i = 0; i < 10; ++i) {
    while (i < 5) {
      print(++i);
    }
  }
  print(i);
  while (i < 10) {
    for (int j = 0; j < 3; ++j) {
      i += j;
    }
  }
  print(i);
}

void chainedHeaders(int i) {
  do {
    do {
      i -= 17;
    } while (i >= 0);
  } while (i % 2 == 0);
}

void irreducible(int i) {
  switch (i) {
    L1:
    case 1:
      i += 1;
      continue L2;
    L2:
    case 2:
      i += 2;
      if (i > 10) {
        break;
      }
      continue L1;
  }
}

void main() {}
