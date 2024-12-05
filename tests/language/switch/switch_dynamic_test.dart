// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2wasm: #56321. Switching on a dynamic value should
// use object equality for the test.

void main() {
  dynamic x = 3.0;

  switch (x) {
    case 0:
      throw 'Test failed';
    case 1:
      throw 'Test failed';
    case 2:
      throw 'Test failed';
    case 3:
      return;
  }

  throw 'Test failed';
}
