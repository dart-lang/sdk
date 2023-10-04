// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int bad() { // LINT
  return 1;
}

int good() {
  int a = 2 + 3;
  return a;
}

class A {
  int left = 1, right = 1;
  bool one = false;

  int bad() { // LINT
    return 1;
  }

  int good() { // OK
    int a = 2 + 3;
    return a;
  }

  int good2() { // OK
    if (one) { // OK because it is not a block of a function or method
      return 1;
    }
    return 0;
  }

  get badWidth { // LINT
    return right - left;
  }

  int get goodWidth => right - left; // OK

  set goodWidth(int width) => right = left + width; // OK

  set goodWidth2(int width) { // OK
    right = left + width;
  }
}
