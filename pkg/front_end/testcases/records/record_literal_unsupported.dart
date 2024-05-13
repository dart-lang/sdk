// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

method() {
  (0, 1);
  (0, b: 1);
  (a: 0, b: 1);
  (a: 0, 1);
  (int, String);
}

sorting() {
  (a: 0, b: 1, c: 2, d: 3);
  (a: 0, b: 1, d: 2, c: 3);
  (a: 0, d: 1, b: 2, c: 3);
  (d: 0, a: 1, b: 2, c: 3);
  (0, 1, 2, a: 3, b: 4, c: 5);
  (0, 1, a: 2, 3, b: 4, c: 5);
  (0, 1, a: 2, b: 3, 4, c: 5);
  (0, 1, a: 2, b: 3, c: 4, 5);
  (0, a: 1, 2, 3, b: 4, c: 5);
  (a: 0, 1, 2, 3, b: 4, c: 5);
}

class Class {
  method() {
    (a: this, 0);
  }
}